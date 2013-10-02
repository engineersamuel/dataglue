settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
logger        = require('tracer').colorConsole(utils.logger_config)
mongodb       = require 'mongodb'
zlib          = require 'zlib'
md5           = require 'MD5'
_             = require 'lodash'
prettyjson    = require 'prettyjson'
#EventEmitter  = require("events").EventEmitter



mongoUrl = utils.generateMongoUrl(settings.master_ref)

#DataSetCache = new EventEmitter()
DataSetCache = {}

# https://github.com/mongodb/node-mongodb-native/blob/master/lib/mongodb/collection.js
DataSetCache.refDelete = (_id, callback) ->
  self = @
  mongodb.connect mongoUrl, (err, conn) ->
    if err
      callback err
    else
      conn.collection settings.master_ref.collection, (err, coll) ->
        if err
          callback err
          conn.close()
        else
          coll.remove {_id: mongodb.ObjectID(_id)}, {w:1}, (err, outcome) ->
            callback err, outcome
            conn.close()
  return self

DataSetCache.refGet = (_id, callback) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongoUrl}"
  mongodb.connect mongoUrl, (err, conn) ->
    if err
      callback err
    else
      #logger.debug "Attempting to lookup dataset with _id: #{_id} in collection: #{settings.master_ref.collection}"
      conn.collection settings.master_ref.collection, (err, coll) ->
        if err
          callback err
          conn.close()
        else
          logger.debug _id
          coll.findOne {_id: mongodb.ObjectID(_id)}, (err, doc) ->
            if err
              callback err
              conn.close()
            else
              callback null, doc
              conn.close()

  return self

DataSetCache.refUpsert = (doc, callback) ->
#  logger.debug prettyjson.render doc

  # First sanitize the doc from angular to remove any $$hashKey elements
  _.each doc.dbReferences, (value, key) ->
    _.each value.fields, (field) ->
      if _.has field, '$$hashKey'
        delete field['$$hashKey']

  mongodb.connect mongoUrl, (err, conn) ->
    if err
      callback err
    else
      conn.collection settings.master_ref.collection, (err, coll) ->
        if err
          callback err
          conn.close()
        else

        # Get the type of the db ref from the yaml and make sure the doc has that field
        _.each doc.dbReferences, (dbReference) ->
          dbReference.type = settings.db_refs[dbReference.connection].type

        if _.has doc, '_id'
          _id = mongodb.ObjectID(doc['_id'])
          doc['_id'] = _id

          coll.update {_id: _id}, doc, {upsert: true, safe: true}, (err, outcome) ->
            if err
              callback err
            else
              callback null, _id.toString()
            conn.close()
        else
          coll.insert doc, {safe:true}, (err, insertedId) ->
            if err then logger.warn(err.message)
            if (err and err.message.indexOf('E11000') isnt -1) then logger.error "This _id was already inserted in the database"
            if err
              callback err
            else
              logger.debug prettyjson.render "insertedId: #{insertedId}"
              # output is [ObjectId]
              callback null, doc['_id'].toString()
            conn.close()

# Send query and see if the results are cached
DataSetCache.statementCacheGet = (dbReference, queryHash, callback) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongoUrl}"
  mongodb.connect mongoUrl, (err, conn) ->
    if err then return callback err
    #logger.debug "Attempting to lookup dataset results via the given query
    conn.collection settings.master_ref.cache, (err, coll) ->
      if err
        callback err
      else
        hash = md5("#{dbReference.key}#{utils.stringify(queryHash.query)}")
        logger.debug "Cache made up of key: #{dbReference.key} query: #{JSON.stringify(queryHash.query)}"
        coll.findOne {_id: hash}, (err, doc) ->
          if err
            callback err
          else if not doc?
            logger.debug "\tCache miss"
            callback null, null
          else
            logger.debug "\tCache hit"

            zlib.unzip new Buffer(doc['data'], 'base64'), (err, results) ->
              if err?
                logger.error "Error decompressing data: #{err}"
                callback err
              else
                callback null, JSON.parse(results)
          conn.close()

  return self

# Cache the d3Data for a dataSet, there can be multiple dataSets per reference
DataSetCache.dataSetResultCachePut = (dataSetResult, callback) ->

#  logger.debug "dataSetResult: #{prettyjson.render dataSetResult}"
  self = @
  logger.debug "Connecting to mongo on: #{mongoUrl}"
  mongodb.connect mongoUrl, (err, conn) ->
    if err
      logger.error prettyjson.render err
      callback err
    else
      #logger.debug "Attempting to lookup dataset results via the given query
      conn.collection settings.master_ref.cache, (err, coll) ->
        if err
          callback err
        else
          #logger.debug "Caching dataSetResult: #{prettyjson.render dataSetResult}"
          #logger.debug "Attempting to Hash dataSetResult: #{dataSetResult.dbRefKey}"
          hash = md5("#{dataSetResult.dbRefKey}#{utils.stringify(dataSetResult.queryHash.query)}")
          logger.debug "Cache hash: #{hash}"
          logger.debug "Cache made up of key: #{dataSetResult.dbRefKey} query: #{JSON.stringify(dataSetResult.queryHash.query)}"
          zlib.deflate JSON.stringify(dataSetResult.d3Data), (err, buffer) ->
            if err
              logger.error "Problem compressing data: #{err}"
              callback err
            else
              doc =
                _id: hash
                query: dataSetResult.queryHash.query
                data: buffer.toString('base64')
                lastTouched: new Date()
              #coll.update {md5: hash}, {$set: {query: dataSetResult.queryHash.query, data: buffer.toString('base64'), last_touched: new Date()}}, {upsert: true}, (err, outcome) ->
              coll.update {_id: doc._id}, doc, {upsert: true, safe: true}, (err, outcome) ->
                if err
                  callback err
                else
                  callback null, outcome
                conn.close()

  return self

module.exports = DataSetCache