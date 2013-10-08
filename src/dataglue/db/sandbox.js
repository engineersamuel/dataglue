// Generated by CoffeeScript 1.6.2
(function() {
  var Db, assert, async, dataSetCache, dbLogic, logger, mongodb, mysql, pj, prettyjson, sandbox, settings, utils, zlib, _;

  settings = require('../utilitis/settings');

  utils = require('../utilitis/utils');

  logger = require('tracer').colorConsole(utils.logger_config);

  pj = require('prettyjson');

  dataSetCache = require('../db/datasetCache');

  dbLogic = require('../db/dbLogic');

  zlib = require('zlib');

  prettyjson = require('prettyjson');

  Db = require('mongodb').Db;

  mongodb = require('mongodb');

  _ = require('lodash');

  assert = require('assert');

  async = require('async');

  mysql = require('mysql');

  sandbox = {};

  sandbox.hashEach = function() {
    var test;

    test = {
      a: 1,
      b: 2
    };
    return _.each(test, function(value, key) {
      return logger.debug("key: " + key + ", value: " + value);
    });
  };

  sandbox.test_query_dataset = function() {
    var p;

    p = dbLogic.queryDataSet('52277447f95fb65818000001');
    return p.on('dataset', function(dataset) {
      return console.log(dataset);
    });
  };

  sandbox.test_compress = function(input) {
    return zlib.deflate(input, function(err, buffer) {
      logger.info("Compressed: " + buffer);
      return logger.info("Compressed: " + (buffer.toString('base64')));
    });
  };

  sandbox.test_decompress = function(input) {
    var buff;

    buff = new Buffer(input, 'base64');
    logger.info("buff: " + (buff.toString('base64')));
    return zlib.unzip(buff, function(err, results) {
      return logger.info("Decompressed: " + (results.toString()));
    });
  };

  sandbox.refGet = function(_id) {
    logger.debug("Looking up ref with _id: " + _id);
    return dataSetCache.refGet(_id, function(err, doc) {
      return logger.debug(prettyjson.render(result));
    });
  };

  sandbox.dataset_get = function(_id) {
    logger.debug("Looking up data set with _id: " + _id);
    return dataSetCache.refGet(_id, function(err, doc) {
      var p;

      p = dbLogic.loadDataSet(doc);
      return p.on('resultsReady', function(results) {
        logger.debug(typeof results);
        return logger.debug(JSON.stringify(results));
      });
    });
  };

  sandbox.test_parse_string = function() {
    var s;

    s = "52277447f95fb65818000001";
    return logger.info(JSON.parse(s));
  };

  sandbox.test_converting_streams_to_bubble = function() {
    var bubbleData, streams, uniqueXs;

    streams = [
      {
        "key": "id count",
        "values": [
          {
            "x": "ANZ",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 104,
            "yType": "varchar"
          }, {
            "x": "ASEAN",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 21,
            "yType": "varchar"
          }, {
            "x": "Brazil",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 52,
            "yType": "varchar"
          }, {
            "x": "Canada",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 41,
            "yType": "varchar"
          }, {
            "x": "CE",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 61,
            "yType": "varchar"
          }, {
            "x": "GCG",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 69,
            "yType": "varchar"
          }, {
            "x": "India",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 207,
            "yType": "varchar"
          }, {
            "x": "Japan",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 65,
            "yType": "varchar"
          }, {
            "x": "Korea",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 11,
            "yType": "varchar"
          }, {
            "x": "Mexico",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 3,
            "yType": "varchar"
          }, {
            "x": "NEE",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 246,
            "yType": "varchar"
          }, {
            "x": "SOLA",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 31,
            "yType": "varchar"
          }, {
            "x": "SWE",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 114,
            "yType": "varchar"
          }, {
            "x": "UKI",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 144,
            "yType": "varchar"
          }, {
            "x": "UNKNOWN",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 882,
            "yType": "varchar"
          }, {
            "x": "US",
            "xType": "varchar",
            "xGroupBy": "field",
            "y": 1064,
            "yType": "varchar"
          }
        ]
      }
    ];
    bubbleData = _.flatten(_.map(streams, function(stream) {
      return _.map(stream.values, function(item) {
        return item;
      });
    }));
    uniqueXs = _.unique(_.map(bubbleData, function(item) {
      return item.x;
    }));
    logger.info(prettyjson.render(bubbleData));
    return logger.info(prettyjson.render(uniqueXs));
  };

  sandbox.test_openshift_mongo = function(user, pass, host, port, db) {
    var mongourl;

    mongourl = "mongodb://" + user + ":" + pass + "@" + host + ":" + port + "/" + db + "?auto_reconnect=true";
    logger.info("Attempting to connect to: " + mongourl);
    return mongodb.connect(mongourl, function(err, conn) {
      if (err) {
        return logger.error(err);
      } else {
        logger.info("Attempting to connect to collection: " + settings.master_ref.cache);
        return conn.collection(settings.master_ref.cache, function(err, coll) {
          if (err) {
            logger.error(err);
            return conn.close();
          } else {
            return coll.find({}, function(err, results) {
              logger.debug(prettyjson.render(results));
              return conn.close();
            });
          }
        });
      }
    });
  };

  sandbox.test_unique_stream_x = function() {
    var streams, uniqueXs;

    streams = [
      {
        key: 'a',
        values: [
          {
            x: 1,
            y: 4
          }
        ]
      }, {
        key: 'b',
        values: [
          {
            x: 2,
            y: 10
          }
        ]
      }
    ];
    uniqueXs = _.without(_.unique(_.map(_.flatten(_.map(streams, function(stream) {
      return stream.values;
    }), true), function(item) {
      return item.x;
    })), void 0);
    _.each(uniqueXs, function(uniqueX) {
      return _.each(streams, function(stream) {
        if (_.findIndex(stream.values, function(v) {
          return v.x === uniqueX;
        }) === -1) {
          return stream.values.push({
            x: uniqueX,
            y: 0
          });
        }
      });
    });
    logger.info(uniqueXs);
    return logger.info(prettyjson.render(streams));
  };

  sandbox.test_sort = function() {
    var a, streams;

    a = [1, 3, 5, 1, 2, 30, 99, 2];
    streams = [
      {
        key: 'a',
        values: [
          {
            x: 1,
            y: 4
          }
        ]
      }, {
        key: 'b',
        values: [
          {
            x: 2,
            y: 10
          }
        ]
      }
    ];
    logger.info(a);
    a.sort();
    return logger.info(a);
  };

  sandbox.test_first_stream_value = function() {
    var firstItem, streams;

    streams = [
      {
        key: 'a',
        values: [
          {
            x: 1,
            y: 4
          }
        ]
      }, {
        key: 'b',
        values: [
          {
            x: 2,
            y: 10
          }
        ]
      }
    ];
    firstItem = _.first(_.first(streams).values);
    return logger.info(prettyjson.render(firstItem));
  };

  sandbox.test_merge = function() {
    var dest, results, source;

    results = [];
    source = {
      x: '2010-10',
      xType: 'datetime',
      xGroupBy: 'month',
      xMultiplex: 'x_multiplex',
      xMultiplexType: 'varchar',
      y: 3.1585,
      yType: 'int'
    };
    dest = {
      x: '2012-10',
      y: 0
    };
    results.push(_.merge(source, dest));
    return logger.info(prettyjson.render(results));
  };

  sandbox.test_unique_sort = function() {
    var values;

    values = ["2012-04", "2011-03", "2010-12", "2011-01", "2011-02", "2010-10", "2011-04", "2011-05", "2011-06", "2011-07", "2011-08", "2011-09", "2011-10", "2011-11", "2011-12", "2012-01", "2012-02", "2012-03", "2010-11", "2012-05", "2012-06", "2012-07", "2012-08", "2012-09", "2012-10", "2012-11", "2012-12", "2013-01", "2013-02", "2013-03", "2013-04", "2013-05", "2013-06", "2013-07", "2013-08", "2013-09", "2010-09"];
    values.sort();
    return logger.info(values);
  };

  sandbox.test_mongo_bson_types = function() {
    var mongourl;

    mongourl = "mongodb://127.0.0.1:27017/dataglue?auto_reconnect=true";
    logger.info("Attempting to connect to: " + mongourl);
    return mongodb.connect(mongourl, function(err, conn) {
      if (err) {
        return logger.error(err);
      } else {
        logger.info("Attempting to connect to collection: " + settings.master_ref.collection);
        return conn.collection(settings.master_ref.collection, function(err, coll) {
          if (err) {
            return logger.error(err);
          } else {
            return coll.find({}).toArray(function(err, results) {
              logger.debug(prettyjson.render(results));
              return conn.close();
            });
          }
        });
      }
    });
  };

  sandbox.test_mongo_run_command = function() {
    var mongourl;

    mongourl = "mongodb://127.0.0.1:27017/admin?auto_reconnect=true";
    logger.info("Attempting to connect to: " + mongourl);
    return mongodb.connect(mongourl, function(err, conn) {
      if (err) {
        return logger.error(err);
      } else {
        logger.info("Attempting to connect to collection: " + settings.master_ref.collection);
        return conn.command({
          listDatabases: 1
        }, function(err, output) {
          logger.info(prettyjson.render(output));
          return conn.close();
        });
      }
    });
  };

  sandbox.test_collections = function() {
    var mongourl;

    mongourl = "mongodb://127.0.0.1:27017/dataglue?auto_reconnect=true";
    logger.info("Attempting to connect to: " + mongourl);
    return Db.connect(mongourl, function(err, db) {
      assert.equal(null, err);
      logger.info("Opened connection to: " + mongourl);
      return db.collectionNames(function(err, collectionNames) {
        assert.equal(null, err);
        logger.info(prettyjson.render(collectionNames));
        return db.close();
      });
    });
  };

  sandbox.test_find = function() {
    return logger.info(_.find(void 0, function(item) {
      return item === 'a';
    }));
  };

  sandbox.test_substring = function() {
    var dbName, item;

    dbName = 'dataglue-foo';
    item = {
      name: 'dataglue-foo.system.indexes'
    };
    return logger.info(item.name.replace(dbName + '.', ''));
  };

  sandbox.setMongoDataTypes = function(obj) {
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
    } else if (utils.isInteger(obj)) {
      return 'int';
    } else if (utils.isFloat(obj)) {
      return 'float';
    }
  };

  sandbox.test_fields = function() {
    var mongourl;

    mongourl = "mongodb://127.0.0.1:27017/test?auto_reconnect=true";
    logger.info("Attempting to connect to: " + mongourl);
    return Db.connect(mongourl, function(err, db) {
      assert.equal(null, err);
      logger.info("Opened connection to: " + mongourl);
      return db.collection('managers', function(err, coll) {
        logger.info("Opened collection: ref");
        return coll.findOne({}, function(err, doc) {
          var fields;

          fields = _.map(_.keys(doc), function(f) {
            return {
              COLUMN_NAME: f,
              DATA_TYPE: sandbox.setMongoDataTypes(doc[f]),
              COLUMN_TYPE: void 0,
              COLUMN_KEY: void 0
            };
          });
          logger.info(prettyjson.render(fields));
          return db.close();
        });
      });
    });
  };

  sandbox.test_array_concat = function() {
    var a, b;

    a = [1, 2];
    b = a.concat([3, 4]);
    return logger.info(prettyjson.render(b));
  };

  sandbox.test_mysql_escape = function() {
    var beginCond;

    beginCond = mysql.escape("!=").replace(/'/g, "");
    return logger.debug(beginCond);
  };

  sandbox.test_mysql_escape();

}).call(this);

/*
//@ sourceMappingURL=sandbox.map
*/
