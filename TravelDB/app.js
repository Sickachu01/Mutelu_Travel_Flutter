var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
const mongoose = require('mongoose');
const actorsRoutes = require('./routes/actors');
const travelsRoutes = require('./routes/travels');
const mapRoutes = require('./routes/maps'); 

mongoose.Promise = global.Promise;

mongoose.connect('mongodb+srv://admin:1234@cluster0.rxlqs.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0')
  .then(() => console.log('Connection successful!'))
  .catch((err) => console.error('Connection error:', err));

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// ตั้งค่า routes
app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/actors', actorsRoutes);
app.use('/travels', travelsRoutes);
app.use('/maps', mapRoutes); 

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
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
