// Generated by CoffeeScript 1.6.2
(function() {
  var QueryBuilder, logger, moment, mysql, prettyjson, settings, squel, utils, _;

  settings = require('../utilitis/settings');

  utils = require('../utilitis/utils');

  squel = require('squel');

  _ = require('lodash');

  logger = require('tracer').colorConsole(utils.logger_config);

  prettyjson = require('prettyjson');

  moment = require('moment');

  mysql = require('mysql');

  QueryBuilder = {};

  QueryBuilder.buildSqlQuery = function(dbReference, callback) {
    var d3Lookup, output, sql;

    d3Lookup = {
      key: void 0,
      x: void 0,
      xType: void 0,
      y: void 0,
      yType: void 0
    };
    output = {
      query: void 0,
      d3Lookup: void 0
    };
    sql = squel.select();
    sql.from("" + dbReference.schema + "." + dbReference.table);
    if (utils.verifyPropertyExists(dbReference, 'limit')) {
      sql.limit(dbReference.limit);
    }
    _.each(dbReference.fields, function(field) {
      var addGroupByDate, addX, beginCond, cond, endCond, fieldAlias, fieldName;

      if (field['excluded'] == null) {
        fieldName = field.COLUMN_NAME;
        fieldAlias = void 0;
        if (utils.verifyPropertyExists(field, 'aggregation')) {
          fieldAlias = 'y';
          if (field.aggregation === 'count') {
            sql.field("COUNT(" + fieldName + ")", fieldAlias);
            d3Lookup.key = "" + fieldName + " count";
          } else if (field.aggregation === 'distinctCount') {
            sql.field("COUNT(DISTINCT " + fieldName + ")", fieldAlias);
            d3Lookup.key = "" + fieldName + " distinct count";
          } else if (field.aggregation === 'sum') {
            sql.field("SUM(" + fieldName + ")", fieldAlias);
            d3Lookup.key = "" + fieldName + " sum";
          } else if (field.aggregation === 'avg') {
            sql.field("AVG(" + fieldName + ")", fieldAlias);
            d3Lookup.key = "" + fieldName + " avg";
          }
          d3Lookup.y = fieldName;
          d3Lookup.yType = field.DATA_TYPE;
        } else {
          sql.field(fieldName);
        }
        if (utils.verifyPropertyExists(field, 'cond') && (field.cond != null)) {
          cond = mysql.escape(field.cond).replace(/'/g, "");
          sql.where("" + fieldName + " " + cond + " ?", utils.formatFieldValue(field, field.condValue, 'sql'));
        }
        if (utils.verifyPropertyExists(field, 'beginCond') && (field.beginCond != null)) {
          beginCond = mysql.escape(field.beginCond).replace(/'/g, "");
          if (_.contains(['date', 'datetime'], field.DATA_TYPE)) {
            sql.where("" + fieldName + " " + beginCond + " TIMESTAMP(" + (utils.formatFieldValue(field, field.beginValue, 'sql')) + ")");
          } else {
            sql.where("" + fieldName + " " + beginCond + " ?", utils.formatFieldValue(field, field.beginValue, 'sql'));
          }
        }
        if (utils.verifyPropertyExists(field, 'endCond') && (field.endCond != null)) {
          endCond = mysql.escape(field.endCond).replace(/'/g, "");
          if (_.contains(['date', 'datetime'], field.DATA_TYPE)) {
            sql.where("" + fieldName + " " + endCond + " TIMESTAMP(" + (utils.formatFieldValue(field, field.endValue, 'sql')) + ")");
          } else {
            sql.where("" + fieldName + " " + endCond + " ?", utils.formatFieldValue(field, field.endValue, 'sql'));
          }
        }
        addX = function(field, fieldAlias, multiplex) {
          if (multiplex == null) {
            multiplex = false;
          }
          if (multiplex) {
            d3Lookup.xMultiplex = fieldAlias;
            return d3Lookup.xMultiplexType = field.DATA_TYPE;
          } else {
            d3Lookup.x = fieldAlias;
            d3Lookup.xType = field.DATA_TYPE;
            return d3Lookup.xGroupBy = field.groupBy;
          }
        };
        addGroupByDate = function(sql, field, fieldAlias, dateFormat) {
          addX(field, fieldAlias);
          sql.field("DATE_FORMAT(" + field.COLUMN_NAME + ", '" + dateFormat + "')", fieldAlias);
          return sql.group(fieldAlias);
        };
        if (utils.verifyPropertyExists(field, 'groupBy')) {
          if (field.groupBy === 'multiplex') {
            fieldAlias = 'x_multiplex';
            sql.field(field.COLUMN_NAME, fieldAlias);
            sql.group(fieldAlias);
            return addX(field, fieldAlias, true);
          } else {
            fieldAlias = 'x';
            if (field.groupBy === 'second') {
              return addGroupByDate(sql, field, fieldAlias, "%Y-%m-%d %H:%M:%S");
            } else if (field.groupBy === 'minute') {
              return addGroupByDate(sql, field, fieldAlias, "%Y-%m-%d %H:%M");
            } else if (field.groupBy === 'hour') {
              return addGroupByDate(sql, field, fieldAlias, "%Y-%m-%d %H");
            } else if (field.groupBy === "day") {
              return addGroupByDate(sql, field, fieldAlias, "%Y-%m-%d");
            } else if (field.groupBy === "month") {
              return addGroupByDate(sql, field, fieldAlias, "%Y-%m");
            } else if (field.groupBy === "year") {
              return addGroupByDate(sql, field, fieldAlias, "%Y");
            } else if (field.groupBy === 'field') {
              sql.field(field.COLUMN_NAME, fieldAlias);
              sql.group(fieldAlias);
              return addX(field, fieldAlias);
            }
          }
        }
      }
    });
    output.query = sql.toString();
    output.d3Lookup = d3Lookup;
    return callback(null, output);
  };

  QueryBuilder.buildMongoQuery = function(dbReference, callback) {
    var addObjToMatch, addX, addY, d3Lookup, multiplex, output, pipeline, theGroup, theLimit, theMatch, theProject;

    d3Lookup = {
      key: void 0,
      x: void 0,
      xType: void 0,
      y: void 0,
      yType: void 0
    };
    output = {
      query: void 0,
      d3Lookup: {}
    };
    pipeline = [];
    theMatch = {
      '$match': {}
    };
    theGroup = {
      '$group': {
        _id: {}
      }
    };
    theProject = {
      '$project': {
        '_id': 0
      }
    };
    theLimit = {
      '$limit': void 0
    };
    if (utils.verifyPropertyExists(dbReference, 'limit')) {
      theLimit['$limit'] = parseInt(dbReference.limit);
    } else {
      theLimit['$limit'] = dbReference.limit;
    }
    addX = function(field, fieldAlias, multiplex) {
      if (multiplex == null) {
        multiplex = false;
      }
      if (multiplex) {
        d3Lookup.xMultiplex = fieldAlias;
        return d3Lookup.xMultiplexType = field.DATA_TYPE;
      } else {
        d3Lookup.x = fieldAlias;
        d3Lookup.xType = field.DATA_TYPE;
        return d3Lookup.xGroupBy = field.groupBy;
      }
    };
    addY = function(field, fieldAlias) {
      d3Lookup.y = fieldAlias;
      return d3Lookup.yType = field.DATA_TYPE;
    };
    multiplex = false;
    addObjToMatch = function(fieldName, obj, op) {
      if (op == null) {
        op = null;
      }
      if (!utils.verifyPropertyExists(theMatch['$match'], fieldName)) {
        theMatch['$match'][fieldName] = {};
      }
      if ((op != null) && op === '=') {
        return theMatch['$match'][fieldName] = obj;
      } else {
        return _.assign(theMatch['$match'][fieldName], obj);
      }
    };
    _.each(dbReference.fields, function(field) {
      var fieldAlias, fieldName, hash, obj, _ref;

      if (field['excluded'] == null) {
        fieldName = field.COLUMN_NAME;
        if (utils.verifyPropertyExists(field, 'cond') && (field.cond != null)) {
          obj = {};
          if (field.cond === '=') {
            obj = utils.formatFieldValue(field, field.condValue, 'mongo');
          } else {
            obj[utils.sqlToMongoOperand(field.cond)] = utils.formatFieldValue(field, field.condValue, 'mongo', {
              regex: /LIKE/i.test(field.cond)
            });
          }
          addObjToMatch(fieldName, obj, field.cond);
        }
        if (utils.verifyPropertyExists(field, 'beginCond') && (field.beginCond != null)) {
          hash = {};
          hash[utils.sqlToMongoOperand(field.beginCond)] = utils.formatFieldValue(field, field.beginValue, 'mongo');
          addObjToMatch(fieldName, hash);
        }
        if (utils.verifyPropertyExists(field, 'endCond') && (field.endCond != null)) {
          hash = {};
          hash[utils.sqlToMongoOperand(field.endCond)] = utils.formatFieldValue(field, field.endValue, 'mongo');
          addObjToMatch(fieldName, hash);
        }
        if (utils.verifyPropertyExists(field, 'groupBy') && (field.groupBy != null)) {
          addObjToMatch(fieldName, {
            '$exists': true
          });
          if ((_ref = field.groupBy) === 'year' || _ref === 'month' || _ref === 'day' || _ref === 'hour' || _ref === 'minute' || _ref === 'second') {
            addObjToMatch(fieldName, {
              '$ne': null
            });
          }
          if (field.groupBy === 'multiplex') {
            fieldAlias = 'x_multiplex';
            theGroup['$group']['_id'].x_multiplex = "$" + fieldName;
            theProject['$project'].x_multiplex = '$_id.x_multiplex';
            addX(field, fieldAlias, true);
            multiplex = true;
          } else {
            fieldAlias = 'x';
            if (field.groupBy === 'year') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              addX(field, fieldAlias);
              theProject['$project'].x = '$_id.year';
            } else if (field.groupBy === 'month') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              theGroup['$group']['_id'].month = {
                '$month': "$" + fieldName
              };
              addX(field, fieldAlias);
              theProject['$project'].x = {
                '$concat': ['$_id.year', '-', '$_id.month']
              };
            } else if (field.groupBy === 'day') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              theGroup['$group']['_id'].month = {
                '$month': "$" + fieldName
              };
              theGroup['$group']['_id'].day = {
                '$dayOfMonth': "$" + fieldName
              };
              theProject['$project'].x = {
                '$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day']
              };
              addX(field, fieldAlias);
            } else if (field.groupBy === 'hour') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              theGroup['$group']['_id'].month = {
                '$month': "$" + fieldName
              };
              theGroup['$group']['_id'].day = {
                '$dayOfMonth': "$" + fieldName
              };
              theGroup['$group']['_id'].hour = {
                '$hour': "$" + fieldName
              };
              theProject['$project'].x = {
                '$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour']
              };
              addX(field, 'x');
            } else if (field.groupBy === 'minute') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              theGroup['$group']['_id'].month = {
                '$month': "$" + fieldName
              };
              theGroup['$group']['_id'].day = {
                '$dayOfMonth': "$" + fieldName
              };
              theGroup['$group']['_id'].hour = {
                '$hour': "$" + fieldName
              };
              theGroup['$group']['_id'].minute = {
                '$minute': "$" + fieldName
              };
              theProject['$project'].x = {
                '$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour', '-', '$_id.minute']
              };
              addX(field, 'x');
            } else if (field.groupBy === 'second') {
              theGroup['$group']['_id'].year = {
                '$year': "$" + fieldName
              };
              theGroup['$group']['_id'].month = {
                '$month': "$" + fieldName
              };
              theGroup['$group']['_id'].day = {
                '$dayOfMonth': "$" + fieldName
              };
              theGroup['$group']['_id'].hour = {
                '$hour': "$" + fieldName
              };
              theGroup['$group']['_id'].minute = {
                '$minute': "$" + fieldName
              };
              theGroup['$group']['_id'].second = {
                '$second': "$" + fieldName
              };
              theProject['$project'].x = {
                '$concat': ['$_id.year', '-', '$_id.month', '-', '$_id.day', ' ', '$_id.hour', '-', '$_id.minute', '-', '$_id.second']
              };
              addX(field, 'x');
            } else if (field.groupBy === 'field') {
              theGroup['$group']['_id'] = {
                'x': "$" + fieldName
              };
              addX(field, fieldAlias);
              theProject['$project'].x = '$_id.x';
            }
          }
        }
        if (utils.verifyPropertyExists(field, 'aggregation')) {
          if (field.aggregation === 'count') {
            addY(field, 'y');
            theGroup['$group']['count'] = {
              '$sum': 1
            };
            theProject['$project'].y = '$count';
            return d3Lookup.key = "" + fieldName + " count";
          }
        }
      }
    });
    pipeline.push(theMatch);
    pipeline.push(theGroup);
    pipeline.push(theProject);
    if (theLimit['$limit'] !== void 0) {
      pipeline.push(theLimit);
    }
    output.query = pipeline;
    output.d3Lookup = d3Lookup;
    return callback(null, output);
  };

  QueryBuilder.buildQuery = function(dbReference, callback) {
    var self, type;

    self = this;
    type = dbReference['type'];
    if (type === 'mysql' || type === 'postgre' || type === 'postgresql') {
      QueryBuilder.buildSqlQuery(dbReference, function(err, output) {
        return callback(err, output);
      });
    } else if (type === 'mongo') {
      QueryBuilder.buildMongoQuery(dbReference, function(err, output) {
        return callback(err, output);
      });
    }
    return self;
  };

  module.exports = QueryBuilder;

}).call(this);

/*
//@ sourceMappingURL=queryBuilder.map
*/
