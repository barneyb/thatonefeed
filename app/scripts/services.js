angular.module("ThatOneFeed.services", [])
    .factory("qs", ["$window", function qsFactory($window) {
        return function qs() {
            const ps = {};
            for (let s of $window.location.search.substr(1).split("&")) {
                const a = s.split("=");
                ps[a.shift()] = a.join("=");
            }
            return ps;
        };
    }])
    .factory(
        "syncPromise",
        ["$q", "$timeout", function syncPromiseFactory($q, $timeout) {
            return function syncPromise(resolution) {
                const d = $q.defer();
                $timeout(() => d.resolve(resolution));
                return d.promise;
            };
        }],
    )
    .factory(
        "syncFail",
        ["$q", "syncPromise", function syncFailFactory($q, sync) {
            return function syncFail(resolution) {
                return sync($q.reject(resolution));
            };
        }],
    )
    .factory("promiseImage", ["$q", function promiseImageFactory($q) {
        return function promiseImage(src) {
            const deferred = $q.defer();
            const img = new Image();
            angular.element(img)
                .bind("load", () => deferred.resolve(img))
                .bind("error", () => deferred.reject());

            img.src = src;
            return deferred.promise;
        };
    }])
    .factory(
        "entryRipper",
        ["$q", "$sce", "promiseImage", function entryRipperFactory(
            $q,
            $sce,
            promiseImage,
        ) {
            const ripperRE = /<img[^>]*\ssrc=(['"])([^'"]+)\1[^>]*>/;
            const altRE = /\salt="([^"]+)"/;
            const titleRE = /\stitle="([^"]+)"/;
            const tumblrImgRE = /^(.*tumblr\.com.*_)[1-9][0-9]{2}(\.(jp(?:e?)g|png))$/;
            const wordpressImgRE = /^(.*files.wordpress.com.*\.(jp(?:e?)g|png))\?.*([wh])=[0-9].*$/;

            function rip(block) {
                const imgs = [];
                let caption = "";
                while (true) {
                    const m = ripperRE.exec(block);
                    if (m == null) {
                        break;
                    }
                    imgs.push({src: m[2]});
                    caption += block.substr(0, m.index);
                    block = block.substr(m.index + m[0].length);
                    const tm = titleRE.exec(m[0]) || altRE.exec(m[0]);
                    if (tm && tm[1].length > 0) {
                        caption += "<blockquote class=\"title\">" + tm[1] + "</blockquote>";
                    }
                }
                caption += block;

                caption = caption
                    // remove IFRAME
                    .replace(/(<\/?iframe[^>]*>)+/gi, "")
                    // remove empty tags
                    .replace(/<([a-z0-9])[^>]*>\s*<\/\1[^>]*>/gi, "")
                    // collapse multiple BR
                    .replace(/(<br[^>]*>\s*)+/gi, "$1")
                    // remove BR before P/BLOCKQUOTE
                    .replace(/<br[^>]*>\s*(<\/?(p|blockquote)[^a-z])/gi, "$1")
                    // remove BR after P/BLOCKQUOTE
                    .replace(/(<\/?(p|blockquote)[^a-z])\s*<br[^>]*>/gi, "$1")
                    // remove BR at start
                    .replace(/^\s*<br[^>]*>/i, "")
                    // remove BR at end
                    .replace(/<br[^>]*>\s*$/i, "");

                caption = $sce.trustAsHtml(caption); // we trust what feedly gave us
                imgs.forEach(it => it.caption = caption);

                return imgs;
            }

            function core(it, d) {
                d.id = it.id;
                d.published = moment(it.published);
                d.age = d.published.fromNow(true);
                d.origin = it.origin.title;
                d.title = it.title
                    ? it.title.replace(/&nbsp;/g, ' ')
                    : '';
                d.link = (it.canonical || it.alternate)[0].href;
                d.saved = it.saved;
                d.unread = it.unread;
                d.keywords = it.keywords
                    ? it.keywords.filter(it => !it.endsWith("staple"))
                    : [];
                // d.raw = it
                return d;
            }

            /*
            I accept an 'item' element and if it's an image attempt to find a
            higher resolution version to use instead.
            */
            function hires(d) {
                if (d.type === "image") {
                    let m = tumblrImgRE.exec(d.img);
                    if (m) {
                        promiseImage(m[1] + "1280" + m[2])
                            .then(img => d.img = img.src);
                        return d;
                    }
                    m = wordpressImgRE.exec(d.img);
                    if (m) {
                        d.img = m[1];
                        return d;
                    }
                }
                return d;
            }

            return function entryRipper(it) {
                const deferred = $q.defer();

                // this should actually rip stuff, and notify per item.  resolve can hand out an item OR null.
                setTimeout(() => {
                    let block = it.content || it.summary;
                    block = block ? block.content : '';
                    let r = block; // assume text
                    if (block.replace(/<\/?[a-z][^>]*>/gi, "")
                        .replace(/\s+/g, " ").length <= 1000) {
                        if (ripperRE.test(block)) {
                            r = rip(block); // has images, and not to much text, so rip
                        } else if (typeof r === "string"
                            && it.visual
                            && it.visual.contentType
                            && it.visual.contentType.indexOf("image/") === 0
                        ) {
                            // make it a single-item image array
                            r = [{
                                src: it.visual.url,
                                caption: $sce.trustAsHtml(r),
                            }];
                        }
                    }

                    function asText(body) {
                        deferred.resolve(core(it, {
                            type: "html",
                            content: $sce.trustAsHtml(body),
                        }));
                    }

                    if (typeof r === "string") {
                        // synchronous
                        asText(r); // we trust what feedly gave us
                    } else {
                        let processed = 0;
                        // list of images - asynchronous
                        const accepted = [];

                        function resolveIfDone() {
                            processed += 1;
                            if (processed < r.length) {
                                // still more to come...
                                return;
                            }

                            if (accepted.length === 0) {
                                // revert back to textual.
                                asText(block);
                            } else {
                                accepted.forEach((it, idx) => {
                                    if (accepted.length > 1) {
                                        it.title = `(${idx + 1} of ${accepted.length}) ${it.title}`;
                                    }
                                    deferred.notify(it);
                                });
                                deferred.resolve();
                            }
                        }

                        function reject() {
                            resolveIfDone();
                        }

                        function accept(item, itemIndex, img) {
                            const nw = img.naturalWidth;
                            const nh = img.naturalHeight;
                            if (nw < 200 || nh < 100 || nw < 400 && nh < 150) {
                                reject(item, itemIndex);
                                return;
                            }
                            const partial = core(it, {
                                    type: "image",
                                    img: img.src,
                                    caption: item.caption,
                                },
                            );
                            accepted[itemIndex] = hires(partial);
                            resolveIfDone();
                        }

                        r.forEach((item, itemIndex) =>
                            promiseImage(item.src)
                                .then(
                                    img => accept(item, itemIndex, img),
                                    () => reject(item, itemIndex),
                                ));
                    }

                }, 200);
                return deferred.promise;
            };
        }],
    );
