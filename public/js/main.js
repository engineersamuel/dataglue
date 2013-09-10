// main.js
require.config({
    baseUrl: 'js',
    paths: {
        jquery: 'bower_components/jquery/jquery',
        'jquery-bridget': 'bower_components/jquery-bridget/jquery.bridget',
        angular: 'bower_components/angular/angular',
        'angular-route': 'bower_components/angular-route/angular-route',
        'angular-animate': 'bower_components/angular-animate/angular-animate',
        'angular-resource': 'bower_components/angular-resource/angular-resource',
        'ui-bootstrap': 'bower_components/angular-bootstrap/ui-bootstrap-tpls',
        text: 'bower_components/require/text',
        bootstrap: 'bower_components/bootstrap/dist/js/bootstrap',
        base64: 'bower_components/requirejs-base64/base64',
        underscore: 'bower_components/lodash/lodash',
        moment: 'bower_components/momentjs/moment',
        pnotify: 'bower_components/pines-notify/jquery.pnotify', // https://github.com/sciactive/pnotify
        d3: 'bower_components/d3/d3',
        nv: 'bower_components/nvd3/nv.d3',
        dbLogic: 'db/dbLogic'

        //pnotify: 'https://raw.github.com/sciactive/pnotify/master/jquery.pnotify.min'

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // masonry related
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // http://stackoverflow.com/questions/17763828/how-to-use-masonry-3-0-with-require-and-bower
//        eventie: 'bower_components/eventie',
//        'doc-ready': 'bower_components/doc-ready',
//        eventEmitter: 'bower_components/eventEmitter',
//        'get-style-property': 'bower_components/get-style-property',
//        'get-size': 'bower_components/get-size',
//        'matches-selector': 'bower_components/matches-selector',
//        outlayer: 'bower_components/outlayer',
//        masonry: 'bower_components/masonry/masonry'
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    },
    shim: {
        angular : {'exports' : 'angular'},
        angularMocks: {deps:['angular'], 'exports':'angular.mock'},
        'angular-route': ['angular'],
        'angular-animate': ['angular'],
        'angular-resource': ['angular'],
        'ui-bootstrap': ['angular'],
        bootstrap: ['jquery'],
        pnotify: ['jquery'],
        d3: { exports: 'd3' },
        nv: { deps:['d3'], exports: 'nv'}

//        masonry: ['jquery']
//        'angular-masonry': ['angular', 'masonry']
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
