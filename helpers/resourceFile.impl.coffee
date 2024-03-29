log = require('../helpers/logger').mainLogger
VErr = require 'verror'
sections = require('../helpers/sections')

createNamespace = require('cls-hooked').createNamespace
markedRenderer = createNamespace('markedRenderer')

{readFile} = require('fs')
marked = require('marked')

localizeFilename = (filename) -> 
  filename = decodeURIComponent(filename)
  if filename.substr(-3) != '.md' then filename + '.' + markedRenderer.get('language') + '.md' else filename

markdownLinkTo = (url, chapeau, inline) ->
  if markedRenderer.get('resolvingMarkdownLinks')  == 1 
    if !markedRenderer.get("file:"+url)
      return cacheFile(url)
    return '' #ok, already cached
  if markedRenderer.get('resolvingMarkdownLinks') == 2  #done resolving links
    return """
    <include-markup content="{
        &quot;filename&quot;:&quot;#{url}&quot;,
        &quot;chapeau&quot;:&quot;#{chapeau.replace(/[\n\\\"]/g,escape)}&quot;,
        &quot;inline&quot;:#{if inline then 'true' else 'false'}
      }" popup-links="popupLinks">#{markedRenderer.get("file:"+url)}</include-markup>
    """
  log.error new VErr(), "We should never be here"


# we do a two pass rendering: first an assynchronous caching of all the files referenced in the markdown
# then a synchronous rendering calling marked(data) recursively on the cached files
# obviously this is not optimal: at the very least we should also be caching the result
markdownEmbed = (url, title) ->
  if markedRenderer.get('resolvingMarkdownLinks')  == 1 
    if !markedRenderer.get("file:"+url)
      return cacheFile(url)
    return "" #ok, already cached
  if markedRenderer.get('resolvingMarkdownLinks') == 2  #done resolving links
    return """
    <div marked compile=true prerendered=true filename="'#{url}'">
      #{marked(markedRenderer.get("file:"+url))}
    </div>
    """
  log.error new VErr(), "We should never be here"

isFirstPass = ()->
  return markedRenderer.get('first.pass.language') == markedRenderer.get('language') && markedRenderer.get('resolvingMarkdownLinks') == 1

includeSectionFile = (url, section) ->
  if isFirstPass() then sections.registerSection(section)
  return markdownEmbed(url)


cacheFile = (url)->
  dataRoot = markedRenderer.get('dataRoot')
  openFiles = markedRenderer.get("open") ? 0
  markedRenderer.set("open",openFiles + 1)
  readFile("#{dataRoot + localizeFilename(url)}",'utf8', (err, data) ->    
    if(err)
      log.error err, "cannot read #{localizeFilename(url)}"
      data = ""
    openFiles = markedRenderer.get("open")
    markedRenderer.set("open",openFiles - 1)
    markedRenderer.set("file:"+url,data)
    marked(data)
    if markedRenderer.get("open") == 0 
      markedRenderer.get('doneResolving')()
    return ''
  )
  

#the callback takes one param: the calculated cache
renderMarkdown = (url, callback) ->
  markedRenderer.set('resolvingMarkdownLinks', 1)
  markedRenderer.set('doneResolving', doneResolving(url, callback))
  markdownEmbed(url)

doneResolving = (url, callback) ->
  ()->
    markedRenderer.set('resolvingMarkdownLinks', 2)
    cache = markdownEmbed(url)
    callback(cache)

registerSectionData = (sectionData) ->
  if isFirstPass() then log.info {name: "register section data", section: sections.registerSectionData(sectionData).id}
  return


module.exports = 
  markdownLinkTo:markdownLinkTo
  markdownEmbed:markdownEmbed
  markedRenderer:markedRenderer
  includePageFile:markdownEmbed
  includeSectionFile:includeSectionFile
  renderMarkdown:renderMarkdown
  registerSectionData:registerSectionData