angular.module("ThatOneFeed.directives", [])
.directive("tofMenu", [ ->
        restrict: "E"
        templateUrl: "partials/_menu.html"
    ])
.directive("itemTitle", [ ->
        restrict: "A"
        templateUrl: "partials/_entry_title.html"
    ])