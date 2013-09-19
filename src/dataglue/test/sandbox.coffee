settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
logger        = require('tracer').colorConsole(utils.logger_config)
pj            = require 'prettyjson'
dataSetCache  = require '../db/datasetCache'
dbLogic       = require '../db/dbLogic'
snappy        = require 'snappy'
zlib          = require 'zlib'
prettyjson    = require 'prettyjson'
_             = require 'lodash'

sandbox = {}
sandbox.hashEach = () ->
  test = {a: 1, b: 2}
  _.each test, (value, key) -> logger.debug "key: #{key}, value: #{value}"


sandbox.test_query_dataset = () ->
  p = dbLogic.queryDataSet '52277447f95fb65818000001'
  p.on 'dataset', (dataset) ->
    console.log dataset

sandbox.test_snappy = (stuff) ->
  data = snappy.compress stuff, (err, data) ->
    logger.info "Compressed text: #{data}"

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

#  buffer = new Buffer('eJzT0yMAAGTvBe8=', 'base64')
#  zlib.unzip buffer, (err, buffer) ->
#    if !err
#      logger.info buffer.toString()

#logger.debug "db_refs:"
#logger.debug settings.db_refs
#
#logger.debug "mysql_refs:"
#logger.debug settings.mysql_refs
#
#logger.debug "master database: "
#logger.debug settings.master_ref

#p = dataset_cache.refGet('52277447f95fb65818000001')
#p.on 'success', (doc) -> logger.debug pj.render doc

#p = dbLogic.queryDataset '52277447f95fb65818000001'


#sandbox.hashEach()
#sandbox.test_snappy(settings.db_refs)
#sandbox.test_compress('Hello World!')
#sandbox.test_decompress('eJzzSM3JyVcIzy/KSVEEABxJBD4=')
#sandbox.test_query_dataset()
#sandbox.refGet '52277447f95fb65818000001'
#sandbox.dataset_get '52277447f95fb65818000001'
#sandbox.test_parse_string()
sandbox.test_converting_streams_to_bubble()
