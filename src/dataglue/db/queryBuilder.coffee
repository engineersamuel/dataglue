settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
squel         = require 'squel'
_             = require 'lodash'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'
moment        = require 'moment'
mysql         = require 'mysql'  # Primarily for the mysql.escape function

QueryBuilder = {}

QueryBuilder.buildSqlQuery = (dbReference, callback) ->
  # Define a lookup to easily associate the field aliases to the d3 to be parsed out later
  d3Lookup =
    key: undefined
    x: undefined
    xType: undefined
    y: undefined
    yType: undefined

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
      # See if a single value condition is set
      ################################################################################################################
      if utils.verifyPropertyExists(field, 'cond') and field.cond?
        # Escape the cond to prevent malicious input, but replace the ' with nothing
        cond = mysql.escape(field.cond).replace /'/g, ""
        # Since the field.cond is an operator like =, !=, LIKE, ect.. escape that value and insert it right in
#        sql.where("#{fieldName} #{cond} ?", utils.formatFieldValue(field, field.condValue, 'sql'))
        sql.where("#{fieldName} #{cond} #{utils.formatFieldValue(field, field.condValue, 'sql')}")

      ################################################################################################################
      # See if a range value condition is set
      ################################################################################################################
      # Since the field.cond is an operator like =, !=, LIKE, ect.. escape that value and insert it right in
      if utils.verifyPropertyExists(field, 'beginCond') and field.beginCond?
        # Escape the cond to prevent malicious input, but replace the ' with nothing
        beginCond = mysql.escape(field.beginCond).replace /'/g, ""
        if _.contains ['date', 'datetime'], field.DATA_TYPE
          sql.where("#{fieldName} #{beginCond} TIMESTAMP('#{utils.formatFieldValue(field, field.beginValue, 'sql')}')")
        else
          sql.where("#{fieldName} #{beginCond} ?", utils.formatFieldValue(field, field.beginValue, 'sql'))

      if utils.verifyPropertyExists(field, 'endCond') and field.endCond?
        # Escape the cond to prevent malicious input, but replace the ' with nothing
        endCond = mysql.escape(field.endCond).replace /'/g, ""
        if _.contains ['date', 'datetime'], field.DATA_TYPE
          sql.where("#{fieldName} #{endCond} TIMESTAMP('#{utils.formatFieldValue(field, field.endValue, 'sql')}')")
        else
          sql.where("#{fieldName} #{endCond} ?", utils.formatFieldValue(field, field.endValue, 'sql'))


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

        #
        else
          fieldAlias = 'x'
          if field.groupBy is 'second'
            addGroupByDate sql, field, fieldAlias, "%Y-%m-%d %H:%M:%S"
          else if field.groupBy is 'minute'
            addGroupByDate sql, field, fieldAlias, "%Y-%m-%d %H:%M"
          else if field.groupBy is 'hour'
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
  d3Lookup =
    key: undefined
    x: undefined
    xType: undefined
    y: undefined
    yType: undefined

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
  theProject = {
    '$project': {
      '_id': 0
    }
  }

  # The following works and is very useful and effective however it won't solve the issue of missing data with streams
  # By that I mean a stream should have a guaranteed set of x's for many d3 graphs.  Without that the graph has
  # Issues.  While these additional group and projections work well, they don't fit in well with that above paradigm
#  # Group by the x_multiplex field from the previous projection, push the values onto that stream
#  theMultiplexGroup = {
#    '$group': {
#      '_id': {'x_multiplex': '$x_multiplex'},
#      'values': {
#        '$push': {'x': '$x', 'y': '$y'}
#      }
#    }
#  }
#  # A very simple pipieline action that renames the _id.key to just key, really all this does
#  theMultiplexProject = {
#    '$project': {
#      '_id': 0,
#      'key': {'$concat': ['$_id.x_multiplex']}, # To be appended contextuall below
#      'values': 1
#    }
#  }

  # These vars represent typical projections, can't set them by default otherwise should.js isn't happy with
  # undefined comparisons
  # 'x': undefined # {'$concat': ['$_id.year', '-', '$_id.month']},
  # 'x_multiplex': undefined #'$_id.x_multiplex',
  # 'y': undefined # $count

  theLimit = {'$limit': undefined}

  if utils.verifyPropertyExists dbReference, 'limit'
    theLimit['$limit'] = parseInt dbReference.limit
  else
    theLimit['$limit'] = dbReference.limit

  # Convenience method to add the x field and properly set the d3Lookup
  addX = (field, fieldAlias, multiplex=false) ->
    if multiplex
      d3Lookup.xMultiplex = fieldAlias
      d3Lookup.xMultiplexType = field.DATA_TYPE
    else
      d3Lookup.x = fieldAlias
      d3Lookup.xType = field.DATA_TYPE
      d3Lookup.xGroupBy = field.groupBy

  # Convenience method to add the y field and properly set the d3Lookup
  addY = (field, fieldAlias) ->
    d3Lookup.y = fieldAlias
    d3Lookup.yType = field.DATA_TYPE

  # This is set to true if a field is multiplexed, this will be the indicator to add the multiplex group to the pipeline
  multiplex = false

  addObjToMatch = (fieldName, obj, op=null) ->
    # Make sure that the $match.feldName exists and is initialized
    if not utils.verifyPropertyExists theMatch['$match'], fieldName
      theMatch['$match'][fieldName] = {}

    # With mongo if the op is =/$eq then the assignment is direct and not through a hash
    if op? and op is '='
      theMatch['$match'][fieldName] = obj

    # This implies an AND query, potentially need to rethink that in the future but for now it is fine
    # Here we are assigning the object to the $match.fieldName.  A list of objects under $match implies $and unless $or
    # is specificied.
    else
      _.assign theMatch['$match'][fieldName], obj

  # Iterate over the fields and build the aggregation pipeline based on the given field options
  _.each dbReference.fields, (field) ->
    if not field['excluded']?
      fieldName = field.COLUMN_NAME
      ################################################################################################################
      # See if a single value condition is set
      ################################################################################################################
      if utils.verifyPropertyExists(field, 'cond') and field.cond?
        obj = {}
        # If = then mongo just wants a simple {field: value} and not {field: {$op: value}}
        if field.cond is '='
          obj = utils.formatFieldValue(field, field.condValue, 'mongo')
        else
          obj[utils.sqlToMongoOperand(field.cond)] = utils.formatFieldValue(field, field.condValue, 'mongo', {regex: /LIKE/i.test(field.cond)})

        addObjToMatch fieldName, obj, field.cond

      ################################################################################################################
      # See if a range value condition is set
      ################################################################################################################
      if utils.verifyPropertyExists(field, 'beginCond') and field.beginCond?
        hash = {}
        hash[utils.sqlToMongoOperand(field.beginCond)] = utils.formatFieldValue(field, field.beginValue, 'mongo')
        addObjToMatch fieldName, hash

      if utils.verifyPropertyExists(field, 'endCond') and field.endCond?
        hash = {}
        hash[utils.sqlToMongoOperand(field.endCond)] = utils.formatFieldValue(field, field.endValue, 'mongo')
        addObjToMatch fieldName, hash

      if utils.verifyPropertyExists(field, 'groupBy') and field.groupBy?
        # Mongo likes to always hae the field exist in the doc if grouping on
        addObjToMatch fieldName, {'$exists': true}
        #theMatch['$match'][fieldName] = {'$exists': true}

        # For any date specific groups, must ensure the field is not null
        if field.groupBy in ['year', 'month', 'day', 'hour', 'minute', 'second']
          addObjToMatch fieldName, {'$ne': null}
          #theMatch['$match'][fieldName] = {'$ne': null}

        # Multiplexed mongo fields can be easily handled with an additional $group after the $project, love mongo
        if field.groupBy is 'multiplex'
          fieldAlias = 'x_multiplex'
          # Add the x_multiplex to the group
          theGroup['$group']['_id'].x_multiplex = "$#{fieldName}"
          # The project also needs to read and project that same field
          theProject['$project'].x_multiplex = '$_id.x_multiplex'
          # Add the lookup
          addX field, fieldAlias, true
          # Set multiplex to true so we can add the additional group and project at the end of the pipeline
          multiplex = true

        else
          fieldAlias = 'x'
          if field.groupBy is 'year'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            addX field, fieldAlias
            theProject['$project'].x = '$_id.year'

          else if field.groupBy is 'month'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
            addX field, fieldAlias
            #theProject['$project'].x = {'$concat': ['$_id.year', '-', '$_id.month']}
            theProject['$project'].x = {'year': '$_id.year', 'month': '$_id.month'}

            # TODO for each one of these add a project to project the x to this field?
            # theProject['$project'] = {x : year + month ?}
          else if field.groupBy is 'day'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
            theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
            #theProject['$project'].x = {'$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day']}
            theProject['$project'].x = {'year': '$_id.year', 'month': '$_id.month', 'day': '$_id.day'}
            addX field, fieldAlias
          else if field.groupBy is 'hour'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
            theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
            theGroup['$group']['_id'].hour = {'$hour': "$#{fieldName}"}
            theProject['$project'].x = {'$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour']}
            addX field, 'x'
          else if field.groupBy is 'minute'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
            theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
            theGroup['$group']['_id'].hour = {'$hour': "$#{fieldName}"}
            theGroup['$group']['_id'].minute = {'$minute': "$#{fieldName}"}
            theProject['$project'].x = {'$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour', '-', '$_id.minute']}
            addX field, 'x'
          else if field.groupBy is 'second'
            theGroup['$group']['_id'].year = {'$year': "$#{fieldName}"}
            theGroup['$group']['_id'].month = {'$month': "$#{fieldName}"}
            theGroup['$group']['_id'].day = {'$dayOfMonth': "$#{fieldName}"}
            theGroup['$group']['_id'].hour = {'$hour': "$#{fieldName}"}
            theGroup['$group']['_id'].minute = {'$minute': "$#{fieldName}"}
            theGroup['$group']['_id'].second = {'$second': "$#{fieldName}"}
            theProject['$project'].x = {'$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour', '-', '$_id.minute', '-', '$_id.second']}
            addX field, 'x'
          else if field.groupBy is 'field'
            theGroup['$group']['_id'] = {'x': "$#{fieldName}"}
            addX field, fieldAlias
            theProject['$project'].x = '$_id.x'

      if utils.verifyPropertyExists field, 'aggregation'
        if field.aggregation is 'count'
          # Add the y field to the d3Lookup
          addY field, 'y'
          # The count is simply the count of all docs in the group so $sum 1 for each grouped doc
          theGroup['$group']['count'] = {'$sum': 1}
          # Project the y as the $count set in the $group
          theProject['$project'].y = '$count'
          # Set the key to a human readable format for d3
          d3Lookup.key = "#{fieldName} count"
          # Add the key to the final projection
          # Must also set the key in the final multiplexed operation
          # So if counting over the _id we'd have "<multiplex> _id count
          #theMultiplexProject['$project']['key']['$concat'] = theMultiplexProject['$project']['key']['$concat'].concat [' ', fieldName, ' ', 'count']
        else if field.aggregation is 'sum'
          # Add the y field to the d3Lookup
          addY field, 'y'
          # The count is simply the count of all docs in the group so $sum 1 for each grouped doc
          theGroup['$group']['sum'] = {'$sum': "$#{field.COLUMN_NAME}"}
          # Project the y as the $count set in the $group
          theProject['$project'].y = '$sum'
          # Set the key to a human readable format for d3
          d3Lookup.key = "#{fieldName} sum"


  pipeline.push theMatch
  pipeline.push theGroup
  pipeline.push theProject

#  pipeline.push theMultiplexGroup unless multiplex is false
#  pipeline.push theMultiplexProject unless multiplex is false
  pipeline.push theLimit unless theLimit['$limit'] is undefined

  #logger.debug prettyjson.render JSON.stringify(pipeline)
  output.query = pipeline
  output.d3Lookup = d3Lookup
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
