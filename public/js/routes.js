define(['angular', 'app'], function(angular, app) {
    'use strict';

    return app.config(['$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
        $routeProvider.when('/AddData/:_id?', {
            templateUrl: 'partials/addData.html',
            controller: 'AddData'
        });
        $routeProvider.when('/Graph/:_id?', {
            templateUrl: 'partials/graph.html',
            controller: 'Graph'
        });
        $routeProvider.when('/view1', {
            templateUrl: 'partials/partial1.html',
            controller: 'MyCtrl1'
        });
        $routeProvider.when('/view2', {
            templateUrl: 'partials/partial2.html',
            controller: 'MyCtrl2'
        });
        $routeProvider.when('/view3', {
            templateUrl: 'partials/partial3.html',
            controller: 'MyCtrl3'
        });
        $routeProvider.when('/mysqlTest', {
            templateUrl: 'partials/mysqlTest.html',
            controller: 'MysqlTest'
        });
        $routeProvider.otherwise({redirectTo: '/AddData/'});
    }]);

});
