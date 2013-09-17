settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
logger        = require('tracer').colorConsole(utils.logger_config)
mongodb       = require 'mongodb'
snappy        = require 'snappy'
zlib          = require 'zlib'
md5           = require 'MD5'
_             = require 'lodash'
prettyjson    = require 'prettyjson'
#EventEmitter  = require("events").EventEmitter

generate_mongo_url = (obj) ->
  obj.host = (obj.host || '127.0.0.1')
  obj.port = (obj.port || 27017)
  obj.db = (obj.db || 'test')

  if obj.user and obj.pass
    return "mongodb://" + obj.user + ":" + obj.pass + "@" + obj.host + ":" + obj.port + "/" + obj.db + "?auto_reconnect=true"
  else
    return "mongodb://" + obj.host + ":" + obj.port + "/" + obj.db

mongo_url = generate_mongo_url(settings.master_ref)

#DataSetCache = new EventEmitter()
DataSetCache = {}

# TODO potentially make the events emitted specific to connection/collection/ect... instead of just 'failure'
DataSetCache.refGet = (_id, callback) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongo_url}"
  mongodb.connect mongo_url, (err, conn) ->
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
  # First sanitize the doc from angular to remove any $$hashKey elements
  _.each doc.dbReferences, (value, key) ->
    _.each value.fields, (field) ->
      if _.has field, '$$hashKey'
        delete field['$$hashKey']

  mongodb.connect mongo_url, (err, conn) ->
    if err
      callback err
    else
      conn.collection settings.master_ref.collection, (err, coll) ->
        if err
          callback err
          conn.close()
        else

        if _.has doc, '_id'
          _id = mongodb.ObjectID(doc['_id'])
          doc['_id'] = _id

          coll.update {_id: _id}, doc, {upsert: true}, (err, outcome) ->
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

# Send sql and see if the results are cached
DataSetCache.statementCacheGet = (dbReference, queryHash, callback) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongo_url}"
  mongodb.connect mongo_url, (err, conn) ->
    if err then return callback err
    #logger.debug "Attempting to lookup dataset results via the given sql
    conn.collection settings.master_ref.cache, (err, coll) ->
      if err
        callback err
        conn.close()
      else
        hash = md5("#{dbReference.key}#{queryHash.sql}")
        coll.findOne {md5: hash}, (err, doc) ->
          if err
            callback err
            conn.close()
          else if not doc?
            logger.debug "Cache miss for hash: #{hash}, sql: #{queryHash.sql}"
            callback null, null
          else
            logger.debug "Cache hit for hash: #{hash}, sql: #{queryHash.sql}"

            zlib.unzip new Buffer(doc['data'], 'base64'), (err, results) ->
              if err?
                logger.error "Error decompressing data: #{err}"
                callback err
              else
                callback null, JSON.parse(results)
          conn.close()

  return self

# Send sql and see if the results are cached
DataSetCache.statementCachePut = (dbReference, queryHash, results, callback) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongo_url}"
  mongodb.connect mongo_url, (err, conn) ->
    if err
      logger.error prettyjson.render err
      callback err
    else
      #logger.debug "Attempting to lookup dataset results via the given sql
      conn.collection settings.master_ref.cache, (err, coll) ->
        if err
          callback err
        else
          hash = md5("#{dbReference.key}#{queryHash.sql}")
          zlib.deflate JSON.stringify(results), (err, buffer) ->
            if err
              logger.error "Problem compressing data: #{err}"
              callback err
              conn.close()
            else
              coll.update {md5: hash}, {$set: {sql: queryHash.sql, data: buffer.toString('base64'), last_touched: new Date()}}, {upsert: true}, (err, outcome) ->
                if err
                  callback err
                else
                  callback null, outcome
                conn.close()

  return self

module.exports = DataSetCache
