'use strict';
angular.module('ThatOneFeed.filters', [])
    .filter('urlEncode', [function (version) {
        return function (text) {
            return encodeURIComponent(text);
        }
    }]);
