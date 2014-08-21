angular.module("google-maps.directives.api")
.factory "Polyroute", ["IPolyroute", "$timeout", "array-sync", "PolyrouteChildModel",
  (IPolyroute, $timeout, arraySync, PolyrouteChildModel) ->
    class Polyroute extends IPolyroute
      link: (scope, element, attrs, mapCtrl) =>
        # Validate required properties
        if angular.isUndefined(scope.path) or scope.path is null or not @validatePath(scope.path)
          @$log.error "polyroute: no valid path attribute found"
          return

        # Wrap polyroute initialization inside a $timeout() call to make sure the map is created already
        IPolyroute.mapPromise(scope, mapCtrl).then (map) =>
          new PolyrouteChildModel scope, attrs, map, @DEFAULTS
]