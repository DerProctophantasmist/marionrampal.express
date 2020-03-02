express = require('express')
router = express.Router()
vasync = require('vasync')
VErr = require('verror')
exec = require('child_process').execFile;
log = require('../helpers/logger').mainLogger

#hbs = require('hbs')
prodDir = null
fromDir = null
renderError = (err) -> {}

folder = (rootSource, subDir) ->
    cleanup : (callback)-> 
        if prodDir == null then throw new VErr("config not loaded.")
        exec('rm', ['-rf', prodDir + '/' + subDir ], 
          (err,stdout, stderr) ->
            callback(err, {stdout, stderr})
        )
    ,
    sync : (callback) ->
        if prodDir == null then throw new VErr("config not loaded.")
        exec('rsync', ['-a', rootSource + '/' + subDir + '/', prodDir + '/' + subDir ], 
          (err,stdout, stderr) ->
            callback(err, {stdout, stderr})
        )

done = (res, req, next) -> 
  ( err, results ) ->
    if err
      req.log.error(err, "failed to commit changes")
      renderError new VErr(err, "Failed to commit changes")
    else
      res.render('ok', { 
        message: "Data and images from " + fromDir + " have been saved to the website"
      })


onInit= (_,config) ->
  prodDir = config.prodPublicDir
  fromDir = config.stagingPublicDir
  if prodDir == null || fromDir == null then throw new VErr("config not loaded.")
  # GET home page. 
  router.get('/commit', (req, res, next) ->
    renderError = (err) -> next(err)
    req.log = require('../helpers/logger').requestLogger(req)

    data = folder(fromDir, 'data')
    images = folder(fromDir, 'images')
    vasync.parallel(
          'funcs': [
            data.sync,
            images.sync
          ]
        ,
        done(res, req, next)
    )
    return
  )

require('../helpers/init').readConfig(onInit)

module.exports = router