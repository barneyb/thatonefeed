angular.module("ThatOneFeed.directives", [])
.directive("tofMenu", [ ->
        restrict: "A"
        templateUrl: "partials/_sidebar.html"
    ])
.directive("itemTitle", [ ->
        restrict: "A"
        templateUrl: "partials/_entry_title.html"
    ])
.directive("autoScale", [ ->
        restrict: "A"
        controller: ['$scope', '$element', '$window', ($scope, $element, $window) ->
            rescale = ->
                w = $element.width()
                h = $element.height()
                p = $element.parent()
                pw = p.width()
                ph = p.height() * 2 - 20 # padding
                p.parent().children().each ->
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
        ]
    ])