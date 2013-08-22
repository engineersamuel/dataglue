define(['angular', 'services'], function(angular, services) {
	'use strict';

	angular.module('dataGlue.directives', ['dataGlue.services'])
		.directive('appVersion', ['version', function(version) {
			return function(scope, elm, attrs) {
				elm.text(version);
		};
	}]);
});