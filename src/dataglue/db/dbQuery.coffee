settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
mysql         = require 'mysql'
_             = require 'lodash'
logger        = require('tracer').colorConsole(utils.logger_config)
mongodb       = require 'mongodb'
Db            = require('mongodb').Db
prettyjson    = require 'prettyjson'


DbQuery = {}

DbQuery.query = (dbReference, queryHash, callback) ->
  self = @
  if dbReference.type is 'mysql'
    logger.debug "Querying mysql reference: #{dbReference.name} with query: #{queryHash.query}"
    DbQuery.mysqlQuery dbReference, queryHash, (err, results) ->
      if err
        callback err
      else callback null, results

  else if dbReference.type is 'mongo'
    logger.debug "Querying mongo reference: #{dbReference.name} with queryHash: #{prettyjson.render queryHash}"
    DbQuery.mongoQuery dbReference, queryHash, (err, results) ->
      callback err, results
  return self

DbQuery.mongoQuery = (dbReference, queryHash, callback) ->
  self = @

  # Make a clone of the dbReference to override any necessary fields like the db
  dbRefCopy = _.clone dbReference
  # If a command is present, must run it against the admin database
  if queryHash.command? then dbRefCopy.db = 'admin'
  mongoUrl = utils.generate_mongo_url(dbRefCopy)
  mongodb.connect mongoUrl, (err, conn) ->
    if err
      logger.error err
    else
      if queryHash.command?
        conn.command queryHash.command, (err, results) ->
          callback err, results
          conn.close()
      else
        logger.info "Attempting to connect to collection: #{settings.master_ref.collection}"
        # TODO TBD
        conn.close()

  return self

# Since the mongodb native drive has no native showCollections, easiest just to create a separate function for this
DbQuery.showCollections = (dbReference, dbName, callback) ->
  self = @

  # Make a clone of the dbReference to override any necessary fields like the db
  dbRefCopy = _.clone dbReference
  dbRefCopy.db = dbName
  mongoUrl = utils.generate_mongo_url(dbRefCopy)
  Db.connect mongoUrl, (err, db) ->
    if err
      logger.error err
    else
      db.collectionNames (err, collectionNames) ->
        # In the following format: [{name: dataglue.system.indexes}, {name: dataglue.cache}, {name: dataglue.refs}]
        # Map the name: to TABLE_NAME and remove the dbName which is generally just the first word + .
        callback err, _.map collectionNames, (item) -> {TABLE_NAME: item.name.replace(dbName + '.', '')}
        db.close()

  return self

# Since the mongodb native drive has no native showCollections, easiest just to create a separate function for this
DbQuery.showFields = (dbReference, dbName, collectionName, callback) ->
  self = @

  # Make a clone of the dbReference to override any necessary fields like the db
  dbRefCopy = _.clone dbReference
  dbRefCopy.db = dbName
  mongoUrl = utils.generate_mongo_url(dbRefCopy)
  Db.connect mongoUrl, (err, db) ->
    if err
      callback err
    else
      db.collection collectionName, (err, coll) ->
        if err
          callback err
        else
          coll.findOne {}, (err, doc) ->
            callback null, _.map(_.keys(doc), (f) -> {COLUMN_NAME: f, DATA_TYPE: utils.setMongoFieldDataType(doc[f]), COLUMN_TYPE: undefined, COLUMN_KEY: undefined})
            db.close()

  return self

DbQuery.mysqlQuery = (dbReference, queryHash, callback) ->
  self = @
  # Remember the connection property is the unique name of the connection reference
  mysql_ref = settings.mysql_refs[dbReference.connection || dbReference.name]
  conn = mysql.createConnection
    host     : mysql_ref['host'],
    user     : mysql_ref['user'],
    password : mysql_ref['pass'],

  # Query mysql, attempt to cache, and return the results regardless
  logger.debug "Querying mysql reference: #{dbReference.connection} with query: #{prettyjson.render queryHash.query}"
  conn.query queryHash.query, (err, results) ->
    if err
      logger.debug "Error Querying mysql reference: #{dbReference.connection} with sql: #{queryHash}, err: #{prettyjson.render err}"
      callback err
    else
      logger.debug "Found #{results.length} results."
      callback null, results

    # End the connection before existing the function
    conn.end()

  return self

module.exports = DbQuery
