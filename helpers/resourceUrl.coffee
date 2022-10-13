
attributeString = (object) ->
  ret = " "
  for own key, value of object
    ret += key+'="' +value.replace(/"/g,"&quote;")+ '" '
  return ret

resourceUrl = (url,title, text) ->
  
  #note that subdomain includes the final '.'
  res = false
  if style=text.match(/^\w*class=(?<class>[^ ]+)\w*$/)
    res =  {
      html: '<a href="'+url+'" class="'+style.groups.class+'"/></a>'
    }      
  else if provider = url.match(/(?<protocol>https?:\/\/)(?<subdomain>[^./]+\.)?(?<domain>[^./]+(?:\.[^./]+)+)/)
    switch provider.groups.domain
      when 'soundcloud.com' 
        res =  {
          provider: "soundcloud"
        }
      when 'youtu.be', 'youtube.com'
        res =  {          
          provider: "youtube"
        }
      when 'vimeo.com'
        res =  {
          provider: 'vimeo'
        }
      when 'akamaihd.net'
        res = {
          provider: "akamai"
          'player-id': provider.groups.subdomain + provider.groups.domain 
          image: text ? ""
        }
      when 'fnac.com'
        res =  {
          html: '<a href="'+url+'" /><span class="icon-fnac"></span></a>'
        }        
      when 'qobuz.com'
        res =  {
          html: '<a href="'+url+'" /><span class="icon-qobuz"></span></a>'
        }   
      when 'spotify.com'
        res =  {
          html: '<a href="'+url+'" /><span class="icon-spotify"></span></a>'
        }
      when 'amazon.com', 'amazon.co.uk', 'amazon.de', 'amazon.fr', 'amazon.be'
        res =  {
          html: '<a href="'+url+'" /><span class="icon-amazon"></span></a>'
        }      
      when 'bandcamp.com'
        res =  {
          html: '<a href="'+url+'" /><span class="icon-bandcamp"></span></a>'
        }
  if res then res.url = url
  return res


embedUrl = (url,title,text) -> 
  res = resourceUrl(url,title,text) 
  if res && !res.html  
    res.html = '<o-embed' + attributeString(res) + '></o-embed>'
  return res


module.exports = 
  embedUrl:embedUrl
  resourceUrl:resourceUrl