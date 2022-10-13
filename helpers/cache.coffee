
{markedRenderer, markdownEmbed, renderMarkdown} = require('../helpers/resourceFile.impl')
log = require('../helpers/logger').mainLogger
vasync = require('vasync')
markdownParam = require('../helpers/marked.utils')
sections = require('../helpers/sections')

globalCache =
  en:null, fr:null


cacheFactory = (entryFile, language) ->
  (doneCachingLanguage) ->   
    markedRenderer.run cacheVersion = () ->
      markedRenderer.set('language', language)
      log.info {
        name: "running cache"
        language
      }
      done = (cache)->
        # log.info {lang:language, cache: cache}
        globalCache[language]=cache
        doneCachingLanguage(null, cache)
      return renderMarkdown(entryFile, done)
    
createGlobalCache = (dataDir,entryFile, callback) ->
  markedRenderer.run ()->
    markedRenderer.set('dataRoot', dataDir)
    for language of globalCache
      markedRenderer.set('first.pass.language', language)
      break;
    markdownParam({nbrOfSectionsToLoad:setNbrOfSections})
    versions = []
    for language of globalCache
      versions.push( cacheFactory(entryFile, language) )
    # log.info({versions:versions})
    
    vasync.parallel(
        'funcs': versions,
      callback
    )
nbrOfSections = 0

setNbrOfSections = (nbr) ->
  if nbrOfSections 
    if nbrOfSections != nbr 
      log.error "WTF? sections are not language specific. Something is very wrong."
    return
  nbrOfSections = nbr
  sections.nbrOfSectionsToLoad(nbr)



module.exports = 
  globalCache: globalCache
  createGlobalCache: createGlobalCache
  getNbrOfSections: ()-> return nbrOfSections