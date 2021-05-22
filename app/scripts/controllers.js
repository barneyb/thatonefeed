angular.module("ThatOneFeed.controllers", [])
    .controller(
        "SplashCtrl",
        ["$scope", "$location", "profile", "dataUrl", "qs", function SplashCtrl(
            $scope,
            $location,
            profile,
            dataUrl,
            qs,
        ) {
            $scope.$emit('page.title');
            $scope.authUrl = dataUrl("auth");
            profile.get().then(() => $location.path("/view"));

            function passback(target) {
                if (window.opener) {
                    window.opener.location.hash = "#" + target;
                    window.close();
                } else {
                    $location.path(target);
                }
            }

            const q = qs();
            if (q.code) {
                profile.auth(q.code).then(() => passback("/view"));
            } else if (q.error) {
                passback("/decline");
            }
        }],
    )
    .controller("LogoutCtrl", ["$location", "profile", ($location, profile) =>
        profile.logout().then(() => $location.url("/")),
    ])
    .controller(
        "BodyCtrl",
        ["$window", "$element", "$scope", function BodyCtrl(
            $window,
            $element,
            $scope,
        ) {
            $scope.down = function down(e) {
                $scope.$broadcast("keydown", e);
            };
            $scope.press = function press(e) {
                if (e.key === " ") {
                    if (e.shiftKey) {
                        // trying to scroll up
                        if ($element.scrollTop() > 0) {
                            // there is room, don't $broadcast
                            return;
                        }
                    } else {
                        // trying to scroll down
                        if (($element[0].scrollHeight - $window.innerHeight) > $element.scrollTop()) {
                            // there is room, don't $broadcast
                            return;
                        }
                    }
                }
                $scope.$broadcast("key", e);
            };
            $scope.up = function up(e) {
                $scope.$broadcast("keyup", e);
            };
            $scope.click = function click(e) {
                $scope.$broadcast("click", e);
            };
        }],
    )
    .controller(
        "PageCtrl",
        ["$routeParams", "$templateCache", "$scope", function PageCtrl(
            $routeParams,
            $templateCache,
            $scope,
        ) {
            const {
                pageId,
            } = $routeParams;
            $scope.$emit('page.title', pageId);
            const partial = "partials/" + pageId + ".html";
            if (pageId.indexOf("_") !== 0 && $templateCache.get(partial)) {
                $scope.templateUrl = partial;
            } else {
                $scope.templateUrl = null;
            }
        }],
    )
    .controller(
        "NavCtrl",
        ["$routeParams", "$location", "$interval", "$scope", "categories", function NavCtrl(
            $routeParams,
            $location,
            $interval,
            $scope,
            cats,
        ) {
            let lastItemId = null;

            function setCats(cats) {
                cats.sort((a, b) => {
                    if (a.label < b.label) return -1;
                    if (a.label > b.label) return 1;
                    return 0;
                });
                $scope.categories = cats.filter(it =>
                    it.id === $scope.streamId || (it.unreadCount != null && it.unreadCount > 0));
            }

            $scope.streamId = $routeParams.type + '/' + $routeParams.name;
            $scope.categories = null;
            $scope.open = function open(id) {
                $scope.streamId = id;
                $location.path("/view/" + id);
            };

            $scope.activeClass = function activeClass(id) {
                return $scope.streamId === id ? "active" : null;
            };

            $scope.$on("$destroy", $scope.$on("item-read", (e, item) => {
                if (item.id === lastItemId) return;
                lastItemId = item.id;
                for (let c of $scope.categories) {
                    if (c.id === $scope.streamId) {
                        if (c.unreadCount > 0) {
                            c.unreadCount -= 1;
                        }
                        break;
                    }
                }
            }));

            cats.get().then(
                setCats,
                data => console.log("error loading categories", data),
                setCats,
            );

            const countInterval = $interval(() => cats.counts().then(setCats)
                , 1000 * 30);

            $scope.$on("$destroy", () => $interval.cancel(countInterval));
        }],
    )
    .controller(
        "GreetingCtrl",
        ["$scope", "prefs", function GreetingCtrl($scope, prefs) {
            $scope.$emit('page.title');
            let escDereg = null;

            function escHandler(e, ke) {
                if (ke.key === "Escape") {
                    hideHelp();
                }
            }

            function showHelp() {
                $scope.showHelp = true;
                escDereg = $scope.$on("keydown", escHandler);
                $scope.$on("$destroy", escDereg);
            }

            function hideHelp() {
                $scope.showHelp = false;
                if (escDereg) {
                    escDereg();
                }
            }

            function toggleHelp() {
                if ($scope.showHelp) {
                    hideHelp();
                } else {
                    showHelp();
                }
            }

            $scope.showHelp = false;
            $scope.clickHelp = toggleHelp;

            $scope.$on("$destroy", $scope.$on("key", (e, ke) => {
                if (ke.key === "?") {
                    toggleHelp();
                }
            }));

            prefs.get().then(p => {
                if (p.showHelp !== "0") {
                    showHelp();
                    p.showHelp = "0";
                    prefs.set(p);
                }
            });
        }],
    )
    .controller(
        "PickViewCtrl",
        ["$scope", "categories", function PickViewCtrl($scope, cats) {
            $scope.$emit('page.title');
            cats.get().then(data => {
                if (data.length === 0) {
                    $scope.templateUrl = "partials/_entry_no_categories.html";
                } else if (data.filter(it => it.unreadCount != null && it.unreadCount > 0).length === 0) {
                    $scope.templateUrl = "partials/_entry_no_unread.html";
                } else {
                    $scope.templateUrl = "partials/_entry_select_category.html";
                }
            });
        }],
    )
    .controller(
        "ViewCtrl",
        ["$routeParams", "$scope", "categories", "profile", (
            $params,
            $scope,
            cats,
            profile,
        ) => profile.get().then(p => {
            $scope.streamId = ['user', p.id, $params.type, $params.name]
                .join('/');
            let title = $params.name;
            if ($params.type === "category") {
                cats.get().then(cs => {
                    const targetId = `category/${$params.name}`;
                    for (let c of cs) {
                        if (c.id === targetId) {
                            title = c.label;
                        }
                    }
                    $scope.$emit('page.title', title);
                });
            } else {
                $scope.$emit('page.title', title);
            }
        })],
    );

function coreItemCtrl($window, $scope, sync) {

    $scope.hasNext = function hasNext() {
        return $scope.index < $scope.items.length;
    };

    $scope.next = function next() {
        if ($scope.hasNext()) {
            $scope.index += 1;
            sync();
        }
    };

    $scope.hasPrevious = function hasPrevious() {
        return $scope.index >= 0;
    };

    $scope.previous = function previous() {
        if ($scope.hasPrevious()) {
            $scope.index -= 1;
            sync();
        }
    };

    $scope.$on("$destroy", $scope.$on("key", (e, ke) => {
        switch (ke.key) {
            // for j, k, and space, the SHIFT key reverses behaviour
            case " ":
                $scope[(ke.shiftKey ? "previous" : "next")]();
                ke.stopImmediatePropagation();
                ke.stopPropagation();
                ke.preventDefault();
                break;
            case "K":
            case "j":
                $scope.next();
                break;
            case "J":
            case "k":
                $scope.previous();
                break;
            case "S":
            case "s":
                $scope.toggleSaved();
                break;
            case "A":
            case "a":
            case "Z":
            case "z":
                $scope.zoom = !$scope.zoom;
                $scope.$broadcast('rescale');
                break;
        }
    }));

    // Backspace doesn't give a press?
    $scope.$on("$destroy", $scope.$on("keydown", (e, ke) => {
        if (ke.key === "Backspace") {
            $scope.previous();
        }
    }));

    $scope.$watch("item", () => {
        $window.scrollTo(0, 0);
        $scope.$broadcast('unscale');
        $scope.zoom = true;
    });

    $scope.$on("$destroy", $scope.$on("click-left", () =>
        $scope.$apply(() => $scope.previous())));

    $scope.$on("$destroy", $scope.$on("click-right", () =>
        $scope.$apply(() => $scope.next())));
}

angular.module("ThatOneFeed.controllers")
    .controller(
        "StreamCtrl",
        ["$window", "$scope", "entries", "entryRipper", "markers", function StreamCtrl(
            $window,
            $scope,
            entries,
            ripper,
            markers,
        ) {
            $scope.index = -1;
            $scope.items = [];
            $scope.item = null;
            let continuation = undefined;
            let showOnLoad = true;
            let inFlight = false;

            function sync() {
                $scope.item = (($scope.index >= 0) && ($scope.index < $scope.items.length) ? $scope.items[$scope.index] : null);
                // keep 200 items max, but retain at least 100 - 25 = 75 previous items
                if ($scope.index > 100 && $scope.items.length > 200) {
                    $scope.items.splice(0, 25);
                    $scope.index -= 25;
                }
                if ($scope.index > ($scope.items.length - 8) && continuation !== null) {
                    inFlight = true;
                    entries($scope.streamId, continuation)
                        .then((data => {
                            if (data.id === $scope.streamId && (continuation === undefined || continuation !== data.continuation)) {
                                continuation = data.continuation ? data.continuation : null;

                                function addIt(item) {
                                    if (item) {
                                        $scope.items.push(item);
                                        if (showOnLoad) {
                                            $scope.next();
                                            showOnLoad = false;
                                        }
                                    }
                                }

                                let ripCount = 0;
                                data.items.forEach(it => ripper(it).then(addIt
                                    ,
                                    err => console.log(
                                        "error ripping entry",
                                        err,
                                    )
                                    ,
                                    addIt,
                                ).finally(() => {
                                    ripCount += 1;
                                    if (ripCount === data.items.length) {
                                        inFlight = false;
                                    }
                                }));
                            }
                        }), data => console.log("error loading entries", data));
                }
            }

            coreItemCtrl($window, $scope, sync);
            $scope.$watch('streamId', id => {
                if (id != null) {
                    sync();
                }
            });

            $scope.nextEntry = function nextEntry() {
                if ($scope.item && $scope.item.id) {
                    const idToSkip = $scope.item.id;
                    while ($scope.hasNext()) {
                        $scope.next();
                        if ($scope.item && $scope.item.id === idToSkip) continue;
                        break;
                    }
                } else {
                    $scope.next();
                }
            };

            $scope.previousEntry = function previousEntry() {
                if ($scope.item && $scope.item.id) {
                    const idToSkip = $scope.item.id;
                    while ($scope.hasPrevious()) {
                        $scope.previous();
                        if ($scope.item && $scope.item.id === idToSkip) continue;
                        break;
                    }
                } else {
                }
            };

            $scope.saveClass = function saveClass() {
                return $scope.item && $scope.item.saved ? "saved" : null;
            };

            $scope.toggleSaved = function toggleSaved() {
                if ($scope.item) {
                    const it = $scope.item;
                    if (it.saved) {
                        // todo track unsave
                        markers.unsave(it.id, it)
                            .then(() => it.saved = false);
                    } else {
                        // todo track save
                        markers.save(it.id, it)
                            .then(() => it.saved = true);
                    }
                }
            };

            $scope.$on("$destroy", $scope.$on("key", (e, ke) => {
                    switch (ke.key) {
                        case "D":
                            $scope.previousEntry();
                            break;
                        case "d":
                            $scope.nextEntry();
                            break;
                    }
                }),
            );

            $scope.$watch("item", item => {
                let subpartial = "end";
                if (item) {
                    $scope.$emit('ga.page', {
                        entry_source: item.origin != null
                            ? item.origin
                            : '-unknown-',
                    });
                    if (item.unread) {
                        markers.read(item.id)
                            .then(() => {
                                item.unread = false;
                                $scope.$broadcast("item-read", item);
                            });
                        for (let i of $scope.items) {
                            if (item.id === i.id) {
                                i.unread = false;
                            }
                        }
                    }
                    subpartial = item.type;
                } else if ($scope.items.length === 0) {
                    subpartial = 'loading';
                } else if ($scope.index < 0) {
                    subpartial = 'start';
                } else if (inFlight) {
                    showOnLoad = true;
                    $scope.index--;
                    subpartial = 'in_flight';
                }
                $scope.templateUrl = `partials/_entry_${subpartial}.html`;
                // $scope.json = JSON.stringify(item, null, 3)
            });
        }],
    );
