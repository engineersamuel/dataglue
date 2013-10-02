_           = require 'lodash'
moment      = require 'moment'
logger      = require('tracer').colorConsole(exports.logger_config)
prettyjson  = require 'prettyjson'

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
  o.host = (exports.resolveEnvVar(obj.host) || obj.host || '127.0.0.1')
  o.port = (exports.resolveEnvVar(obj.port) || obj.port || 27017)
  o.db = (exports.resolveEnvVar(obj.db) || obj.db || 'test')
  o.user = exports.resolveEnvVar(obj.user) || obj.user || undefined
  o.pass = exports.resolveEnvVar(obj.user) || obj.pass || undefined

  mongourl = undefined
  if (o.user and o.user isnt '') and (o.pass and o.pass isnt '')
    mongourl = "mongodb://#{o.user}:#{o.pass}@#{o.host}:#{o.port}/#{o.db}" #"?auto_reconnect=true"
  else
    mongourl = "mongodb://#{o.host}:#{o.port}/#{o.db}" #"?auto_reconnect=true"

  #logger.debug "Finished generating mongo url: #{mongourl}"
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
