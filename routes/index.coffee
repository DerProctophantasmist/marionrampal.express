express = require('express')
router = express.Router()

log = require('../helpers/logger').mainLogger
VErr = require('verror')
hbs = require('hbs')



httpContext = require('express-http-context')

{globalCache,getNbrOfSections} = require('../helpers/cache')

sections = require('../helpers/sections')


hbs.registerHelper('description', () ->
  page = this.page ? sections.head?.id
  return sections.data[page]?.description?[this.curLang]
)


hbs.registerHelper('websiteTitle', () ->
  page = this.page ? sections.head?.id
  title = sections.data[page]?.title ? sections.data[page]?.name
  return title?[this.curLang]
)


 
hbs.registerHelper('includeRoot', (filename) ->
  log.info {curLang:this.curLang, httpContextLang: httpContext.get('curLang')}
  if this.allowEdit == "false"  
    if this.cache
      return new hbs.SafeString cache  
    return new hbs.SafeString """
      <marked compile="true" filename="'#{filename}'"></marked>
      """    
  return new hbs.SafeString("""
    <marked compile="true" filename="'#{filename}'"  editor-button-style="position:absolute;top:2em;left:0;color:black;z-index:1000;"></marked>
    """
  )
)

language = (req,res,next) ->
  log = require('../helpers/logger').requestLogger(req)
  fbLang = req.get('X-Facebook-Locale')
  if cookieLang = req.cookies["marionrampal.locale"]
    cookieLang = cookieLang.substring(0,2)
    log.info {cookieLang: cookieLang}

  res.locals.prefLang = cookieLang ? req.acceptsLanguages('fr','en') ? fbLang ? 'en'

  forceLang = req.query.forceLang
  if forceLang == "" then forceLang = null
  res.locals.forceLang = forceLang
  res.locals.curLang =  forceLang ? fbLang ? res.locals.prefLang

  httpContext.set('curLang',res.locals.curLang)
  next()

cache = (req,res,next) -> 
  next()

onInit = (_,config) ->
  log.info({config}, "configuration object")
  # GET home page. 
  router.get('/', httpContext.middleware, language, cache, (req, res, next) ->
    log = require('../helpers/logger').requestLogger(req)
    cache = null
    nbrOfSections = 0

    basePath = req.query.path
    basePath = (if basePath?  then basePath else '') + '/'
    allowEdit = (if basePath == '/staging/' then 'true' else 'false')
    if allowEdit == "false"
      cache = globalCache[this.curLang]
      if !cache 
        log.error new VErr(), "content was not cached"
      nbrOfSections = getNbrOfSections() 

    log.info { 'query path': basePath}
    page = req.query.page
    if page == "" then page = null
    res.render('index', { allowEdit, basePath , page , bannerTitle: config.bannerTitle,  mainPage: config.mainPage, compileDate:config.compileDate, cache, nbrOfSections  })
    return
  )

require('../helpers/init').readConfig(onInit)
 
module.exports = router

