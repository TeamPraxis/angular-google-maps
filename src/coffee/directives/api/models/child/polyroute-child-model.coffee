angular.module("google-maps.directives.api")
.factory "PolyrouteChildModel", ["BaseObject", "Logger", "$timeout", "array-sync", "GmapUtil", "EventsHelper"
  (BaseObject, $log, $timeout, arraySync, GmapUtil,EventsHelper) ->
    class PolyrouteChildModel extends BaseObject
      @include GmapUtil
      @include EventsHelper
      constructor: (@scope, @attrs, @map, @defaults, @model) ->
        @dirService = new google.maps.DirectionsService
        @routeParts = [];

        scope.$watch 'path', (newValue, oldValue) =>
          _.each @routeParts, (r) =>
            r.setMap null
            r = null
          @routeParts = []

          if @polyline
            @polyline.setMap null
            @polyline = null

          pathPoints = @convertPathPoints scope.path
          lineOpts = @buildOpts pathPoints if pathPoints.length > 0
          lineOpts.strokeColor = 'transparent';
          @polyline = new google.maps.Polyline lineOpts
          if @polyline
            @extendMapBounds map, pathPoints if scope.fit
            arraySync @polyline.getPath(), scope, "path", (pathPoints) =>
              @extendMapBounds map, pathPoints if scope.fit
            @listeners = if @model then @setEvents @polyline, scope, @model else @setEvents @polyline, scope, scope

          # Lookup the route between the poly line points
          pathParts = Math.ceil (pathPoints.length / 10) - 1
          for j in [0..pathParts]
            start = j * 10
            end = (j+1) * 10 - 1
            if end > pathPoints.length - 1
              end = pathPoints.length - 1
            
            routeRequest = {
              origin: pathPoints.getAt(start), 
              destination: pathPoints.getAt(end),
              travelMode: google.maps.DirectionsTravelMode.DRIVING
            }

            if end - start > 1
              waypoints = []
              for k in [start+1..end-1]
                waypoints.push {location:pathPoints.getAt(k)}
              routeRequest.waypoints = waypoints

            @dirService.route routeRequest, (result, status) =>
              if status == google.maps.DirectionsStatus.OK
                routeLength = result.routes[0].overview_path.length - 1
                route = new google.maps.MVCArray
                for i in [0..routeLength]
                  route.push(result.routes[0].overview_path[i]);
                routeOpts = @buildOpts route if route.length > 0
                routeOpts.editable = false;
                polyRoute = new google.maps.Polyline routeOpts 
                if polyRoute
                  @routeParts.push polyRoute
              else
                console.log status
        , true

        if !scope.static and angular.isDefined(scope.editable)
          scope.$watch "editable", (newValue, oldValue) =>
            @polyline?.setEditable newValue if newValue != oldValue

        if angular.isDefined scope.draggable
          scope.$watch "draggable", (newValue, oldValue) =>
            @polyline?.setDraggable newValue if newValue != oldValue

        if angular.isDefined scope.visible
          scope.$watch "visible", (newValue, oldValue) =>
            @polyline?.setVisible newValue if newValue != oldValue

        if angular.isDefined scope.geodesic
          scope.$watch "geodesic", (newValue, oldValue) =>
            @polyline?.setOptions @buildOpts(@polyline.getPath()) if newValue != oldValue

        if angular.isDefined(scope.stroke) and angular.isDefined(scope.stroke.weight)
          scope.$watch "stroke.weight", (newValue, oldValue) =>
            @polyline?.setOptions @buildOpts(@polyline.getPath()) if newValue != oldValue

        if angular.isDefined(scope.stroke) and angular.isDefined(scope.stroke.color)
          scope.$watch "stroke.color", (newValue, oldValue) =>
            @polyline?.setOptions @buildOpts(@polyline.getPath()) if newValue != oldValue

        if angular.isDefined(scope.stroke) and angular.isDefined(scope.stroke.opacity)
          scope.$watch "stroke.opacity", (newValue, oldValue) =>
            @polyline?.setOptions @buildOpts(@polyline.getPath()) if newValue != oldValue

        if angular.isDefined(scope.icons)
          scope.$watch "icons", (newValue, oldValue) =>
            @polyline?.setOptions @buildOpts(@polyline.getPath()) if newValue != oldValue

        # Remove @polyline on scope $destroy
        scope.$on "$destroy", =>
          @clean()
          @scope = null

        $log.info @

      buildOpts: (pathPoints) =>
        opts = angular.extend({}, @defaults,
          map: @map
          path: pathPoints
          icons: @scope.icons
          strokeColor: @scope.stroke and @scope.stroke.color
          strokeOpacity: @scope.stroke and @scope.stroke.opacity
          strokeWeight: @scope.stroke and @scope.stroke.weight
        )
        angular.forEach
          clickable: true
          draggable: false
          editable: false
          geodesic: false
          visible: true
          static: false
          fit: false
        , (defaultValue, key) =>
          if angular.isUndefined(@scope[key]) or @scope[key] is null
            opts[key] = defaultValue
          else
            opts[key] = @scope[key]
        opts.editable = false if opts.static
        opts

      clean: =>
        @removeEvents @listeners
        if @polyline
          @polyline.setMap null
          @polyline = null
        _.each @routeParts, (r) =>
          r.setMap null
          r = null
        if arraySyncer
          arraySyncer()
          arraySyncer = null

      destroy: () ->
        @scope.$destroy()
]
