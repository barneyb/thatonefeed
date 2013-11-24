'use strict';
angular.module('ThatOneFeed.controllers', [])
    .controller('SplashCtrl', [function () {
    }])
    .controller('KeyCtrl', ['$scope', function ($scope) {
        $scope.key = function (e) {
            $scope.$broadcast("key", e)
        };
    }])
    // depend on 'feedly', even though we don't use it, so it'll be instantiated and bootstrapped
    .controller("NavCtrl", ['$location', '$scope', 'categories', function ($location, $scope, cats) {
        $scope.categories = [];
        $scope.open = function(id) {
            $location.path("/view/" + encodeURIComponent(id));
        };
        $scope.activeClass = function(id) {
            return $scope.streamId == id ? "active" : null;
        };
        cats().then(function(data) {
            $scope.categories = data;
        }, function(data) {
            console.log("error loading categories", data)
        });
    }])
    .controller('StreamCtrl', ['$routeParams', '$scope', 'entries', 'entryRipper', function ($routeParams, $scope, entries, ripper) {
        var index = -1,
            continuation = undefined,
            sync = function() {
//                clearTimeout(viewFlushTimeout);
                var it = $scope.item = index >= 0 && index < $scope.items.length ? $scope.items[index] : null;
// todo: record read status
//                if (it && it.id) {
//                    var found = false;
//                    viewQueue.forEach(function (id) {
//                        if (it.id == id) {
//                            found = true;
//                        }
//                    });
//                    viewHistory.forEach(function (id) {
//                        if (it.id == id) {
//                            found = true;
//                        }
//                    });
//                    if (!found) {
//                        viewQueue.push(it.id);
//                    }
//                }
                // keep 200 items max, but retain at least 100 - 25 = 75 previous items
                if (index > 100 && $scope.items.length > 200) {
                    $scope.items.splice(0, 25);
                    index -= 25;
                }
                if (index > $scope.items.length - 8 && continuation !== null) {
                    entries($scope.streamId, continuation).then(function(data) {
                        if (data.id == $scope.streamId && (continuation === undefined || continuation != data.continuation)) {
                            continuation = data.continuation ? data.continuation : null;
                            data.items.forEach(function(it) {
                                ripper(it).then(function(item) {
                                    if (item) {
                                        $scope.items.push(item);
                                    }
                                }, function(err) {
                                    console.log("error ripping entry", err)
                                }, function(item) {
                                    $scope.items.push(item);
                                });
                            });
                        }
                    }, function(data) {
                        console.log("error loading entries", data)
                    });
                }
// todo: view queue?
//                if (viewQueue.length > 10) {
//                    flushViews();
//                } else {
//                    viewFlushTimeout = setTimeout(flushViews, 5000);
//                }
            };

        $scope.streamId = $routeParams.streamId;
        $scope.items = [];
        $scope.item = null;

        $scope.hasNext = function () {
            return index < $scope.items.length;
        };

        $scope.next = function () {
            if ($scope.hasNext()) {
                index += 1;
                $scope.$emit('_itemRead');
// todo: scaling
//                $scope.$broadcast('unscale');
//                $scope.zoom = true;
                sync();
            }
        };

        $scope.skipRest = function() {
            if ($scope.item && $scope.item.id) {
                var idToSkip = $scope.item.id;
                while ($scope.hasNext()) {
                    $scope.next();
                    if ($scope.item && $scope.item.id == idToSkip) {
                        continue;
                    }
                    break;
                }
            }
        };

        $scope.hasPrevious = function () {
            return index > 0;
        };

        $scope.previous = function () {
            if ($scope.hasPrevious()) {
                index -= 1;
// todo: scaling
//                $scope.$broadcast('unscale');
//                $scope.zoom = true;
                sync();
            }
        };

        $scope.$on('key', function (e, ke) {
            //noinspection FallthroughInSwitchStatementJS
            switch (ke.keyCode) {
                case 32: // SPACE
                    $scope[ke.shiftKey ? 'previous' : 'next']();
                    ke.stopImmediatePropagation();
                    ke.stopPropagation();
                    ke.preventDefault();
                    break;
                case 74: // J
                case 106: // j
                    $scope.next();
                    break;
                case 75: // K
                case 107: // k
                    $scope.previous();
                    break;
// todo: saving
//                case 83: // S
//                case 115: // s
//                    $scope.toggleSaved();
//                    break;
                case 68: // D
                case 100: // d
                    $scope.skipRest();
                    break;
// todo: scaling
//                case 65: // A
//                case 97: // a
//                case 90: // Z
//                case 122: // z
//                    $scope.zoom = ! $scope.zoom;
//                    $scope.$broadcast('rescale');
//                    break;
            }
        });

        $scope.$watchCollection('items', function() {
            if (index < 0 && $scope.items.length > 0) {
                $scope.next();
            }
        });

        $scope.$watch('item', function() {
            $scope.templateUrl = $scope.item ? 'partials/_entry_' + $scope.item.type + '.html' : null;
        });

        $scope.$on("$destroy", function() {
            $scope.streamId = null;
            // todo: sync read status
        });

        sync();
    }]);