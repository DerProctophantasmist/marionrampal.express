fs = require('fs')
path = require('path')
log = require('../helpers/logger').mainLogger
config = null
vErr = require("verror")

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

module.exports = {
    readConfig # takes one arg: a callback that witl receive the config object as argument when initialization is done
}
