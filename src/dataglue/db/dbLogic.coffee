settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
dataSetCache  = require '../db/datasetCache'
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

# Convenience method to verify a field exists and has a valid value
CachedDataSet.verifyPropertyExists = (obj, field) ->
  if (_.has obj, field) and (obj[field] isnt undefined) and (obj[field] isnt '') then return true else return false

# Must do a callback here as this will be called in parallel and collected up
CachedDataSet.buildSql = (dbReference, callback) ->
  self = @
  type = settings.db_refs[dbReference['connection']]['type']
  #tableAliasLookup = {}
  # Define a lookup to easily associate the field aliases to the d3 to be parsed out later
  d3Lookup =
    key: undefined
    x: undefined
    xType: undefined
    y: undefined
    yType: undefined
    y2: undefined
    y2Type: undefined
    z: undefined
    zType: undefined
    r: undefined
    rType: undefined

  output = {
    sql: undefined
    d3Lookup: undefined
  }

  if type in ['mysql']
    sql = squel.select()
    sql.from("#{dbReference.schema}.#{dbReference.table}")
    _.each dbReference.fields, (field) ->
      if not field['excluded']?

        fieldName = field.COLUMN_NAME
        fieldAlias = undefined
        ################################################################################################################
        # Aggregations require the field be wrapped in something like COUNT
        ################################################################################################################
        if self.verifyPropertyExists field, 'aggregation'
          fieldAlias = 'y'
          if field.aggregation is 'count'
            sql.field("COUNT(#{fieldName})", fieldAlias)
            d3Lookup.key = "#{fieldName} count"
          else if field.aggregation is 'distinctCount'
            sql.field("COUNT(DISTINCT #{fieldName})", fieldAlias)
            d3Lookup.key = "#{fieldName} distinct count"
          else if field.aggregation is 'sum'
            sql.field("SUM(#{fieldName})", fieldAlias)
            d3Lookup.key = "#{fieldName} sum"
          else if field.aggregation is 'avg'
            sql.field("AVG(#{fieldName})", fieldAlias)
            d3Lookup.key = "#{fieldName} avg"

          d3Lookup.y = fieldName
          d3Lookup.yType = field.DATA_TYPE

        ################################################################################################################
        # Otherwise it is just the plain field
        ################################################################################################################
        else
          sql.field(fieldName)

        ################################################################################################################
        # See if a begin and end date are set
        ################################################################################################################
        if self.verifyPropertyExists field, 'beginDate'
          sql.where("#{fieldName} >= TIMESTAMP('#{field.beginDate}')")

        if self.verifyPropertyExists field, 'endDate'
          sql.where("#{fieldName} < TIMESTAMP('#{field.endDate}')")

        ################################################################################################################
        # Group By's require the group and the field
        ################################################################################################################
        addX = (field, fieldAlias, multiplex=false) ->
          if multiplex
            d3Lookup.xMultiplex = fieldAlias
            d3Lookup.xMultiplexType = field.DATA_TYPE
          else
            d3Lookup.x = fieldAlias
            d3Lookup.xType = field.DATA_TYPE
            d3Lookup.xGroupBy = field.groupBy

        addGroupByDate = (sql, field, fieldAlias, dateFormat) ->
          addX field, fieldAlias
          sql.field("DATE_FORMAT(#{field.COLUMN_NAME}, '#{dateFormat}')", fieldAlias)
          sql.group(fieldAlias)

        if self.verifyPropertyExists field, 'groupBy'

          if field.groupBy is 'multiplex'
            fieldAlias = 'x_multiplex'
            sql.field(field.COLUMN_NAME, fieldAlias)
            sql.group(fieldAlias)
            addX field, fieldAlias, true

          else
            fieldAlias = 'x'
            if field.groupBy is 'hour'
              addGroupByDate sql, field, fieldAlias, "%Y-%m-%d %H"
            else if field.groupBy is "day"
              addGroupByDate sql, field, fieldAlias, "%Y-%m-%d"
            else if field.groupBy is "month"
              addGroupByDate sql, field, fieldAlias, "%Y-%m"
            else if field.groupBy is "year"
              addGroupByDate sql, field, fieldAlias, "%Y"
            else if field.groupBy is 'field'
              sql.field(field.COLUMN_NAME, fieldAlias)
              sql.group(fieldAlias)
              addX field, fieldAlias

    output.sql = sql.toString()
    output.d3Lookup = d3Lookup

    callback null, output

  return self

CachedDataSet.mysqlQuery = (dbReference, queryHash, callback) ->
  self = @
  # Remember the connection property is the unique name of the connection reference
  mysql_ref = settings.mysql_refs[dbReference.connection || dbReference.name]
  conn = mysql.createConnection
    host     : mysql_ref['host'],
    user     : mysql_ref['user'],
    password : mysql_ref['pass'],

  # Query mysql, attempt to cache, and return the results regardless
  logger.debug "Querying mysql reference: #{dbReference.connection} with sql: #{queryHash}"
  conn.query queryHash.sql, (err, results) ->
    if err
      logger.debug "Error Querying mysql reference: #{dbReference.connection} with sql: #{queryHash}, err: #{prettyjson.render err}"
      callback err
    else
      logger.debug "Found #{results.length} results."
      # Attempt to cache if the cache option is set to true, otherwise just return the results
      if queryHash.cache?
        dataSetCache.statementCachePut dbReference, queryHash, results, (err, outcome) ->
          if err
            logger.error "Failed to cache sql due to: #{prettyjson.render err}"
          else
            # After the results have been cached go ahead and return the results from the above query
            callback null, results
      else
        callback null, results

    # End the connection before existing the function
    conn.end()

  return self

CachedDataSet.query = (dbReference, queryHash, callback) ->
  self = @
  if dbReference.type is 'mysql'
    logger.debug "Querying mysql reference: #{dbReference.name} with sql: #{queryHash.sql}"
    CachedDataSet.mysqlQuery dbReference, queryHash, (err, results) ->
      if err
        callback err
      else callback null, results
  return self

#CachedDataSet.getAllDbInformation = (callback) ->
#  output =
#    d3TreeData:
#      name: 'DB References',
#      children: _.map settings.db_refs, (db_ref) ->
#        name: db_ref.name,
#        children: CachedDataSet.showSchemas db_ref, (schema) ->
#          name: schema
##              children: _.map dbLogic.showTables, (table) ->
##                name: table,
##                children: []
##              }
CachedDataSet.getFields = (dbRefName, schemaName, tableName, callback) ->
  dbReference = settings.db_refs[dbRefName]
  sql = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{schemaName}' AND TABLE_NAME = '#{tableName}'"
  CachedDataSet.query dbReference, {sql: sql, cache: false}, (err, fields) ->
    callback err, fields
  return @

#  return DatabaseManagerModule::query(params[:ref], sql).to_a.to_json || []
CachedDataSet.getTables = (dbRefName, schemaName, callback) ->
  dbReference = settings.db_refs[dbRefName]
  sql = "SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{schemaName}'"
  CachedDataSet.query dbReference, {sql: sql, cache: false}, (err, results) ->
    callback err, _.map results
  return @

CachedDataSet.getSchemas = (dbRefName, callback) ->
  logger.debug "Call to getSchemas"
  dbReference = settings.db_refs[dbRefName]
  sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA'
  CachedDataSet.query dbReference, {sql: sql, cache: false}, (err, results) ->
    logger.debug prettyjson.render "Schemas: results"
    callback err, _.map results, (schema) -> schema.schema
  return @

#
#CachedDataSet.showSchemas = (dbReference, callback) ->
#  sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA'
#  CachedDataSet.query dbReference, {sql: sql, cache: false}, (err, results) ->
#    callback err, _.map results, (schema) -> results.schema

CachedDataSet.queryDynamic = (dbReference, callback) ->
  self = @
  output = {}
  key = dbReference['key']
  output = {}
  output[key] =
    results: undefined
    queryHash: undefined

  # logger.debug "queryDynamic, key: #{key}, dbReference: #{prettyjson.render dbReference}"
  CachedDataSet.buildSql dbReference, (err, queryHash) ->
    if err
      logger.error "Error building SQL: #{prettyjson.render err}"
      callback err
    else
      # To compute the query and transform to the d3 results requires an x or a y to be set, if not, do nothing
      if queryHash.d3Lookup.x isnt undefined and queryHash.d3Lookup.y isnt undefined
        dataSetCache.statementCacheGet dbReference, queryHash, (err, results) ->
          if err
            callback err
          else
            output[key].queryHash = queryHash
            # If results, place into a hash with the key and send back up the chain
            if results?
              output[key].results = results
              callback null, output
            # Otherwise this is a cache miss, need to refetch the data
            else
              CachedDataSet.mysqlQuery dbReference, queryHash, (err, results) ->
                output[key].queryHash = queryHash
                output[key].results = results
                callback err, output
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

  async.map _.values(doc.dbReferences), self.queryDynamic, (err, arrayOfDataSetResults) ->
    if err
      logger.error "Error querying dbReferences: #{prettyjson.render err}"
      callback err
    else
      _.each arrayOfDataSetResults, (dataSetResult, idx) ->
        # The dataSetResult is simply a hash
        dataSetResult = _.values(dataSetResult)[0]
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
                x: item.x,
                xOrig: item.x
                # Converts x to a unix offset (ms) if x is a type date
                x: if dataSetResult.queryHash.d3Lookup.xType in ['date', 'datetime'] then +moment(item.x) else item.x
                xType: dataSetResult.queryHash.d3Lookup.xType
                xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy
                xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex
                xMultipleType: dataSetResult.queryHash.d3Lookup.xMultiplexType
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
          refItem = _.first(_.first(streams).values)

          _.each uniqueXs, (uniqueX) ->

            _.each streams, (stream, streamIdx) ->
              # TODO must print each line to figur eout why 2010-09 is equaling itself
#              logger.debug "Looking for: #{uniqueX} in stream: #{stream.key}"
              if stream.key is "professional avg (APAC)" and uniqueX is '2010-09'
                streamXs = _.map(streams[streamIdx].values, (v) -> v.x)
                streamXs.sort()

              if _.find(stream.values, (v) -> return v.x is uniqueX) is undefined
                newItem = {
                  x: uniqueX,
                  y: 0,
                  xType: refItem.xType
                  xGroupBy: refItem.xGroupBy
                  xMultiplex: refItem.xMultiplex
                  xMultipleType:  refItem.xMultiplexType
                  yType: refItem.yType

                }
                # The _.merge has SERIOUS implications.  Do NOT use that method without understanding that it overrides
                # past objects in the future
                #newItem = _.merge {x: uniqueX, y: 0}, _.clone(refItem)
                #logger.debug "\tNot Found in stream: #{streamIdx}, adding: #{prettyjson.render newItem}"
                #logger.debug  "Stream #{streamIdx}.length: before #{streams[streamIdx].values.length}"
                streams[streamIdx].values.push(newItem)
                #streamXs = _.map(streams[streamIdx].values, (v) -> v.x)
                #streamXs.sort()
                #logger.debug  "Stream: #{streamIdx} now has values: #{streamXs}"
                #logger.debug  "Stream #{streamIdx}.length: #{streams[streamIdx].values.length}"

          # Finally set the d3Data to the streams and delete the results so as not to create too big of a response
          dataSetResult.d3Data = streams
          delete dataSetResult.results

        # else No mutliplex so just return a 1 stream for the array of results
        else
          logger.debug "Working with non-multiplexed data!"
          stream = {key: dataSetResult.queryHash.d3Lookup.key, values: []}
          _.each dataSetResult.results, (item) ->

            # logger.debug "item: #{prettyjson.render item}"
            stream.values.push
#              x: item.x,
              xOrig: item.x
              x: if dataSetResult.queryHash.d3Lookup.xType in ['date', 'datetime'] then moment(item.x).unix() else item.x
              xType: dataSetResult.queryHash.d3Lookup.xType
              xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy
              xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex
              xMultipleType: dataSetResult.queryHash.d3Lookup.xMultiplexType
              y: item.y
              yType: dataSetResult.queryHash.d3Lookup.yType

             dataSetResult.d3Data = [stream]
          delete dataSetResult.results

        # Now that we have a d3Data composed of one or more streams each those streams and sort by x
        _.each dataSetResult.d3Data, (stream) ->
          stream.values.sort (a, b) -> a.x - b.x
#          stream.values.sort (a, b) -> +moment(a.x) - +moment(b.x)
          # TODO do not renable this unless specifically verifying the moment is not being duplicated resulting in identical values
          # A clone may be required or a new
#          stream.values.sort (a, b) -> new moment(a.x).valueOf() - new moment(b.x).valueOf()

      callback null, arrayOfDataSetResults
  return self


# Now build the query for each database reference
CachedDataSet.queryDataSet = (arg, callback) ->
  @.loadDataSet arg, (err, results) -> callback err, results

module.exports = CachedDataSet
