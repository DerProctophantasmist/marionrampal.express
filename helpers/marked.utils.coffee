

nbrOfSectionsToLoad = null

module.exports = (callbacks) ->  
  nbrOfSectionsToLoad = callbacks.nbrOfSectionsToLoad  

marked = require('marked')
oldRenderer = new marked.Renderer()
ResourceFile = require('./resourceFile')
{includeSectionFile,includePageFile,registerSectionData} = require('./resourceFile.impl')
EmbedUrl =  require('./resourceUrl').embedUrl

CSON = require('cson-parser')
htmlentities = require('html-entities')

# console.log "marked defaults: "
# console.log marked.defaults
renderer =
  link :  ( href, title, text) ->
    if  res = ResourceFile(href,title,text,false) #last param is embed=true/false
      return res.html;
    else 
      return oldRenderer.link(href,title,text)
  # heading: (text, level,raw,slugger) ->
  #   if level > 3 then return oldRenderer.heading(text,level,raw,slugger)
  #   escapedText = text.toLowerCase().replace(/[^\w]+/g, '-')
  #   return '<h' + level + ' class="special-font" ><a name="' +
  #     escapedText +
  #     '" class="anchor" href="#' +
  #     escapedText +
  #     '"><span class="header-link"></span></a>' +
  #     text + '</h' + level + '>';
    
  image : ( href, title, text) ->
    if (res = EmbedUrl(href, title, text) || res = ResourceFile(href, title, text, true) )
      # if res.provider &&res.provider != text.toLowerCase() then console.error('embeding failed for: ' + href + 'service ('+text+') doesn\'t match the one in the url ('+res.provider+')')
      return res.html;
    else 
      return '<img class="image centered half" src="'+href+'" alt="'+text+'" title="'+title+'" >'
  code :  (code,  infostring,  escaped) ->
    res = shorthand(infostring, code)
    return if res then res else oldRenderer.code(code, infostring, escaped) 


    

#for rendering the markdown inside the carousel code block, we start from our default options,
genRenderer = new marked.Renderer
genRenderer.link = renderer.link
genRenderer.image = renderer.image
genRenderer.code = renderer.code 
console.log "genRenderer"
options = { gfm: true, breaks: false, renderer: genRenderer}
marked.setOptions(options)
lexer = new marked.Lexer(options)


shorthand = (heading, content) ->
  switch heading
    when 'carousel'
      result = lexer.lex(content);
      # console.log "carousel content:"
      result = parserFactory(carouselScheme)(result)
      # console.log result
      return result
    when "figure"
      # result = marked.inlineLexer(content,[],options)
      result = marked(content,options)
      # console.log result
      return result = """
        <figure left-aside class="clickable image half" mdfile="#{params.mdfile}" >
          #{result}                                        
          <figcaption>#{params.caption}</figurecaption>
        </figure>          
        """
    when "imagesLeft"
      result = marked(content,options)
      # console.log result
      return result = """
        <div style="margin: 0" class="force-float-images-left clearfix">
          #{result}                                            
        </div>            
        """
    when 'sections' #section list
      result = lexer.lex(content);
      # console.log "sections content: "
      acc = {nbr:0}
      result = parserFactory(sectionsScheme(acc))(result)
      # console.log result
      if nbrOfSectionsToLoad
        nbrOfSectionsToLoad(acc.nbr)
      return result

    when 'singlePage' #single page section
      section={}
      result = lexer.lex(content);
      result = parserFactory(singlePageScheme(section))(result)

      page = section.page
      delete section.page

      if registerSectionData then registerSectionData(section)
      
      #we "fetch" the parent section from the section controller, see section.coffee:
      return """ 
      <section  ng-if="website.displaySection('#{section.id}')"  id="#{section.id}" section-data='#{JSON.stringify(section).replace(/'/g, "&apos;")}' class="section-#{section.id}"
      style="{{(website.state.getAllowEdit())?'min-height:6em;':''}}">
        <page sec-ctrl='$sc' page-data='#{JSON.stringify(page)}'> 
          #{result}
        </page>
      </section>
      """
    else  
      return false


carouselScheme = 
  list: (body) -> 
    '<div uib-carousel active="active" interval="website.getCarouselInterval()">  \n' +  body + '  \n</div>  \n'
  listItem: (body, curIndex) ->
    '<div uib-slide index="' + curIndex + '" >  \n' + marked(body,options) + '  \n</div>  \n'

sectionsScheme = (acc) -> 
  scheme = 
    text: (text) -> text
    link: ()->{}
    image: ( href, title, text) ->
      acc.nbr++
      return """ 
        #{includeSectionFile(href, {id:text})}
      """

  scheme.inlineLexer = new marked.InlineLexer([], {options...,renderer:scheme})
  return scheme


singlePageScheme = (section)->
  cur = {data : section, root: null}
  closingSub = false # true if we need to close nested list and link it to root data
  prevIndex = -1
  scheme = 
    list: (body) -> # we are out of the nested list (it's actually called a second time when we are out of the main section list, but we don't care)
      closingSub = true
      ""
    listItem: (body, curIndex) ->
      if curIndex == 0 && curIndex <= prevIndex # we are at the start of a nested list
        newNode = {}
        newNode.root = cur
        newNode.data = {}
        cur = newNode
        inSub = true
      prevIndex = curIndex
      i = body.indexOf(':')
      if i!=-1
        key = body.substring(0, i).trim()
        value = body.substring(i+1).trim() 
        try
          cur.data[key]= CSON.parse value
        catch e
          msg = "data in section " + section.id + " not well formed: " + value + " is not a json string. " + e.message
          console.log msg
      else if closingSub
        cur.root.data[body.trim()]=cur.data
        cur=cur.root
        closingSub = false
        # just do nothing, it's ok, we'll do cur = section with the list token
      else       
        console.log "malformed data: " + body
        return ""
      return ""
    text: (text) -> text
    link: ()->{}
    image: ( href, title, text) ->
      box = {}
      title = htmlentities.decode(title)
      if title != ""        
        try
          box=CSON.parse title
        catch e
          msg = "box not well formed: " + title + " is not a cson string. " + e.message
          console.log msg
          return "<div>" + msg + "</div>"
      html ="""
        <div ng-controller="BoxCtrl" class="content-sizer box #{text}" ng-hide="website.isMainContentHidden()">
      """
      if box.mobileHeader
        html+="""
          <mobile-header>
          </mobile-header>
        """
      return html + """         
        #{includePageFile(href)}
        </div>
      """
  scheme.inlineLexer = new marked.InlineLexer([], {options...,renderer:scheme})
  return scheme


parserFactory = (parserScheme)->
  token = null
  tokens = null
  curIndex = 0

  parse = (src) ->
    tokens = src.reverse()

    out = '';
    while next()
      out += tok()

    return out 
  
  # * Next Token
  
  next = ()->
    token = tokens.pop()
    return token

  
  #  Preview Next Token
  peek = () ->
    tokens[tokens.length - 1] || 0

  # * Parse Text Tokens
  parseText = () ->
    body = token.text
    while (peek().type == 'text')
      body += '\n' + next().text

    return body

  unknownToken = () ->
    errMsg = 'Token with "' + token.type + '" type was not found.'
    console.log errMsg
    return ''
  # Parse Current Token

  tok = () ->
    switch token.type
      when 'space'
        return ''
      # when 'hr': 
      #   return renderer.hr();
      
      # when 'heading': 
      #   return renderer.heading(
      #     inline.output(token.text),
      #     token.depth,
      #     unescape(inlineText.output(token.text)),
      #     slugger);
      
      # when 'code': 
      #   return renderer.code(token.text,
      #     token.lang,
      #     token.escaped);
      
      # when 'table': 
      #   header = ''
      #   body = ''

      #   // header
      #   cell = '';
      #   for (i = 0; i < token.header.length; i++) 
      #     cell += renderer.tablecell(
      #       inline.output(token.header[i]),
      #       { header: true, align: token.align[i] 
      #     );
        
      #   header += renderer.tablerow(cell);

      #   for (i = 0; i < token.cells.length; i++) {
      #     row = token.cells[i];

      #     cell = '';
      #     for (j = 0; j < row.length; j++) {
      #       cell += renderer.tablecell(
      #         inline.output(row[j]),
      #         { header: false, align: token.align[j] 
      #       );
          

      #     body += renderer.tablerow(cell);
        
      #   return renderer.table(header, body);
      
      # when 'blockquote_start': 
      #   body = '';

      #   while (next().type !== 'blockquote_end') 
      #     body += tok();         

      #   return parserScheme.blockquote(body);
      
      when 'list_start'
        if !parserScheme.list then return unknownToken()
        curIndex = 0 
        body = ''
        ordered = token.ordered
        start = token.start

        while (next().type != 'list_end') 
          body += tok();          

        return parserScheme.list(body)
      
      when 'list_item_start'
        if !parserScheme.listItem then return unknownToken()
        body = ''
        loose = token.loose
        checked = token.checked
        task = token.task

        # if (token.task) 
        #   body += renderer.checkbox(checked);
        

        # while (next().type !== 'list_item_end') 
        #   body += !loose && token.type === 'text'
        #     ? parseText()
        #     : tok();

        while next().type != 'list_item_end'
          body += if !loose && token.type == 'text' then  parseText() else tok()
        
        return parserScheme.listItem(body,curIndex++)
      
      # when 'html': 
      #   // TODO parse inline content if parameter markdown=1
      #   return renderer.html(token.text);
      
      when 'paragraph' 
        if !parserScheme.inlineLexer then return unknownToken()
        return parserScheme.inlineLexer.output(token.text)
      
      when 'text'
         return parserFactory(parserScheme)(parseText())
      
      else 
        return unknownToken()
        
      
  return parse
