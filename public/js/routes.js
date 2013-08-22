define(['angular', 'app'], function(angular, app) {
    'use strict';

    return app.config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
        $routeProvider.when('/AddData', {
            templateUrl: 'partials/addData.html',
            controller: 'AddData'
        });
        $routeProvider.when('/view1', {
            templateUrl: 'partials/partial1.html',
            controller: 'MyCtrl1'
        });
        $routeProvider.when('/view2', {
            templateUrl: 'partials/partial2.html',
            controller: 'MyCtrl2'
        });
        $routeProvider.when('/mysqlTest', {
            templateUrl: 'partials/mysqlTest.html',
            controller: 'MysqlTest'
        });
        $routeProvider.otherwise({redirectTo: '/AddData'});
    }]);

});
