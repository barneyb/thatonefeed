angular.module("ThatOneFeed.resources", [])
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
.factory("entries", ["$http", "$q", ($http, $q) ->
        (streamId, continuation) ->
            # don't want $http's promise directly, we want a protocol-less promise
            deferred = $q.defer()
            $http.get("data/entries.json?streamId=" + encodeURIComponent(streamId) + "&continuation=" + encodeURIComponent(continuation || ''))
            .success (data) ->
                deferred.resolve data

            deferred.promise
    ])
.factory("markers", ["$http", "$q", ($http, $q) ->
        tags = []
        globalSavedTagId = null
        ( ->
            $http.get("data/tags.json").success((data) ->
                tags = data.sort((a, b) ->
                    (if a.label < b.label then -1 else 1)
                )
                tags.forEach (it) ->
                    globalSavedTagId = it.id if it.id.split("/").pop() is "global.saved"
            ).error( ->
                console.log "error retrieving tags"
            )
        )()

        save: (id) ->
            console.log "no 'saved' tag is known"  unless globalSavedTagId?
            $http.put("data/tag.json",
                tagId: globalSavedTagId
                entryId: id
            ).error(->
                alert "error saving item"
            )
        unsave: (id) ->
            console.log "no 'saved' tag is known"  unless globalSavedTagId?
            $http.delete("data/untag.json",
                tagId: globalSavedTagId
                entryId: id
            ).error(->
                alert "error unsaving item"
            )
        read: (id) ->
            $http.post("data/read.json",
                id: id
            ).error(->
                console.log "error marking item read"
            )
    ])