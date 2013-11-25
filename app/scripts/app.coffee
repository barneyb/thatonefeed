"use strict"
angular.module("ThatOneFeed", [
        "ngRoute",
        "ThatOneFeed.filters",
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
            templateUrl: "partials/viewer.html"

        $routeProvider.when "/view/:streamId",
            templateUrl: "partials/stream.html"
            controller: "StreamCtrl"

        $routeProvider.otherwise
            redirectTo: "/"
    ])