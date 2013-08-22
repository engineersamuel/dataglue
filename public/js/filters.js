define(['angular', 'services'], function (angular, services) {
	'use strict';
	
	angular.module('dataGlue.filters', ['dataGlue.services'])
		.filter('interpolate', ['version', function(version) {
			return function(text) {
				return String(text).replace(/\%VERSION\%/mg, version);
			};
	}]);
});
