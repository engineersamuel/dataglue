// http://iffycan.blogspot.com/2013/05/angular-service-or-factory.html
//If you want your function to be called like a normal function, use factory. If you want your function to be instantiated with the new operator, use service. If you don't know the difference, use factory.

define(['angular', 'jquery', 'underscore', 'pnotify'], function (angular, $, _) {
    'use strict';

    angular.module('dataGlue.services', [])
        .value('version', '0.1')
        .service('sharedProperties', function () {
            return {
                foo: 'bar'
            };
        })
        // http://pinesframework.org/pnotify/
        .factory('notificationService', ['$http', function($http){
            return {
                notify: function(hash) {
                    hash.opacity = .8;
                    hash.nonblock = true;
                    hash.nonblock_opacity = .2;
                    hash.cornerclass = 'ui-pnotify-sharp';
                    hash.history = false; // Remove the upper right redisplay
                    $.pnotify(hash);
                }
            };
        }])
        .factory('dbService', ['$http', 'notificationService', function($http, notificationService) {
            var onError = function(data, status, headers, config) {
                var theHtml = 'There was a ' + status + ' accessing ' + config.url;
                if(_.has(data, 'sqlState')) {
                    theHtml  = '<p><b>code:</b> ' + data.code + '</p>'
                    theHtml += '<p><b>errno:</b> ' + data.errno + '</p>'
                    theHtml += '<p><b>sqlState:</b> ' + data.sqlState + '</p>'
                    theHtml += '<p><b>index:</b> ' + data.index + '</p>'
                }
                notificationService.notify({
                    title: 'Request Error',
                    text: 'There was a ' + status + ' accessing ' + config.url,
                    type: 'error',
                    icon: false
                });
            };
            var service = {};
            //----------------------------------------------------------------------------------------------------------
            // Define data types to filter the various group by options
            //----------------------------------------------------------------------------------------------------------
            // Date group by types -- Data types that can be grouped by date
            service.dateGroupByTypes = ['date', 'datetime'];
            // Field group by types -- Data types that can be grouped by field
            service.fieldGroupByTypes = ['int', 'varchar', 'text'];
            // Multiplex group by types -- Data types that can be multiplexed
            service.multiplexGroupByTypes = ['int', 'varchar', 'text'];

            //----------------------------------------------------------------------------------------------------------
            // Define data types to filter the aggregation options
            //----------------------------------------------------------------------------------------------------------
            // This says that any field can be counted over
            service.countAggregationDataTypes = ['*'];
            // Sum/avg only numerical fields
            service.avgAggregationDataTypes = ['numerical', 'number', 'int', 'tinyint', 'float', 'decimal', 'double'];
            service.sumAggregationDataTypes = service.avgAggregationDataTypes;

            // Graph types
            service.limits = [
                {name: 'limit', value: null, label: 'No Limit'},
                {name: 'limit', value: 500, label: '500'},
                {name: 'limit', value: 1000, label: '1000'},
                {name: 'limit', value: 2000, label: '2000'}
            ];

            // Graph types -- range: true allows for filtering if the condition is specific just to a range
            service.whereConds = [
                {name: 'cond', value: 'equal', label: '='},
                {name: 'cond', value: 'notEqual', label: '!='},
                {name: 'cond', value: 'like', label: 'Like'},
                {name: 'cond', value: 'gt', label: '>', range: true, begin: true},
                {name: 'cond', value: 'gte', label: '>=', range: true, begin: true},
                {name: 'cond', value: 'lt', label: '<', range: true, end: true},
                {name: 'cond', value: 'lte', label: '<=', range: true, end: true }
            ];
            service.rangeConds = _.where(service.whereConds, {range: true});
            service.beginRangeConds = _.where(service.whereConds, {range: true, begin: true});
            service.endRangeConds = _.where(service.whereConds, {range: true, end: true});

            // Graph types
            service.graphTypes = [
                {name: 'graphType', value: 'multiBarChart', label: 'MultiBar (Default)'},
                {name: 'graphType', value: 'stackedAreaChart', label: 'Stacked Area'},
                {name: 'graphType', value: 'bubble', label: 'Bubble'},
                {name: 'graphType', value: 'pie', label: 'Pie'}
            ];

            // Eventually supporting changing to a specified datatype, but only a restricted set so don't have to
            // Cover all database types.
            // Field Data types
            // Example mysql data types
//            [   {'DATA_TYPE': 'varchar'},
//                {'DATA_TYPE': 'bigint'},
//                {'DATA_TYPE': 'longtext'},
//                {'DATA_TYPE': 'datetime'},
//                {'DATA_TYPE': 'int'},
//                {'DATA_TYPE': 'decimal'},
//                {'DATA_TYPE': 'tinyint'},
//                {'DATA_TYPE': 'text'},
//                {'DATA_TYPE': 'date'},
//                {'DATA_TYPE': 'float'}]
//            service.dataTypes = [
//                {name: 'fieldDataType', value: 'bigint', label: 'Big int'},
//                {name: 'fieldDataType', value: 'date', label: 'Date'},
//                {name: 'fieldDataType', value: 'decimal', label: 'Decimal'},
//                {name: 'fieldDataType', value: 'int', label: 'Int'},
//                {name: 'fieldDataType', value: 'longtext', label: 'Long Text'},
//                {name: 'fieldDataType', value: 'text', label: 'Text'},
//                {name: 'fieldDataType', value: 'tinyint', label: 'Tiny int'},
//                {name: 'fieldDataType', value: 'varchar', label: 'Varchar'}
//            ];

            // Dataset represents the set of data that comprises the graph
            service.dataSet = {};
            service.resetDataSet = function() {
                service.dataSet = {
                    _id: undefined,
                    name: undefined,
                    description: undefined,
                    graphType: 'multiBarChart',
                    inserted_on: undefined,
                    last_updated: undefined,
                    dbReferences: []
                };
            };

            // Go ahead and init the dataSet
            service.resetDataSet();

            service.selectedConnection = undefined;
            service.selectedSchema = undefined;
            service.selectedTable = undefined;
            service.fields = undefined;
            service.getAllDbInfo = function(callback) {
                $http.get('/db/infos')
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            service.getConnections = function(ref, callback) {
                $http.get(ref)
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            service.getSchemas = function(ref, callback) {
                $http.get('/db/info/' + ref)
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            service.getTables = function(ref, schema, callback) {
                $http.get('/db/info/' + ref + '/' + schema)
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            service.getFields = function(ref, schema, table, callback) {
                $http.get('/db/info/' + ref + '/' + schema + '/' + table)
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            service.queryDb = function(ref, schema, table, fields, callback) {
                // Fields contains additional options set like exclude/groupOn
                $http.post('/db/info/' + ref + '/' + schema + '/' + table, {fields: fields})
                    .success(function(data) { callback(data); })
                    .error(onError)
            };
            // Query the backend connections based on the options in the dataset
            service.queryDataSet = function(callback) {
                // Fields contains additional options set like exclude/groupOn
                $http.post('/dataset/query/', {doc: JSON.stringify(service.dataSet)})
                    .success(function(data) {
                        // Process any warnings
                        _.each(data, function (resultsHash) {
                            _.each(resultsHash, function(theHash, dbRefKey) {
                                if(_.has(theHash, 'warning')) {
                                    notificationService.notify({
                                        title: 'Warning...',
                                        text: theHash.warning,
                                        icon: false
                                    });
                                }
                            });
                        });
                        callback(data);
                    })
                    .error(onError)
            };
            service.cacheUpsert = function(callback) {
                // Fields contains additional options set like exclude/groupOn
                $http.post('/db/ref', {doc: JSON.stringify(service.dataSet)})
                    .success(function(data) {
                        // Set the cached _id
                        service.dataSet._id = data._id;
                        notificationService.notify({
                            title: 'Saved...',
                            text: 'Successfully saved the Data Set with id: ' + data._id,
                            type: 'success',
                            icon: false
                        });
                        callback(data);
                    })
                    .error(onError)
            };
            service.cacheGet = function(_id, callback) {
                // Fields contains additional options set like exclude/groupOn
                $http.get('/db/ref/' + _id, {})
                    .success(function(data) {
                        service.dataSet = data;
                        callback(data);
                    })
                    .error(onError)
            };
            service.cacheDelete = function(_id, callback) {
                // Fields contains additional options set like exclude/groupOn
                $http.post('/db/delete/ref/' + _id, {})
                    .success(function(data) {
                        service.resetDataSet();
                        callback(data);
                    })
                    .error(onError)
            };
            return service;
        }]);
//                            console.log(JSON.stringify(data));
//                            console.log(JSON.stringify(status));
//                            console.log(JSON.stringify(headers));
//                            console.log(JSON.stringify(config));
        // Doesn't work yet
//        .factory('schemaService', ['$http', '$injector', '$resource', 'notificationService', function($http, $injector,  $resource, notificationService) {
//            require(['services/schemaService'], function(schemaService) {
//                $injector.invoke(schemaService, this, {'$http': $http, '$resource': $resource, 'notificationService': notificationService });
//            });
//        }])
});