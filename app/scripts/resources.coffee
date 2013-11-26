angular.module("ThatOneFeed.resources", [])
.factory("wrapHttp", ["$q", ($q) ->
        (hp) ->
            d = $q.defer()
            hp
            .success( (data) ->
                d.resolve data
            )
            .error( (err) ->
                d.reject err
            )
            d.promise
    ])
.factory("profile", ["$http", "wrapHttp", "syncPromise", ($http, wrapHttp, sync) ->
        profile = null
        get: () ->
            return sync(profile) if profile?
            wrapHttp($http.get("data/profile.json")).then (d) ->
                profile = d
        logout: () ->
            wrapHttp($http.delete("data/profile.json")).then ->
                profile = null
    ])
.factory("categories", ["$http", "$q", ($http, $q) ->
        cats = null
        (forceRefresh) ->
            deferred = $q.defer()
            counts = null
            process = ->
                return if not cats? or not counts?
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
.factory("entries", ["$http", "wrapHttp", ($http, wrapHttp) ->
        (streamId, continuation) ->
            # don't want $http's promise directly, we want a protocol-less promise
            wrapHttp($http.get("data/entries.json?streamId=" + encodeURIComponent(streamId) + "&continuation=" + encodeURIComponent(continuation || '')))
    ])
.factory("markers", ["$http", "wrapHttp", "syncPromise", "syncFail", ($http, wrap, sync, syncFail) ->
        tags = []
        globalSavedTagId = null
        lastReadId = null

        ( ->
            $http.get("data/tags.json")
            .success((data) ->
                tags = data.sort((a, b) ->
                    (if a.label < b.label then -1 else 1)
                )
                tags.forEach (it) ->
                    globalSavedTagId = it.id if it.id.split("/").pop() is "global.saved"
            )
            .error( ->
                console.log "error retrieving tags"
            )
        )()

        save: (id) ->
            return syncFail(null) unless globalSavedTagId?
            wrap($http.put("data/tag.json",
                tagId: globalSavedTagId
                entryId: id
            ))
        unsave: (id) ->
            return syncFail(null) unless globalSavedTagId?
            wrap($http.delete("data/untag.json",
                tagId: globalSavedTagId
                entryId: id
            ))
        read: (id) ->
            return sync(null) if id == lastReadId
            wrap($http.post("data/read.json",
                id: id
            )).then( ->
                lastReadId = id
            )
    ])