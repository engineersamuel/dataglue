settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
logger        = require('tracer').colorConsole(utils.logger_config)
mongodb       = require 'mongodb'
snappy        = require 'snappy'
zlib          = require 'zlib'
md5           = require 'MD5'
prettyjson    = require 'prettyjson'
EventEmitter  = require("events").EventEmitter

generate_mongo_url = (obj) ->
  obj.host = (obj.host || '127.0.0.1')
  obj.port = (obj.port || 27017)
  obj.db = (obj.db || 'test')

  if obj.user and obj.pass
    return "mongodb://" + obj.user + ":" + obj.pass + "@" + obj.host + ":" + obj.port + "/" + obj.db + "?auto_reconnect=true"
  else
    return "mongodb://" + obj.host + ":" + obj.port + "/" + obj.db

mongo_url = generate_mongo_url(settings.master_ref)

DataSetCache = new EventEmitter()

# TODO potentially make the events emitted specific to connection/collection/ect... instead of just 'failure'
DataSetCache.ref_get = (_id, callback) ->
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
              #logger.debug prettyjson.render(err)
              #logger.debug prettyjson.render(doc)
              callback null, doc
              conn.close()

  return self

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
DataSetCache.statementCachePut = (dbReference, queryHash, results) ->
  self = @
  logger.debug "Connecting to mongo on: #{mongo_url}"
  mongodb.connect mongo_url, (err, conn) ->
    if err then self.emit 'failure', err
    #logger.debug "Attempting to lookup dataset results via the given sql
    conn.collection settings.master_ref.cache, (err, coll) ->
      if err
        self.emit 'failure', err
      else
        hash = md5("#{dbReference.key}#{queryHash.sql}")
        zlib.deflate JSON.stringify(results), (err, buffer) ->
          if err
            logger.error "Problem compressing data: #{err}"
            self.emit 'failure', err
            conn.close()
          else
            coll.update {md5: hash}, {$set: {sql: queryHash.sql, data: buffer.toString('base64'), last_touched: new Date()}}, {upsert: true}, (err, outcome) ->
              if err then self.emit 'failure', err else self.emit 'cachePut'
              conn.close()

#        snappy.compress results, (err, data) ->
#          if err
#            logger.error "Problem compressing data: #{err}"
#            self.emit 'failure', err
#            conn.close()
#          else
#            coll.update {md5: hash}, {$set: {data: data, last_touched: new Date()}}, {upsert: true}, (err, outcome) ->
#              if err then self.emit 'failure', err else self.emit 'cachePut'
#              conn.close()

  return self

DataSetCache.ref_upsert = (doc) ->
  self = @

  return @

module.exports = DataSetCache

#exports.ref_get = (_id) ->
#  logger.debug "Connecting to mongo on: #{mongo_url}"
#  mongodb.connect mongo_url, (err, conn) ->
#    logger.debug "Attempting to lookup dataset with _id: #{_id} in collection: #{settings.master_ref.collection}"
#    conn.collection settings.master_ref.collection, (err, coll) ->
#      logger.debug mongodb.ObjectID(_id)
#      coll.findOne {_id: mongodb.ObjectID(_id)}, (err, doc) ->
#        logger.debug prettyjson.render(err)
#        logger.debug prettyjson.render(doc)
#        conn.close()


#def self.ref_upsert(doc)
## First sanitize the doc from angular to remove any $$hashKey elements
#doc['dbReferences'].each do |k, v|
#v['fields'].each {|f| f.except!('$$hashKey')}
#end
#
#saved_or_updated_id = nil
## If no _id this is a brand new document
#if doc['_id'].nil? or doc['_id'] == ''
#  saved_or_updated_id = @coll_refs.insert(doc)
#  p "New cached document inserted with _id: #{saved_or_updated_id.to_s}"
#else
#  #saved_or_updated_id = self.get_mongo_id(doc['_id'])
#  saved_or_updated_id = BSON::ObjectId(doc['_id'])
#  doc['_id'] = saved_or_updated_id
#  p "Existing cached document received with _id: #{doc['_id'].to_s}"
#  ap doc
#  @coll_refs.update({:_id => doc['_id']}, doc, opts = {:upsert => true})
#end
#saved_or_updated_id.to_s
#end
#
#def self.ref_get(_id)
##_id = self.get_mongo_id(_id)
#ap _id
#doc = @coll_refs.find_one({:_id => BSON::ObjectId(_id)})
#if doc
#  doc['_id'] = doc['_id'].to_s
#end
#return doc
#end
