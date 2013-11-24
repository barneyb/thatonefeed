'use strict';
angular.module('ThatOneFeed.directives', [])
    .directive('tofMenu', [function() {
        return {
            restrict: 'E',
            templateUrl: 'partials/_menu.html'
        };
    }])
    .directive("itemTitle", [function() {
        return {
            restrict: 'E',
            template: '<span class="save" ng-click="toggleSaved()" ng-class="saveClass()">save</span> <a href="{{item.link}}">{{item.title}}</a> <span class="origin">{{item.origin}}</span>'
        };
    }])
    .directive('appVersion', ['version', function (version) {
        return function (scope, elm, attrs) {
            elm.text(version);
        };
    }]);
