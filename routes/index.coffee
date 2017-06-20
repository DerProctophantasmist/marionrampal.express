express = require('express')
router = express.Router()
hbs = require('hbs')
mainPage = require('../data/main')


hbs.registerHelper('description', () ->
  return this.data.description[this.curLang]
)


# GET home page. 
router.get('/', (req, res, next) ->
  fbLang = req.get('X-Facebook-Locale')
  prefLang = req.acceptsLanguages('fr','en') ? fbLang ? 'en'
  page = req.query.page
  if page == "" then page = null
  forceLang = req.query.forceLang
  if forceLang == "" then forceLang = null
  curLang = forceLang ? fbLang ? prefLang
  res.render('index', { prefLang: prefLang, page: page, title: "marionrampal.com", curLang:curLang, forceLang:forceLang, data: mainPage })
  return
)


 
module.exports = router

