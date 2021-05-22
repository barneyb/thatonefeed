angular.module("ThatOneFeed.directives", [])
    .directive("tofMenu", [() => ({
        restrict: "A",
        templateUrl: "partials/_sidebar.html",
        controller: ["$scope", "$location", "profile", function tofMenuCtrl(
            $scope,
            $location,
            profile,
        ) {
            $scope.name = null;
            $scope.feedlyUrl = null;
            $scope.year = new Date().getFullYear();
            profile.get().then(
                p => {
                    $scope.name = p.givenName;
                    $scope.feedlyUrl = p.apiRoot;
                },
                () => $location.path("/"),
            );
        }],
    })])
    .directive("itemTitle", [() => ({
        restrict: "A",
        templateUrl: "partials/_entry_title.html",
    })])
    .directive("maximizeImage", [() => ({
        restrict: "A",
        controller: ['$scope', '$element', '$window', function maximizeImageCtrl(
            $scope,
            $element,
            $window,
        ) {
            function rescale() {
                const w = $element.width();
                const h = $element.height();
                const p = $element.parents(".item").first();
                const pw = p.width();
                let ph = (p.height() + h) - 10; // padding
                p.children().each(function () {
                    ph -= angular.element(this).height()
                });
                const factor = Math.min(3, Math.min(
                    pw / w,
                    $window.innerWidth <= 800
                        ? 1000
                        : ph / h,
                ));
                if ($scope.zoom || factor < 1) {
                    $element.width(Math.floor(w * factor) + "px")
                        .height(Math.floor(h * factor) + "px");
                } else {
                    $element.width("auto").height("auto");
                }
                $element.removeClass("loading");
            }

            $element.on("$destroy", () =>
                $element.unbind("load", rescale));
            $element.bind("load", rescale);

            $scope.$on("$destroy", $scope.$on("unscale", () =>
                $element.addClass("loading").width("auto").height("auto")));

            $scope.$on("$destroy", $scope.$on("rescale", rescale));

            $scope.$on("$destroy", () =>
                angular.element($window).unbind("resize", rescale));
            angular.element($window).bind("resize", rescale);
        }],
    })])
    .directive("scaledImageContainer", [() => ({
        restrict: "A",
        controller: ['$timeout', '$scope', '$element', function scaledImageContainerCtrl(
            $timeout,
            $scope,
            $element,
        ) {
            function rescale() {
                const nw = this.naturalWidth;
                const nh = this.naturalHeight;

                // iframe gives undefined, so use === against null
                if (nw === null || nw === 0 || nh === null || nh === 0) return;

                const e = angular.element(this);
                if (nw < 200 && nh < 200) {
                    e.addClass("hide");
                    return;
                }

                const w = e.width();
                const h = e.height();
                const pw = $element.width(); // .raw-html's width
                const ph = $element.parents("#content").height() * 0.75; // 75% #content's height
                const factor = Math.min(3, Math.min(pw / w, ph / h));
                e.addClass("show")
                    .width(Math.floor(w * factor) + "px")
                    .height(Math.floor(h * factor) + "px");
            }

            $scope.$watch('item', it => {
                if (it !== null) {
                    $timeout(() => {
                        const es = $element.find("img, iframe");
                        es.on("$destroy", () =>
                            es.unbind("load", rescale));
                        es.bind("load", rescale);
                        es.each(rescale);
                    });
                }
            });
        }],
    })])
    .directive("oauthTrigger", [() => ({
        restrict: "A",
        controller: ["$window", "$element", function oauthTriggerCtrl(
            $window,
            $element,
        ) {
            function handler(e) {
                const width = 500;
                const height = 700;
                const left = ($window.innerWidth - width) / 2;
                const top = ($window.innerHeight - height) / 2;
                $window.open(
                    $element.attr("href"),
                    "thatonefeed_oauth",
                    `height=${height},width=${width},top=${top},left=${left},location=0,menubar=0,resizable=0,scrollbars=0,status=0,titlebar=0,toolbar=0,`,
                    "replace",
                );
                e.stopImmediatePropagation();
                e.stopPropagation();
                e.preventDefault();
                return false;
            }

            $element.on("$destroy", () =>
                $element.unbind("click", handler));
            $element.bind("click", handler);
        }],
    })])
    .directive("sideClick", [() => ({
        restrict: "A",
        controller: ["$element", "$scope", function sideClickCtrl(
            $element,
            $scope,
        ) {
            function handler(e) {
                const pos = e.offsetX / $element.width();
                if (pos <= 0.25) {
                    $scope.$emit("click-left", e);
                } else if (pos >= 0.75) {
                    $scope.$emit("click-right", e);
                }
            }

            $element.on("$destroy", () =>
                $element.unbind("click", handler));
            $element.bind("click", handler);
        }],
    })])
    .directive("touchClass", [() => ({
        restrict: "A",
        controller: ["$element", "$scope", function touchClassCtrl(
            $element,
            $scope,
        ) {
            function addClass() {
                $element.addClass("touch");
            }

            $element.on("$destroy", () => $element.unbind("click", addClass));
            $element.bind("click", addClass);

            $scope.$on("$destroy", $scope.$on("click", () =>
                $element.removeClass("touch")));
        }],
    })]);
