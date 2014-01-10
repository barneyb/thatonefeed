angular.module("ThatOneFeed.services", [])
.factory("qs", ["$window", ($window) ->
        ->
            ps = {}
            for s in $window.location.search.substr(1).split("&")
                a = s.split("=")
                ps[a.shift()] = a.join("=")
            ps
    ])
.factory("syncPromise", ["$q", "$timeout", ($q, $timeout) ->
        (resolution) ->
            d = $q.defer()
            $timeout ->
                d.resolve resolution
            d.promise
    ])
.factory("syncFail", ["$q", "syncPromise", ($q, sync) ->
        (resolution) ->
            sync($q.reject(resolution))
    ])
.factory("promiseImage", ["$q", ($q) ->
        (src) ->
            deferred = $q.defer()
            img = new Image()
            angular.element(img).bind("load", ->
                deferred.resolve img
            ).bind "error", ->
                deferred.reject()

            img.src = src
            deferred.promise
    ])
.factory("entryRipper", ["$q", "$sce", "promiseImage", ($q, $sce, promiseImage) ->
        ripperRE = /<img[^>]*\ssrc=(['"])([^'"]+)\1[^>]*>/
        altRE = /\salt="([^"]+)"/
        titleRE = /\stitle="([^"]+)"/
        rip = (block) ->
            return block unless ripperRE.test(block) # has images
            text = block.replace(/<\/?[a-z][^>]*>/g, "").replace(/\s+/g, " ")
            return block if text.length > 1000 # treat as textual
            imgs = []
            caption = ""
            loop
                m = ripperRE.exec(block)
                break    unless m?
                imgs.push src: m[2]
                caption += block.substr(0, m.index)
                block = block.substr(m.index + m[0].length)
                tm = titleRE.exec(m[0]) or altRE.exec(m[0])
                caption += "<blockquote class=\"title\">" + tm[1] + "</blockquote>"    if tm? and tm[1].length > 0
            caption += block

            caption = caption
            .replace(/(<\/?iframe[^>]*>)+/g, "") # remove IFRAME
            .replace(/<([a-z0-9])[^>]*>\s*<\/\1[^>]*>/g, "") # remove empty tags
            .replace(/(<br[^>]*>\s*)+/g, "$1") # collapse multiple BR
            .replace(/<br[^>]*>\s*(<\/?(p|blockquote)[^a-z])/g, "$1") # remove BR before P/BLOCKQUOTE
            .replace(/(<\/?(p|blockquote)[^a-z])\s*<br[^>]*>/g, "$1") # remove BR after P/BLOCKQUOTE

            caption = $sce.trustAsHtml(caption) # we trust what feedly gave us
            imgs.forEach (it) ->
                it.caption = caption

            imgs

        core = (it, d) ->
            d.id = it.id
            d.age = moment(it.published).fromNow(true)
            d.origin = it.origin.title
            d.title = it.title.replace(/&nbsp;/g, ' ')
            d.link = (it.canonical or it.alternate)[0].href
            d.saved = it.saved
            d.unread = it.unread
            d

        hiresRE = /^(.*tumblr\.com.*_)[1-9][0-9]{2}(\.(jp(?:e?)g|png))$/

        ###
        I accept an 'item' element and if it's an image attempt to find a
        higher resolution version to use instead.
        ###
        hires = (d) ->
            if d.type is "image"
                m = hiresRE.exec(d.img)
                if m
                    promiseImage(m[1] + "1280" + m[2]).then (img) ->
                        d.img = img.src

            d

        (it) ->
            deferred = $q.defer()

            # this should actually rip stuff, and notify per item.    resolve can hand out an item OR null.
            setTimeout (->
                block = (it.content or it.summary).content
                r = rip(block)
                asText = (body) ->
                    deferred.resolve core(it,
                        type: "html"
                        content: $sce.trustAsHtml(body)
                    )

                if typeof r is "string"
                    # synchronous
                    asText r # we trust what feedly gave us
                else
                    # list of images - asynchronous
                    accepted = []
                    rejectCount = 0
                    pushAccepted = ->
                        if accepted.length is 0

                            # revert back to textual.
                            asText block
                        else
                            accepted.forEach (it, idx) ->
                                it.title = "(" + (idx + 1) + " of " + accepted.length + ") " + it.title    if accepted.length > 1
                                deferred.notify it
                            deferred.resolve()


                    reject = (item, itemIndex) ->
                        rejectCount += 1
                        pushAccepted()    if accepted.length + rejectCount is r.length

                    accept = (item, itemIndex, img) ->
                        nw = img.naturalWidth
                        nh = img.naturalHeight
                        if nw < 200 or nh < 100 or (nw < 400 and nh < 150)
                            reject item
                            return
                        partial = core(it,
                            type: "image"
                            img: img.src
                            caption: item.caption
                        )
                        accepted.push hires(partial)
                        pushAccepted()    if accepted.length + rejectCount is r.length

                    r.forEach (item, itemIndex) ->
                        promiseImage(item.src).then ((img) ->
                            accept item, itemIndex, img
                        ), ->
                            reject item, itemIndex


            ), 200
            deferred.promise
    ])