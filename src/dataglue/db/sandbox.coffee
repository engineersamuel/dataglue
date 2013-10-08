settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
logger        = require('tracer').colorConsole(utils.logger_config)
pj            = require 'prettyjson'
dataSetCache  = require '../db/datasetCache'
dbLogic       = require '../db/dbLogic'
zlib          = require 'zlib'
prettyjson    = require 'prettyjson'
Db            = require('mongodb').Db
mongodb       = require 'mongodb'
_             = require 'lodash'
assert        = require('assert')
async         = require 'async'
mysql         = require 'mysql'

sandbox = {}
sandbox.hashEach = () ->
  test = {a: 1, b: 2}
  _.each test, (value, key) -> logger.debug "key: #{key}, value: #{value}"


sandbox.test_query_dataset = () ->
  p = dbLogic.queryDataSet '52277447f95fb65818000001'
  p.on 'dataset', (dataset) ->
    console.log dataset


sandbox.test_compress = (input) ->
  zlib.deflate input, (err, buffer) ->
    logger.info "Compressed: #{buffer}"
    logger.info "Compressed: #{buffer.toString('base64')}"

sandbox.test_decompress = (input) ->
    buff = new Buffer input, 'base64'
    logger.info "buff: #{buff.toString('base64')}"
    zlib.unzip buff, (err, results) ->
      logger.info "Decompressed: #{results.toString()}"

sandbox.refGet = (_id) ->
  logger.debug "Looking up ref with _id: #{_id}"
  dataSetCache.refGet _id, (err, doc) ->
    logger.debug prettyjson.render result

sandbox.dataset_get = (_id) ->
  logger.debug "Looking up data set with _id: #{_id}"
  dataSetCache.refGet _id, (err, doc) ->
    p = dbLogic.loadDataSet doc
    p.on 'resultsReady', (results) ->
      logger.debug typeof results
      logger.debug JSON.stringify(results)
#      logger.debug prettyjson.render _.keys(results[0])

sandbox.test_parse_string = () ->
  s = "52277447f95fb65818000001"
  logger.info JSON.parse s

sandbox.test_converting_streams_to_bubble = () ->
  streams = [{"key":"id count","values":[{"x":"ANZ","xType":"varchar","xGroupBy":"field","y":104,"yType":"varchar"},{"x":"ASEAN","xType":"varchar","xGroupBy":"field","y":21,"yType":"varchar"},{"x":"Brazil","xType":"varchar","xGroupBy":"field","y":52,"yType":"varchar"},{"x":"Canada","xType":"varchar","xGroupBy":"field","y":41,"yType":"varchar"},{"x":"CE","xType":"varchar","xGroupBy":"field","y":61,"yType":"varchar"},{"x":"GCG","xType":"varchar","xGroupBy":"field","y":69,"yType":"varchar"},{"x":"India","xType":"varchar","xGroupBy":"field","y":207,"yType":"varchar"},{"x":"Japan","xType":"varchar","xGroupBy":"field","y":65,"yType":"varchar"},{"x":"Korea","xType":"varchar","xGroupBy":"field","y":11,"yType":"varchar"},{"x":"Mexico","xType":"varchar","xGroupBy":"field","y":3,"yType":"varchar"},{"x":"NEE","xType":"varchar","xGroupBy":"field","y":246,"yType":"varchar"},{"x":"SOLA","xType":"varchar","xGroupBy":"field","y":31,"yType":"varchar"},{"x":"SWE","xType":"varchar","xGroupBy":"field","y":114,"yType":"varchar"},{"x":"UKI","xType":"varchar","xGroupBy":"field","y":144,"yType":"varchar"},{"x":"UNKNOWN","xType":"varchar","xGroupBy":"field","y":882,"yType":"varchar"},{"x":"US","xType":"varchar","xGroupBy":"field","y":1064,"yType":"varchar"}]}]
  bubbleData = _.flatten _.map streams, (stream) -> _.map stream.values, (item) -> item
  uniqueXs = _.unique _.map bubbleData, (item) -> item.x
  logger.info prettyjson.render bubbleData
  logger.info prettyjson.render uniqueXs
#  logger.info prettyjson.render _.map bubbleData, (item) -> item.x

sandbox.test_openshift_mongo = (user, pass, host, port, db) ->
  mongourl = "mongodb://#{user}:#{pass}@#{host}:#{port}/#{db}?auto_reconnect=true"
  logger.info "Attempting to connect to: #{mongourl}"
  mongodb.connect mongourl, (err, conn) ->
    if err
      logger.error err
    else
      logger.info "Attempting to connect to collection: #{settings.master_ref.cache}"
      conn.collection settings.master_ref.cache, (err, coll) ->
        if err
          logger.error err
          conn.close()
        else
          coll.find {}, (err, results) ->
            logger.debug prettyjson.render results
            conn.close()

sandbox.test_unique_stream_x = () ->
  streams = [
    {key: 'a', values: [{x:1, y:4}]},
    {key: 'b', values: [{x:2, y:10}]},
  ]
  # This takes each values in the stream and maps each value to x, flattens that out so a list of objects with x, then gets the unique values of x and removes undefined
  uniqueXs = _.without(_.unique(_.map(_.flatten(_.map(streams, (stream) -> stream.values), true), (item) -> item.x)), undefined)

  _.each uniqueXs, (uniqueX) -> _.each streams, (stream) -> if _.findIndex(stream.values, (v) -> v.x is uniqueX) is -1 then stream.values.push({x: uniqueX, y:0})

  logger.info uniqueXs
  logger.info prettyjson.render streams

sandbox.test_sort = () ->
  a = [1, 3, 5, 1, 2, 30, 99, 2]
  streams = [
    {key: 'a', values: [{x:1, y:4}]},
    {key: 'b', values: [{x:2, y:10}]},
  ]
  logger.info a
  a.sort()
  logger.info a

sandbox.test_first_stream_value = () ->
  streams = [
    {key: 'a', values: [{x:1, y:4}]},
    {key: 'b', values: [{x:2, y:10}]},
  ]
  firstItem = _.first(_.first(streams).values)
  logger.info prettyjson.render firstItem

sandbox.test_merge = () ->
  results = []
  source =
    x:             '2010-10'
    xType:         'datetime'
    xGroupBy:      'month'
    xMultiplex:    'x_multiplex'
    xMultiplexType: 'varchar'
    y:             3.1585
    yType:         'int'
  dest =
    x: '2012-10'
    y: 0

  results.push _.merge source, dest
#  results.push _.merge source, dest
  logger.info prettyjson.render results

sandbox.test_unique_sort = () ->
  values = ["2012-04","2011-03","2010-12","2011-01","2011-02","2010-10","2011-04","2011-05","2011-06","2011-07","2011-08","2011-09","2011-10","2011-11","2011-12","2012-01","2012-02","2012-03","2010-11","2012-05","2012-06","2012-07","2012-08","2012-09","2012-10","2012-11","2012-12","2013-01","2013-02","2013-03","2013-04","2013-05","2013-06","2013-07","2013-08","2013-09","2010-09"]
  values.sort()
  logger.info values

sandbox.test_mongo_bson_types = () ->
  mongourl = "mongodb://127.0.0.1:27017/dataglue?auto_reconnect=true"
  logger.info "Attempting to connect to: #{mongourl}"
  mongodb.connect mongourl, (err, conn) ->
    if err
      logger.error err
    else
      logger.info "Attempting to connect to collection: #{settings.master_ref.collection}"
      conn.collection settings.master_ref.collection, (err, coll) ->
        if err
          logger.error err
        else
          coll.find({}).toArray (err, results) ->
            logger.debug prettyjson.render results
            #_.each results, (r) ->
            #  logger.debug prettyjson.render r
            conn.close()

sandbox.test_mongo_run_command = () ->
  mongourl = "mongodb://127.0.0.1:27017/admin?auto_reconnect=true"
  logger.info "Attempting to connect to: #{mongourl}"
  mongodb.connect mongourl, (err, conn) ->
    if err
      logger.error err
    else
      logger.info "Attempting to connect to collection: #{settings.master_ref.collection}"
      #conn.executeDbCommand {text: 'show databases'}, (err, output) ->
      conn.command {listDatabases: 1}, (err, output) ->
        logger.info prettyjson.render output
        conn.close()

sandbox.test_collections = () ->
  mongourl = "mongodb://127.0.0.1:27017/dataglue?auto_reconnect=true"
  logger.info "Attempting to connect to: #{mongourl}"
  Db.connect mongourl, (err, db) ->
    assert.equal null, err
    logger.info "Opened connection to: #{mongourl}"

    db.collectionNames (err, collectionNames) ->
      assert.equal(null, err)
      logger.info prettyjson.render collectionNames

      db.close()

#    db.collections (err, collections) ->
#      _.each collections, (coll) ->
#        coll.stats (err, stats) ->
#          logger.info prettyjson.render stats
#      db.close()

sandbox.test_find = () ->
  logger.info _.find undefined, (item) -> item is 'a'

sandbox.test_substring = () ->
  dbName = 'dataglue-foo'
  item = {name: 'dataglue-foo.system.indexes'}
  logger.info item.name.replace(dbName + '.', '')

# http://www.w3schools.com/sql/sql_datatypes_general.asp
sandbox.setMongoDataTypes = (obj) ->
  if _.isDate obj
    return 'datetime'
  else if _.isBoolean obj
    # column type tinyint(1)
    return 'boolean'
  else if _.isArray obj
    return 'array'
  else if _.isObject obj
    return 'object'
  else if _.isString obj
    return 'varchar'
  else if utils.isInteger obj
    return 'int'
  else if utils.isFloat obj
    return 'float'


sandbox.test_fields = () ->
  mongourl = "mongodb://127.0.0.1:27017/test?auto_reconnect=true"
  logger.info "Attempting to connect to: #{mongourl}"
  Db.connect mongourl, (err, db) ->
    assert.equal null, err
    logger.info "Opened connection to: #{mongourl}"
    db.collection 'managers', (err, coll) ->
      logger.info "Opened collection: ref"
      coll.findOne {}, (err, doc) ->
        fields = _.map(_.keys(doc), (f) -> {COLUMN_NAME: f, DATA_TYPE: sandbox.setMongoDataTypes(doc[f]), COLUMN_TYPE: undefined, COLUMN_KEY: undefined})
        logger.info prettyjson.render fields
        db.close()


sandbox.test_array_concat = () ->
  a = [1, 2]
  b = a.concat [3, 4]
  logger.info prettyjson.render b

sandbox.test_mysql_escape = () ->
  beginCond = mysql.escape("!=").replace /'/g, ""
  logger.debug beginCond

#sandbox.hashEach()
#sandbox.test_compress('Hello World!')
#sandbox.test_decompress('eJzzSM3JyVcIzy/KSVEEABxJBD4=')
#sandbox.test_query_dataset()
#sandbox.refGet '52277447f95fb65818000001'
#sandbox.dataset_get '52277447f95fb65818000001'
#sandbox.test_parse_string()
#sandbox.test_converting_streams_to_bubble()
#sandbox.test_openshift_mongo('admin', 'YPZf1dXxwiFR', '127.13.123.2', '27017', 'dataglue')
#sandbox.test_openshift_mongo('', '', '127.0.0.1', '27018', 'dataglue')
#sandbox.test_unique_stream_x()
#sandbox.test_sort()
#sandbox.test_first_stream_value()
#sandbox.test_merge()
#sandbox.test_unique_sort()
#sandbox.test_mongo_bson_types()
#sandbox.test_mongo_run_command()
#sandbox.test_find()
#sandbox.test_collections()
#sandbox.test_substring()
#sandbox.test_fields()
#sandbox.test_array_concat()
sandbox.test_mysql_escape()