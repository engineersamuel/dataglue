queryBuilder  = require '../db/queryBuilder'
assert        = require 'assert'
should        = require 'should'
_             = require 'lodash'
logger        = require('tracer').colorConsole()
prettyjson    = require 'prettyjson'

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
    it 'build a simple mongo group by year query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "year"
      expectedQuery = [
        { '$match': {"created_date": {"$exists": true}} },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}} } }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by month query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "month"
      expectedQuery = [
        { '$match': {"created_date": {"$exists": true}} },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}} } }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by day query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "day"
      expectedQuery = [
        { '$match': {"created_date": {"$exists": true}} },
        { '$group': { "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}, "day": {"$dayOfMonth": "$created_date"}} } }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'build a simple mongo group by hour query', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[1].groupBy = "hour"
      expectedQuery = [
        { '$match': {"created_date": {"$exists": true}} },
        { '$group': { "_id":
          {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}, "day": {"$dayOfMonth": "$created_date"}, "hour": {"$hour": "$created_date"}} }
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
        { '$group': { "_id": "$geo"}},
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
        { '$group': { "_id": "$geo", "count": {"$sum": 1}}}
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        output.query.should.eql expectedQuery
        done()

    it 'mongo count by month', (done) ->
      ref = _.cloneDeep simpleMongoDbReference
      ref.fields[0].aggregation = 'count'
      ref.fields[1].groupBy = "month"
      expectedQuery = [
        { '$match': {"created_date": {"$exists": true}} },
        {
          '$group': {
            "_id":  {"year": {"$year": "$created_date"}, "month": {"$month": "$created_date"}},
            "count": {"$sum": 1}
          }
        }
      ]
      queryBuilder.buildQuery ref, (err, output) ->
        if err then return done(err)
        logger.debug JSON.stringify output
        output.query.should.eql expectedQuery
        done()
