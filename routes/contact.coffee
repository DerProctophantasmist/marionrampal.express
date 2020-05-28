express = require('express')
nodemailer = require('nodemailer')
xoauth2 = require('xoauth2')
fs = require('fs')
path = require('path')
cors = require('cors')
validator = require('validator')
log = require('../helpers/logger').mainLogger
VErr = require('verror')
vasync = require('vasync')



 

#  generator = xoauth2.createXOAuth2Generator(auth)

  # listen for token updates (if refreshToken is set)
  # you probably want to store these to a db (lets write them to a file
#  generator.on( 'token', (token)->
#    console.log('New token for %s: %s', token.user, token.accessToken);
#    auth.accessToken = token.accessToken
#    fs.writeFile( authFile, JSON.stringify(auth), (err)->
#      if err
#        console.log "Could not save auth data after update: " + err.code
#    ) 
#  )
  
  
#  console.log JSON.stringify(generator)
    
corsOptions = null
router = express.Router()
auth = null
contactMail = null

init = (config, callback) ->   
  corsOptions = 
    origin: config.contact.origin
    optionsSuccessStatus: 200 # some legacy browsers (IE11, various SmartTVs) choke on 204

  authFile = path.join(process.env.EXPRESS_ROOT, config.contact.mailerKeyFile)

  contactMail = config.contact.mailTo

  fs.readFile authFile, (err, data) ->
    if(err) 
      callback(new VErr(err, "Could not read auth data from %s", authFile ) )
    else 
      auth = JSON.parse(data + "")       
      callback()
    
  
#from POST contact form. 
handleMessage = (req, res, next) ->

  log = require('../helpers/logger').requestLogger(req)

  smtpTrans = nodemailer.createTransport({
    service: 'Gmail',
    auth: auth
  })  
  emailFrom = req.body.emailFrom || "";
  subject = req.body.subject || "";
  content = req.body.content || "";
  
  if !validator.isEmail(emailFrom)
    return res.status(400).json {txt: 'Email ' + emailFrom + ' invalide', status: 'fail'}

  #Mail options
  mailOpts = 
    from: emailFrom , #grab form data from the request body object
    to: contactMail,
    subject: subject,        
    "reply-to": emailFrom, #grab form data from the request body object
    text: "de: " + emailFrom + "\n\n\n" + content
  


  smtpTrans.sendMail(mailOpts, (error, response) ->
    #Email not sent
    if (error) 
      log.error new VErr(error, "Could not connect to smtp server")
      res.status(400).json {txt: 'error: Could not connect to smtp server.' + error.message, status: 'fail'}
    #Yay!! Email sent
    else 
      log.info {mailOpts}, "contact mail sent"
      res.json {status: 'success', txt: 'Email envoyé avec succès'}

  )


doneInit = (err,result)->
  if err
    err = new VErr(err, "Cannot initialize mailer!")
    log.error 
    throw err

  else  
    #set options response
    router.options('/',cors(corsOptions))
    #POST contact form. 
    router.post '/', cors(corsOptions), handleMessage
  

vasync.waterfall([require('../helpers/init').done, init], doneInit )

module.exports = router;
