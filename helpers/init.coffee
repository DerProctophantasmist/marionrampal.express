fs = require('fs')
path = require('path')
log = require('../helpers/logger').mainLogger
config = null
vErr = require("verror")

{createGlobalCache} = require '../helpers/cache'

#the data file is actually a js file, richer syntax, the dynamic path means it won't be browserified (if we use that to bundle)
dataFile = path.join(process.env.EXPRESS_ROOT, 'data/main')
# configCallbacks = []

try config = require(dataFile)
catch e 
  err  = new vErr(e, "Could not load config file: " + dataFile ) 
  log.error(err)
  throw err



# fs.readFile dataFile, (err, data) ->
#   if (err) 
#     log.info err, "Could not read config from %s: ", dataFile 
#     throw err
#   config = JSON.parse(data + "")
#   log.info { config }, "Loaded configuration"

#   for callback in configCallbacks
#     callback(err, config)

# readConfig = (callback) ->
#     configCallbacks.push callback
#     return

readConfig = (callback) ->
  callback(null,config)

setCompileDate = ()->
  config.compileDate = Date.now()

doneCaching = ( err, results ) ->
    if err
      log.error new VErr(), "Failed to cache data at init"
    else
      log.info 
        message: "Data has been cached at init."

readConfig (err, config) ->
  if err then throw new Verr(err, "Failed to load config before caching")
  createGlobalCache(config.prodPublicDir+ "/data/",config.entryFile, doneCaching)

module.exports = {
    readConfig # takes one arg: a callback that witl receive the config object as argument when initialization is done
    setCompileDate
}
