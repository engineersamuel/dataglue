utils   = require '../utilitis/utils'
assert  = require 'assert'
should  = require 'should'

describe 'utils', ->
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
