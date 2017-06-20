express = require('express')
nodemailer = require('nodemailer')
xoauth2 = require('xoauth2')
fs = require('fs')
path = require('path')
cors = require('cors')
validator = require('validator')

 
corsOptions = {
  origin: /http:\/\/([^.]+\.)*marionrampal.(com|local)/,
  optionsSuccessStatus: 200 # some legacy browsers (IE11, various SmartTVs) choke on 204
};

authFile = path.join(process.env.MR_EXPRESS_ROOT, 'keys/mailer.marionrampal.com.json')


router = express.Router()


router.options('/',cors(corsOptions))

 

fs.readFile authFile, (err, data) ->
  if (err) 
    console.log "Could not read auth data from " + authFile + ": " + err.code
    throw err
  auth = JSON.parse(data + "")
  generator = xoauth2.createXOAuth2Generator(auth)

  # listen for token updates (if refreshToken is set)
  # you probably want to store these to a db (lets write them to a file
  generator.on( 'token', (token)->
    console.log('New token for %s: %s', token.user, token.accessToken);
    auth.accessToken = token.accessToken
    fs.writeFile( authFile, JSON.stringify(auth), (err)->
      if err
        console.log "Could not save auth data after update: " + err.code
    ) 
  )
  
  
  console.log JSON.stringify(generator)
    
  
  
  #POST contact form. 
  router.post('/', cors(corsOptions), (req, res, next) ->
    smtpTrans = nodemailer.createTransport({
      service: 'gmail',
      auth: {
          xoauth2: generator
      }
    })  
    emailFrom = req.body.emailFrom || "";
    subject = req.body.subject || "";
    content = req.body.content || "";
    
    if !validator.isEmail(emailFrom)
      return res.status(400).json {txt: 'Email ' + emailFrom + ' invalide', status: 'fail'}

    #Mail options
    mailOpts = {
        from: emailFrom , #grab form data from the request body object
        to: 'marionrampal@hotmail.com',
        subject: subject,        
        "reply-to": emailFrom, #grab form data from the request body object
        text: "de: " + emailFrom + "\n\n\n" + content
    }


    smtpTrans.sendMail(mailOpts, (error, response) ->
        #Email not sent
        if (error) 
            res.status(400).json {txt: 'error: ' + JSON.stringify(error), status: 'fail'}
        #Yay!! Email sent
        else 
            res.json {status: 'success', txt: 'Email envoyé avec succès'}

    )
  )
module.exports = router;
