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
            s = base
            s = "#{c.dataDir}#{s}" if c.dataDir
            s = "#{s}#{c.dataExtension}" if c.dataExtension
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
.factory("prefs", ["$http", "wrapHttp", "syncPromise", "dataUrl", ($http, wrapHttp, sync, dataUrl) ->
        prefs = null
        get: () ->
            return sync(prefs) if prefs?
            wrapHttp($http.get(dataUrl("prefs"))).then (d) ->
                prefs = d
        set: (prefs) ->
            wrapHttp($http.post(dataUrl("prefs"), prefs)).then (d) ->
                prefs = d
    ])
.factory("categories", ["$http", "$q", "$timeout", "dataUrl", ($http, $q, $timeout, dataUrl) ->
        cats = null
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
                id = urc.id.split('/')[2..3].join('/')
                cats.forEach (it) ->
                    it.unreadCount = urc.count    if it.id is id

            deferred.resolve cats
        load = (forceRefresh) ->
            deferred = $q.defer()
            counts = null

            cats = null    if forceRefresh
            if cats?
                $timeout ->
                    deferred.notify cats
            else
                $http.get(dataUrl("categories"))
                .success (data) ->
                    cats = for d in data
                        d.id = d.id.split('/')[2..3].join('/')
                        d
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
.factory("httpProxy", ["$http", "wrapHttp", "dataUrl", ($http, wrapHttp, dataUrl) ->
        (url) ->
            wrapHttp($http.get(dataUrl("proxy",
                url: url
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
            wrap($http.delete(dataUrl("tag",
                tagId: globalSavedTagId
                entryId: id
            )))
        read: (id) ->
            return sync(null) if id == lastReadId
            wrap($http.post(dataUrl("read"),
                id: id
            )).then( ->
                lastReadId = id
            )
    ])