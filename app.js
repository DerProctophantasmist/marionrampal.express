const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const cookieParser = require('cookie-parser');
const rfs = require('rotating-file-stream');
const log = require('./helpers/logger').mainLogger;

const app = express();


var debug = require('debug')('main');
/***********************
 *  Logging ***********/

//Generate UUID for request and add it to X-Request-Id header 
const addRequestId = require('express-request-id')();
app.use(addRequestId);




const root = process.env.EXPRESS_ROOT;
console.log("ROOT DIR: "+ root);

/**
 * Monkey-patches the request method of an http/https module to add logging
 * of each request. Logs the URL and method of each request.
 *
 * @param {Object} httpModule - The http or https module to monkey-patch.
 */
function requestLogger(httpModule){
  var original = httpModule.request
  httpModule.request = function(options, callback){
    console.log({options:options})
    return original(options, callback)
  }
}

// requestLogger(require('http'))
// requestLogger(require('https'))

// view engine setup
app.set('views', path.join(root, 'views'));

app.set('view engine', 'hbs');
app.engine('hbs', require('hbs').__express);

app.set('view options', { layout: false });

const index = require('./routes/index');
const contact = require('./routes/contact');
const admin = require('./routes/admin');
const { googlePlaces, youtube, infoconcert } = require('./helpers/proxies');




// uncomment after placing your favicon in /public
//app.use(favicon(path.join(root, 'public', 'favicon.ico')));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
// app.use(formParser);
app.use(express.static(path.join(root, 'public')));

app.use('/googleapis/places', googlePlaces);
app.use('/googleapis/youtube', youtube);
app.use('/infoconcert',infoconcert)
app.use('/', index);
app.use('/contact', contact);
app.use('/admin', admin);
// app.use('/staging', staging);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};
  if (req.app.get('env') === 'development') {
    log.error(err);
  }

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
