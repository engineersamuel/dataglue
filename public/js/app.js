define([
    'angular',
    'filters',
    'services',
    'directives',
    'controllers',
    'angular-masonry',
    'angular-route',
    'angular-animate'
    ], function (angular, filters, services, directives, controllers) {
        'use strict';
        return angular.module('dataGlue', ['ngRoute', 'ngAnimate', 'wu.masonry', 'dataGlue.controllers', 'dataGlue.filters', 'dataGlue.services', 'dataGlue.directives']);
});
