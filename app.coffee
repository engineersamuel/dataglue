# Debug -- http://youtrack.jetbrains.com/issue/WEB-7091, http://devnet.jetbrains.com/message/5481211

express       = require('express')
http          = require('http')
path          = require('path')
utils         = require('./src/dataglue/utilitis/utils')
logger        = require('tracer').colorConsole(utils.logger_config)
dataSetCache  = require './src/dataglue/db/dataset_cache'
dbLogic       = require './src/dataglue/db/db_logic'
prettyjson    = require 'prettyjson'

##########################################################
# Handle configuration
##########################################################
port = process.env['OPENSHIFT_INTERNAL_PORT'] || process.env['OPENSHIFT_NODEJS_PORT'] || 3000
app = express()
app.configure () ->
  app.set('port', port)
  app.set('views', __dirname + '/public')
  app.set('view engine', 'jade')
  app.engine('jade', require('jade').__express)
  app.use(express.favicon())

  app.use(express.logger())
  app.use(express.compress())
  app.use(express.methodOverride())
  app.use(express.bodyParser())

  app.use(app.router)

  app.use(express.static(path.join(__dirname, 'public')))

  app.configure 'development', () ->
    app.use(express.errorHandler())

##########################################################


##########################################################
# Handle Routes
##########################################################
app.get '/', (req, res) ->
  console.log "Hello World!"
  res.render('index.jade', {})
#  res.sendfile(path.join(__dirname, 'public', 'index.html'))
#  res.send("<h1>Hello World!</h1>")

app.get '/db/ref/:_id', (req, res) ->
  logger.debug "Looking up ref with _id: #{req.param('_id')}"
  dataSetCache.ref_get req.param('_id'), (err, doc) ->
    res.send doc

# TODO should also accept a get for somthing like /dataset/query/:_id
app.post '/dataset/query', (req, res) ->
#  logger.debug "doc: #{req.body.doc}"
#  logger.debug "doc, stringify: #{JSON.stringify(req.body.doc)}"
  dbLogic.queryDataSet req.body.doc, (err, results) ->
    if err
      throw err
    else
      res.send results

app.get '/dataset/query/:_id', (req, res) ->
  logger.debug "Looking up data set with _id: #{req.param('_id')}"
  dataSetCache.ref_get req.param('_id'), (err, doc) ->
    dbLogic.loadDataSet doc, (err, results) ->
      if err
        logger.error "Error loading dataset: #{prettyjson.render err}"
      else
      res.send results

##########################################################
# Handle general HTTP opens/closes/listens
##########################################################
process.on 'exit', () ->
  logger.info("process exiting.")
  app.close()

http.createServer(app).listen app.get('port'), () ->
  logger.info("Data glue server listening on port " + app.get('port'))
##########################################################

