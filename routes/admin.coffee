express = require('express')
router = express.Router()
editFile = express.Router()
vasync = require('vasync')
VErr = require('verror')
exec = require('child_process').execFile;
log = mainLog = require('../helpers/logger').mainLogger
fs = require('file-system');
path=require('path')
formParser=require('multer');
markdownFiles = require('../helpers/markdownContent')


#hbs = require('hbs')
prodDir = null
stagingDir = null 
renderError = (err) -> log.error(err)  

folder = (subDir) ->
  cleanup : (callback)-> 
    if prodDir == null then throw new VErr("config not loaded.")
    exec('rm', ['-rf', prodDir + '/' + subDir ], 
      (err,stdout, stderr) ->
        callback(err, {stdout, stderr})
    )
  ,
  sync : (callback) ->
    if prodDir == null then throw new VErr("config not loaded.")
    exec('rsync', ['-a', '--delete', stagingDir + '/' + subDir + '/', prodDir + '/' + subDir ], 
      (err,stdout, stderr) ->
        callback(err, {stdout, stderr})
    )
  unstage: (callback) ->
    if prodDir == null then throw new VErr("config not loaded.")
    exec('rsync', ['-a', '--delete', prodDir + '/' + subDir + '/', stagingDir + '/' + subDir ], 
      (err,stdout, stderr) ->
        callback(err, {stdout, stderr})
    )



filepath = (rootDir, filepath) ->
  filter = fs.fileMatch(stagingDir + '/data/**/*.md')
  absPath = path.join(rootDir, filepath)
  log.info({"full path":absPath})
  file = 
    mayWrite : ()-> 
      filter(absPath)
    full : ()->
      absPath
  return file


commit = (req, res, next) ->
    log = require('../helpers/logger').requestLogger(req)
    renderError = (err) -> 
      log.error err      
      res.status(500).json {txt: err.message, status: 'fail'}

    data = folder('data')
    images = folder('images')
    vasync.parallel(
          'funcs': [
            data.sync,
            images.sync
          ]
        ,
        doneCommit(res, req, next)
    )
    return

unstage = (req, res, next) ->
    log = require('../helpers/logger').requestLogger(req)
    renderError = (err) -> 
      log.error err
      res.status(500).json {txt: err.message, status: 'fail'}

    data = folder('data')
    images = folder('images')
    vasync.parallel(
          'funcs': [
            data.unstage,
            images.unstage
          ]
        ,
        doneUnstage(res, req, next)
    )
    return
  

doneCommit = (res, req, next) -> 
  ( err, results ) ->
    if err
      renderError new VErr(err, "Failed to commit changes")
    else
      res.render('ok', { 
        message: "Data and images from " + stagingDir + " have been saved to the website"
      })


doneUnstage = (res, req, next) -> 
  ( err, results ) ->
    if err
      renderError new VErr(err, "Failed to unstage")
    else
      res.render('ok', { 
        message: "Data and images of the staging area have been reset to match production website"
      })
  


preUpload = (req, res, next) ->
  log = require('../helpers/logger').requestLogger(req)
  renderError = (err) -> 
    log.error err
    res.status(400).json {txt: err.message, status: 'fail'}

  req.dest = req.params[0]
  dest = filepath(stagingDir + '/data', req.dest )
  req.dest = dest.full()
  mayWrite = dest.mayWrite()
  log.info("requested edit: %s maywrite: %s",req.dest, mayWrite)

  if mayWrite then next()
  else res.status(403).send VErr("May not write to %s", req.dest)

  
storage = formParser.diskStorage
  destination:  (req, file, cb) ->
    dir = path.dirname(req.dest)
    fs.mkdir(dir, (err) -> cb(err, dir))
  filename:  (req, file, cb) ->
    cb(null, path.basename(req.dest))


upload = formParser({ storage: storage })


postUpload = (req, res, next) ->
  res.status(200).send("ok")
  return



onInit= (_,config) ->
  prodDir = config.prodPublicDir if !(prodDir = process.env.PROD_PUBLIC_DIR)
  stagingDir = config.stagingPublicDir if !(stagingDir = process.env.STAGING_PUBLIC_DIR)
  if prodDir == null || stagingDir == null then throw new VErr("config not loaded.")
  # commit changes in the staging area to the production website: 
  router.post( '/commit', commit)
  router.post( '/unstage', unstage)
  router.post('/editfile/*', preUpload, upload.single("file"), postUpload)



require('../helpers/init').done(onInit)

module.exports = router