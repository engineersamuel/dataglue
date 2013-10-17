_           = require 'lodash'
moment      = require 'moment'
logger      = require('tracer').colorConsole(exports.logger_config)
prettyjson  = require 'prettyjson'
mysql       = require('mysql')

exports.logger_config =
  level: if process.env.OPENSHIFT_DATA_DIR is undefined then 'debug' else 'info'
  format : "[{{timestamp}}] <{{title}}> <{{file}}:{{line}}> {{message}}"
  dateformat : "yyyy-mm-dd hh:MM:ss"

# Given a string attempts to resolve it as an environment variable otherwise returns the input
exports.resolveEnvVar = (envVar) ->
  if envVar is undefined then return undefined
  # See if th starting starts with a $, ie an environment variable
  if /^\$/i.test(envVar)
    return process.env[envVar.slice 1, envVar.length]
  return envVar

# Convenience method to verify a field exists and has a valid value
exports.verifyPropertyExists = (obj, field) ->
  if (_.has obj, field) and (obj[field] isnt undefined) and (obj[field] isnt '') then return true else return false

exports.dateDateTypes = ['date', 'datetime']
exports.numericalDataTypes = ['numerical', 'number', 'int', 'tinyint', 'float', 'decimal', 'double']
exports.integerDataTypes = ['int', 'smallint', 'bigint', 'tinyint', 'integer']
exports.stringDataTypes = ['varchar', 'string', 'text']
exports.booleanDataTypes = ['bool', 'boolean']

# Field is {COLUMN_NAME: xyz, DATA_TYPE, xzy}, type is ['sql', 'mongo']
exports.formatFieldValue = (field, value, type, opts) ->

  # Pass in {regex: true} to indicate the value is a regex
  regex = exports.truthy opts?.regex

  if not value? then throw Error("Could not format undefined value for field #{field.COLUMN_NAME}!")
  if /^null$/i.test value then return 'NULL'

  output = field.COLUMN_NAME
  if regex
    output = new RegExp("#{value}", 'i')
#    logger.debug output
#    logger.debug JSON.stringify(output)
  # Dates
  else if _.contains exports.dateDateTypes, field.DATA_TYPE
    if type is 'sql'
      #output = "TIMESTAMP('#{moment.utc(value, 'YYYY-MM-DD').toISOString()}')"
      output = moment.utc(value, 'YYYY-MM-DD HH:mm:ss').toISOString()
    else if type is 'mongo'
      output = moment.utc(value, 'YYYY-MM-DD HH:mm:ss').toDate()

  # Numbers
  else if _.contains exports.numericalDataTypes, field.DATA_TYPE
    # First see the the input is an actual true or an actual false if so translate to 1 or 0
    if value is true
      output = 1
    else if value is false
      output = 0
    # If a String see if the data type is an int or float and parse accordingly
    else if _.isString value
      # If in an integer data type then just parseInt
      if _.contains exports.integerDataTypes, field.DATA_TYPE
        output = parseInt(value)
      # Otherwise treat this as a precision value
      else
        output = parseFloat(value)
    else if _.isNumber value
      if _.contains exports.integerDataTypes, field.DATA_TYPE
        output = parseInt(value)
        # Otherwise treat this as a precision value
      else
        output = parseFloat(value)

    if _.isNaN output
      throw Error("You said #{value} was a numeric type but it couldn't be parsed as a string and it wasn't a number!")

  # Strings
  else if _.contains exports.stringDataTypes, field.DATA_TYPE
    # Piggy back on the work already done to prevent SQL injection in the node-mysql package
    # https://github.com/felixge/node-mysql/blob/89a993040f115efc1c00aa117d3ff6eb9d419c5c/lib/protocol/SqlString.js
    return mysql.escape value

  # Boolean values as defined in truth
  else if _.contains exports.booleanDataTypes, field.DATA_TYPE
    if type is 'sql'
      return if exports.truthy value then 'TRUE' else 'FALSE'
    else if type is 'mongo'
      return exports.truthy value


  return output

exports.truthy = (obj) ->
  if obj is undefined
    return false
  else if _.isBoolean obj
    return obj
  else if _.isString obj
    return if _.contains ['YES', 'yes', 'Y', 'y', '1', 'true', 'TRUE', 'ok', 'OK'], obj then true else false
  else if _.isNumber obj
    return parseInt(obj) is 1
  else
    return false

exports.generateMongoUrl = (obj) ->
  o = _.cloneDeep obj
  o.host = exports.resolveEnvVar(obj.host) || obj.host || '127.0.0.1'
  o.port = exports.resolveEnvVar(obj.port) || obj.port || 27017
  o.db = exports.resolveEnvVar(obj.db) || obj.db || 'test'
  o.user = exports.resolveEnvVar(obj.user) || obj.user || undefined
  o.pass = exports.resolveEnvVar(obj.pass) || obj.pass || undefined

  mongourl = undefined
  if (o.user? and o.user isnt '') and (o.pass? and o.pass isnt '')
    mongourl = "mongodb://#{o.user}:#{o.pass}@#{o.host}:#{o.port}/#{o.db}" #"?auto_reconnect=true"
  else
    mongourl = "mongodb://#{o.host}:#{o.port}/#{o.db}" #"?auto_reconnect=true"

  #logger.info "Finished generating mongo url: #{mongourl}"
  return mongourl

exports.isInteger = (f) -> f isnt undefined and typeof(f) is 'number' and Math.round(f) == f
exports.isFloat = (f) -> f isnt undefined and typeof(f) is 'number' and !exports.isInteger(f)

exports.setMongoFieldDataType = (obj) ->
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
  else if exports.isInteger obj
    return 'int'
  else if exports.isFloat obj
    return 'float'

exports.stringify = (obj) ->
  if _.isString obj
    return obj
  else if _.isObject obj
    return JSON.stringify obj

  return obj

exports.sqlDbTypes = ['mysql', 'postgresql', 'postgre', 'mariadb']
exports.noSqlTypes = ['mongo']
exports.isUnixOffset = (theInput) -> /[0-9]{13}/.test(theInput)
exports.isUnixTimestamp = (theInput) -> /[0-9]{10}/.test(theInput) and String(theInput).length is 10

# Parses a variety of inputs to a unix offset (ms)
exports.parseDateToOffset = (theDate, opts = {}) ->
  format = opts?.format
  utc = opts?.utc || true

  # Assume if a number and if of length 1230768000000 then a unix offset, length of 10 is unix timestamp
  isUnixOffset = exports.isUnixOffset(theDate)
  isUnixTimestamp = exports.isUnixOffset(theDate)

  pFormat = switch format
    when 'year'  then 'YYYY'
    when 'month' then 'YYYY-MM'
    when 'day'   then 'YYYY-MM-DD'
    when 'hour'  then 'YYYY-MM-DD HH'
    when 'minute'  then 'YYYY-MM-DD HH:mm'
    when 'second'  then 'YYYY-MM-DD HH:mm:ss'
    else  undefined

  if exports.isUnixOffset(theDate)
    return if utc then +moment.utc(theDate) else +moment(theDate)
  else if exports.isUnixTimestamp(theDate)
    return +moment.unix(theDate)
  if _.isDate theDate
    return +moment.utc(theDate)
  else if format is 'year' and _.isNumber(theDate)
    return if utc then +moment.utc(String(theDate), pFormat) else +moment(String(theDate), pFormat)
  # The default here is theDate is a String
  else
    return if utc then +moment.utc(theDate, pFormat) else +moment(theDate, pFormat)

# Convenience method to parse x base on a type
exports.parseX = (item, opts={}) ->
  xType = opts?.xType
  xGroupBy = opts?.xGroupBy

  #logger.debug "parseX: item: #{item}, opts: #{JSON.stringify(opts)}"
  if _.contains ['date', 'datetime'], xType
    #logger.debug "returning: #{exports.parseDateToOffset(item, {format: xGroupBy})}"
    return exports.parseDateToOffset(item, {format: xGroupBy})

  #logger.debug "returning: #{item}"
  return item

exports.sqlToMongoOperand = (op) ->
  switch op?.toLowerCase()
    when '<' then '$lt'
    when '<=' then '$lte'
    when '>' then '$gt'
    when '>=' then '$gte'
    when '=' then '$eq' # $eq is not a valid mongo command, but leaving it here for completeness
    when '!=' then '$ne'
    when 'like' then '$regex'
    else throw Error("op: #{op} could not be translated")
