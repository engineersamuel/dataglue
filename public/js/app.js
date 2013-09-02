define([
    'angular',
    'filters',
    'services',
    'directives',
    'controllers',
    'angular-route',
    'angular-animate',
    'angular-resource',
    'ui-bootstrap'
    ], function (angular, filters, services, directives, controllers) {
        'use strict';
        return angular.module('dataGlue', ['ngRoute', 'ngAnimate', 'ngResource', 'dataGlue.controllers', 'dataGlue.filters', 'dataGlue.services', 'dataGlue.directives', 'ui.bootstrap']);
});
