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
            templateUrl: "partials/pick-view.html"
            controller: "PickViewCtrl"

        $router.when "/view/:type/:name",
            templateUrl: "partials/view.html"
            controller: "ViewCtrl"

        $router.when "/flatten/:title?/:url",
            templateUrl: "partials/stream.html"
            controller: "FlattenCtrl"

        $router.when "/page/:pageId",
            templateUrl: "partials/_page.html"
            controller: "PageCtrl"

        $router.otherwise
            redirectTo: "/"
    ])
.run(['$window', '$location', '$rootScope', ($window, $location, $rootScope) ->
        if $window.ga?
            $rootScope.$on '$routeChangeSuccess', ->
                $window.ga 'send', 'pageview', $location.path()
    ])