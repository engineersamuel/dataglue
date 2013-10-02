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
