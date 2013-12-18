angular.module("ThatOneFeed.directives", [])
.directive("tofMenu", [ ->
        restrict: "A"
        templateUrl: "partials/_sidebar.html",
        controller: ["$scope", "$location", "profile", ($scope, $location, profile) ->
            $scope.name = null
            $scope.feedlyUrl = null
            profile.get().then (p) ->
                $scope.name = p.givenName
                $scope.feedlyUrl = p.apiRoot
            , ->
                $location.path "/"

        ]
    ])
.directive("itemTitle", [ ->
        restrict: "A"
        templateUrl: "partials/_entry_title.html"
    ])
.directive("maximizeImage", [ ->
        restrict: "A"
        controller: ['$scope', '$element', '$window', ($scope, $element, $window) ->
            rescale = ->
                w = $element.width()
                h = $element.height()
                p = $element.parents(".item").first()
                pw = p.width()
                ph = p.height() + h - 10 # padding
                p.children().each ->
                    ph -= angular.element(this).height()
                factor = Math.min(3, Math.min(pw / w, ph / h))
                if $scope.zoom or factor < 1
                    $element.width(Math.floor(w * factor) + "px").height(Math.floor(h * factor) + "px")
                else
                    $element.width("auto").height("auto")
                $element.removeClass("loading")

            angular.element($window).bind "resize", rescale

            $element.bind "load", rescale

            $scope.$on "unscale", ->
                $element.addClass("loading").width("auto").height("auto")

            $scope.$on "rescale", rescale

            $scope.$on "$destroy", ->
                angular.element($window).unbind "resize", rescale
        ]
    ])
.directive("scaledImageContainer", [ ->
        restrict: "A",
        controller: ['$timeout', '$element', ($timeout, $element) ->
            rescale = ->
                nw = @naturalWidth
                nh = @naturalHeight

                # iframe gives undefined, so use === against null
                return if nw is null or nw is 0 or nh is null or nh is 0

                e = angular.element(this)
                if nw < 200 and nh < 200
                    e.addClass "hide"
                    return

                w = e.width()
                h = e.height()
                pw = $element.width() # .raw-html's width
                ph = $element.parents("#content").height() * 0.75 # 75% #content's height
                factor = Math.min(3, Math.min(pw / w, ph / h))
                e.addClass("show").width(Math.floor(w * factor) + "px").height(Math.floor(h * factor) + "px")

            $timeout ->
                es = $element.find("img, iframe")
                es.bind "load", rescale
                for e in es
                    rescale.call(e)
        ]
    ])
.directive("oauthTrigger", [ ->
        restrict: "A",
        controller: ["$window", "$element", ($window, $element) ->
            $element.bind "click", (e) ->
                width = 500
                height = 700
                left = ($window.innerWidth - width) / 2
                top = ($window.innerHeight - height) / 2
                $window.open($element.attr("href"), "thatonefeed_oauth", "height=#{height},width=#{width},top=#{top},left=#{left},location=0,menubar=0,resizable=0,scrollbars=0,status=0,titlebar=0,toolbar=0,", "replace")
                e.stopImmediatePropagation()
                e.stopPropagation()
                e.preventDefault()
                false
        ]
    ])
.directive("sideClick", [ ->
        restrict: "A",
        controller: ["$element", "$scope", ($element, $scope) ->
            $element.bind "click", (e) ->
                pos = e.offsetX / $element.width()
                if pos <= 0.25
                    $scope.$emit "click-left", e
                else if pos >= 0.75
                    $scope.$emit "click-right", e
        ]
    ])