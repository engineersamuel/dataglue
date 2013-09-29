settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
squel         = require 'squel'
_             = require 'lodash'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'


QueryBuilder = {}

QueryBuilder.buildSqlQuery = (dbReference, callback) ->
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
    query: undefined
    d3Lookup: undefined
  }

  sql = squel.select()
  sql.from("#{dbReference.schema}.#{dbReference.table}")

  ################################################################################################################
  # Limit the query by default
  ################################################################################################################
  if utils.verifyPropertyExists dbReference, 'limit'
    sql.limit(dbReference.limit)

  _.each dbReference.fields, (field) ->
    if not field['excluded']?

      fieldName = field.COLUMN_NAME
      fieldAlias = undefined
      ################################################################################################################
      # Aggregations require the field be wrapped in something like COUNT
      ################################################################################################################
      if utils.verifyPropertyExists field, 'aggregation'
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
      if utils.verifyPropertyExists field, 'beginDate'
        sql.where("#{fieldName} >= TIMESTAMP('#{field.beginDate}')")

      if utils.verifyPropertyExists field, 'endDate'
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

      if utils.verifyPropertyExists field, 'groupBy'

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

  output.query = sql.toString()
  output.d3Lookup = d3Lookup

  callback null, output

# Builds a Mongo Aggregation query: http://docs.mongodb.org/manual/aggregation/
QueryBuilder.buildMongoQuery = (dbReference, callback) ->

  # Define a lookup to easily associate the field aliases to the d3 to be parsed out later
  output = {
    query: undefined
    d3Lookup: {}
  }

  pipeline = []
  theMatch = {
    '$match': {}
  }
  theGroup = {
    '$group': {
      _id: {}
    }
  }
  theLimit = {'$limit': undefined}

  if utils.verifyPropertyExists dbReference, 'limit'
    theLimit['$limit'] = parseInt dbReference.limit
  else
    theLimit['$limit'] = dbReference.limit

  # Iterate over the fields and build the aggregation pipeline based on the given field options
  _.each dbReference.fields, (field) ->
    if not field['excluded']?
      fieldName = field.COLUMN_NAME

      if utils.verifyPropertyExists field, 'beginDate'
        theMatch['$match'][fieldName] = {'$gt': moment(field.beginDate)}

      if utils.verifyPropertyExists field, 'endDate'
        theMatch['$match'][fieldName] = {'$lte': moment(field.endDate)}


      if utils.verifyPropertyExists field, 'groupBy'
        # Mongo likes to always hae the field exist in the doc if grouping on
        theMatch['$match'][fieldName] = {'$exists': true}

        if field.groupBy is 'year'
          theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}

        else if field.groupBy is 'month'
          theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
          theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}

          # TODO for each one of these add a project to project the x to this field?
          # theProject['$project'] = {x : year + month ?}
        else if field.groupBy is 'day'
          theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
          theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
          theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
        else if field.groupBy is 'hour'
          theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
          theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
          theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
          theGroup['$group']['_id'].hour = {'$hour': "$#{fieldName}"}
        else if field.groupBy is 'field'
          theGroup['$group']['_id'] = "$#{fieldName}"

      if utils.verifyPropertyExists field, 'aggregation'
        if field.aggregation is 'count'
          theGroup['$group']['count'] = {'$sum': 1}

  pipeline.push theMatch
  pipeline.push theGroup
  pipeline.push theLimit unless theLimit['$limit'] is undefined

  #logger.debug prettyjson.render JSON.stringify(pipeline)
  output.query = pipeline
  callback null, output

# Must do a callback here as this will be called in parallel and collected up
QueryBuilder.buildQuery = (dbReference, callback) ->
  self = @
  #type = settings.db_refs[dbReference['connection']]['type']
  type  = dbReference['type']

  if type in ['mysql', 'postgre', 'postgresql']
    QueryBuilder.buildSqlQuery dbReference, (err, output) ->
      callback err, output
  else if type in ['mongo']
    # Note that this is a mongo Aggregation Query
    QueryBuilder.buildMongoQuery dbReference, (err, output) ->
      callback err, output


  return self

module.exports = QueryBuilder
