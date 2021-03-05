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
            .replace(/(<\/?iframe[^>]*>)+/gi, "") # remove IFRAME
            .replace(/<([a-z0-9])[^>]*>\s*<\/\1[^>]*>/gi, "") # remove empty tags
            .replace(/(<br[^>]*>\s*)+/gi, "$1") # collapse multiple BR
            .replace(/<br[^>]*>\s*(<\/?(p|blockquote)[^a-z])/gi, "$1") # remove BR before P/BLOCKQUOTE
            .replace(/(<\/?(p|blockquote)[^a-z])\s*<br[^>]*>/gi, "$1") # remove BR after P/BLOCKQUOTE
            .replace(/^\s*<br[^>]*>/i, "") # remove BR at start
            .replace(/<br[^>]*>\s*$/i, "") # remove BR at end

            caption = $sce.trustAsHtml(caption) # we trust what feedly gave us
            imgs.forEach (it) ->
                it.caption = caption

            imgs

        core = (it, d) ->
            d.id = it.id
            d.published = moment(it.published)
            d.age = d.published.fromNow(true)
            d.origin = it.origin.title
            d.title = if it.title then it.title.replace(/&nbsp;/g, ' ') else ''
            d.link = (it.canonical or it.alternate)[0].href
            d.saved = it.saved
            d.unread = it.unread
            if it.author
                d.origin += " (#{it.author})"
            d.keywords = if it.keywords then it.keywords.filter((it) -> !it.endsWith("staple")) else []
#            d.raw = it
            d

        ###
        I accept an 'item' element and if it's an image attempt to find a
        higher resolution version to use instead.
        ###
        hires = (d) ->
            if d.type is "image"
                m = /^(.*tumblr\.com.*_)[1-9][0-9]{2}(\.(jp(?:e?)g|png))$/.exec(d.img)
                if m
                    promiseImage(m[1] + "1280" + m[2]).then (img) ->
                        d.img = img.src
                    return d
                m = /^(.*files.wordpress.com.*\.(jp(?:e?)g|png))\?.*(w|h)=[0-9].*$/.exec(d.img)
                if m
                    d.img = m[1]
                    return d
            d

        (it) ->
            deferred = $q.defer()

            # this should actually rip stuff, and notify per item.  resolve can hand out an item OR null.
            setTimeout (->
                block = (it.content or it.summary)?.content or ''
                r = block # assume text
                if block.replace(/<\/?[a-z][^>]*>/gi, "").replace(/\s+/g, " ").length <= 1000
                    if ripperRE.test(block)
                        r = rip(block) # has images, and not to much text, so rip
                    else if typeof r is "string" && it.visual?.contentType?.indexOf("image/") == 0
                        # make it a single-item image array
                        r = [src: it.visual.url, caption: $sce.trustAsHtml(r)]

                asText = (body) ->
                    deferred.resolve core(it,
                        type: "html"
                        content: $sce.trustAsHtml(body)
                    )

                if typeof r is "string"
                    # synchronous
                    asText r # we trust what feedly gave us
                else
                    processed = 0
                    # list of images - asynchronous
                    accepted = []
                    resolveIfDone = ->
                        processed += 1
                        if processed < r.length
                            # still more to come...
                            return

                        if accepted.length is 0
                            # revert back to textual.
                            asText block
                        else
                            accepted.forEach (it, idx) ->
                                if accepted.length > 1
                                    it.title = "(#{idx + 1} of #{accepted.length}) #{it.title}"
                                deferred.notify it
                            deferred.resolve()

                    reject = (item, itemIndex) ->
                        resolveIfDone()

                    accept = (item, itemIndex, img) ->
                        nw = img.naturalWidth
                        nh = img.naturalHeight
                        if nw < 200 or nh < 100 or (nw < 400 and nh < 150)
                            reject item, itemIndex
                            return
                        partial = core(it,
                            type: "image"
                            img: img.src
                            caption: item.caption
                        )
                        accepted[itemIndex] = hires(partial)
                        resolveIfDone()

                    r.forEach (item, itemIndex) ->
                        promiseImage(item.src).then ((img) ->
                            accept item, itemIndex, img
                        ), ->
                            reject item, itemIndex

            ), 200
            deferred.promise
    ])
