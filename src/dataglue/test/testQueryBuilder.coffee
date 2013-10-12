queryBuilder  = require '../db/queryBuilder'
assert        = require 'assert'
should        = require 'should'
_             = require 'lodash'
logger        = require('tracer').colorConsole()
prettyjson    = require 'prettyjson'
moment        = require 'moment'

describe 'queryBuilder', ->

  simpleMongoDbReference = {
    "key" : "Test⦀some_schema⦀some_table",
    "connection" : "Test",
    "schema" : "some_schema",
    "table" : "some_table",
    "type" : "mongo",
    "fields" : [
      {
        COLUMN_NAME : "id",
        DATA_TYPE : "varchar",
      },
      {
        COLUMN_NAME : "created_date",
        DATA_TYPE : "datetime"
      },
    ]
  }
  simpleMysqlDbReference = {
    "key" : "Test⦀some_schema⦀some_table",
    "connection" : "Test",
    "schema" : "some_schema",
    "table" : "some_table",
    "type" : "mysql",
    "fields" : [
      {
        COLUMN_NAME : "id",
        DATA_TYPE : "varchar",
      },
      {
        COLUMN_NAME : "created_date",
        DATA_TYPE : "datetime"
      },
    ]
    "limit" : 1000
  }
  # Group by the x_multiplex field from the previous projection, push the values onto that stream
  mongoCommonMultiplex = {
    '$group': {
      '_id': {'x_multiplex': '$x_multiplex'},
      'values': {
        '$push': {'x': '$x', 'y': '$y'}
      }
    }
  }
  # A very simple pipieline action that renames the _id.key to just key, really all this does
  mongoCommonMultiplexProject = {
    '$project': {
      '_id': 0,
      'key': {'$concat': ['$_id.x_multiplex',]},
      'values': 1
    }
  }

  describe '#buildMysqlQuery', ->
    it 'build a simple mysql query', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[1].groupBy = "month"
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, DATE_FORMAT(created_date, \'%Y-%m\') AS "x" FROM some_schema.some_table GROUP BY x LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

    it 'build a simple mysql query id = 1', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[0].cond = '='
      ref.fields[0].condValue = 1
      ref.fields[1].groupBy = "month"
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, DATE_FORMAT(created_date, \'%Y-%m\') AS "x" FROM some_schema.some_table WHERE (id = 1) GROUP BY x LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

    it 'build a simple mysql query id != 1', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[0].cond = '!='
      ref.fields[0].condValue = 1
      ref.fields[1].groupBy = "month"
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, DATE_FORMAT(created_date, \'%Y-%m\') AS "x" FROM some_schema.some_table WHERE (id != 1) GROUP BY x LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

    it 'build a simple mysql query id > 1', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[0].cond = '>'
      ref.fields[0].condValue = 1
      ref.fields[1].groupBy = "month"
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, DATE_FORMAT(created_date, \'%Y-%m\') AS "x" FROM some_schema.some_table WHERE (id > 1) GROUP BY x LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

    it 'build a mysql query where 1 < id <= 10', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[0].beginCond = '>'
      ref.fields[0].beginValue = 1
      ref.fields[0].endCond = '<='
      ref.fields[0].endValue = 10
      ref.fields[1].groupBy = "month"
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, DATE_FORMAT(created_date, \'%Y-%m\') AS "x" FROM some_schema.some_table WHERE (id > \'1\') AND (id <= \'10\') GROUP BY x LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

    it 'build a simple multiplexed mysql query', (done) ->
      ref = _.cloneDeep simpleMysqlDbReference
      ref.fields[0].aggregation = "count"
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'multiplex'
      })
      expectedSql = 'SELECT COUNT(id) AS "y", created_date, geo, geo AS "x_multiplex" FROM some_schema.some_table GROUP BY x_multiplex LIMIT 1000'
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.equal expectedSql
        done()

  describe '#buildMongoQuery', ->
    it 'test deep equals', () ->
      x = [{"$match":{"created_date":{"$ne":null}}},{"$group":{"_id":{"year":{"$year":"$created_date"}}}},{"$project":{"_id":0,"x":"$_id.year"}}]
      y = [
        { '$match': {"created_date": {"$ne": null}} },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}} } }
        { "$project": {"_id": 0, "x": "$_id.year"}}
      ]
      x.should.eql y

    it 'build a simple mongo group by year query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "year"
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$exists": true,
              "$ne": null
            }
          }
        },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}} } }
        { "$project": {"_id": 0, "x": "$_id.year"}}
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        #logger.info JSON.stringify output
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by month query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "month"
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$exists": true,
              "$ne": null
            }
          }
        },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}} } },
        {
          "$project": {
            "_id": 0,
            "x": {
              "$concat": [
                "$_id.year",
                "-",
                "$_id.month"
              ]
            }
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by day query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "day"
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$exists": true,
              "$ne": null
            }
          }
        },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}, "day": {"$dayOfMonth": "$created_date"}} } },
        {
          "$project": {
            "_id": 0,
            "x": {
              "$concat": [
                "$_id.year",
                "-",
                "$_id.month",
                "-",
                "$_id.day"
              ]
            }
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by hour query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "hour"
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$exists": true,
              "$ne": null
            }
          }
        },
        { '$group': { "_id":
          {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}, "day": {"$dayOfMonth": "$created_date"}, "hour": {"$hour": "$created_date"}} }
        },
        {
          "$project": {
            "_id": 0,
            "x": {
              "$concat": [
                "$_id.year",
                "-",
                "$_id.month"
                "-",
                "$_id.day",
                " ",
                "$_id.hour"
              ]
            }
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'mongo group by field limit 500', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'field'
      })
      ref.limit = 500
      expectedQuery = [
        { '$match': {"geo": {"$exists": true}} },
        { '$group': {
          "_id": {"x": "$geo"}}
        },
        { "$project": {"_id": 0, "x": "$_id.x"}},
        { '$limit': 500 }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'mongo count by field', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = 'count'
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'field'
      })
      expectedQuery = [
        { '$match': {"geo": {"$exists": true}} },
        { '$group': {
          "_id": {"x": "$geo"},
          "count": {"$sum": 1}}
        },
        {
          "$project": {
            "_id": 0,
            "x": "$_id.x",
            "y": "$count"
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'mongo count by month', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = "count"
      ref.fields[1].groupBy = "month"
      expectedQuery = [
        {
          "$match": {
            "created_date": {
              "$exists": true,
              "$ne": null
            }
          }
        },
        {
          "$group": {
            "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}},
            "count": {"$sum": 1}
          }
        },
        { "$project": {"_id": 0, "x": { "$concat": [ "$_id.year", "-", "$_id.month" ] }, "y": "$count" }}
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        #logger.info JSON.stringify output
        output.query.should.eql expectedQuery
        done()

    it 'mongo count by month multiplex by geo field', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = 'count'
      ref.fields[1].groupBy = 'month'
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'multiplex'
      })
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$exists": true,
              "$ne": null
            },
            "geo": {"$exists": true}
          }
        },
        {
          '$group': {
            "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}, "x_multiplex": "$geo"},
            "count": {"$sum": 1}
          }
        },
        {
          "$project": {
            "_id": 0,
            "y": "$count"
            "x": { "$concat": [ "$_id.year", "-", "$_id.month" ] },
            "x_multiplex": "$_id.x_multiplex",
          }
        },
#        mongoCommonMultiplex,
#        {
#          '$project': {
#            '_id': 0,
#            'key': {'$concat': ['$_id.x_multiplex', ' ', 'id', ' ', 'count']},
#            'values': 1
#          }
#        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'group by month between 2013-09-01 and 2013-10-01', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "month"
      ref.fields[1].beginCond = ">"
      ref.fields[1].beginValue = "2013-09-01"
      ref.fields[1].endCond = "<="
      ref.fields[1].endValue = "2013-10-01"
      expectedQuery = [
        {
          '$match': {
            "created_date": {
              "$gt": moment.utc("2013-09-01").toDate(),
              "$lte": moment.utc("2013-10-01").toDate(),
              "$exists": true,
              "$ne": null
            }
          }
        },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}} } },
        {
          "$project": {
            "_id": 0,
            "x": {
              "$concat": [
                "$_id.year",
                "-",
                "$_id.month"
              ]
            }
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        # Optionally Compare the stingification if not specifying moment().toDate() above otherwise not equal
        # JSON.stringify(output.query).should.eql JSON.stringify(expectedQuery)
        done()

    it 'mongo query where 1 <= id < 10', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = 'count'
      ref.fields[0].beginCond = '>='
      ref.fields[0].beginValue = 1
      ref.fields[0].endCond = '<'
      ref.fields[0].endValue = 10
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'field'
      })
      expectedQuery = [
        {
          '$match': {
            "id": {
              "$gte": "1",
              "$lt": "10",
            }
            "geo": {
              "$exists": true
            }
          }
        },
        { '$group': {
          "_id": {"x": "$geo"},
          "count": {"$sum": 1}}
        },
        {
          "$project": {
            "_id": 0,
            "x": "$_id.x",
            "y": "$count"
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'mongo query regex id like ^1$', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = 'count'
      ref.fields[0].cond = 'LIKE'
      ref.fields[0].condValue = '^1$'
      ref.fields.push({
        COLUMN_NAME : "geo",
        DATA_TYPE : "varchar",
        groupBy: 'field'
      })
      regx = new RegExp(ref.fields[0].condValue)
      expectedQuery = [
        {
          '$match': {
            "id": {
#              "$regex": "#{regx.toString()}i",
              # haven't figure out yet how to properly test this
              "$regex": {},
            }
            "geo": {
              "$exists": true
            }
          }
        },
        { '$group': {
          "_id": {"x": "$geo"},
          "count": {"$sum": 1}}
        },
        {
          "$project": {
            "_id": 0,
            "x": "$_id.x",
            "y": "$count"
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()
