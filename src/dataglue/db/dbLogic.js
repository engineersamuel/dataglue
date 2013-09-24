// Generated by CoffeeScript 1.6.2
(function() {
  var CachedDataSet, async, dataSetCache, logger, moment, mysql, prettyjson, settings, squel, utils, _;

  settings = require('../utilitis/settings');

  utils = require('../utilitis/utils');

  dataSetCache = require('../db/datasetCache');

  squel = require('squel');

  _ = require('lodash');

  async = require('async');

  mysql = require('mysql');

  moment = require('moment');

  logger = require('tracer').colorConsole(utils.logger_config);

  prettyjson = require('prettyjson');

  CachedDataSet = {};

  CachedDataSet.verifyPropertyExists = function(obj, field) {
    if ((_.has(obj, field)) && (obj[field] !== void 0) && (obj[field] !== '')) {
      return true;
    } else {
      return false;
    }
  };

  CachedDataSet.buildSql = function(dbReference, callback) {
    var d3Lookup, output, self, sql, type;

    self = this;
    type = settings.db_refs[dbReference['connection']]['type'];
    d3Lookup = {
      key: void 0,
      x: void 0,
      xType: void 0,
      y: void 0,
      yType: void 0,
      y2: void 0,
      y2Type: void 0,
      z: void 0,
      zType: void 0,
      r: void 0,
      rType: void 0
    };
    output = {
      sql: void 0,
      d3Lookup: void 0
    };
    if (type === 'mysql') {
      sql = squel.select();
      sql.from("" + dbReference.schema + "." + dbReference.table);
      _.each(dbReference.fields, function(field) {
        var addGroupByDate, addX, fieldAlias, fieldName;

        if (field['excluded'] == null) {
          fieldName = field.COLUMN_NAME;
          fieldAlias = void 0;
          if (self.verifyPropertyExists(field, 'aggregation')) {
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
          if (self.verifyPropertyExists(field, 'beginDate')) {
            sql.where("" + fieldName + " >= TIMESTAMP('" + field.beginDate + "')");
          }
          if (self.verifyPropertyExists(field, 'endDate')) {
            sql.where("" + fieldName + " < TIMESTAMP('" + field.endDate + "')");
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
          if (self.verifyPropertyExists(field, 'groupBy')) {
            if (field.groupBy === 'multiplex') {
              fieldAlias = 'x_multiplex';
              sql.field(field.COLUMN_NAME, fieldAlias);
              sql.group(fieldAlias);
              return addX(field, fieldAlias, true);
            } else {
              fieldAlias = 'x';
              if (field.groupBy === 'hour') {
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
      output.sql = sql.toString();
      output.d3Lookup = d3Lookup;
      callback(null, output);
    }
    return self;
  };

  CachedDataSet.mysqlQuery = function(dbReference, queryHash, callback) {
    var conn, mysql_ref, self;

    self = this;
    mysql_ref = settings.mysql_refs[dbReference.connection || dbReference.name];
    conn = mysql.createConnection({
      host: mysql_ref['host'],
      user: mysql_ref['user'],
      password: mysql_ref['pass']
    });
    logger.debug("Querying mysql reference: " + dbReference.connection + " with sql: " + queryHash);
    conn.query(queryHash.sql, function(err, results) {
      if (err) {
        logger.debug("Error Querying mysql reference: " + dbReference.connection + " with sql: " + queryHash + ", err: " + (prettyjson.render(err)));
        callback(err);
      } else {
        logger.debug("Found " + results.length + " results.");
        if (queryHash.cache != null) {
          dataSetCache.statementCachePut(dbReference, queryHash, results, function(err, outcome) {
            if (err) {
              return logger.error("Failed to cache sql due to: " + (prettyjson.render(err)));
            } else {
              return callback(null, results);
            }
          });
        } else {
          callback(null, results);
        }
      }
      return conn.end();
    });
    return self;
  };

  CachedDataSet.query = function(dbReference, queryHash, callback) {
    var self;

    self = this;
    if (dbReference.type === 'mysql') {
      logger.debug("Querying mysql reference: " + dbReference.name + " with sql: " + queryHash.sql);
      CachedDataSet.mysqlQuery(dbReference, queryHash, function(err, results) {
        if (err) {
          return callback(err);
        } else {
          return callback(null, results);
        }
      });
    }
    return self;
  };

  CachedDataSet.getFields = function(dbRefName, schemaName, tableName, callback) {
    var dbReference, sql;

    dbReference = settings.db_refs[dbRefName];
    sql = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '" + schemaName + "' AND TABLE_NAME = '" + tableName + "'";
    CachedDataSet.query(dbReference, {
      sql: sql,
      cache: false
    }, function(err, fields) {
      return callback(err, fields);
    });
    return this;
  };

  CachedDataSet.getTables = function(dbRefName, schemaName, callback) {
    var dbReference, sql;

    dbReference = settings.db_refs[dbRefName];
    sql = "SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '" + schemaName + "'";
    CachedDataSet.query(dbReference, {
      sql: sql,
      cache: false
    }, function(err, results) {
      return callback(err, _.map(results));
    });
    return this;
  };

  CachedDataSet.getSchemas = function(dbRefName, callback) {
    var dbReference, sql;

    logger.debug("Call to getSchemas");
    dbReference = settings.db_refs[dbRefName];
    sql = 'SELECT SCHEMA_NAME AS `schema` FROM INFORMATION_SCHEMA.SCHEMATA';
    CachedDataSet.query(dbReference, {
      sql: sql,
      cache: false
    }, function(err, results) {
      logger.debug(prettyjson.render("Schemas: results"));
      return callback(err, _.map(results, function(schema) {
        return schema.schema;
      }));
    });
    return this;
  };

  CachedDataSet.queryDynamic = function(dbReference, callback) {
    var key, output, self;

    self = this;
    output = {};
    key = dbReference['key'];
    output = {};
    output[key] = {
      results: void 0,
      queryHash: void 0
    };
    CachedDataSet.buildSql(dbReference, function(err, queryHash) {
      var warning;

      if (err) {
        logger.error("Error building SQL: " + (prettyjson.render(err)));
        return callback(err);
      } else {
        if (queryHash.d3Lookup.x !== void 0 && queryHash.d3Lookup.y !== void 0) {
          return dataSetCache.statementCacheGet(dbReference, queryHash, function(err, results) {
            if (err) {
              return callback(err);
            } else {
              output[key].queryHash = queryHash;
              if (results != null) {
                output[key].results = results;
                return callback(null, output);
              } else {
                return CachedDataSet.mysqlQuery(dbReference, queryHash, function(err, results) {
                  output[key].queryHash = queryHash;
                  output[key].results = results;
                  return callback(err, output);
                });
              }
            }
          });
        } else {
          if (queryHash.d3Lookup.x === void 0) {
            warning = "Could not generate data for " + key + ", no x set. Please make sure to group on some field.";
            output[key].warning = warning;
            logger.warn(warning);
          }
          if (queryHash.d3Lookup.y === void 0) {
            warning = "Could not generate data for " + key + ", no y set. Please make sure to aggregate a field.";
            output[key].warning = warning;
            logger.warn(warning);
          }
          output[key].queryHash = queryHash;
          return callback(err, output);
        }
      }
    });
    return self;
  };

  CachedDataSet.loadDataSet = function(doc, callback) {
    var self;

    self = this;
    doc = _.isString(doc) ? JSON.parse(doc) : doc;
    async.map(_.values(doc.dbReferences), self.queryDynamic, function(err, arrayOfDataSetResults) {
      if (err) {
        logger.error("Error querying dbReferences: " + (prettyjson.render(err)));
        return callback(err);
      } else {
        _.each(arrayOfDataSetResults, function(dataSetResult, idx) {
          var refItem, stream, streams, uniqueMutliplexedXs, uniqueXs;

          dataSetResult = _.values(dataSetResult)[0];
          if (dataSetResult.queryHash.d3Lookup.xMultiplex && dataSetResult.queryHash.d3Lookup.xMultiplex !== '') {
            logger.debug("Working with multiplexed data!");
            streams = [];
            uniqueMutliplexedXs = _.unique(_.map(dataSetResult.results, function(item) {
              return item[dataSetResult.queryHash.d3Lookup.xMultiplex];
            }));
            _.each(uniqueMutliplexedXs, function(uniqueX) {
              var stream;

              stream = {
                key: "" + dataSetResult.queryHash.d3Lookup.key + " (" + uniqueX + ")",
                values: []
              };
              stream.values = _(dataSetResult.results).filter(function(item) {
                return item[dataSetResult.queryHash.d3Lookup.xMultiplex] === uniqueX;
              }).map(function(item) {
                var _ref;

                return {
                  x: item.x,
                  xOrig: item.x,
                  x: (_ref = dataSetResult.queryHash.d3Lookup.xType) === 'date' || _ref === 'datetime' ? +moment(item.x) : item.x,
                  xType: dataSetResult.queryHash.d3Lookup.xType,
                  xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy,
                  xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex,
                  xMultipleType: dataSetResult.queryHash.d3Lookup.xMultiplexType,
                  y: item.y || 0,
                  yType: dataSetResult.queryHash.d3Lookup.yType
                };
              }).value();
              return streams.push(stream);
            });
            uniqueXs = _.without(_.unique(_.map(_.flatten(_.map(streams, function(stream) {
              return stream.values;
            }), true), function(item) {
              return item.x;
            })), void 0);
            uniqueXs.sort();
            refItem = _.first(_.first(streams).values);
            _.each(uniqueXs, function(uniqueX) {
              return _.each(streams, function(stream, streamIdx) {
                var newItem, streamXs;

                if (stream.key === "professional avg (APAC)" && uniqueX === '2010-09') {
                  streamXs = _.map(streams[streamIdx].values, function(v) {
                    return v.x;
                  });
                  streamXs.sort();
                }
                if (_.find(stream.values, function(v) {
                  return v.x === uniqueX;
                }) === void 0) {
                  newItem = {
                    x: uniqueX,
                    y: 0,
                    xType: refItem.xType,
                    xGroupBy: refItem.xGroupBy,
                    xMultiplex: refItem.xMultiplex,
                    xMultipleType: refItem.xMultiplexType,
                    yType: refItem.yType
                  };
                  return streams[streamIdx].values.push(newItem);
                }
              });
            });
            dataSetResult.d3Data = streams;
            delete dataSetResult.results;
          } else {
            logger.debug("Working with non-multiplexed data!");
            stream = {
              key: dataSetResult.queryHash.d3Lookup.key,
              values: []
            };
            _.each(dataSetResult.results, function(item) {
              var _ref;

              stream.values.push({
                xOrig: item.x,
                x: (_ref = dataSetResult.queryHash.d3Lookup.xType) === 'date' || _ref === 'datetime' ? moment(item.x).unix() : item.x,
                xType: dataSetResult.queryHash.d3Lookup.xType,
                xGroupBy: dataSetResult.queryHash.d3Lookup.xGroupBy,
                xMultiplex: dataSetResult.queryHash.d3Lookup.xMultiplex,
                xMultipleType: dataSetResult.queryHash.d3Lookup.xMultiplexType,
                y: item.y,
                yType: dataSetResult.queryHash.d3Lookup.yType
              });
              return dataSetResult.d3Data = [stream];
            });
            delete dataSetResult.results;
          }
          return _.each(dataSetResult.d3Data, function(stream) {
            return stream.values.sort(function(a, b) {
              return a.x - b.x;
            });
          });
        });
        return callback(null, arrayOfDataSetResults);
      }
    });
    return self;
  };

  CachedDataSet.queryDataSet = function(arg, callback) {
    return this.loadDataSet(arg, function(err, results) {
      return callback(err, results);
    });
  };

  module.exports = CachedDataSet;

}).call(this);

/*
//@ sourceMappingURL=dbLogic.map
*/
