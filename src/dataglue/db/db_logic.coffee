settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
dataSetCache  = require '../db/dataset_cache'
squel         = require 'squel'
_             = require 'lodash'
async         = require 'async'
mysql         = require 'mysql'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'
EventEmitter  = require("events").EventEmitter

CachedDataSet = new EventEmitter()

# Must do a callback here as this will be called in parallel and collected up
CachedDataSet.buildSql = (dbReference, callback) ->
  self = @
  type = settings.db_refs[dbReference['connection']]['type']
  #tableAliasLookup = {}
  # Define a lookup to easily associate the field aliases to the d3 to be parsed out later
  d3Lookup =
    key: undefined
    x: undefined
    y: undefined
    y2: undefined
    z: undefined

  output = {
    sql: undefined
    d3Lookup: undefined
  }

  if type in ['mysql']
    sql = squel.select()
    sql.from("#{dbReference.schema}.#{dbReference.table}")
    _.each dbReference.fields, (field) ->
      if not field['excluded']?
        field_name = field.COLUMN_NAME
        field_alias = undefined
        ################################################################################################################
        # Aggregations require the field be wrapped in something like COUNT
        ################################################################################################################
        if _.has field, 'aggregation'
          if field.aggregation is 'count'
            # field_alias = "#{field_name}_count"
            field_alias = 'y'
            sql.field("COUNT(#{field_name})", field_alias)

            # TODO statically setting this for now
            d3Lookup.y = field_name
            d3Lookup.key = "#{field_name} count"
        ################################################################################################################
        # Otherwise it is just the plain field
        ################################################################################################################
        else
          sql.field(field_name)

        if _.has field, 'beginDate'
          sql.where("#{field_name} >= TIMESTAMP('#{field.beginDate}')")

        if _.has field, 'endDate'
          sql.where("#{field_name} < TIMESTAMP('#{field.endDate}')")

        ################################################################################################################
        # Group By's require the group and the field
        ################################################################################################################
        if _.has field, 'groupBy'
          if field.groupBy is 'day'
            # Group by day means YYYY-MM-DD
            # field_alias = "#{field_name}_grouped_by_day"
            field_alias = 'x'
            sql.field("DATE_FORMAT(#{field_name}, '%Y-%m-%d')", field_alias)
            sql.group(field_alias)
            # sql.group("DATE_FORMAT(#{field_name}, '%Y-%m-%d')")

            # TODO statically setting this for now
            d3Lookup.x = field_alias

    output.sql = sql.toString()
    output.d3Lookup = d3Lookup
    callback null, output

  return self

CachedDataSet.mysqlQuery = (dbReference, queryHash, callback) ->
  self = @
  # Remember the connection property is the unique name of the connection reference
  mysql_ref = settings.mysql_refs[dbReference.connection]
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
      logger.debug "Found #{results.length} results"
      q = dataSetCache.statementCachePut dbReference, queryHash, results
      q.on 'failure', (cacheError) -> logger.error "Failed to cache sql due to: #{prettyjson.render cacheError}"
      q.on 'cachePut', () ->
        # After the results have been cached go ahead and return the results from the above query
        callback null, results

    # End the connection before existing the function
    conn.end()

  return self

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


#      # A failure means something happened at the caching layer, but that shouldn't affect the query
#      q.on 'failure', (err) ->
#        logger.warn "Failure in the caching layer, but continuing with the query.  Error: #{prettyjson.render err}"
#        self.mysqlQuery dbReference, sql, (err, results) -> callback err, makeOutput(results)
#      # Cache hit is simple, return the cached results
#      q.on 'cacheHit', (results) -> callback null, makeOutput(results)
#      # If cache miss re-execute the query and make sure the statement is cached inline as well
#      q.on 'cacheMiss', () -> self.mysqlQuery dbReference, sql, (err, results) -> callback err, makeOutput(results)

  return self

CachedDataSet.loadDataSet = (doc, callback) ->
  self = @

  # Parse to JSON if not already
  doc = if _.isString(doc) then JSON.parse doc else doc

  async.map _.values(doc.dbReferences), self.queryDynamic, (err, arrayOfHashes) ->
    if err
      logger.error "Error querying dbReferences: #{prettyjson.render err}"
      callback err
    else


      _.each arrayOfHashes, (resultsHash) ->

        _.each resultsHash, (theHash, dbRefKey) ->
          #logger.debug "theHash: #{theHash}, dbRefKey: #{dbRefKey}"
          dbReference = doc[dbRefKey]
          # The d3Data for now will be composed of Streams of unique data sets defined by the dataset reference
          stream = {key: theHash.queryHash.d3Lookup.key, values: []}

          _.each theHash.results, (item) ->
            # logger.debug "item: #{prettyjson.render item}"
            stream.values.push
              x: item.x
              y: item.y

          resultsHash[dbRefKey].d3Data = stream
        # Now convert the results to d3
        callback null, arrayOfHashes

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
