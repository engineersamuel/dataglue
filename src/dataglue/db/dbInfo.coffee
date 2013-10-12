settings      = require '../utilitis/settings'
utils         = require '../utilitis/utils'
DbQuery       = require './dbQuery'
_             = require 'lodash'
logger        = require('tracer').colorConsole(utils.logger_config)
prettyjson    = require 'prettyjson'

DbInfo = {}

DbInfo.getFields = (dbRefName, schemaName, tableName, fieldRestrictionQuery, callback) ->
  dbReference = settings.db_refs[dbRefName]
  type = dbReference['type']

  if type in ['mysql']
    sql = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{schemaName}' AND TABLE_NAME = '#{tableName}'"
    DbQuery.query dbReference, {query: sql, cache: false}, (err, fields) ->
      callback err, fields
  else if type in ['mongo']
    # Since mongo has no listFields or anything of the nature, we are making the assumption that the schema is consistent
    # i.e. pulling one since doc represents all docs.  This is the only/quickest way to simulate an info schema
    DbQuery.showFields dbReference, schemaName, tableName, fieldRestrictionQuery, (err, results) ->
      callback err, results

  return @

#  return DatabaseManagerModule::query(params[:ref], sql).to_a.to_json || []
DbInfo.getTables = (dbRefName, schemaName, callback) ->
  dbReference = settings.db_refs[dbRefName]
  type = dbReference['type']

  if type in ['mysql']
    sql = "SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '#{schemaName}'"
    DbQuery.query dbReference, {query: sql, cache: false}, (err, results) ->
      callback err, _.map results
  else if type in ['mongo']
    DbQuery.showCollections dbReference, schemaName, (err, results) ->
      # This gets a list of all tables and filters then through the excluded table names if there are any.  This is
      # defined in the ~.dataglue-settings.yml as the field excluded_tables under a dbref
      # To think this through, filter all tables where the name is not in the exclude_tables
      callback err, _.filter results, (item) -> return not _.find(dbReference.excluded_tables, (excludedTable) -> excludedTable is item.TABLE_NAME)
  return @

DbInfo.getSchemas = (dbRefName, callback) ->
  logger.debug "Call to getSchemas"
  dbReference = settings.db_refs[dbRefName]
  type = dbReference['type']
  logger.debug "Getting schemas for type: #{type}"

  if type in ['mysql']
    sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA'
    DbQuery.query dbReference, {query: sql, cache: false}, (err, results) ->
      logger.debug prettyjson.render results
      # Since the native info schema returns the column schema, map that to name before filtering excluded schemas
      callback err, _.filter(_.map(results, (schema) -> {name: schema.schema}), (item) -> return not _.find(dbReference.excluded_schemas, (excludedSchema) -> excludedSchema is item.schema))

  else if type in ['mongo']
    DbQuery.query dbReference, {command: {listDatabases: 1}}, (err, results) ->
      # This gets a list of all databases and filters then through the excluded db names if there are any.  This is
      # defined in the ~.dataglue-settings.yml as the field 'excluded_schemas under a dbref
      # To think this through, filter all databases where the name is not in the exclude_schemas
      callback err, _.filter results?['databases'], (item) -> return not _.find(dbReference.excluded_schemas, (excludedSchema) -> excludedSchema is item.name)

  return @

module.exports = DbInfo
