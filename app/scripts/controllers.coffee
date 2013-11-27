angular.module("ThatOneFeed.controllers", [])
.controller("SplashCtrl", ["$scope", "$location", "profile", "dataUrl", ($scope, $location, profile, dataUrl) ->
        $scope.authUrl = dataUrl("auth")
        profile.get().then (d) ->
            $location.path "/view"
    ])
.controller("LogoutCtrl", ["$location", "profile", ($location, profile) ->
        profile.logout().then ->
            $location.url "/"
    ])
.controller("KeyCtrl", ["$scope", ($scope) ->
        $scope.key = (e) ->
            $scope.$broadcast "key", e
    ])
.controller("NavCtrl", ["$location", "$scope", "categories", ($location, $scope, cats) ->
        $scope.categories = []
        $scope.open = (id) ->
            $location.path "/view/" + encodeURIComponent(id)

        $scope.activeClass = (id) ->
            (if $scope.streamId is id then "active" else null)

        cats().then ((data) ->
            $scope.categories = data
        ), (data) ->
            console.log "error loading categories", data
    ])
.controller("ViewerCtrl", ["$scope", ($scope) ->
        $scope.templateUrl = "partials/_entry_select_category.html"
    ])
.controller("StreamCtrl", ["$routeParams", "$window", "$scope", "entries", "entryRipper", "markers", ($routeParams, $window, $scope, entries, ripper, markers) ->
        index = -1
        continuation = `undefined`
        sync = ->
            $scope.item = (if index >= 0 and index < $scope.items.length then $scope.items[index] else null)
            # keep 200 items max, but retain at least 100 - 25 = 75 previous items
            if index > 100 and $scope.items.length > 200
                $scope.items.splice 0, 25
                index -= 25
            if index > $scope.items.length - 8 and continuation isnt null
                entries($scope.streamId, continuation).then ((data) ->
                    if data.id is $scope.streamId and (continuation is `undefined` or continuation isnt data.continuation)
                        continuation = (if data.continuation then data.continuation else null)
                        data.items.forEach (it) ->
                            ripper(it).then (item) ->
                                $scope.items.push item    if item
                            , (err) ->
                                console.log "error ripping entry", err
                            , (item) ->
                                $scope.items.push item
                ), (data) ->
                    console.log "error loading entries", data

        $scope.streamId = $routeParams.streamId
        $scope.items = []
        $scope.item = null
        $scope.hasNext = ->
            index < $scope.items.length

        $scope.next = ->
            if $scope.hasNext()
                index += 1
                sync()

        $scope.skipRest = ->
            if $scope.item and $scope.item.id
                idToSkip = $scope.item.id
                while $scope.hasNext()
                    $scope.next()
                    continue    if $scope.item and $scope.item.id is idToSkip
                    break

        $scope.hasPrevious = ->
            index > 0

        $scope.previous = ->
            if $scope.hasPrevious()
                index -= 1
                sync()

        $scope.saveClass = ->
            if $scope.item && $scope.item.saved then "saved" else null

        $scope.toggleSaved = ->
            if $scope.item
                if $scope.item.saved
                    markers.unsave($scope.item.id)
                        .then ->
                            $scope.item.saved = false
                else
                    markers.save($scope.item.id)
                        .then ->
                            $scope.item.saved = true

        $scope.$on "key", (e, ke) ->
            switch ke.keyCode
                when 32 # SPACE
                    $scope[(if ke.shiftKey then "previous" else "next")]()
                    ke.stopImmediatePropagation()
                    ke.stopPropagation()
                    ke.preventDefault()
                when 74, 106 # J, j
                    $scope.next()
                when 75, 107 # K ,k
                    $scope.previous()
                when 83, 115 # S, s
                    $scope.toggleSaved();
                when 68, 100 # D, d
                    $scope.skipRest()
                when 65, 97, 90, 122 # A, a, Z, z
                    $scope.zoom = ! $scope.zoom;
                    $scope.$broadcast('rescale');

        $scope.$watchCollection "items", ->
            $scope.next() if index < 0 and $scope.items.length > 0

        $scope.$watch "item", ->
            $window.scrollTo 0, 0
            $scope.$broadcast('unscale');
            $scope.zoom = true;
            $scope.templateUrl = "partials/_entry_" + (if $scope.item then $scope.item.type else if index > 0 then 'done' else 'loading') + ".html"
            if $scope.item && $scope.item.unread
                markers.read($scope.item.id)
                    .then ->
                        $scope.item.unread = false

        $scope.$on "$destroy", ->
            $scope.streamId = null

        sync()
    ])
