define(['angular', 'services'], function (angular) {
    'use strict';

    // injector method takes an array of modules as the first argument
    // if you want your controller to be able to use components from
    // any of your other modules, make sure you include it together with 'ng'
    // Furthermore we need to pass on the $scope as it's unique to this controller
    return angular.module('dataGlue.controllers', ['dataGlue.services'])
        .controller('MyCtrl1', ['$scope', 'version', function ($scope, version) {
            $scope.scopedAppVersion = version;
        }])
        // More involved example where controller is required from an external file
        .controller('MyCtrl2', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/myctrl2'], function(myctrl2) {
                $injector.invoke(myctrl2, this, {'$scope': $scope});
            });
        }])
        .controller('MyCtrl3', ['$scope', function ($scope) {
        }])
        // More involved example where controller is required from an external file
        .controller('MysqlTest', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/mysqlTest'], function(mysqlTest) {
                $injector.invoke(mysqlTest, this, {'$scope': $scope});
            });
        }])
        // More involved example where controller is required from an external file
        .controller('AddData', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/addData'], function(ctrl) {
                $injector.invoke(ctrl, this, {'$scope': $scope});
            });
        }])
        // More involved example where controller is required from an external file
        .controller('Graph', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/graph'], function(ctrl) {
                $injector.invoke(ctrl, this, {'$scope': $scope});
            });
        }]);
});
