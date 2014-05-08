"use strict"
angular.module("ThatOneFeed", [
        "ngRoute",
        "ThatOneFeed.filters",
        "ThatOneFeed.resources",
        "ThatOneFeed.services",
        "ThatOneFeed.directives",
        "ThatOneFeed.controllers"
    ])
.config(["$routeProvider", ($router) ->
        $router.when "/",
            templateUrl: "partials/splash.html"
            controller: "SplashCtrl"

        $router.when "/logout",
            templateUrl: "partials/splash.html"
            controller: "LogoutCtrl"

        $router.when "/decline", # when the oauth loop fails for whatever reason - the server sends people here
            templateUrl: "partials/decline.html"
            controller: "SplashCtrl"

        $router.when "/view",
            templateUrl: "partials/stream.html"
            controller: "ViewerCtrl"

        $router.when "/view/:streamId",
            templateUrl: "partials/stream.html"
            controller: "StreamCtrl"

        $router.when "/flatten/:title?/:url",
            templateUrl: "partials/stream.html"
            controller: "FlattenCtrl"

        $router.when "/page/:pageId",
            templateUrl: "partials/_page.html"
            controller: "PageCtrl"

        $router.otherwise
            redirectTo: "/"
    ])