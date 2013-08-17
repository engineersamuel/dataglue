require.config({
	paths: {
        jquery: 'lib/jquery/jquery-2.0.3',
		angular: 'lib/angular/angular',
		text: 'lib/require/text',
        bootstrap: 'lib/bootstrap/bootstrap'
	},
	baseUrl: 'js',
	shim: {
		'angular' : {'exports' : 'angular'},
		'angularMocks': {deps:['angular'], 'exports':'angular.mock'},
        'bootstrap': ["jquery"]
	},
	priority: [
		"angular"
	]
});

require([
	'angular',
	'app',
	'routes',
    'bootstrap'
], function(angular, app, routes) {
	'use strict';
		angular.bootstrap(document, [app['name']]);
});
