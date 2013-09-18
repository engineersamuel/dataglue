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
                notificationService.notify({
                    title: 'Request Error',
                    text: 'There was a ' + status + ' accessing ' + config.url,
                    type: 'error',
                    icon: false
                });
            };
            var service = {};
            // Graph types
            service.graphTypes = [
                {value: 'multiBarChart', label: 'MultiBar Chart (Default)'},
                {value: 'bubble', label: 'Bubble'}
            ];

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