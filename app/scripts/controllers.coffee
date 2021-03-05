angular.module("ThatOneFeed.controllers", [])
.controller("SplashCtrl", ["$scope", "$location", "profile", "dataUrl", "qs", ($scope, $location, profile, dataUrl, qs) ->
        $scope.$emit('page.title')
        $scope.authUrl = dataUrl("auth")
        profile.get().then ->
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
        $scope.click = (e) ->
            $scope.$broadcast "click", e
    ])
.controller("PageCtrl", ["$routeParams", "$templateCache", "$scope", ($routeParams, $templateCache, $scope) ->
        pageId = $routeParams.pageId
        $scope.$emit('page.title', pageId)
        partial = "partials/" + pageId + ".html"
        if pageId.indexOf("_") != 0 && $templateCache.get(partial)
            $scope.templateUrl = partial
        else
            $scope.templateUrl = null
    ])
.controller("NavCtrl", ["$routeParams", "$location", "$interval", "$scope", "categories", ($routeParams, $location, $interval, $scope, cats) ->
        lastItemId = null
        setCats = (cats) ->
            cats.sort (a, b) ->
                return -1 if a.label < b.label
                return 1 if a.label > b.label
                0
            $scope.categories = cats.filter (it) ->
                it.id == $scope.streamId || (it.unreadCount? && it.unreadCount > 0)

        $scope.streamId = $routeParams.type + '/' + $routeParams.name
        $scope.categories = null
        $scope.open = (id) ->
            $scope.streamId = id
            $location.path "/view/" + id

        $scope.activeClass = (id) ->
            (if $scope.streamId is id then "active" else null)

        $scope.$on "$destroy", $scope.$on "item-read", (e, item) ->
            return if item.id == lastItemId
            lastItemId = item.id
            for c in $scope.categories
                if c.id == $scope.streamId
                    c.unreadCount -= 1 if c.unreadCount? && c.unreadCount > 0
                    break

        cats.get().then setCats, (data) ->
            console.log "error loading categories", data
        , setCats

        countInterval = $interval ->
            cats.counts().then setCats
        , 1000 * 30

        $scope.$on "$destroy", ->
            $interval.cancel(countInterval)
    ])
.controller("GreetingCtrl", ["$scope", "prefs", ($scope, prefs) ->
        $scope.$emit('page.title')
        escDereg = null
        escHandler = (e, ke) ->
            switch ke.keyCode
                when 27 # ESC
                    hideHelp()

        showHelp = ->
            $scope.showHelp = true
            escDereg = $scope.$on "keydown", escHandler
            $scope.$on "$destroy", escDereg

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

        $scope.$on "$destroy", $scope.$on "key", (e, ke) ->
            switch ke.keyCode
                when 63 # ?
                    toggleHelp()

        prefs.get().then (p) ->
            if p.showHelp != "0"
                showHelp()
                p.showHelp = "0"
                prefs.set(p)

    ])
.controller("PickViewCtrl", ["$scope", "categories", ($scope, cats) ->
        $scope.$emit('page.title')
        cats.get().then (data) ->
            if data.length == 0
                $scope.templateUrl = "partials/_entry_no_categories.html"
            else if data.filter( (it) -> it.unreadCount? && it.unreadCount > 0 ).length == 0
                $scope.templateUrl = "partials/_entry_no_unread.html"
            else
                $scope.templateUrl = "partials/_entry_select_category.html"
    ])
.controller("ViewCtrl", ["$routeParams", "$scope", "categories", "profile", ($params, $scope, cats, profile) ->
        profile.get().then (p) ->
            $scope.streamId = ['user', p.id, $params.type, $params.name].join('/')
            title = $params.name
            if $params.type == "category"
                cats.get().then (cs) ->
                    targetId = "category/#{$params.name}"
                    for c in cs when c.id == targetId
                        title = c.label
                    $scope.$emit('page.title', title)
            else
                $scope.$emit('page.title', title)
    ])
coreItemCtrl = ($window, $scope, sync) ->

        $scope.hasNext = ->
            $scope.index < $scope.items.length

        $scope.next = ->
            if $scope.hasNext()
                $scope.index += 1
                sync()

        $scope.hasPrevious = ->
            $scope.index >= 0

        $scope.previous = ->
            if $scope.hasPrevious()
                $scope.index -= 1
                sync()

        $scope.$on "$destroy", $scope.$on "key", (e, ke) ->
            switch ke.keyCode
                # for j, k, and space, the SHIFT key reverses behaviour
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
                    $scope.toggleSaved()
                when 65, 97, 90, 122 # A, a, Z, z
                    $scope.zoom = ! $scope.zoom;
                    $scope.$broadcast('rescale');

        $scope.$watch "item", ->
            $window.scrollTo 0, 0
            $scope.$broadcast('unscale');
            $scope.zoom = true;

        $scope.$on "$destroy", $scope.$on "click-left", (e, ce) ->
            $scope.$apply ->
                $scope.previous()

        $scope.$on "$destroy", $scope.$on "click-right", (e, ce) ->
            $scope.$apply ->
                $scope.next()

angular.module("ThatOneFeed.controllers")
.controller("StreamCtrl", ["$window", "$scope", "entries", "entryRipper", "markers", ($window, $scope, entries, ripper, markers) ->
        $scope.index = -1
        $scope.items = []
        $scope.item = null
        continuation = `undefined`
        showOnLoad = true
        inFlight = false
        sync = ->
            $scope.item = (if $scope.index >= 0 and $scope.index < $scope.items.length then $scope.items[$scope.index] else null)
            # keep 200 items max, but retain at least 100 - 25 = 75 previous items
            if $scope.index > 100 and $scope.items.length > 200
                $scope.items.splice 0, 25
                $scope.index -= 25
            if $scope.index > $scope.items.length - 8 and continuation isnt null
                inFlight = true
                entries($scope.streamId, continuation).then ((data) ->
                    if data.id is $scope.streamId and (continuation is `undefined` or continuation isnt data.continuation)
                        continuation = (if data.continuation then data.continuation else null)
                        addIt = (item) ->
                            if item
                                $scope.items.push item
                                if showOnLoad
                                    $scope.next()
                                    showOnLoad = false
                        ripCount = 0
                        data.items.forEach (it) ->
                            ripper(it).then(addIt
                                , (err) ->
                                    console.log "error ripping entry", err
                                , addIt
                            ).finally ->
                                inFlight = false if ++ripCount == data.items.length
                ), (data) ->
                    console.log "error loading entries", data

        coreItemCtrl($window, $scope, sync)
        $scope.$watch 'streamId', (id) ->
            sync() if id?

        $scope.nextEntry = ->
            if $scope.item and $scope.item.id
                idToSkip = $scope.item.id
                while $scope.hasNext()
                    $scope.next()
                    continue if $scope.item and $scope.item.id is idToSkip
                    break
            else
                $scope.next()

        $scope.previousEntry = ->
            if $scope.item and $scope.item.id
                idToSkip = $scope.item.id
                while $scope.hasPrevious()
                    $scope.previous()
                    continue if $scope.item and $scope.item.id is idToSkip
                    break
            else
                $scope.previous()

        $scope.saveClass = ->
            if $scope.item && $scope.item.saved then "saved" else null

        $scope.toggleSaved = ->
            if $scope.item
                ((it) ->
                    if it.saved
                        # todo track unsave
                        markers.unsave(it.id, it)
                            .then ->
                                it.saved = false
                    else
                        # todo track save
                        markers.save(it.id, it)
                            .then ->
                                it.saved = true
                )($scope.item)

        $scope.$on "$destroy", $scope.$on "key", (e, ke) ->
            switch ke.keyCode
                when 68 # D
                    $scope.previousEntry()
                when 100 # d
                    $scope.nextEntry()

        $scope.$watch "item", (item) ->
            $scope.templateUrl = "partials/_entry_" + (
                if item
                    $scope.$emit 'ga.page', entry_source: item.origin ? '-unknown-'
                    item.type
                else if $scope.items.length == 0
                    'loading'
                else if $scope.index < 0
                    'start'
                else if inFlight
                    showOnLoad = true
                    $scope.index--
                    'in_flight'
                else
                    'end'
            ) + ".html"
#            $scope.json = JSON.stringify(item, null, 3)
            if item?.unread
                ((it) ->
                    markers.read(it.id)
                        .then ->
                            it.unread = false
                            $scope.$broadcast("item-read", it)
                    for i in $scope.items
                        if it.id == i.id
                            i.unread = false
                )(item)
    ])
