
log = mainLog = require('../helpers/logger').mainLogger

# proxy = require('express-http-proxy')
{ createProxyMiddleware, fixRequestBody } = require('http-proxy-middleware')
https = require('https')

googleApiKey = null

onInit= (_,config) ->
  #todo: add a middleware in app.js that adds the config object to req so that it is accessible from the callbacks without hassle
  # for now hack it with globals:
  googleApiKey = config.googleApiKey
  if googleApiKey == null then throw new VErr("config not loaded.")


encodeRFC3986URI = (str) ->
  encodeURI(str)
    .replace(/%5B/g, "[")
    .replace(/%5D/g, "]")
    .replace(
      /[!'()*]/g,
      (c) =>"%#{c.charCodeAt(0).toString(16).toUpperCase()}",
    )

require('../helpers/init').readConfig(onInit)

module.exports =
  # googlePlaces: proxy(
  #   'https://places.googleapis.com/'
  #     proxyReqOptDecorator: (opts,req)->
  #       if googleApiKey == null
  #         req.res.status(500).end()

  #       opts.headers['X-Goog-Api-Key'] = googleApiKey
  #       opts      
  # )
  googlePlaces:createProxyMiddleware {
    target: 'https://places.googleapis.com'
    changeOrigin: true
    headers: { 'X-Goog-Api-Key': googleApiKey }
    xfwd: true
    on:
      proxyReq: fixRequestBody
  }
  youtube: createProxyMiddleware {
    target: 'https://www.googleapis.com/youtube'
    changeOrigin: true
    xfwd: true
    pathRewrite: (path, req) ->
      if googleApiKey == null
        req.res.status(500).end()
      log.info path = path + '&key=' + googleApiKey
      path
  }
  infoconcert: createProxyMiddleware {
    target: 'https://www.infoconcert.com'
    changeOrigin: true
    xfwd: false
  }
  