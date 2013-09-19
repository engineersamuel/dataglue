settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
dataSetCache  = require '../db/datasetCache'
squel         = require 'squel'
_             = require 'lodash'
async         = require 'async'
mysql         = require 'mysql'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'
#EventEmitter  = require("events").EventEmitter

#CachedDataSet = new EventEmitter()
CachedDataSet = {}

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
        if _.has field, 'aggregation'
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

        if _.has field, 'beginDate'
          sql.where("#{fieldName} >= TIMESTAMP('#{field.beginDate}')")

        if _.has field, 'endDate'
          sql.where("#{fieldName} < TIMESTAMP('#{field.endDate}')")

        ################################################################################################################
        # Group By's require the group and the field
        ################################################################################################################
        addX = (field, fieldAlias) ->
          d3Lookup.x = fieldAlias
          d3Lookup.xType = field.DATA_TYPE
          d3Lookup.xGroupBy = field.groupBy

        addGroupByDate = (sql, field, fieldAlias, dateFormat) ->
          addX field, fieldAlias
          sql.field("DATE_FORMAT(#{field.COLUMN_NAME}, '#{dateFormat}')", fieldAlias)
          sql.group(fieldAlias)

        if _.has field, 'groupBy'
          fieldAlias = 'x'
          if field.groupBy is 'hour'
            addGroupByDate sql, field, fieldAlias, "%Y-%m-%d %H"
            #sql.field("DATE_FORMAT(#{fieldName}, "%Y-%m-%d %H")", fieldAlias)
          else if field.groupBy is "day"
            addGroupByDate sql, field, fieldAlias, "%Y-%m-%d"
            #sql.field("DATE_FORMAT(#{fieldName}, "%Y-%m-%d")", fieldAlias)
          else if field.groupBy is "month"
            addGroupByDate sql, field, fieldAlias, "%Y-%m"
            #sql.field("DATE_FORMAT(#{fieldName}, "%Y-%m")", fieldAlias)
          else if field.groupBy is "year"
            addGroupByDate sql, field, fieldAlias, "%Y"
            #sql.field("DATE_FORMAT(#{fieldName}, '%Y-%m')", fieldAlias)
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
        stream = {key: dataSetResult.queryHash.d3Lookup.key, values: []}

        # Now convert the results to d3
        _.each dataSetResult.results, (item) ->
          # logger.debug "item: #{prettyjson.render item}"
          stream.values.push
            x: item.x
            xType: dataSetResult.queryHash.d3Lookup.xType
            xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy
            y: item.y
            yType: dataSetResult.queryHash.d3Lookup.yType

           dataSetResult.d3Data = stream
          delete dataSetResult.results

      callback null, arrayOfDataSetResults
  return self


# Now build the query for each database reference
CachedDataSet.queryDataSet = (arg, callback) ->
  @.loadDataSet arg, (err, results) -> callback err, results

module.exports = CachedDataSet


#  def self.query_dataset(doc, opts={})
#  data = {}
#  tmp = {}
#  threads = []
#  doc['dbReferences'].each do |key, dbReference|
#  threads << Thread.new {
#  # Db reference is a key => value (hash)
#  data[key] = self.query_dynamic(dbReference['connection'], dbReference['schema'], dbReference['table'], dbReference['fields'])
#    ap "Data key: #{key} length: #{data[key].length}"
#  }
#  end
#
#  # Join each of the threads that fetched the data
#  threads.each {|t| t.join()}
#
#  # TODO just do all cross db joins now in Ruby, not feasible to do this in javascript due to the potential amount
#  # Of data being gzipped.  Event say 1-2 megs of gzipped content which is 9 megs uncompressed results in the
#  # Browser malfunctioning on a quad i7 laptop with 8g ram.
#  doc['dbReferences'].each do |dbReference, value|
#  tmp[dbReference] = {
#  :rawValues => nil
#  }
#
#  # Make sure the d3 key is in the hash
#  if tmp[dbReference].has_key?(:d3).nil?
#  tmp[dbReference][:d3] = {}
#  end
#
#  value['fields'].each do |field|
#
#  # Make sure the field is in the hash
#  if tmp[dbReference][:field].nil?
#  tmp[dbReference][:field] = field
#  end
#
#  ################################################
#  # Grouping by must always come first
#  ################################################
#  if field['groupBy'] and field['groupBy'] != ''
#    groupedRows = {}
#  end
#  end
#  end
#
#  ap tmp
#  return data
#  end
