const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const cookieParser = require('cookie-parser');
const rfs = require('rotating-file-stream');
const logger = require('./helpers/logger');

const app = express();


var debug = require('debug')('main');
/***********************
 *  Logging ***********/

//Generate UUID for request and add it to X-Request-Id header 
const addRequestId = require('express-request-id')();
app.use(addRequestId);




const root = process.env.EXPRESS_ROOT;
console.log("ROOT DIR: "+ root);

// view engine setup
app.set('views', path.join(root, 'views'));

app.set('view engine', 'hbs');
app.engine('hbs', require('hbs').__express);

app.set('view options', { layout: false });

const index = require('./routes/index');
const contact = require('./routes/contact');
const admin = require('./routes/admin');




// uncomment after placing your favicon in /public
//app.use(favicon(path.join(root, 'public', 'favicon.ico')));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
// app.use(formParser);
app.use(express.static(path.join(root, 'public')));

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

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
