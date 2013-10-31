settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
dataSetCache  = require './datasetCache'
DbQuery       = require './dbQuery'
QueryBuilder  = require './queryBuilder'
squel         = require 'squel'
_             = require 'lodash'
async         = require 'async'
mysql         = require 'mysql'
moment        = require 'moment'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'
#EventEmitter  = require("events").EventEmitter

#CachedDataSet = new EventEmitter()
CachedDataSet = {}

CachedDataSet.queryDynamic = (dbReference, callback) ->
  self = @
  output = {}
  key = dbReference['key']
  output = {}
  output[key] =
    dbRefKey: dbReference.key
    results: undefined
    d3Data: undefined
    queryHash: undefined
    cache: dbReference.cache

  # logger.debug "queryDynamic, key: #{key}, dbReference: #{prettyjson.render dbReference}"
  QueryBuilder.buildQuery dbReference, (err, queryHash) ->
    if err
      logger.error "Error building query: #{prettyjson.render err}"
      callback err
    else
      logger.debug prettyjson.render queryHash

      # To compute the query and transform to the d3 results requires an x or a y to be set, if not, do nothing
      if queryHash.d3Lookup.x isnt undefined and queryHash.d3Lookup.y isnt undefined

        # If cache is true for this reference then attempt to lookup the cache first, falling back otherwise
        if utils.truthy(dbReference.cache)
          # The statementCacheGet will attempt to get the d3 data, not the results of the sql query
          dataSetCache.statementCacheGet dbReference, queryHash, (err, cachedD3Data) ->
            if err
              callback err
            else
              output[key].queryHash = queryHash
              # If results, place into a hash with the key and send back up the chain
              if cachedD3Data?
                output[key].d3Data = cachedD3Data
                callback null, output
              # Otherwise this is a cache miss, need to refetch the data
              else
                DbQuery.query dbReference, queryHash, (err, dbResults) ->
                  output[key].queryHash = queryHash
                  output[key].results = dbResults
                  # If a SQL result we must do further processing on the data to transform it to d3 streams
  #                if dbReference.type in utils.sqlDbTypes then output[key].results = dbResults
  #                # If a NoSQL result no further processing need due to pipelining ability
  #                if dbReference.type in utils.noSqlTypes then output[key].d3Data = dbResults
                  callback err, output
        # If cache is false do a query immediately and don't even attempt to hit the cache.
        else
          DbQuery.query dbReference, queryHash, (err, dbResults) ->
            output[key].queryHash = queryHash
            output[key].results = dbResults
            callback err, output


      # These are mainly convenience warnings to send to the user to indicate why the SQL couldn't be run
      else
        if queryHash.d3Lookup.x is undefined
          warning = "Could not generate data for #{key}, no x set. Please make sure to group on some field."
          output[key].warning = warning
          logger.warn warning
        if queryHash.d3Lookup.y is undefined
          warning = "Could not generate data for #{key}, no y set. Please make sure to aggregate a field."
          output[key].warning = warning
          logger.warn warning

        output[key].queryHash = queryHash
        callback err, output

  return self

CachedDataSet.loadDataSet = (doc, callback) ->
  self = @

  # Parse to JSON if not already
  doc = if _.isString(doc) then JSON.parse doc else doc

  # TODO First attempt to resolve these queries in cache where the Cache will contain the d3 formatted data
  # Maybe a first implementation will be an all or nothing cache, but why not make it more intelligent the first time
  # around?

  # TODO if two dbReferences are of the same connection and are joined to each other, must map those as a set
  # Let's say we have doc.dbReferences = [a, b, c, d, e] where b, c, d are joined, then need to pass
  # [a, [b, c, d], e] which would result in 3 mapped results, not 5.

  # TODO create a method in utils.coffee which will utils.splitByJoinedDbReferences

  async.map _.values(doc.dbReferences), self.queryDynamic, (err, arrayOfDataSetResults) ->
    if err
      logger.error "Error querying dbReferences: #{prettyjson.render err}"
      callback err
    else

#      logger.debug prettyjson.render arrayOfDataSetResults

      _.each arrayOfDataSetResults, (dataSetResult, idx) ->

        #logger.debug "arrayOfDataSetResults: #{prettyjson.render arrayOfDataSetResults}"
        # The dataSetResult is simply a hash with 1 key, therefore the value is [0]
        dataSetResult = _.values(dataSetResult)[0]

        # If there is no d3Data defined, no cached data, so compute the d3 data based on the data set results
        if not dataSetResult.d3Data?

          # The d3Data for now will be composed of Streams of unique data sets defined by the dataset reference
          # If xMultiplex exists iterate over the results
          if dataSetResult.queryHash.d3Lookup.xMultiplex and dataSetResult.queryHash.d3Lookup.xMultiplex != ''
            logger.debug "Working with multiplexed data!"
            streams = []
            uniqueMutliplexedXs = _.unique _.map dataSetResult.results, (item) -> item[dataSetResult.queryHash.d3Lookup.xMultiplex]
            # For each of the unique multiplexed results
            _.each uniqueMutliplexedXs, (uniqueX) ->

              stream = {key: "#{dataSetResult.queryHash.d3Lookup.key} (#{uniqueX})", values: []}

              # Filter the results by that multiplexed x
              stream.values =
              _(dataSetResult.results)
              .filter((item) -> item[dataSetResult.queryHash.d3Lookup.xMultiplex] is uniqueX)  # Filter by each unique Mutliplexed x
              .map((item) ->
                  #x: item.x,
                  x: utils.parseX(item.x, {xType: dataSetResult.queryHash.d3Lookup.xType, xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy})
                  xOrig: item.x
                  # Converts x to a unix offset (ms) if x is a type date
#                  x: if dataSetResult.queryHash.d3Lookup.xType in ['date', 'datetime'] then +moment.utc(item.x) else item.x
                  xType: dataSetResult.queryHash.d3Lookup.xType
                  xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy
                  xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex
                  xMultiplexType: dataSetResult.queryHash.d3Lookup.xMultiplexType
                  y: item.y || 0
                  yType: dataSetResult.queryHash.d3Lookup.yType
              ) # Each result, filtered by the multiplexed x is composed into a single stream
              .value()  # The value is the array of values filtered by the multiplexed x value

              # Now push this stream onto the streams
              streams.push stream

            # The data is pure at this point but d3 doesn't work well with mismatching streams.
            # I.e. [{a:1,b:2,c:3},{a:4,c:5}] so let's do some slicing and dicing to 0 init any missing data

            # Grab the unique x's in all streams
            # This takes each values in the stream and maps each value to x, flattens that out so a list of objects with x, then gets the unique values of x and removes undefined
            uniqueXs = _.without(_.unique(_.map(_.flatten(_.map(streams, (stream) -> stream.values), true), (item) -> item.x)), undefined)
            uniqueXs.sort()

            # Every Unique stream *must* contain a defined set of attributes.  I.e. If x is a datetime it is always a datetime in this unique stream or set of streams
            # Given that let's extract out a single object of types to apply below when filling in the data
            refItem = _.first(_.first(streams)?.values)

            _.each uniqueXs, (uniqueX) ->
              _.each streams, (stream, streamIdx) ->
                if _.find(stream.values, (v) -> return v.x is uniqueX) is undefined
                  newItem = {
                    x: uniqueX,
                    y: 0,
                    xType: refItem.xType
                    xGroupBy: refItem.xGroupBy
                    xMultiplex: refItem.xMultiplex
                    xMultiplexType:  refItem.xMultiplexType
                    yType: refItem.yType

                  }
                  # The _.merge has SERIOUS implications.  Do NOT use that method without understanding that it overrides
                  # past objects in the future
                  #newItem = _.merge {x: uniqueX, y: 0}, _.clone(refItem)
                  streams[streamIdx].values.push(newItem)

            # Finally set the d3Data to the streams and delete the results so as not to create too big of a response
            dataSetResult.d3Data = streams
            delete dataSetResult.results

            # Store the d3Data of the dataSetResult after the data has been successfully generated
            if utils.truthy(dataSetResult.cache) and dataSetResult.d3Data? and dataSetResult.d3Data.length > 0
              dataSetCache.dataSetResultCachePut dataSetResult, (err, outcome) ->
                if err
                  logger.error "Failed to cache the dataSetResult due to: #{prettyjson.render err}"
                else
                  # After the results have been cached go ahead and return the results from the above query
                  callback null, outcome
            else
              logger.warn "Not caching, either cache set to false or no d3Data"

          # else No mutliplex so just return a 1 stream for the array of results
          else

            # If there is no d3Data defined compute for this single data set
            if not dataSetResult.d3Data?
              logger.debug "Working with non-multiplexed data!"
              stream = {key: dataSetResult.queryHash.d3Lookup.key, values: []}
              _.each dataSetResult.results, (item) ->

                # TODO optionally allow null eventually, for now filter it out of the x
                if item.x?

                  # logger.debug "item: #{prettyjson.render item}"
                  stream.values.push
                    # x: item.x,
                    x: utils.parseX(item.x, {xType: dataSetResult.queryHash.d3Lookup.xType, xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy})
                    xOrig: item.x
                    #x: if dataSetResult.queryHash.d3Lookup.xType in ['date', 'datetime'] then +moment(item.x) else item.x
                    xType: dataSetResult.queryHash.d3Lookup.xType
                    xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy
                    xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex
                    xMultiplexType: dataSetResult.queryHash.d3Lookup.xMultiplexType
                    y: item.y
                    yType: dataSetResult.queryHash.d3Lookup.yType

                   dataSetResult.d3Data = [stream]
              delete dataSetResult.results

          # Now that we have a d3Data composed of one or more streams each those streams and sort by x
          _.each dataSetResult.d3Data, (stream) ->
            stream.values.sort (a, b) -> a.x - b.x
            # stream.values.sort (a, b) -> +moment(a.x) - +moment(b.x)

          # Store the d3Data of the dataSetResult after the data has been successfully generated
          # if dataSetResult.queryHash.cache?  # Maybe in the future I will allow it to be configurable
          if utils.truthy(dataSetResult.cache) and dataSetResult.d3Data? and dataSetResult.d3Data.length > 0
            dataSetCache.dataSetResultCachePut dataSetResult, (err, outcome) ->
              if err
                logger.error "Failed to cache the dataSetResult due to: #{prettyjson.render err}"
              else
                # After the results have been cached go ahead and return the results from the above query
                logger.debug "Successfully cached d3Data."
                callback null, outcome
          else
            logger.warn "Not caching, either cache set to false or no d3Data"

      #logger.debug prettyjson.render arrayOfDataSetResults
      callback null, arrayOfDataSetResults
  return self


# Now build the query for each database reference
CachedDataSet.queryDataSet = (arg, callback) ->
  @.loadDataSet arg, (err, results) -> callback err, results

module.exports = CachedDataSet
