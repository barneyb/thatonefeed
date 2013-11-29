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
.factory("config", ["$window", ($window) ->
        config = $window.ThatOneFeed
        () ->
            config
    ])
.factory("dataUrl", ["config", (config) ->
        c = config()
        (base, params) ->
            s = "#{c.dataDir}/#{base}.#{c.dataExtension}"
            if params?
                s += "?" + (for n, v of params
                    n + "=" + encodeURIComponent(v || '')
                ).join("&")
            s
    ])
.factory("profile", ["$http", "wrapHttp", "syncPromise", "dataUrl", ($http, wrapHttp, sync, dataUrl) ->
        profile = null
        get: () ->
            return sync(profile) if profile?
            wrapHttp($http.get(dataUrl("profile"))).then (d) ->
                profile = d
        auth: (code) ->
            wrapHttp($http.post(dataUrl("auth",
                code: code
            )))
        logout: () ->
            wrapHttp($http.delete(dataUrl("profile"))).then ->
                profile = null
    ])
.factory("categories", ["$http", "$q", "$timeout", "dataUrl", ($http, $q, $timeout, dataUrl) ->
        cats = null
        filteredCats = ->
            cats.filter (it) ->
                it.unreadCount? && it.unreadCount > 0
        process = (deferred, counts) ->
            if not cats?
                return

            if not counts?
                deferred.notify cats
                return

            # reset
            cats.forEach (it) ->
                it.unreadCount = 0

            # apply counts
            counts.unreadcounts.forEach (urc) ->
                cats.forEach (it) ->
                    it.unreadCount = urc.count    if it.id is urc.id

            deferred.resolve filteredCats()
        load = (forceRefresh) ->
            deferred = $q.defer()
            counts = null

            cats = null    if forceRefresh
            if cats?
                $timeout ->
                    deferred.notify filteredCats()
            else
                $http.get(dataUrl("categories"))
                .success (data) ->
                    cats = data
                    process(deferred, counts)

            $http.get(dataUrl("counts"))
            .success (data) ->
                counts = data
                process(deferred, counts)

            deferred.promise
        counts = () ->
            deferred = $q.defer()

            $http.get(dataUrl("counts", background: true))
            .success (data) ->
                process(deferred, data)

            deferred.promise

        get: load
        counts: counts
    ])
.factory("entries", ["$http", "wrapHttp", "dataUrl", ($http, wrapHttp, dataUrl) ->
        (streamId, continuation) ->
            # don't want $http's promise directly, we want a protocol-less promise
            wrapHttp($http.get(dataUrl("entries",
                streamId: streamId
                continuation: continuation
            )))
    ])
.factory("markers", ["$http", "wrapHttp", "syncPromise", "syncFail", "dataUrl", ($http, wrap, sync, syncFail, dataUrl) ->
        tags = []
        globalSavedTagId = null
        lastReadId = null

        ( ->
            $http.get(dataUrl("tags"))
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
            wrap($http.put(dataUrl("tag"),
                tagId: globalSavedTagId
                entryId: id
            ))
        unsave: (id) ->
            return syncFail(null) unless globalSavedTagId?
            wrap($http.delete(dataUrl("tag"),
                tagId: globalSavedTagId
                entryId: id
            ))
        read: (id) ->
            return sync(null) if id == lastReadId
            wrap($http.post(dataUrl("read"),
                id: id
            )).then( ->
                lastReadId = id
            )
    ])