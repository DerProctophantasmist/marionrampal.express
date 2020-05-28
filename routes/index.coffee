express = require('express')
router = express.Router()

log = require('../helpers/logger').mainLogger
hbs = require('hbs')


hbs.registerHelper('description', () ->
  return this.mainPage.description[this.curLang]
)





onInit = (_,config) ->
  log.info({config}, "configuration object")
  # GET home page. 
  router.get('/', (req, res, next) ->
    log = require('../helpers/logger').requestLogger(req)
    fbLang = req.get('X-Facebook-Locale')
    prefLang = req.acceptsLanguages('fr','en') ? fbLang ? 'en'
    basePath = req.query.path
    basePath = (if basePath?  then basePath else '') + '/'
    allowEdit = (if basePath == '/staging/' then 'true' else 'false')
    log.info basePath
    page = req.query.page
    if page == "" then page = null
    forceLang = req.query.forceLang
    if forceLang == "" then forceLang = null
    curLang = forceLang ? fbLang ? prefLang
    res.render('index', { allowEdit: allowEdit, basePath: basePath, prefLang: prefLang, page: page, title: config.title, curLang:curLang, forceLang:forceLang, mainPage: config.mainPage  })
    return
  )

require('../helpers/init').done(onInit)
 
module.exports = router

