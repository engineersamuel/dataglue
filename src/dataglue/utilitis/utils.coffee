_ = require 'lodash'

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


exports.generate_mongo_url = (obj) ->
  obj.host = (exports.resolveEnvVar(obj.host) || '127.0.0.1')
  obj.port = (exports.resolveEnvVar(obj.port) || 27017)
  obj.db = (exports.resolveEnvVar(obj.db) || 'test')

  mongourl = undefined
  if (obj.user and obj.user isnt '') and (obj.pass and obj.pass isnt '')
    mongourl = "mongodb://#{exports.resolveEnvVar(obj.user)}:#{exports.resolveEnvVar(obj.pass)}@#{exports.resolveEnvVar(obj.host) || '127.0.0.1'}:#{exports.resolveEnvVar(obj.port) || '27017'}/#{exports.resolveEnvVar(obj.db)}?auto_reconnect=true"
  else
    mongourl = "mongodb://#{exports.resolveEnvVar(obj.host) || '127.0.0.1'}:#{exports.resolveEnvVar(obj.port) || '27017'}/#{exports.resolveEnvVar(obj.db) || 'dataglue'}?auto_reconnect=true"

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
