// Generated by CoffeeScript 1.6.2
(function() {
  var assert, should, utils;

  utils = require('../utilitis/utils');

  assert = require('assert');

  should = require('should');

  describe('utils', function() {
    describe('#test', function() {
      var dataSet;

      dataSet = {
        "_id": "5260218133ff1defb7000001",
        "name": "Test",
        "graphType": "multiBarChart",
        "dbReferences": [
          {
            "key": "a⦀b⦀people",
            "connection": "a",
            "schema": "b",
            "table": "persons",
            "fields": [
              {
                "COLUMN_NAME": "id",
                "DATA_TYPE": "varchar",
                "COLUMN_KEY": "PRI",
                "COLUMN_TYPE": "varchar(18)",
                "aggregation": "count"
              }, {
                "COLUMN_NAME": "companyid",
                "DATA_TYPE": "varchar",
                "COLUMN_KEY": "MUL",
                "COLUMN_TYPE": "varchar(254)",
                "joinTo": "a⦀b⦀company",
                "joinOn": "id",
                "joinType": "inner"
              }
            ],
            "cache": true,
            "limit": 1000,
            "type": "mysql"
          }, {
            "key": "a⦀b⦀company",
            "connection": "a",
            "schema": "b",
            "table": "company",
            "fields": [
              {
                "COLUMN_NAME": "id",
                "DATA_TYPE": "varchar",
                "COLUMN_KEY": "PRI",
                "COLUMN_TYPE": "varchar(18)",
                "aggregation": "count"
              }
            ],
            "cache": true,
            "limit": 1000,
            "type": "mysql"
          }, {
            "key": "d⦀e⦀foo",
            "connection": "a",
            "schema": "b",
            "table": "bar",
            "fields": [
              {
                "COLUMN_NAME": "id",
                "DATA_TYPE": "varchar",
                "COLUMN_KEY": "PRI",
                "COLUMN_TYPE": "varchar(18)",
                "aggregation": "count"
              }
            ],
            "cache": true,
            "limit": 1000,
            "type": "mongo"
          }
        ]
      };
      return it('should split the dbReferences into 2 groups', function() {
        return utils.splitByJoinedDbReferences(dataSet.dbReferences).length.should.equal(2);
      });
    });
    describe('#testTruthy', function() {
      it('undefined should be false', function() {
        return utils.truthy(void 0).should.be["false"];
      });
      it('no input should be false', function() {
        return utils.truthy().should.be["false"];
      });
      describe('#testTruthy - true values', function() {
        it('YES should be true', function() {
          return utils.truthy("YES").should.be["true"];
        });
        it('yes should be true', function() {
          return utils.truthy("yes").should.be["true"];
        });
        it('Y should be true', function() {
          return utils.truthy("Y").should.be["true"];
        });
        it('y should be true', function() {
          return utils.truthy("y").should.be["true"];
        });
        it('y should be true', function() {
          return utils.truthy("y").should.be["true"];
        });
        return it('1 should be true', function() {
          return utils.truthy(1).should.be["true"];
        });
      });
      return describe('#testTruthy - false values', function() {
        it('NO should be false', function() {
          return utils.truthy("NO").should.be["false"];
        });
        it('no should be false', function() {
          return utils.truthy("no").should.be["false"];
        });
        it('N should be false', function() {
          return utils.truthy("N").should.be["false"];
        });
        it('n should be false', function() {
          return utils.truthy("n").should.be["false"];
        });
        return it('0 should be false', function() {
          return utils.truthy(0).should.be["false"];
        });
      });
    });
    describe('#stringify', function() {
      it('should return a string for a string', function() {
        return utils.stringify('Hello World!').should.equal('Hello World!');
      });
      return it('should return a string for an object', function() {
        return utils.stringify({
          a: 1
        }).should.equal('{"a":1}');
      });
    });
    describe('#isInteger', function() {
      it('should return true for 1', function() {
        return utils.isInteger(1).should.equal(true);
      });
      it('should return true for 1.0', function() {
        return utils.isInteger(1.0).should.equal(true);
      });
      it('should return false for 1.1', function() {
        return utils.isInteger(1.1).should.equal(false);
      });
      return it('should return false for undefined', function() {
        return utils.isInteger(void 0).should.equal(false);
      });
    });
    describe('#isFloat', function() {
      it('should return false for 1', function() {
        return utils.isFloat(1).should.equal(false);
      });
      it('should return false for 1.0', function() {
        return utils.isFloat(1.0).should.equal(false);
      });
      it('should return true for 1.1', function() {
        return utils.isFloat(1.1).should.equal(true);
      });
      return it('should return false for undefined', function() {
        return utils.isFloat(void 0).should.equal(false);
      });
    });
    describe('#resolveEnvVar', function() {
      return it('undefined should return undefined', function() {
        return should.not.exist(utils.resolveEnvVar());
      });
    });
    describe('#parseDateToOffset ', function() {
      it('parse 2009 with year format', function() {
        return utils.parseDateToOffset('2009', 'year').should.equal(1230768000000);
      });
      return it('parse 2009 with no format', function() {
        return utils.parseDateToOffset('2009', void 0).should.equal(1230768000000);
      });
    });
    describe('#xParse ', function() {
      it('parse string 2009', function() {
        return utils.parseX('2009', {
          xType: 'datetime',
          xGroupBy: 'year'
        }).should.equal(1230768000000);
      });
      it('parse number 2009', function() {
        return utils.parseX(2009, {
          xType: 'datetime',
          xGroupBy: 'year'
        }).should.equal(1230768000000);
      });
      it('parse a number, 10', function() {
        return utils.parseX(10, void 0).should.equal(10);
      });
      it('parse a number, 10', function() {
        return utils.parseX(10).should.equal(10);
      });
      return it('parse 2012', function() {
        return utils.parseX('2012', {
          "xType": "datetime",
          "xGroupBy": "year"
        }).should.equal(1325376000000);
      });
    });
    describe('#isUnixOffset ', function() {
      it('parse a unix offset', function() {
        return utils.isUnixOffset(1230768000000).should.be["true"];
      });
      it('parse a unix timestamp', function() {
        return utils.isUnixOffset(1230768000).should.be["false"];
      });
      it('parse undefined', function() {
        return utils.isUnixOffset(void 0).should.be["false"];
      });
      it('parse nothing', function() {
        return utils.isUnixOffset().should.be["false"];
      });
      return it('parse a string of length 13', function() {
        return utils.isUnixOffset('aaaaaaaaaaaaa').should.be["false"];
      });
    });
    describe('#isUnixTimestamp ', function() {
      it('parse a unix timestamp', function() {
        return utils.isUnixTimestamp(1230768000).should.be["true"];
      });
      it('parse a unix offset', function() {
        return utils.isUnixTimestamp(1230768000000).should.be["false"];
      });
      it('parse undefined', function() {
        return utils.isUnixTimestamp(void 0).should.be["false"];
      });
      it('parse nothing', function() {
        return utils.isUnixTimestamp().should.be["false"];
      });
      return it('parse a string of length 13', function() {
        return utils.isUnixTimestamp('aaaaaaaaaaaaa').should.be["false"];
      });
    });
    return describe('#formatFieldValue ', function() {
      describe('SQL Injection', function() {
        return it("parse anything' OR 'x'='x", function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'varchar'
          }, "anything' OR 'x'='x").should.equal("'anything\\' OR \\'x\\'=\\'x'");
        });
      });
      it('parse undefined', function() {
        return (function() {
          return utils.formatFieldValue({
            COLUMN_NAME: 'a',
            DATA_TYPE: 'int'
          }, void 0);
        }).should["throw"]("Could not format undefined value for field a!");
      });
      it('parse null', function() {
        return utils.formatFieldValue({
          DATA_TYPE: 'dosntmatter'
        }, "null").should.equal('NULL');
      });
      it('parse NULL', function() {
        return utils.formatFieldValue({
          DATA_TYPE: 'dosntmatter'
        }, "NULL").should.equal('NULL');
      });
      describe('#nonPrecision ', function() {
        it('parse actual int', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'int'
          }, 1.0).should.equal(1);
        });
        it('parse int that is a float', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'int'
          }, 1.1).should.equal(1);
        });
        it('parse int that is a string', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'int'
          }, "1").should.equal(1);
        });
        return it('parse int that is a string but not parsable', function() {
          return (function() {
            return utils.formatFieldValue({
              DATA_TYPE: 'int'
            }, "({a: 1})");
          }).should["throw"]("You said ({a: 1}) was a numeric type but it couldn't be parsed as a string and it wasn't a number!");
        });
      });
      describe('#precision ', function() {
        it('parse actual float', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'float'
          }, 1.1).should.equal(1.1);
        });
        it('parse float that is an int', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'float'
          }, 1).should.equal(1);
        });
        return it('parse float that is a string', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'float'
          }, "1.3").should.equal(1.3);
        });
      });
      describe('#dateTypes', function() {
        return it('parse actual datetime', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'datetime'
          }, '2013-09-01 00:00:00', 'sql').should.equal('2013-09-01T00:00:00.000Z');
        });
      });
      describe('#stringTypes', function() {
        it('parse actual string', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'varchar'
          }, 'Hello World').should.equal("'Hello World'");
        });
        return it('parse a regex mongo string', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'varchar'
          }, '^1$', 'mongo', {
            regex: true
          }).toString().should.equal('/^1$/i');
        });
      });
      return describe('#booleanTypes', function() {
        it('parse 1', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, 1, 'sql').should.equal('TRUE');
        });
        it('parse yes', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, 'yes', 'sql').should.equal('TRUE');
        });
        it('parse true', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, true, 'sql').should.equal('TRUE');
        });
        it('parse 0', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, 0, 'sql').should.equal('FALSE');
        });
        it('parse n', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, 'n', 'sql').should.equal('FALSE');
        });
        it('parse false', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, false, 'sql').should.equal('FALSE');
        });
        return it('parse false', function() {
          return utils.formatFieldValue({
            DATA_TYPE: 'bool'
          }, false, 'mongo').should.be["false"];
        });
      });
    });
  });

}).call(this);

/*
//@ sourceMappingURL=testUtils.map
*/
