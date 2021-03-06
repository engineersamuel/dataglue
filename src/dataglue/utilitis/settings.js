// Generated by CoffeeScript 1.6.3
(function() {
  var config_file, db_refs_hash, doc, e, fs, logger, mysql_refs_hash, prettyjson, utils, yaml, _;

  yaml = require('js-yaml');

  fs = require('fs');

  utils = require('./utils');

  logger = require('tracer').colorConsole(utils.logger_config);

  prettyjson = require('prettyjson');

  _ = require('lodash');

  config_file = "" + process.env['HOME'] + "/.dataglue-settings.yml";

  if (process.env['OPENSHIFT_DATA_DIR'] != null) {
    config_file = "" + process.env['OPENSHIFT_DATA_DIR'] + "/.dataglue-settings.yml";
  } else {
    config_file = "" + process.env['HOME'] + "/.dataglue-settings.yml";
  }

  try {
    doc = yaml.safeLoad(fs.readFileSync(config_file, 'utf-8'));
    logger.debug("Succssfully read " + config_file);
    exports.env = doc.env;
    exports.environment = doc.env;
    logger.info("Running in " + doc.env);
    db_refs_hash = {};
    _.each(doc.db_refs, function(item) {
      return db_refs_hash[item.name] = item;
    });
    exports.db_refs = db_refs_hash;
    mysql_refs_hash = {};
    _(doc.db_refs).filter(function(item) {
      return item.type === 'mysql';
    }).each(function(item) {
      return mysql_refs_hash[item.name] = item;
    });
    exports.mysql_refs = mysql_refs_hash;
    exports.master_ref = doc['master_database'][doc.env];
  } catch (_error) {
    e = _error;
    logger.error(prettyjson.render(e));
    throw e;
  }

}).call(this);

/*
//@ sourceMappingURL=settings.map
*/
