// Generated by CoffeeScript 1.6.3
(function() {
  var logger, moment, mysql, prettyjson, _;

  _ = require('lodash');

  moment = require('moment');

  logger = require('tracer').colorConsole(exports.logger_config);

  prettyjson = require('prettyjson');

  mysql = require('mysql');

  exports.logger_config = {
    level: process.env.OPENSHIFT_DATA_DIR === void 0 ? 'debug' : 'info',
    format: "[{{timestamp}}] <{{title}}> <{{file}}:{{line}}> {{message}}",
    dateformat: "yyyy-mm-dd hh:MM:ss"
  };

  exports.resolveEnvVar = function(envVar) {
    if (envVar === void 0) {
      return void 0;
    }
    if (/^\$/i.test(envVar)) {
      return process.env[envVar.slice(1, envVar.length)];
    }
    return envVar;
  };

  exports.verifyPropertyExists = function(obj, field) {
    if ((_.has(obj, field)) && (obj[field] !== void 0) && (obj[field] !== '')) {
      return true;
    } else {
      return false;
    }
  };

  exports.dateDateTypes = ['date', 'datetime'];

  exports.numericalDataTypes = ['numerical', 'number', 'int', 'tinyint', 'float', 'decimal', 'double'];

  exports.integerDataTypes = ['int', 'smallint', 'bigint', 'tinyint', 'integer'];

  exports.stringDataTypes = ['varchar', 'string', 'text'];

  exports.booleanDataTypes = ['bool', 'boolean'];

  exports.formatFieldValue = function(field, value, type, opts) {
    var output, regex;
    regex = exports.truthy(opts != null ? opts.regex : void 0);
    if (value == null) {
      throw Error("Could not format undefined value for field " + field.COLUMN_NAME + "!");
    }
    if (/^null$/i.test(value)) {
      return 'NULL';
    }
    output = field.COLUMN_NAME;
    if (regex) {
      output = new RegExp("" + value, 'i');
    } else if (_.contains(exports.dateDateTypes, field.DATA_TYPE)) {
      if (type === 'sql') {
        output = moment.utc(value, 'YYYY-MM-DD HH:mm:ss').toISOString();
      } else if (type === 'mongo') {
        output = moment.utc(value, 'YYYY-MM-DD HH:mm:ss').toDate();
      }
    } else if (_.contains(exports.numericalDataTypes, field.DATA_TYPE)) {
      if (value === true) {
        output = 1;
      } else if (value === false) {
        output = 0;
      } else if (_.isString(value)) {
        if (_.contains(exports.integerDataTypes, field.DATA_TYPE)) {
          output = parseInt(value);
        } else {
          output = parseFloat(value);
        }
      } else if (_.isNumber(value)) {
        if (_.contains(exports.integerDataTypes, field.DATA_TYPE)) {
          output = parseInt(value);
        } else {
          output = parseFloat(value);
        }
      }
      if (_.isNaN(output)) {
        throw Error("You said " + value + " was a numeric type but it couldn't be parsed as a string and it wasn't a number!");
      }
    } else if (_.contains(exports.stringDataTypes, field.DATA_TYPE)) {
      return mysql.escape(value);
    } else if (_.contains(exports.booleanDataTypes, field.DATA_TYPE)) {
      if (type === 'sql') {
        if (exports.truthy(value)) {
          return 'TRUE';
        } else {
          return 'FALSE';
        }
      } else if (type === 'mongo') {
        return exports.truthy(value);
      }
    }
    return output;
  };

  exports.truthy = function(obj) {
    if (obj === void 0) {
      return false;
    } else if (_.isBoolean(obj)) {
      return obj;
    } else if (_.isString(obj)) {
      if (_.contains(['YES', 'yes', 'Y', 'y', '1', 'true', 'TRUE', 'ok', 'OK'], obj)) {
        return true;
      } else {
        return false;
      }
    } else if (_.isNumber(obj)) {
      return parseInt(obj) === 1;
    } else {
      return false;
    }
  };

  exports.generateMongoUrl = function(obj) {
    var mongourl, o;
    o = _.cloneDeep(obj);
    o.host = exports.resolveEnvVar(obj.host) || obj.host || '127.0.0.1';
    o.port = exports.resolveEnvVar(obj.port) || obj.port || 27017;
    o.db = exports.resolveEnvVar(obj.db) || obj.db || 'test';
    o.user = exports.resolveEnvVar(obj.user) || obj.user || void 0;
    o.pass = exports.resolveEnvVar(obj.pass) || obj.pass || void 0;
    mongourl = void 0;
    if (((o.user != null) && o.user !== '') && ((o.pass != null) && o.pass !== '')) {
      mongourl = "mongodb://" + o.user + ":" + o.pass + "@" + o.host + ":" + o.port + "/" + o.db;
    } else {
      mongourl = "mongodb://" + o.host + ":" + o.port + "/" + o.db;
    }
    return mongourl;
  };

  exports.isInteger = function(f) {
    return f !== void 0 && typeof f === 'number' && Math.round(f) === f;
  };

  exports.isFloat = function(f) {
    return f !== void 0 && typeof f === 'number' && !exports.isInteger(f);
  };

  exports.setMongoFieldDataType = function(obj) {
    if (_.isDate(obj)) {
      return 'datetime';
    } else if (_.isBoolean(obj)) {
      return 'boolean';
    } else if (_.isArray(obj)) {
      return 'array';
    } else if (_.isObject(obj)) {
      return 'object';
    } else if (_.isString(obj)) {
      return 'varchar';
    } else if (exports.isInteger(obj)) {
      return 'int';
    } else if (exports.isFloat(obj)) {
      return 'float';
    }
  };

  exports.stringify = function(obj) {
    if (_.isString(obj)) {
      return obj;
    } else if (_.isObject(obj)) {
      return JSON.stringify(obj);
    }
    return obj;
  };

  exports.sqlDbTypes = ['mysql', 'postgresql', 'postgre', 'mariadb'];

  exports.noSqlTypes = ['mongo'];

  exports.isUnixOffset = function(theInput) {
    return /[0-9]{13}/.test(theInput);
  };

  exports.isUnixTimestamp = function(theInput) {
    return /[0-9]{10}/.test(theInput) && String(theInput).length === 10;
  };

  exports.parseDateToOffset = function(theDate, opts) {
    var format, pFormat, utc;
    if (opts == null) {
      opts = {};
    }
    format = opts != null ? opts.format : void 0;
    utc = (opts != null ? opts.utc : void 0) || true;
    pFormat = (function() {
      switch (format) {
        case 'year':
          return 'YYYY';
        case 'month':
          return 'YYYY-MM';
        case 'day':
          return 'YYYY-MM-DD';
        case 'hour':
          return 'YYYY-MM-DD HH';
        case 'minute':
          return 'YYYY-MM-DD HH:mm';
        case 'second':
          return 'YYYY-MM-DD HH:mm:ss';
        default:
          return void 0;
      }
    })();
    if (theDate.year != null) {
      return +moment.utc(theDate);
      void 0;
    } else if (exports.isUnixOffset(theDate)) {
      if (utc) {
        return +moment.utc(theDate);
      } else {
        return +moment(theDate);
      }
    } else if (exports.isUnixTimestamp(theDate)) {
      return +moment.unix(theDate);
    }
    if (_.isDate(theDate)) {
      return +moment.utc(theDate);
    } else if (format === 'year' && _.isNumber(theDate)) {
      if (utc) {
        return +moment.utc(String(theDate), pFormat);
      } else {
        return +moment(String(theDate), pFormat);
      }
    } else {
      if (utc) {
        return +moment.utc(theDate, pFormat);
      } else {
        return +moment(theDate, pFormat);
      }
    }
  };

  exports.parseX = function(item, opts) {
    var xGroupBy, xType;
    if (opts == null) {
      opts = {};
    }
    xType = opts != null ? opts.xType : void 0;
    xGroupBy = opts != null ? opts.xGroupBy : void 0;
    if (_.contains(['date', 'datetime'], xType)) {
      return exports.parseDateToOffset(item, {
        format: xGroupBy
      });
    }
    return item;
  };

  exports.sqlToMongoOperand = function(op) {
    switch (op != null ? op.toLowerCase() : void 0) {
      case '<':
        return '$lt';
      case '<=':
        return '$lte';
      case '>':
        return '$gt';
      case '>=':
        return '$gte';
      case '=':
        return '$eq';
      case '!=':
        return '$ne';
      case 'like':
        return '$regex';
      default:
        throw Error("op: " + op + " could not be translated");
    }
  };

  exports.groupDbReferencesByJoins = function(dbReferences) {
    var groupedDbReferences;
    groupedDbReferences = [];
    return _.each(dbReferences, function(dbReference) {
      return _.each(dbReference.fields, function(field) {
        if (_.has(field, 'joinType')) {
          return console.log("");
        }
      });
    });
  };

}).call(this);

/*
//@ sourceMappingURL=utils.map
*/
