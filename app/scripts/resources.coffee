angular.module("ThatOneFeed.resources", [])
.factory("categories", ["$http", "$q", ($http, $q) ->
        cats = null
        (forceRefresh) ->
            deferred = $q.defer()
            counts = null
            process = ->
                return    if not cats? or not counts?
                # reset
                cats.forEach (it) ->
                    it.unreadCount = 0

                # apply counts
                counts.unreadcounts.forEach (urc) ->
                    cats.forEach (it) ->
                        it.unreadCount = urc.count    if it.id is urc.id


                deferred.resolve cats

            cats = null    if forceRefresh
            unless cats?
                $http.get("data/categories.json")
                .success (data) ->
                    cats = data
                    process()

            $http.get("data/counts.json")
            .success (data) ->
                counts = data
                process()

            deferred.promise
    ])
.factory("entries", ["$http", "$q", ($http, $q) ->
        (streamId, continuation) ->
            # don't want $http's promise directly, we want a protocol-less promise
            deferred = $q.defer()
            $http.get("data/entries.json?streamId=" + encodeURIComponent(streamId) + "&continuation=" + encodeURIComponent(continuation || ''))
            .success (data) ->
                deferred.resolve data

            deferred.promise
    ])