utils   = require '../utilitis/utils'
assert  = require 'assert'
should  = require 'should'

describe 'utils', ->
  describe '#testTruthy', ->
    it 'undefined should be false', ->
      utils.truthy(undefined).should.be.false
    it 'no input should be false', ->
      utils.truthy().should.be.false

    describe '#testTruthy - true values', ->
      it 'YES should be true', ->
        utils.truthy("YES").should.be.true
      it 'yes should be true', ->
        utils.truthy("yes").should.be.true
      it 'Y should be true', ->
        utils.truthy("Y").should.be.true
      it 'y should be true', ->
        utils.truthy("y").should.be.true
      it 'y should be true', ->
        utils.truthy("y").should.be.true
      it '1 should be true', ->
        utils.truthy(1).should.be.true

    describe '#testTruthy - false values', ->
      it 'NO should be false', ->
        utils.truthy("NO").should.be.false
      it 'no should be false', ->
        utils.truthy("no").should.be.false
      it 'N should be false', ->
        utils.truthy("N").should.be.false
      it 'n should be false', ->
        utils.truthy("n").should.be.false
      it '0 should be false', ->
        utils.truthy(0).should.be.false


  describe '#stringify', ->
    it 'should return a string for a string', ->
      utils.stringify('Hello World!').should.equal 'Hello World!'
    it 'should return a string for an object', ->
      utils.stringify({a: 1}).should.equal '{"a":1}'

  describe '#isInteger', ->
    it 'should return true for 1', ->
      utils.isInteger(1).should.equal true
    it 'should return true for 1.0', ->
      utils.isInteger(1.0).should.equal true
    it 'should return false for 1.1', ->
      utils.isInteger(1.1).should.equal false
    it 'should return false for undefined', ->
      utils.isInteger(undefined).should.equal false

  describe '#isFloat', ->
    it 'should return false for 1', ->
      utils.isFloat(1).should.equal false
    it 'should return false for 1.0', ->
      utils.isFloat(1.0).should.equal false
    it 'should return true for 1.1', ->
      utils.isFloat(1.1).should.equal true
    it 'should return false for undefined', ->
      utils.isFloat(undefined).should.equal false

  describe '#resolveEnvVar', ->
    it 'undefined should return undefined', ->
      should.not.exist(utils.resolveEnvVar())

  describe '#parseDateToOffset ', ->
    it 'parse 2009 with year format', ->
      utils.parseDateToOffset('2009', 'year').should.equal 1230768000000
    it 'parse 2009 with no format', ->
      utils.parseDateToOffset('2009', undefined).should.equal 1230768000000

  describe '#xParse ', ->
    it 'parse string 2009', ->
      utils.parseX('2009', {xType: 'datetime', xGroupBy: 'year'}).should.equal 1230768000000
    it 'parse number 2009', ->
      utils.parseX(2009, {xType: 'datetime', xGroupBy: 'year'}).should.equal 1230768000000
    it 'parse a number, 10', ->
      utils.parseX(10, undefined).should.equal 10
    it 'parse a number, 10', ->
      utils.parseX(10).should.equal 10
    it 'parse 2012', ->
      utils.parseX('2012', {"xType":"datetime","xGroupBy":"year"}).should.equal 1325376000000

  describe '#isUnixOffset ', ->
    it 'parse a unix offset', ->
      utils.isUnixOffset(1230768000000).should.be.true
    it 'parse a unix timestamp', ->
      utils.isUnixOffset(1230768000).should.be.false
    it 'parse undefined', ->
      utils.isUnixOffset(undefined).should.be.false
    it 'parse nothing', ->
      utils.isUnixOffset().should.be.false
    it 'parse a string of length 13', ->
      utils.isUnixOffset('aaaaaaaaaaaaa').should.be.false

  describe '#isUnixTimestamp ', ->
    it 'parse a unix timestamp', ->
      utils.isUnixTimestamp(1230768000).should.be.true
    it 'parse a unix offset', ->
      utils.isUnixTimestamp(1230768000000).should.be.false
    it 'parse undefined', ->
      utils.isUnixTimestamp(undefined).should.be.false
    it 'parse nothing', ->
      utils.isUnixTimestamp().should.be.false
    it 'parse a string of length 13', ->
      utils.isUnixTimestamp('aaaaaaaaaaaaa').should.be.false

  describe '#formatFieldValue ', ->
    describe 'SQL Injection', ->
      it "parse anything' OR 'x'='x", ->
        utils.formatFieldValue({DATA_TYPE: 'varchar'}, "anything' OR 'x'='x").should.equal "'anything\\' OR \\'x\\'=\\'x'"
    it 'parse undefined', ->
      (() ->
        utils.formatFieldValue({COLUMN_NAME: 'a', DATA_TYPE: 'int'}, undefined)
      ).should.throw "Could not format undefined value for field a!"
    it 'parse null', ->
      utils.formatFieldValue({DATA_TYPE: 'dosntmatter'}, "null").should.equal 'NULL'
    it 'parse NULL', ->
      utils.formatFieldValue({DATA_TYPE: 'dosntmatter'}, "NULL").should.equal 'NULL'
    describe '#nonPrecision ', ->
      it 'parse actual int', ->
        utils.formatFieldValue({DATA_TYPE: 'int'}, 1.0).should.equal 1
      it 'parse int that is a float', ->
        utils.formatFieldValue({DATA_TYPE: 'int'}, 1.1).should.equal 1
      it 'parse int that is a string', ->
        utils.formatFieldValue({DATA_TYPE: 'int'}, "1").should.equal 1
      it 'parse int that is a string but not parsable', ->
        (() ->
          utils.formatFieldValue({DATA_TYPE: 'int'}, "({a: 1})")
        ).should.throw "You said ({a: 1}) was a numeric type but it couldn't be parsed as a string and it wasn't a number!"
    describe '#precision ', ->
      it 'parse actual float', ->
        utils.formatFieldValue({DATA_TYPE: 'float'}, 1.1).should.equal 1.1
      it 'parse float that is an int', ->
        utils.formatFieldValue({DATA_TYPE: 'float'}, 1).should.equal 1
      it 'parse float that is a string', ->
        utils.formatFieldValue({DATA_TYPE: 'float'}, "1.3").should.equal 1.3
    describe '#dateTypes', ->
      it 'parse actual datetime', ->
        utils.formatFieldValue({DATA_TYPE: 'datetime'}, '2013-09-01 00:00:00', 'sql').should.equal '2013-09-01T00:00:00.000Z'
    describe '#stringTypes', ->
      it 'parse actual string', ->
        utils.formatFieldValue({DATA_TYPE: 'varchar'}, 'Hello World').should.equal "'Hello World'"
      it 'parse a regex mongo string', ->
        utils.formatFieldValue({DATA_TYPE: 'varchar'}, '^1$', 'mongo', {regex: true}).toString().should.equal '/^1$/i'
    describe '#booleanTypes', ->
      it 'parse 1', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, 1, 'sql').should.equal 'TRUE'
      it 'parse yes', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, 'yes', 'sql').should.equal 'TRUE'
      it 'parse true', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, true, 'sql').should.equal 'TRUE'
      it 'parse 0', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, 0, 'sql').should.equal 'FALSE'
      it 'parse n', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, 'n', 'sql').should.equal 'FALSE'
      it 'parse false', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, false, 'sql').should.equal 'FALSE'
      it 'parse false', ->
        utils.formatFieldValue({DATA_TYPE: 'bool'}, false, 'mongo').should.be.false
