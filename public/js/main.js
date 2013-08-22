// main.js
require.config({
    baseUrl: 'js',
    paths: {
        jquery: 'bower_components/jquery/jquery',
        'jquery-bridget': 'bower_components/jquery-bridget/jquery.bridget',
        angular: 'bower_components/angular/angular',
        'angular-route': 'bower_components/angular-route/angular-route',
        'angular-animate': 'bower_components/angular-animate/angular-animate',
        text: 'bower_components/require/text',
        bootstrap: 'bower_components/bootstrap/dist/js/bootstrap',
        base64: 'bower_components/requirejs-base64/base64',
        underscore: 'bower_components/lodash',
        pnotify: 'bower_components/pines-notify/jquery.pnotify', // https://github.com/sciactive/pnotify
        //pnotify: 'https://raw.github.com/sciactive/pnotify/master/jquery.pnotify.min'

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // masonry related
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // http://stackoverflow.com/questions/17763828/how-to-use-masonry-3-0-with-require-and-bower
        eventie: 'bower_components/eventie',
        'doc-ready': 'bower_components/doc-ready',
        eventEmitter: 'bower_components/eventEmitter',
        'get-style-property': 'bower_components/get-style-property',
        'get-size': 'bower_components/get-size',
        'matches-selector': 'bower_components/matches-selector',
        outlayer: 'bower_components/outlayer',
        masonry: 'bower_components/masonry/masonry',
        imagesloaded: 'bower_components/imagesloaded/imagesloaded',
        'angular-masonry': 'lib/angular-masonry/angular-masonry'  //http://passy.github.io/angular-masonry/
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    },
    shim: {
        angular : {'exports' : 'angular'},
        angularMocks: {deps:['angular'], 'exports':'angular.mock'},
        'angular-route': ['angular'],
        'angular-animate': ['angular'],
        bootstrap: ['jquery'],
        pnotify: ['jquery'],
        masonry: ['jquery'],
        "imagesloaded": ["jquery"],
        'angular-masonry': ['angular', 'masonry']
        // Maybe add in a shim for underscore -> _
    },
    priority: [
        "angular"
    ],
    // http://stackoverflow.com/questions/8315088/prevent-requirejs-from-caching-required-scripts
    urlArgs: "bust=" + (new Date()).getTime()
    // urlArgs: "bust=v2" // prod
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
