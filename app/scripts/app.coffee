"use strict"
angular.module("ThatOneFeed", [
        "ngRoute",
        "ThatOneFeed.filters",
        "ThatOneFeed.resources",
        "ThatOneFeed.services",
        "ThatOneFeed.directives",
        "ThatOneFeed.controllers"
    ])
.config(["$routeProvider", ($routeProvider) ->
        $routeProvider.when "/",
            templateUrl: "partials/splash.html"
            controller: "SplashCtrl"

        $routeProvider.when "/decline", # when the oauth loop fails for whatever reason - the server sends people here
            templateUrl: "partials/decline.html"

        $routeProvider.when "/view",
            templateUrl: "partials/stream.html"
            controller: "ViewerCtrl"

        $routeProvider.when "/view/:streamId",
            templateUrl: "partials/stream.html"
            controller: "StreamCtrl"

        $routeProvider.otherwise
            redirectTo: "/"
    ])