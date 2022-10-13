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




require('../helpers/marked.utils')

{createGlobalCache} = require '../helpers/cache'
 

prodDir = null
stagingDir = null
entryFile = null
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
        doneCommit(req,res,next)
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
          'funcs': [data.unstage,
            images.unstage
          ],
        doneUnstage(req,res,next)
    )
    return
  

doneCommit = (req,res,next) -> 
  ( err, results ) ->
    if err
      renderError new VErr(err, "Failed to commit changes")
    else
      next()


doneUnstage = (req,res,next) -> 
  ( err, results ) ->
    if err
      renderError new VErr(err, "Failed to unstage")
    else
      res.render('ok', { 
        message: "Data and images of the staging area have been reset to match production website"
      })
  

doCache = (req,res,next) ->
  createGlobalCache("#{prodDir}/data/",entryFile, doneCaching(req,res,next))
  
doneCaching = (req,res,next) -> 
  ( err, results ) ->
    if err
      renderError new VErr(err, "Failed to cache commited data ")
    else
      require('../helpers/init').setCompileDate()
      res.render('ok', { 
        message: "Data and images of the staging area have been commited and cached."
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
  #todo: add a middleware in app.js that adds the config object to req so that it is accessible from the callbacks without hassle
  # for now hack it with globals:
  prodDir = config.prodPublicDir
  stagingDir = config.stagingPublicDir
  entryFile = config.entryFile
  if prodDir == null || stagingDir == null then throw new VErr("config not loaded.")
  # commit changes in the staging area to the production website: 
  router.post( '/commit', commit, doCache)
  router.post( '/unstage', unstage)
  router.post('/editfile/*', preUpload, upload.single("file"), postUpload)



require('../helpers/init').readConfig(onInit)

module.exports = router