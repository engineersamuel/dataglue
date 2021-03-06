// Generated by CoffeeScript 1.6.2
(function() {
  var DataSetCache, logger, md5, mongoUrl, mongodb, prettyjson, settings, utils, zlib, _;

  settings = require('../utilitis/settings');

  utils = require('../utilitis/utils');

  logger = require('tracer').colorConsole(utils.logger_config);

  mongodb = require('mongodb');

  zlib = require('zlib');

  md5 = require('MD5');

  _ = require('lodash');

  prettyjson = require('prettyjson');

  mongoUrl = utils.generateMongoUrl(settings.master_ref);

  DataSetCache = {};

  DataSetCache.refDelete = function(_id, callback) {
    var self;

    self = this;
    mongodb.connect(mongoUrl, function(err, conn) {
      if (err) {
        return callback(err);
      } else {
        return conn.collection(settings.master_ref.collection, function(err, coll) {
          if (err) {
            callback(err);
            return conn.close();
          } else {
            return coll.remove({
              _id: mongodb.ObjectID(_id)
            }, {
              w: 1
            }, function(err, outcome) {
              callback(err, outcome);
              return conn.close();
            });
          }
        });
      }
    });
    return self;
  };

  DataSetCache.refGet = function(_id, callback) {
    var self;

    self = this;
    logger.debug("Connecting to mongo on: " + mongoUrl);
    mongodb.connect(mongoUrl, function(err, conn) {
      if (err) {
        return callback(err);
      } else {
        return conn.collection(settings.master_ref.collection, function(err, coll) {
          if (err) {
            callback(err);
            return conn.close();
          } else {
            logger.debug(_id);
            return coll.findOne({
              _id: mongodb.ObjectID(_id)
            }, function(err, doc) {
              if (err) {
                callback(err);
                return conn.close();
              } else {
                callback(null, doc);
                return conn.close();
              }
            });
          }
        });
      }
    });
    return self;
  };

  DataSetCache.refUpsert = function(doc, callback) {
    _.each(doc.dbReferences, function(value, key) {
      return _.each(value.fields, function(field) {
        if (_.has(field, '$$hashKey')) {
          return delete field['$$hashKey'];
        }
      });
    });
    return mongodb.connect(mongoUrl, function(err, conn) {
      if (err) {
        return callback(err);
      } else {
        return conn.collection(settings.master_ref.collection, function(err, coll) {
          var _id;

          if (err) {
            callback(err);
            conn.close();
          } else {

          }
          _.each(doc.dbReferences, function(dbReference) {
            return dbReference.type = settings.db_refs[dbReference.connection].type;
          });
          if (_.has(doc, '_id')) {
            _id = mongodb.ObjectID(doc['_id']);
            doc['_id'] = _id;
            return coll.update({
              _id: _id
            }, doc, {
              upsert: true,
              safe: true
            }, function(err, outcome) {
              if (err) {
                callback(err);
              } else {
                callback(null, _id.toString());
              }
              return conn.close();
            });
          } else {
            return coll.insert(doc, {
              safe: true
            }, function(err, insertedId) {
              if (err) {
                logger.warn(err.message);
              }
              if (err && err.message.indexOf('E11000') !== -1) {
                logger.error("This _id was already inserted in the database");
              }
              if (err) {
                callback(err);
              } else {
                logger.debug(prettyjson.render("insertedId: " + insertedId));
                callback(null, doc['_id'].toString());
              }
              return conn.close();
            });
          }
        });
      }
    });
  };

  DataSetCache.statementCacheGet = function(dbReference, queryHash, callback) {
    var self;

    self = this;
    logger.debug("Connecting to mongo on: " + mongoUrl);
    mongodb.connect(mongoUrl, function(err, conn) {
      if (err) {
        return callback(err);
      }
      return conn.collection(settings.master_ref.cache, function(err, coll) {
        var hash;

        if (err) {
          return callback(err);
        } else {
          hash = md5("" + dbReference.key + (utils.stringify(queryHash.query)));
          logger.debug("Cache made up of key: " + dbReference.key + " query: " + (JSON.stringify(queryHash.query)));
          return coll.findOne({
            _id: hash
          }, function(err, doc) {
            if (err) {
              callback(err);
            } else if (doc == null) {
              logger.debug("\tCache miss");
              callback(null, null);
            } else {
              logger.debug("\tCache hit");
              zlib.unzip(new Buffer(doc['data'], 'base64'), function(err, results) {
                if (err != null) {
                  logger.error("Error decompressing data: " + err);
                  return callback(err);
                } else {
                  return callback(null, JSON.parse(results));
                }
              });
            }
            return conn.close();
          });
        }
      });
    });
    return self;
  };

  DataSetCache.dataSetResultCachePut = function(dataSetResult, callback) {
    var self;

    self = this;
    logger.debug("Connecting to mongo on: " + mongoUrl);
    mongodb.connect(mongoUrl, function(err, conn) {
      if (err) {
        logger.error(prettyjson.render(err));
        return callback(err);
      } else {
        return conn.collection(settings.master_ref.cache, function(err, coll) {
          var hash;

          if (err) {
            return callback(err);
          } else {
            hash = md5("" + dataSetResult.dbRefKey + (utils.stringify(dataSetResult.queryHash.query)));
            logger.debug("Cache hash: " + hash);
            logger.debug("Cache made up of key: " + dataSetResult.dbRefKey + " query: " + (JSON.stringify(dataSetResult.queryHash.query)));
            return zlib.deflate(JSON.stringify(dataSetResult.d3Data), function(err, buffer) {
              var doc;

              if (err) {
                logger.error("Problem compressing data: " + err);
                return callback(err);
              } else {
                doc = {
                  _id: hash,
                  query: dataSetResult.queryHash.query,
                  data: buffer.toString('base64'),
                  lastTouched: new Date()
                };
                return coll.update({
                  _id: doc._id
                }, doc, {
                  upsert: true,
                  safe: true
                }, function(err, outcome) {
                  if (err) {
                    callback(err);
                  } else {
                    callback(null, outcome);
                  }
                  return conn.close();
                });
              }
            });
          }
        });
      }
    });
    return self;
  };

  module.exports = DataSetCache;

}).call(this);

/*
//@ sourceMappingURL=datasetCache.map
*/
