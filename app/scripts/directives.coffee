angular.module("ThatOneFeed.directives", [])
.directive("tofMenu", [ ->
        restrict: "A"
        templateUrl: "partials/_sidebar.html"
    ])
.directive("itemTitle", [ ->
        restrict: "A"
        templateUrl: "partials/_entry_title.html"
    ])