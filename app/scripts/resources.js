angular.module("ThatOneFeed.resources", [])
    .factory("wrapHttp", ["$q", function wrapHttpFactory($q) {
        return function wrapHttp(hp) {
            const d = $q.defer();
            hp
                .success(data => d.resolve(data))
                .error(err => d.reject(err));
            return d.promise;
        };
    }])
    .factory("dataUrl", ["config", function dataUrlFactory(config) {
        const c = config();
        return function dataUrl(base, params) {
            let s = base;
            if (c.dataDir) {
                s = `${c.dataDir}${s}`;
            }
            if (c.dataExtension) {
                s = `${s}${c.dataExtension}`;
            }
            if (params) {
                s += "?" + Object.keys(params)
                    .map(n =>
                        n + "=" + encodeURIComponent(params[n] || ''))
                    .join("&");
            }
            return s;
        };
    }])
    .factory(
        "profile",
        ["$http", "wrapHttp", "syncPromise", "dataUrl", function profileFactory(
            $http,
            wrapHttp,
            sync,
            dataUrl,
        ) {
            let profile = null;
            return {
                get() {
                    if (profile) {
                        return sync(profile);
                    }
                    return wrapHttp($http.get(dataUrl("profile")))
                        .then(d => profile = d);
                },
                auth(code) {
                    return wrapHttp($http.post(dataUrl(
                        "auth",
                        {code},
                    )));
                },
                logout() {
                    return wrapHttp($http.delete(dataUrl("profile")))
                        .then(() => profile = null);
                },
            };
        }],
    )
    .factory(
        "prefs",
        ["$http", "wrapHttp", "syncPromise", "dataUrl", function prefsFactory(
            $http,
            wrapHttp,
            sync,
            dataUrl,
        ) {
            let prefs = null;
            return {
                get() {
                    if (prefs) {
                        return sync(prefs);
                    }
                    return wrapHttp($http.get(dataUrl("prefs")))
                        .then(d => prefs = d);
                },
                set(prefs) {
                    return wrapHttp($http.post(dataUrl("prefs"), prefs))
                        .then(d => prefs = d);
                },
            };
        }],
    )
    .factory(
        "categories",
        ["$http", "$q", "$timeout", "dataUrl", function categoriesFactory(
            $http,
            $q,
            $timeout,
            dataUrl,
        ) {
            let cats = null;

            function process(deferred, counts) {
                if (cats == null) {
                    return;
                }

                if (counts == null) {
                    deferred.notify(cats);
                    return;
                }

                // reset
                cats.forEach(it => it.unreadCount = 0);

                // apply counts
                counts.unreadcounts.forEach(urc => {
                    const id = urc.id.split('/').slice(2, 4).join('/');
                    cats.forEach(it => {
                        if (it.id === id) {
                            it.unreadCount = urc.count;
                        }
                    });
                });

                return deferred.resolve(cats);
            }

            function load(forceRefresh) {
                const deferred = $q.defer();
                let counts = null;

                if (forceRefresh) {
                    cats = null;
                }
                if (cats) {
                    $timeout(() => deferred.notify(cats));
                } else {
                    $http.get(dataUrl("categories"))
                        .success(data => {
                            cats = data.map(d => {
                                d.id = d.id.split('/')
                                    .slice(2, 4)
                                    .join('/');
                                return d;
                            });
                            return process(deferred, counts);
                        });
                }

                $http.get(dataUrl("counts"))
                    .success(data => {
                        counts = data;
                        return process(deferred, counts);
                    });

                return deferred.promise;
            }

            function counts() {
                const deferred = $q.defer();

                $http.get(dataUrl("counts", {background: true}))
                    .success(data => process(deferred, data));

                return deferred.promise;
            }

            return {
                get: load,
                counts,
            };
        }],
    )
    .factory(
        "entries",
        ["$http", "wrapHttp", "dataUrl", function entriesFactory(
            $http,
            wrapHttp,
            dataUrl,
        ) {
            return function entries(streamId, continuation) {
                return wrapHttp($http.get(dataUrl("entries", {
                    streamId,
                    continuation,
                })));
            };
        }],
    )
    .factory(
        "markers",
        ["$http", "$sce", "wrapHttp", "syncPromise", "syncFail", "dataUrl", function markersFactory(
            $http,
            $sce,
            wrap,
            sync,
            syncFail,
            dataUrl,
        ) {
            let tags = [];
            let globalSavedTagId = null;
            let lastReadId = null;

            $http.get(dataUrl("tags"))
                .success(data => {
                    tags = data.sort((a, b) => {
                        if (a.label < b.label) return -1;
                        if (a.label > b.label) return 1;
                        return 0;
                    });
                    tags.forEach(it => {
                        if (it.id.split("/").pop() === "global.saved") {
                            globalSavedTagId = it.id;
                        }
                    });
                })
                .error(() => console.log("error retrieving tags"))

            return {
                save(id, it) {
                    if (globalSavedTagId == null) {
                        return syncFail(null);
                    }
                    const payload = {
                        tagId: globalSavedTagId,
                        entryId: id,
                        type: it.type,
                        published: it.published.valueOf(),
                        title: (it.title ? it.title.replace(
                            /\s+/g,
                            ' ',
                        ) : undefined),
                        link: it.link,
                    };
                    if (it.type === 'image') {
                        payload.image = it.img;
                        payload.content = $sce.getTrustedHtml(it.caption);
                    } else {
                        payload.content = $sce.getTrustedHtml(it.content);
                    }
                    return wrap($http.put(dataUrl("save"), payload));
                },
                unsave(id) {
                    if (globalSavedTagId == null) {
                        return syncFail(null);
                    }
                    return wrap($http.delete(dataUrl("tag", {
                            tagId: globalSavedTagId,
                            entryId: id,
                        },
                    )));
                },
                read(id) {
                    if (id === lastReadId) {
                        return sync(null);
                    }
                    return wrap($http.post(
                        dataUrl("read"),
                        {id},
                    )).then(() => lastReadId = id);
                },
            };
        }],
    );
