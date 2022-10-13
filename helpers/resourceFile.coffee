
{markdownLinkTo, markdownEmbed} = require('./resourceFile.impl')

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

  
  switch text
    when 'markdown'
      title?= ""
    when 'inline'
      inline = true # this is for link type only, makes no sense for embed
      title?= ''
    else #check the file extension to see if it is a markdown file
      file = url.match(/\.([^.]+)$/)
      return false if !file[1]? #no extension
      switch file[1] 
        when 'md' #treat as markdown             
          title?= (text?= ""); # if title is empty, use text instead to create the chapeau
        when 'i18n'  #treat as markdown, filename needs to be localised (include-markup takes care of that when we get rid of the extension)   
          url = url.substr(0, url.length -5)     
          title?= (text?= "")
        else return false #not a resource link

   
  html =  genHtml(url, title, inline)
          
  return {
    html: html
  } 

module.exports = resourceFile
 