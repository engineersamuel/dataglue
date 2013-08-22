// http://iffycan.blogspot.com/2013/05/angular-service-or-factory.html
//If you want your function to be called like a normal function, use factory. If you want your function to be instantiated with the new operator, use service. If you don't know the difference, use factory.

define(['angular', 'jquery', 'pnotify'], function (angular, $) {
	'use strict';
	
	angular.module('dataGlue.services', [])
        .value('version', '0.1')
        .service('sharedProperties', function () {
            return {
                foo: 'bar'
            };
        })
        .factory('notificationService', ['$http', function($http){
            return {
                notify: function(hash) {
                    hash.opacity = .8;
                    hash.nonblock = true;
                    hash.nonblock_opacity = .2;
                    $.pnotify(hash);
                }
            };
        }])
        .factory('schemaService', ['$http', 'notificationService', function($http, notificationService){
            return {
                get: function(ref, callback){
                    $http.get('/db/info', {ref: ref})
                        .success(function(data) { callback(data); })
                        .error(function(data, status, headers, config) {
                            notificationService.notify({
                                title: 'Request Error',
                                text: 'There was a ' + status + ' accessing ' + config.url,
                                type: 'error',
                                icon: false
                            });
                        });
                }
            };
        }])
        .factory('connectionService', ['$http', 'notificationService', function($http, notificationService) {
            return {
                get: function(ref, callback) {
                    $http.get(ref)
                        .success(function(data) { callback(data); })
                        .error(function(data, status, headers, config) {
                            // console.log("data: " + data);
                            // console.log("status: " + status);
                            // console.log("config: " + JSON.stringify(config));
                            notificationService.notify({
                                title: 'Request Error',
                                text: 'There was a ' + status + ' accessing ' + config.url,
                                type: 'error',
                                icon: false
                            });
                        });
                }
            };
        }]);
});