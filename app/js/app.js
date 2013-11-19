'use strict';
angular.module('ThatOneFeed', [
        'ngRoute',
        'ThatOneFeed.filters',
        'ThatOneFeed.services',
        'ThatOneFeed.directives',
        'ThatOneFeed.controllers'
    ])
    .config(['$routeProvider', function ($routeProvider) {
        $routeProvider.when('/', {templateUrl: 'partials/home.html', controller: 'HomeCtrl'});
        $routeProvider.when('/view', {templateUrl: 'partials/viewer.html', controller: 'ViewerCtrl'});
        $routeProvider.otherwise({redirectTo: '/'});
    }]);
