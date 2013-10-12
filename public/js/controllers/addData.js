// Generated by CoffeeScript 1.6.2
(function() {
  define(['jquery', 'underscore'], function($, _) {
    return [
      '$scope', '$location', '$routeParams', 'dbService', function($scope, $location, $routeParams, dbService) {
        $scope.welcomeMessage = 'Add Data';
        $scope.dataSetName = void 0;
        $scope.dataSetDescription = void 0;
        $scope.restrictionQuery = void 0;
        if ($routeParams['_id'] != null) {
          dbService.cacheGet($routeParams['_id'], function(data) {
            console.debug("Read cached dataSet: " + (JSON.stringify(data)));
            $scope.dataSetName = data.name;
            return $scope.dataSetDescription = data.description;
          });
        } else {
          dbService.resetDataSet();
        }
        $scope.connection = void 0;
        $scope.schema = void 0;
        $scope.table = void 0;
        $scope.connections = void 0;
        $scope.schemas = void 0;
        $scope.tables = void 0;
        if (!$scope.connection) {
          dbService.getConnections('/db/info', function(data) {
            return $scope.connections = data;
          });
        }
        $scope.select_connection = function(connection) {
          $scope.connection = connection;
          $scope.schemas = [];
          $scope.tables = [];
          return dbService.getSchemas($scope.connection.name, function(data) {
            return $scope.schemas = data;
          });
        };
        $scope.select_schema = function(schema) {
          $scope.schema = schema;
          $scope.tables = [];
          return dbService.getTables($scope.connection.name, $scope.schema, function(data) {
            return $scope.tables = data;
          });
        };
        $scope.addDataSet = function() {
          if ($scope.dataSetName) {
            dbService.dataSet.name = $scope.dataSetName;
          }
          if ($scope.dataSetDescription) {
            dbService.dataSet.description = $scope.dataSetDescription;
          }
          $scope.fields = [];
          return dbService.getFields($scope.connection.name, $scope.schema, $scope.table, $scope.restrictionQuery, function(data) {
            var key;

            dbService.fields = data;
            $scope.fields = data;
            key = [$scope.connection.name, $scope.schema, $scope.table].join('\u2980');
            dbService.dataSet.dbReferences.push({
              key: key,
              connection: $scope.connection.name,
              schema: $scope.schema,
              table: $scope.table,
              fields: $scope.fields,
              cache: true,
              limit: 1000,
              restrictionQuery: $scope.restrictionQuery
            });
            return dbService.cacheUpsert(function(data) {
              return $location.path("/Graph/" + data['_id']);
            });
          });
        };
        $scope.select_table = function(table) {
          $scope.table = table;
          return $('#graph_options_modal').modal();
        };
        return $scope.$apply();
      }
    ];
  });

}).call(this);

/*
//@ sourceMappingURL=addData.map
*/
