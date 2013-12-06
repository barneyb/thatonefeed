angular.module("ThatOneFeed.controllers", [])
.controller("SplashCtrl", ["$scope", "$location", "profile", "dataUrl", "qs", ($scope, $location, profile, dataUrl, qs) ->
        $scope.authUrl = dataUrl("auth")
        profile.get().then (d) ->
            $location.path "/view"

        passback = (target) ->
            if window.opener
                window.opener.location.hash = "#" + target
                window.close()
            else
                $location.path target

        q = qs()
        if q.code
            profile.auth(q.code).then ->
                passback "/view"
        else if q.error
            passback "/decline"
    ])
.controller("LogoutCtrl", ["$location", "profile", ($location, profile) ->
        profile.logout().then ->
            $location.url "/"
    ])
.controller("BodyCtrl", ["$window", "$element", "$scope", ($window, $element, $scope) ->
        $scope.down = (e) ->
            $scope.$broadcast "keydown", e
        $scope.press = (e) ->
            if e.keyCode == 32
                # it's a space
                if e.shiftKey
                    # trying to scroll up
                    if $element.scrollTop() > 0
                        # there is room, don't $broadcast
                        return
                else
                    # trying to scroll down
                    if $element[0].scrollHeight - $window.innerHeight > $element.scrollTop()
                        # there is room, don't $broadcast
                        return
            $scope.$broadcast "key", e
        $scope.up = (e) ->
            $scope.$broadcast "keyup", e
    ])
.controller("PageCtrl", ["$routeParams", "$templateCache", "$scope", ($routeParams, $templateCache, $scope) ->
        pageId = $routeParams.pageId
        partial = "partials/" + pageId + ".html"
        if pageId.indexOf("_") != 0 && $templateCache.get(partial)
            $scope.templateUrl = partial
        else
            $scope.templateUrl = null
    ])
.controller("NavCtrl", ["$routeParams", "$location", "$interval", "$scope", "categories", "prefs", ($routeParams, $location, $interval, $scope, cats, prefs) ->
        lastItemId = null
        setCats = (cats) ->
            $scope.categories = cats.filter (it) ->
                it.unreadCount? && it.unreadCount > 0
            if $scope.categories? && $scope.categories.length == 0
                $scope.categories = cats

        $scope.streamId = $routeParams.streamId
        $scope.categories = []
        $scope.open = (id) ->
            $scope.streamId = id
            $location.path "/view/" + encodeURIComponent(id)

        $scope.activeClass = (id) ->
            (if $scope.streamId is id then "active" else null)

        $scope.$on "item-read", (e, item) ->
            return if item.id == lastItemId
            lastItemId = item.id
            for c in $scope.categories
                if c.id == $scope.streamId
                    c.unreadCount -= 1 if c.unreadCount?
                    break

        cats.get().then setCats, (data) ->
            console.log "error loading categories", data
        , setCats

        countInterval = $interval ->
            cats.counts().then setCats
        , 1000 * 30

        $scope.$on "$destroy", ->
            $interval.cancel(countInterval)

        # help stuff
        escDereg = null
        escHandler = (e, ke) ->
            switch ke.keyCode
                when 27 # ESC
                    hideHelp()

        showHelp = ->
            $scope.showHelp = true
            escDereg = $scope.$on "keydown", escHandler

        hideHelp = ->
            $scope.showHelp = false
            if escDereg
                escDereg()

        toggleHelp = ->
            if $scope.showHelp
                hideHelp()
            else
                showHelp()

        $scope.showHelp = false
        $scope.clickHelp = toggleHelp

        $scope.$on "key", (e, ke) ->
            switch ke.keyCode
                when 63 # ?
                    toggleHelp()

        prefs.get().then (p) ->
            if p.showHelp != "0"
                showHelp()
                p.showHelp = "0"
                prefs.set(p)

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
                # for j, k and space, the SHIFT key reverses behaviour
                when 32 # SPACE
                    $scope[(if ke.shiftKey then "previous" else "next")]()
                    ke.stopImmediatePropagation()
                    ke.stopPropagation()
                    ke.preventDefault()
                when 75, 106 # K, j
                    $scope.next()
                when 74, 107 # J ,k
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
                        $scope.$broadcast("item-read", $scope.item)

        $scope.$on "$destroy", ->
            $scope.streamId = null

        sync()
    ])
