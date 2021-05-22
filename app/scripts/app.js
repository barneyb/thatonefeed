"use strict";
angular.module("ThatOneFeed", [
    "ngRoute",
    "ThatOneFeed.filters",
    "ThatOneFeed.resources",
    "ThatOneFeed.services",
    "ThatOneFeed.directives",
    "ThatOneFeed.controllers",
])
    .factory("config", ["$window", function configFactory($window) {
        const config = $window.ThatOneFeed;
        return () => config;
    }])
    .config(["$routeProvider", function $routeProvider($router) {
        $router.when("/", {
            templateUrl: "partials/splash.html",
            controller: "SplashCtrl",
        });

        $router.when("/logout", {
            templateUrl: "partials/splash.html",
            controller: "LogoutCtrl",
        });

        $router.when("/decline", { // when the oauth loop fails for whatever reason - the server sends people here
            templateUrl: "partials/decline.html",
            controller: "SplashCtrl",
        });

        $router.when("/view", {
            templateUrl: "partials/pick-view.html",
            controller: "PickViewCtrl",
        });

        $router.when("/view/:type/:name", {
            templateUrl: "partials/view.html",
            controller: "ViewCtrl",
        });

        $router.when("/page/:pageId", {
            templateUrl: "partials/_page.html",
            controller: "PageCtrl",
        });

        $router.otherwise({
            redirectTo: "/",
        });
    }])
    .run(['$window', '$location', '$rootScope', function main(
        $window,
        $location,
        $rootScope,
    ) {
        $rootScope.pageTitle = 'That One Feed';
        $rootScope.$on('page.title', (e, title) =>
            $rootScope.pageTitle = title != null
                ? `1Feed : ${title}`
                : 'That One Feed');

        $rootScope.$on('ga.page', (e, data) => {
            if ($window.ga != null) {
                if (data == null) {
                    data = {};
                }
                if (data.page == null) {
                    data.page = $location.path();
                }
                if (data.entry_source != null) {
                    data.dimension2 = data.entry_source;
                    delete data.entry_source;
                }
                return $window.ga('send', 'pageview', data);
            }
        });

        $rootScope.$on('$routeChangeSuccess', () =>
            $rootScope.$emit('ga.page'));
    }]);
