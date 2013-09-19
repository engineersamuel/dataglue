exports.logger_config =
  level: if process.env.OPENSHIFT_DATA_DIR is undefined then 'debug' else 'info'
  format : "[{{timestamp}}] <{{title}}> <{{file}}:{{line}}> {{message}}"
  dateformat : "yyyy-mm-dd hh:MM:ss"

# Given a string attempts to resolve it as an environment variable otherwise returns the input
exports.resolveEnvVar = (envVar) ->
  console.log JSON.stringify(envVar)
  if envVar is undefined then return undefined
  # See if th starting starts with a $, ie an environment variable
  if /^\$/i.test(envVar)
    console.log "Returning sliced envar: #{envVar.slice 1, envVar.length}"
    console.log "Returning env var : #{process.env[envVar.slice 1, envVar.length]}"
    return process.env[envVar.slice 1, envVar.length]

  console.log "No conditions matched hitting default return of #{envVar}"
  return envVar
