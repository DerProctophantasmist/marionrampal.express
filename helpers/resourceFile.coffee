
{markdownLinkTo, markdownEmbed} = require('./resourceFile.impl')
CSON = require("cson-parser")

escape = (str)->
    #nueuuasrege!
    switch str
        when "\n"
            return "\\n"
        when "\""
            return "\\&quot;"
    return str


resourceFile = (url,title,text,embed) ->  
  genHtml = if embed then markdownEmbed else markdownLinkTo
  inline = false
  params = {}

  
  switch text
    when 'markdown'
      content = {filename:url,chapeau: tille?""}
    when 'inline'
      content = {filename:url,chapeau: tille?"",inline:true}# inline is for link type only, makes no sense for embed
    else 
      try #text is CSON 
        params = CSON.parse text.replace(/(&#39;)|(&quot;)/g, (sub)->
          switch sub  
            when "&#39;"
              return "'"
            when "&quot;"
              return '"'
        )
        content = {filename:url, chapeau :title}
      catch#check the file extension to see if it is a markdown file
        file = url.match(/\.([^.]+)$/)
        return false if !file?[1]? #no extension
        content = {chapeau: title?text?""}
        switch file[1] 
          when 'md' #treat as markdown             
            content.filename = url
          when 'i18n'  #treat as markdown, filename needs to be localised (include-markup takes care of that when we get rid of the extension)   
            content.filename = url.substr(0, url.length -5)     
          else return false #not a resource link

  content.chapeau = content.chapeau.replace(/[\n\\\"]/g,escape)
  if !embed && !(content.inline?) then content.inline = false
  params.content = content
   
  html =  genHtml(params) 
          
  return {
    html: html
  } 

module.exports = resourceFile
 
 