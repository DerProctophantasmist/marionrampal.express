express = require('express')
router = express.Router()
fs = require('fs')
path = require('path')
hbs = require('hbs')
#mainPage = require('../data/main')


hbs.registerHelper('description', () ->
  console.log "what the fuck?"
  return this.data.description[this.curLang]
)

dataFile = path.join(process.env.MR_EXPRESS_ROOT, 'data/main.json')

fs.readFile dataFile, (err, data) ->
  if (err) 
    console.log "Could not read auth data from " + dataFile + ": " + err.code
    throw err
  mainPage = JSON.parse(data + "")
  console.log JSON.stringify mainPage

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

