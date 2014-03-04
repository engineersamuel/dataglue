# https://github.com/nodeca/js-yaml
yaml        = require('js-yaml')
fs          = require('fs')
utils       = require('./utils')
logger      = require('tracer').colorConsole(utils.logger_config)
prettyjson  = require 'prettyjson'
_           = require 'lodash'

# Load the config file either locally or in openshift if the OPENSHIFT_DATA_DIR variable exists
config_file = "#{process.env['HOME']}/.dataglue-settings.yml"
if process.env['OPENSHIFT_DATA_DIR']?
  config_file = "#{process.env['OPENSHIFT_DATA_DIR']}/.dataglue-settings.yml"
else
  config_file = "#{process.env['HOME']}/.dataglue-settings.yml"

try
  doc = yaml.safeLoad(fs.readFileSync(config_file, 'utf-8'))
  logger.debug "Succssfully read #{config_file}"
#  logger.debug prettyjson.render doc
#  exports.config = doc

  # Figure the environment we are running in.  Easiest to base this on the settings yaml
  exports.env = doc.env
  exports.environment = doc.env

  logger.info "Running in #{doc.env}"

  # Build a hash of db_refs keyed by the name
  db_refs_hash = {}
  _.each doc.db_refs, (item) -> db_refs_hash[item.name] = item
  exports.db_refs = db_refs_hash

  # Build a hash of mysql specific dbs
  mysql_refs_hash = {}
  _(doc.db_refs)
    .filter((item) -> item.type is 'mysql')
    .each((item) -> mysql_refs_hash[item.name] = item)
  exports.mysql_refs = mysql_refs_hash

  # Export the master reference based on the environment
  exports.master_ref = doc['master_database'][doc.env]

catch e
  logger.error prettyjson.render(e)
  throw e

## Set the environment depending first by the data glue settings, otherwise assing prod if on Openshift
#def self.environment
#if self.config['env'].nil?
#  return ENV['OPENSHIFT_DATA_DIR'].nil? ? 'dev' : 'prod'
#end
#return self.config['env']
#end
#
