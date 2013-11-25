angular.module("ThatOneFeed.filters", [])
.filter "urlEncode", [ () ->
    (text) ->
        encodeURIComponent text
]