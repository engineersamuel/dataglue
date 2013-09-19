# Debug -- http://youtrack.jetbrains.com/issue/WEB-7091, http://devnet.jetbrains.com/message/5481211

express       = require('express')
http          = require('http')
path          = require('path')
utils         = require('./src/dataglue/utilitis/utils')
logger        = require('tracer').colorConsole(utils.logger_config)
dataSetCache  = require './src/dataglue/db/datasetCache'
dbLogic       = require './src/dataglue/db/dbLogic'
prettyjson    = require 'prettyjson'
_             = require 'lodash'
settings      = require './src/dataglue/utilitis/settings'
utils         = require './src/dataglue/utilitis/utils'

##########################################################
# Handle configuration
##########################################################
port = process.env['OPENSHIFT_INTERNAL_PORT'] || process.env['OPENSHIFT_NODEJS_PORT'] || 3000
ipAddress = process.env['OPENSHIFT_NODEJS_IP'] || '127.0.0.1'
app = express()
app.configure () ->
  app.set('ipAddress', ipAddress)
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

##########################################################
# Getting and upserting the dataSet definition
##########################################################
app.post '/db/ref', (req, res) ->
  logger.info "post to /db/ref"
  doc = if _.isString(req.body.doc) then JSON.parse(req.body.doc) else req.body.doc
  dataSetCache.refUpsert doc, (err, _id) ->
    if err
      logger.error prettyjson.render err
      res.send 500, err
    else
      res.send {_id: _id}

app.get '/db/ref/:_id', (req, res) ->
  logger.debug "Looking up ref with _id: #{req.param('_id')}"
  dataSetCache.refGet req.param('_id'), (err, doc) ->
    res.send doc

app.post '/db/delete/ref/:_id', (req, res) ->
  logger.debug "Looking up ref with _id: #{req.param('_id')}"
  dataSetCache.refDelete req.param('_id'), (err, outcome) ->
    if err
      logger.error prettyjson.render err
      res.send 500, err
    else
      logger.error prettyjson.render outcome
      res.send {success: outcome}

##########################################################
# Querying the dataset
##########################################################
# TODO should also accept a get for somthing like /dataset/query/:_id
app.post '/dataset/query', (req, res) ->
#  logger.debug "doc: #{req.body.doc}"
#  logger.debug "doc, stringify: #{JSON.stringify(req.body.doc)}"
  dbLogic.queryDataSet req.body.doc, (err, results) ->
    if err
      logger.error prettyjson.render err
      res.send 500, err
    else
      res.send results

app.get '/dataset/query/:_id', (req, res) ->
  logger.debug "Looking up data set with _id: #{req.param('_id')}"
  dataSetCache.refGet req.param('_id'), (err, doc) ->
    dbLogic.loadDataSet doc, (err, results) ->
      if err
        logger.error "Error loading dataset: #{prettyjson.render err}"
        res.send 500, err
      else
      res.send results

########################################################################################################################
# Informational queries
########################################################################################################################
# Get fields
app.get '/db/info/:ref/:schema/:table', (req, res) ->
  dbLogic.getFields req.param('ref'), req.param('schema'), req.param('table'), (err, output) ->
    res.send output

# Get tables
app.get '/db/info/:ref/:schema', (req, res) ->
  dbLogic.getTables req.param('ref'), req.param('schema'), (err, output) ->
    res.send output

# Get schemas
app.get '/db/info/:ref', (req, res) ->
  dbLogic.getSchemas req.param('ref'), (err, output) ->
    res.send output

# Get list of database connection references
app.get '/db/info', (req, res) ->
  res.send _.keys settings.db_refs


########################################################################################################################

##########################################################
# Handle general HTTP opens/closes/listens
##########################################################
process.on 'exit', () ->
  logger.info("process exiting.")
  app.close()

http.createServer(app).listen app.get('port'), app.get('ipAddress'), () ->
  logger.info "Data glue server listening on #{app.get('ipAddress')}:#{app.get('port')}"
##########################################################

