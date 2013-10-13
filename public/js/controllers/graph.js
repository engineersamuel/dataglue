// Generated by CoffeeScript 1.6.2
(function() {
  define(['jquery', 'underscore', 'moment', 'dbLogic'], function($, _, moment, dbLogic) {
    return [
      '$scope', '$rootScope', '$location', '$routeParams', '$timeout', 'dbService', function($scope, $rootScope, $location, $routeParams, $timeout, dbService) {
        $scope._ = _;
        $scope._id = $routeParams['_id'];
        if ($routeParams['_id'] != null) {
          dbService.cacheGet($routeParams['_id'], function(data) {
            dbService.dataSet = data;
            $scope.dataSet = dbService.dataSet;
            return $rootScope.$broadcast('dataSetLoaded');
          });
        } else {
          $scope.dataSet = dbService.dataSet;
          $rootScope.$broadcast('dataSetLoaded');
        }
        $scope.removeDbReference = function(idx) {
          $scope.dataSet.dbReferences.splice(idx, 1);
          dbService.dataSet = $scope.dataSet;
          return dbService.cacheUpsert(function() {
            return $rootScope.$broadcast('dataSetLoaded');
          });
        };
        $scope.copyDbReference = function(idx) {
          var dbRefToCopy;

          console.debug("Copying dbReference at idx: " + idx);
          dbRefToCopy = $scope.dataSet.dbReferences[idx];
          $scope.dataSet.dbReferences.splice(idx, 0, dbRefToCopy);
          dbService.dataSet = $scope.dataSet;
          return dbService.cacheUpsert(function() {
            return $rootScope.$broadcast('dataSetLoaded');
          });
        };
        $scope.graphTypes = dbService.graphTypes;
        $scope.limits = dbService.limits;
        $scope.whereConds = dbService.whereConds;
        $scope.rangeConds = dbService.rangeConds;
        $scope.beginRangeConds = dbService.beginRangeConds;
        $scope.endRangeConds = dbService.endRangeConds;
        $scope.booleanConds = dbService.booleanConds;
        $scope.booleanOptions = dbService.booleanOptions;
        $scope.optionsSetOnField = function(dbRefIdx, fieldIdx) {
          var field, _ref, _ref1, _ref2, _ref3, _ref4;

          field = $scope.dataSet.dbReferences[dbRefIdx].fields[fieldIdx];
          if ((field.groupBy != null) && ((_ref = field.groupBy) !== (void 0) && _ref !== '')) {
            return true;
          }
          if ((field.aggregation != null) && ((_ref1 = field.aggregation) !== (void 0) && _ref1 !== '')) {
            return true;
          }
          if ((field.cond != null) && ((_ref2 = field.condValue) !== (void 0) && _ref2 !== '')) {
            return true;
          }
          if ((field.beginCond != null) && ((_ref3 = field.beginValue) !== (void 0) && _ref3 !== '')) {
            return true;
          }
          if ((field.endCond != null) && ((_ref4 = field.endValue) !== (void 0) && _ref4 !== '')) {
            return true;
          }
          return false;
        };
        $scope.groupBySetOnField = function(selectedField) {
          var _ref;

          if ((selectedField != null) && (selectedField.groupBy != null) && ((_ref = selectedField.groupBy) !== (void 0) && _ref !== '')) {
            return true;
          } else {
            return false;
          }
        };
        $scope.aggregationSetOnField = function(selectedField) {
          var _ref;

          if ((selectedField != null) && (selectedField.aggregation != null) && ((_ref = selectedField.aggregation) !== (void 0) && _ref !== '')) {
            return true;
          } else {
            return false;
          }
        };
        $scope.whereSetOnField = function(selectedField) {
          var _ref, _ref1;

          if ((selectedField != null) && (selectedField.beginValue != null) && ((_ref = selectedField.beginValue) !== (void 0) && _ref !== '')) {
            return true;
          }
          if ((selectedField != null) && (selectedField.endValue != null) && ((_ref1 = selectedField.endValue) !== (void 0) && _ref1 !== '')) {
            return true;
          }
          return false;
        };
        $scope.fieldOptionDisplay = function(selectedDbReference, fieldIdx) {
          var field, theHtml, _ref, _ref1, _ref2, _ref3, _ref4;

          field = selectedDbReference != null ? selectedDbReference.fields[fieldIdx] : void 0;
          theHtml = [];
          if (((field != null ? field.groupBy : void 0) != null) && ((_ref = field.groupBy) !== (void 0) && _ref !== '')) {
            theHtml.push("Group by " + field.groupBy);
          }
          if (((field != null ? field.aggregation : void 0) != null) && ((_ref1 = field.aggregation) !== (void 0) && _ref1 !== '')) {
            theHtml.push("Aggregate by " + field.aggregation);
          }
          if (((field != null ? field.cond : void 0) != null) && ((_ref2 = field.condValue) !== (void 0) && _ref2 !== '')) {
            theHtml.push("Field " + field.cond + " " + field.condValue);
          }
          if (((field != null ? field.beginCond : void 0) != null) && ((_ref3 = field.beginValue) !== (void 0) && _ref3 !== '')) {
            theHtml.push("Field " + field.cond + " " + field.condValue);
          }
          if (((field != null ? field.endCond : void 0) != null) && ((_ref4 = field.endValue) !== (void 0) && _ref4 !== '')) {
            theHtml.push("Field " + field.cond + " " + field.condValue);
          }
          if (theHtml.length === 0) {
            return 'Field being used.';
          } else {
            return theHtml.join(' | ');
          }
        };
        $scope.resetOtherFields = function(dbRefIdx, fieldIdx, varName) {
          var field, groupByValue;

          console.debug("Clearing " + varName + " from dbRef: " + dbRefIdx + ", except field: " + fieldIdx);
          field = $scope.dataSet.dbReferences[dbRefIdx].fields[fieldIdx];
          if (varName === 'groupBy') {
            groupByValue = field['groupBy'];
            if (groupByValue === 'multiplex') {
              return _.each($scope.dataSet.dbReferences[dbRefIdx].fields, function(field, idx) {
                if (fieldIdx !== idx && field['groupBy'] === 'multiplex') {
                  return delete field[varName];
                }
              });
            } else {
              return _.each($scope.dataSet.dbReferences[dbRefIdx].fields, function(field, idx) {
                if (fieldIdx !== idx && field['groupBy'] !== 'multiplex') {
                  return delete field[varName];
                }
              });
            }
          } else {
            return _.each($scope.dataSet.dbReferences[dbRefIdx].fields, function(field, idx) {
              if (fieldIdx !== idx) {
                return delete field[varName];
              }
            });
          }
        };
        $scope.$on('dataSetLoaded', function() {
          return dbService.queryDataSet(function(data) {
            return dbLogic.processDataSet($scope.dataSet, data, function(err, d3Data) {
              return $scope.d3DataSet = d3Data;
            });
          });
        });
        $scope.aggregationOptions = [
          {
            name: 'aggregation',
            value: void 0,
            label: 'No Selection',
            dataTypes: ['*']
          }, {
            name: 'aggregation',
            value: 'count',
            label: 'Count',
            tooltip: "COUNT(field)",
            dataTypes: dbService.countAggregationDataTypes
          }, {
            name: 'aggregation',
            value: 'distinctCount',
            label: 'Distinct Count',
            tooltip: "COUNT(DISTINCT field)",
            dataTypes: dbService.countAggregationDataTypes
          }, {
            name: 'aggregation',
            value: 'sum',
            label: 'Sum',
            tooltip: "SUM(field)",
            dataTypes: dbService.sumAggregationDataTypes
          }, {
            name: 'aggregation',
            value: 'avg',
            label: 'Avg',
            tooltip: "AVG(field)",
            dataTypes: dbService.avgAggregationDataTypes
          }
        ];
        $scope.filterByFieldDataType = function(opt) {
          var _ref;

          return _.contains(opt.dataTypes, (_ref = $scope.selectedField) != null ? _ref.DATA_TYPE : void 0) || _.contains(opt.dataTypes, '*');
        };
        $scope.groupByOptions = [
          {
            name: 'groupBy',
            value: void 0,
            label: 'No Selection',
            dataTypes: ['*']
          }, {
            name: 'groupBy',
            value: 'multiplex',
            label: 'Multiplex',
            tooltip: 'Multiplexes the x-axis over this field.',
            dataTypes: ['*']
          }, {
            name: 'groupBy',
            value: 'field',
            label: 'Field Itself',
            tooltip: 'Adds this field as the primary x axis group',
            dataTypes: ['*']
          }, {
            name: 'groupBy',
            value: 'year',
            label: 'Year',
            tooltip: "Groups on DATE_FORMAT(field, '%Y')",
            dataTypes: dbService.dateGroupByTypes
          }, {
            name: 'groupBy',
            value: 'month',
            label: 'Month',
            tooltip: "Groups on DATE_FORMAT(field, '%Y-%m')",
            dataTypes: dbService.dateGroupByTypes
          }, {
            name: 'groupBy',
            value: 'day',
            label: 'Day',
            tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d')",
            dataTypes: dbService.dateGroupByTypes
          }, {
            name: 'groupBy',
            value: 'hour',
            label: 'Hour',
            tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H')",
            dataTypes: dbService.dateGroupByTypes
          }, {
            name: 'groupBy',
            value: 'minute',
            label: 'Minute',
            tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H:%M')",
            dataTypes: dbService.dateGroupByTypes
          }, {
            name: 'groupBy',
            value: 'second',
            label: 'Second',
            tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H:%M:%S')",
            dataTypes: dbService.dateGroupByTypes
          }
        ];
        $scope.selectedReference = void 0;
        $scope.selectedField = void 0;
        $scope.selectedFieldName = void 0;
        $scope.dbRefIndex = void 0;
        $scope.fieldIndex = void 0;
        $scope.openModalForReference = function(dbRefIndex, r) {
          $scope.dbRefIndex = dbRefIndex;
          $scope.selectedReference = r;
          return $('#dbReferenceModal').modal();
        };
        $scope.openModalForField = function(dbRefIndex, r, fieldIndex, f) {
          $scope.dbRefIndex = dbRefIndex;
          $scope.fieldIndex = fieldIndex;
          $scope.selectedReference = r;
          $scope.selectedField = f;
          $scope.selectedFieldName = f['COLUMN_NAME'] != null ? f['COLUMN_NAME'] : f;
          return $('#graph_field_modal').modal();
        };
        $scope.openModalForOptions = function() {
          return $('#graph_options_modal').modal();
        };
        $scope.updateDataSet = function(graph) {
          if (graph == null) {
            graph = true;
          }
          $('#graph_field_modal').modal('hide');
          dbService.dataSet = $scope.dataSet;
          return dbService.cacheUpsert(function() {
            if (graph) {
              return $rootScope.$broadcast('dataSetLoaded');
            }
          });
        };
        $scope.deleteDataSet = function() {
          $('#graph_options_modal').modal('hide');
          return $timeout((function() {
            return dbService.cacheDelete($scope.dataSet._id, function() {
              return $location.path("/AddData/");
            });
          }), 1000);
        };
        $scope.updateMetaData = function(graph) {
          if (graph == null) {
            graph = true;
          }
          console.log("Updating graph options with graph name: " + $scope.dataSet.name);
          dbService.dataSet = $scope.dataSet;
          return dbService.cacheUpsert(function() {
            if (graph) {
              return $rootScope.$broadcast('dataSetLoaded');
            }
          });
        };
        $scope.beginValueOpened = false;
        $scope.endValueOpened = false;
        $scope.dateOptions = {
          'year-format': "'yyyy'",
          'starting-day': 1
        };
        $scope.today = function() {
          return $scope.dt = new Date();
        };
        $scope.clearBeginDate = function() {
          return $scope.beginValue = void 0;
        };
        $scope.clearEndDate = function() {
          return $scope.endValue = void 0;
        };
        $scope.openBeginDate = function() {
          return $timeout(function() {
            return $scope.beginValueOpened = true;
          });
        };
        $scope.openEndDate = function() {
          return $timeout(function() {
            return $scope.endValueOpened = true;
          });
        };
        $scope.testGraph = function() {
          dbService.queryDb($scope.connection, $scope.schema, $scope.table, $scope.fields, function(data) {
            return console.log(data);
          });
          return console.log("Test graph " + (JSON.stringify($scope.fields)));
        };
        return $scope.$apply();
      }
    ];
  });

}).call(this);

/*
//@ sourceMappingURL=graph.map
*/
