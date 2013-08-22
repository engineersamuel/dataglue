define(['angular', 'services'], function (angular) {
    'use strict';

    return angular.module('dataGlue.controllers', ['dataGlue.services'])
        // Sample controller where service is being used
        .controller('MyCtrl1', ['$scope', 'version', function ($scope, version) {
            $scope.scopedAppVersion = version;
        }])
        // More involved example where controller is required from an external file
        .controller('MyCtrl2', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/myctrl2'], function(myctrl2) {
                // injector method takes an array of modules as the first argument
                // if you want your controller to be able to use components from
                // any of your other modules, make sure you include it together with 'ng'
                // Furthermore we need to pass on the $scope as it's unique to this controller
                $injector.invoke(myctrl2, this, {'$scope': $scope});
            });
        }])
        .controller('MyCtrl3', ['$scope', function ($scope) {
            function genBrick() {
                return {
                    src: 'http://lorempixel.com/g/400/200/?' + ~~(Math.random() * 10000)
                };
            }

            $scope.bricks = [
                genBrick(),
                genBrick(),
                genBrick()
            ];

            $scope.add = function add() {
                $scope.bricks.push(genBrick());
            };

            $scope.remove = function remove() {
                $scope.bricks.splice(
                    ~~(Math.random() * $scope.bricks.length),
                    1
                )
            };
        }])
        // More involved example where controller is required from an external file
        .controller('MysqlTest', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/mysqlTest'], function(mysqlTest) {
                // injector method takes an array of modules as the first argument
                // if you want your controller to be able to use components from
                // any of your other modules, make sure you include it together with 'ng'
                // Furthermore we need to pass on the $scope as it's unique to this controller
                $injector.invoke(mysqlTest, this, {'$scope': $scope});
            });
        }])
        // More involved example where controller is required from an external file
        .controller('AddData', ['$scope', '$injector', function($scope, $injector) {
            require(['controllers/addData'], function(addData) {
                // injector method takes an array of modules as the first argument
                // if you want your controller to be able to use components from
                // any of your other modules, make sure you include it together with 'ng'
                // Furthermore we need to pass on the $scope as it's unique to this controller
                $injector.invoke(addData, this, {'$scope': $scope});
            });
        }]);
});
