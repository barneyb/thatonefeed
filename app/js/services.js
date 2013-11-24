'use strict';
angular.module('ThatOneFeed.services', [])
    .factory("categories", ['$http', '$q', function ($http, $q) {
        var cats = null;
        return function(forceRefresh) {
            var deferred = $q.defer(),
                counts = null,
                process = function() {
                    if (cats == null || counts == null) {
                        return;
                    }
                    // reset
                    cats.forEach(function(it) {
                        it.unreadCount = 0;
                    });
                    // apply counts
                    counts.unreadcounts.forEach(function(urc) {
                        cats.forEach(function(it) {
                            if (it.id == urc.id) {
                                it.unreadCount = urc.count;
                            }
                        });
                    });
                    deferred.resolve(cats);
                };
            if (forceRefresh) {
                cats = null;
            }
            if (cats == null) {
                $http.get("data/categories.json")
                    .success(function(data) {
                        cats = data;
                        process();
                    });
            }
            $http.get("data/counts.json")
                .success(function(data) {
                    counts = data;
                    process();
                });
            return deferred.promise;
        };
    }])
    .factory("entries", ['$http', '$q', function ($http, $q) {
        return function(streamId, continuation) {
            // don't want $http's promise directly, we want a protocol-less promise
            var deferred = $q.defer();
            $http.get("data/entries.json")
                .success(function(data) {
                    deferred.resolve(data);
                });
            return deferred.promise;
        };
    }])
    .factory("promiseImage", ['$q', function ($q) {
        return function(src) {
            var deferred = $q.defer(),
                img = new Image();
            angular.element(img)
                .bind('load', function() {
                    deferred.resolve(img);
                })
                .bind('error', function() {
                    deferred.reject();
                });
            img.src = src;
            return deferred.promise;
        };
    }])
    .factory("entryRipper", ['$q', '$sce', 'promiseImage', function ($q, $sce, promiseImage) {

        var ripperRE = /<img[^>]*\ssrc=(['"])([^'"]+)\1[^>]*>/,
            altRE = /\salt="([^"]+)"/,
            titleRE = /\stitle="([^"]+)"/,
            rip = function(block) {
                if (! ripperRE.test(block)) {
                    return block; // no images
                }
                var text = block
                    .replace(/<\/?[a-z][^>]*>/gi, '')
                    .replace(/\s+/g, ' ');
                if (text.length > 1000) {
                    // treat it as textual content
                    return block;
                }
                var imgs = [];
                var caption = '';
                while (true) {
                    var m = ripperRE.exec(block);
                    if (m == null) {
                        break;
                    }
                    imgs.push({
                        src: m[2]
                    });
                    caption += block.substr(0, m.index);
                    block = block.substr(m.index + m[0].length);
                    var tm = titleRE.exec(m[0]) || altRE.exec(m[0]);
                    if (tm != null && tm[1].length > 0) {
                        caption += '<blockquote class="title">' + tm[1] + '</blockquote>';
                    }
                }
                caption += block;
                caption = caption
                    .replace(/(<\/?iframe[^>]*>)+/gi, '') // remove IFRAME
                    .replace(/<([a-z0-9])[^>]*>\s*<\/\1[^>]*>/gi, '') // remove empty tags
                    .replace(/(<br[^>]*>\s*)+/gi, '$1') // collapse multiple BR
                    .replace(/<br[^>]*>\s*(<\/?(p|blockquote)[^a-z])/gi, '$1') // remove BR before P/BLOCKQUOTE
                    .replace(/(<\/?(p|blockquote)[^a-z])\s*<br[^>]*>/gi, '$1') // remove BR after P/BLOCKQUOTE
                ;
                caption = $sce.trustAsHtml(caption); // we trust what feedly gave us
                imgs.forEach(function(it) {
                    it.caption = caption;
                });
                return imgs;
            },
            core = function(it, d) {
                d.id = it.id;
                d.origin = it.origin.title;
                d.title = it.title;
                d.link = (it.canonical || it.alternate)[0].href;
                d.saved = it.saved;
                return d;
            },
            hiresRE = /^(.*tumblr\.com.*_)[1-9][0-9]{2}(\.(jp(?:e?)g|png))$/,
            /**
             * I accept an 'item' element and if it's an image attempt to find a
             * higher resolution version to use instead.
             */
            hires = function(d) {
                if (d.type == 'image') {
                    var m = hiresRE.exec(d.img);
                    if (m) {
                        promiseImage(m[1] + "1280" + m[2])
                            .then(function(img) {
                                d.img = img.src;
                            });
                    }
                }
                return d;
            };

        return function(it) {
            var deferred = $q.defer();

            // this should actually rip stuff, and notify per item.  resolve can hand out an item OR null.
            setTimeout(function() {
                var block = (it.content || it.summary).content,
                    r = rip(block),
                    asText = function(body) {
                        deferred.notify(core(it, {
                            type: "html",
                            content: $sce.trustAsHtml(body)
                        }));
                    };
                if (typeof r == 'string') {
                    // synchronous
                    asText(r); // we trust what feedly gave us
                    deferred.resolve();
                } else {
                    // list of images - asynchronous
                    var accepted = [],
                        rejectCount = 0,
                        pushAccepted = function() {
                            if (accepted.length == 0) {
                                // revert back to textual.
                                asText(block);
                            } else {
                                accepted.forEach(function(it, idx) {
                                    if (accepted.length > 1) {
                                        it.title = "(" + (idx+ 1) + " of " + accepted.length + ") " + it.title;
                                    }
                                    deferred.notify(it);
                                });
                            }
                        },
                        reject = function(item, itemIndex) {
                            rejectCount += 1;
                            if (accepted.length + rejectCount == r.length) {
                                pushAccepted();
                            }
                        },
                        accept = function(item, itemIndex, img) {
                            var nw = img.naturalWidth,
                                nh = img.naturalHeight;
                            if (nw < 200 || nh < 100 || (nw < 400 && nh < 150)) {
                                reject(item);
                                return;
                            }
                            var partial = core(it, {
                                type: "image",
                                img: img.src,
                                caption: item.caption
                            });
                            accepted.push(hires(partial));
                            if (accepted.length + rejectCount == r.length) {
                                pushAccepted();
                            }
                        };
                    r.forEach(function (item, itemIndex) {
                        promiseImage(item.src).then(function(img) {
                            accept(item, itemIndex, img)
                        }, function() {
                            reject(item, itemIndex);
                        });
                    });
                }
            }, 200);

            return deferred.promise;
        };
    }]);
