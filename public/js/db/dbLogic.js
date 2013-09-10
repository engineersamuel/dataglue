// Generated by CoffeeScript 1.6.2
(function() {
  define(['underscore'], function(_) {
    var data, dbLogic, tmp;

    tmp = {};
    data = void 0;
    dbLogic = {};
    dbLogic.processDataSet = function(dataSet, dataSetData) {
      if (dataSetData) {
        data = dataSetData;
      }
      console.log("dataSet: " + (JSON.stringify(dataSet)));
      console.log("dataSetData: " + data.length + " rows");
      return _.each(_.keys(data), function(key) {
        console.log("Looping on key: " + key);
        tmp[key] = {
          rawValues: void 0
        };
        if (tmp[key]['d3'] == null) {
          tmp[key]['d3'] = {};
        }
        _.each(dataSet.dbReferences[key].fields, function(field) {
          var groupedRows;

          console.log("Looping on field: " + (JSON.stringify(field)));
          if (tmp[key]['field'] == null) {
            tmp[key]['field'] = field;
          }
          if ((field['groupBy'] != null) && field['groupBy'] !== "") {
            groupedRows = void 0;
            console.log("Grouping by " + field.groupBy);
            if (field.groupBy === 'year') {
              groupedRows = _.groupBy(data[key], function(row) {
                var fieldValue;

                fieldValue = row[field['COLUMN_NAME']];
                return moment(fieldValue).format('YYYY');
              });
            } else if (field['groupBy'] === 'month') {
              groupedRows = _.groupBy(data[key], function(row) {
                var fieldValue;

                fieldValue = row[field['COLUMN_NAME']];
                return moment(fieldValue).format('YYYY-MM');
              });
            } else if (field['groupBy'] === 'day') {
              groupedRows = _.groupBy(data[key], function(row) {
                var fieldValue;

                fieldValue = row[field['COLUMN_NAME']];
                return moment(fieldValue).format('YYYY-MM-DD');
              });
            }
            return tmp[key].rawValues = groupedRows;
          }
        });
        return _.each(dataSet.dbReferences[key].fields, function(field) {
          console.log("Looping on field: " + (JSON.stringify(field)));
          if ((field['aggregation'] != null) && field['aggregation'] !== "") {
            if (field['aggregation'] === 'count') {
              if (tmp[key] == null) {
                return console.error("No tmp[" + key + "] found, tmp: " + (JSON.stringify(tmp)));
              } else if (tmp[key].rawValues == null) {
                return console.error("No rawValues found for key: " + key + ", tmp[key]: " + (JSON.stringify(tmp[key])));
              } else if (!_.isArray(tmp[key].rawValues)) {
                return _.each(_.keys(tmp[key].rawValues), function(group) {
                  var theCount;

                  theCount = _.countBy(tmp[key].rawValues[group], function(row) {
                    if (_.has(row, field['COLUMN_NAME'])) {
                      return field['COLUMN_NAME'];
                    } else {
                      return void 0;
                    }
                  });
                  theCount = theCount[field['COLUMN_NAME']];
                  if (tmp[key]['d3'][group] == null) {
                    tmp[key]['d3'][group] = {};
                  }
                  return tmp[key]['d3'][group]['count'] = theCount;
                });
              } else if (_.isArray(tmp.rawValues)) {
                return console.warn("Not yet Implemented!");
              }
            }
          }
        });
      });
    };
    dbLogic.convertToD3 = function() {
      var tmpD3DataSet;

      tmpD3DataSet = [];
      return _.each(_.keys(tmp), function(dbReference) {
        var stack;

        stack = {
          key: tmp[dbReference]['field']['COLUMN_NAME'],
          values: []
        };
        _.each(_.keys(tmp[dbReference]['d3']), function(groupedKey) {
          return stack['values'].push({
            x: groupedKey,
            y: tmp[dbReference]['d3'][groupedKey]['count'],
            f: tmp[dbReference]['field']
          });
        });
        tmpD3DataSet.push(stack);
        return tmpD3DataSet;
      });
    };
    return dbLogic;
  });

}).call(this);
