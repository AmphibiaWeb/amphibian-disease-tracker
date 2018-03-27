###
# Do Georeferencing from data
#
# Plug into CartoDB via
# http://docs.cartodb.com/cartodb-platform/cartodb-js.html
###

uri.domain = uri.o.attr("host").split(".").reverse().pop()

# CartoDB account name
cartoAccount = "mvz"

# Google Maps API key
# This can be public, since we've restricted the referrer
gMapsApiKey = "AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"


cartoMap = null
cartoVis = null

defaultFillColor = "#ff7800"
defaultFillOpacity = 0.35

adData = new Object()
window.geo = new Object()
geo.GLOBE_WIDTH_GOOGLE = 256 # Constant

geo.initLocation = ->
  try
    # Center on Berkeley
    window.locationData.lat = 37.871527
    window.locationData.lng = -122.262113
    # Now get the real location
    getLocation ->
      _adp.currentLocation = new Point window.locationData.lat, window.locationData.lng


geo.init = (doCallback) ->
  ###
  # Initialization script for the mapping protocols.
  # Urls are taken from
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html
  ###
  try
    # Center on Berkeley
    window.locationData.lat = 37.871527
    window.locationData.lng = -122.262113
    # Now get the real location
    getLocation ->
      _adp.currentLocation = new Point window.locationData.lat, window.locationData.lng
  cartoDBCSS = """
  <link rel="stylesheet" href="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css" />
  """
  $("head").append cartoDBCSS
  doCallback ?= ->
    getCanonicalDataCoords geo.dataTable
    false
  window.gMapsCallback = ->
    # Now that that's loaded, we can load CartoDB ...
    # loadJS "https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false
    doCallback()
  speculativeApiLoader()


speculativeApiLoader = ->
  # First, we have to load the Google Maps library
  unless isNull google?.maps?.Geocoder
    ###
    # Use maps element in attempt to address
    #
    # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/137
    # https://github.com/GoogleWebComponents/google-map/issues/308
    ###
    directLoadApi = ->
      unless isNull google?.maps?.Geocoder
        try
          console.debug "API element was insufficient. Loading direct API"
        loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=gMapsCallback"
    unless $("google-maps-api").exists()
      mapsApiElement = """
      <google-maps-api
        api-key="#{gMapsApiKey}" >
      </google-maps-api>
      """
      $("head").append mapsApiElement
      $("google-maps-api").on "api-load", ->
        try
          window.gMapsCallback()
      delay 300, ->
        directLoadApi()
    else
      directLoadApi()
  else
    try
      window.gMapsCallback()


getMapCenter = (bb = geo.canonicalBoundingBox) ->
  if bb?
    i = 0
    totalLat = 0.0
    totalLng = 0.0
    bbArray = Object.toArray bb
    for coords in bbArray
      ++i
      point = canonicalizePoint coords
      totalLat += point.lat
      totalLng += point.lng
      # console.info coords, i, totalLat
    centerLat = toFloat(totalLat) / toFloat(i)
    centerLng = toFloat(totalLng) / toFloat(i)

    center =
      lat: centerLat
      lng: centerLng
  else
    center =
      lat: window.locationData.lat
      lng: window.locationData.lng
  center = canonicalizePoint center
  center


getCorners = (coordSet) ->
  ###
  # Get the corners of a coordinate set
  ###
  polyBoundingBox = new Array()
  north = -90
  south = 90
  west = 180
  east = -180
  # Get the edges for this poly
  i = 0
  for points in coordSet
    if i is 0
      console.debug "Sample point:", points
    ++i
    if points.lat > north then north = points.lat
    if points.lng > east then east = points.lng
    if points.lng < west then west = points.lng
    if points.lat < south then south = points.lat
  # Create a bounding box for this poly
  edge =
    lat: north
    lng: west
  polyBoundingBox.push edge
  edge =
    lat: north
    lng: east
  polyBoundingBox.push edge
  edge =
    lat: south
    lng: east
  polyBoundingBox.push edge
  edge =
    lat: south
    lng: west
  polyBoundingBox.push edge
  # We want this last duplicate to "close the loop"
  edge =
    lat: north
    lng: west
  polyBoundingBox.push edge
  # Return it
  return polyBoundingBox




getPointsFromBoundingBox = (obj, asObj = false) ->
  ###
  # @param Object obj -> either an object with bounding box corners,
  #   or a projectData object.
  ###
  testCoordBounds = [
    "n"
    "e"
    "w"
    "s"
    ]
  failCase = false
  for direction in testCoordBounds
    key = "bounding_box_#{direction}"
    if isNull(obj[key]) or toInt(obj[key]) is 0
      failCase = true
      break
  unless failCase
    # Default
    corners = [
      [obj.bounding_box_n, obj.bounding_box_w]
      [obj.bounding_box_n, obj.bounding_box_e]
      [obj.bounding_box_s, obj.bounding_box_e]
      [obj.bounding_box_s, obj.bounding_box_w]
      ]
  else
    # Those base edges don't exist. Try the alternate method.
    cartoObj = obj.carto_id
    unless typeof cartoObj is "object"
      try
        cartoData = JSON.parse deEscape cartoObj
      catch e
        err1 = e.message
        try
          cartoData = JSON.parse cartoObj
        catch e
          if cartoObj.length > 511
            cartoJson = fixTruncatedJson cartoObj
            if typeof cartoJson is "object"
              console.debug "The carto data object was truncated, but rebuilt."
              cartoData = cartoJson
          if isNull cartoData
            console.error "Couldn't get bounding points: cartoObj must be JSON string or obj"
            return false
    else
      cartoData = cartoObj
    boundingPolygon = cartoData.bounding_polygon ? cartoData['bounding&#95;polygon']
    unless isNull boundingPolygon
      unless isNull boundingPolygon.multibounds
        console.debug "Using multibound coordinate assignment"
        boringMultiBounds = new Array()
        # Loop over each polygon
        for polygon in boundingPolygon.multibounds
          tempBoundingBox = getCorners polygon
          console.debug "Poly got corners #{JSON.stringify tempBoundingBox}", tempBoundingBox
          boringMultiBounds.push tempBoundingBox
          # End Poly loop
        superPoints = new Array()
        for bbSet in boringMultiBounds
          superPoints = superPoints.concat bbSet
        corners = getCorners superPoints
        # End multibound check
      else
        # No multibounds
        console.error "Project objects with no intrinsic bounding box and no multibounds are not supported yet"
        return false
    else
      console.error "Bad bounding box set, and not a projectData object"
      return false
  realCoords = new Array()
  for coords in corners
    console.log "Pushing corner", coords
    realCoords.push canonicalizePoint coords
  realCoords

geo.mapSelector ?= "#transect-viewport"

getMapZoom = (bb, selector = geo.mapSelector, zoomIt = true) ->
  ###
  # Get the zoom factor for Google Maps
  #
  # @param array|object bb -> Collection of Point objects
  # @param selector -> The map to reference
  # @param bool zoomIt -> if selector is a Google Map element, then
  #   apply zoom to it
  ###
  # Minimum zoom out, any more doesn't make sense for the project
  zoomOutThreshold = if $(window).width() < 1024 then 1 else 2
  if bb?
    eastMost = -180
    westMost = 180
    northMost = -90
    southMost = 90
    if isArray bb
      bb = toObject bb
    console.info "Working with dataset", bb
    if Object.size(bb) < 3
      console.warn "Danger: Very small dataset"
    for k, coords of bb
      lng = if coords.lng? then coords.lng else coords[1]
      lat = if coords.lat? then coords.lat else coords[0]
      if lng < westMost
        westMost = lng
      if lng > eastMost
        eastMost = lng
      if lat < southMost
        southMost = lat
      if lat > northMost
        northMost = lat
    angle = eastMost - westMost
    nsAngle = northMost - southMost
    while angle < 0
      angle += 360
    while nsAngle < 0
      nsAngle += 360
    unless $(selector).exists()
      console.warn "Can't find '#{selector}' - will use 650x480"
    mapWidth = $(selector).width() ? 650
    mapHeight = $(selector).height() ? 480
    adjAngle = 360 / angle
    mapScale = adjAngle / geo.GLOBE_WIDTH_GOOGLE
    nsAdjAngle = 360 / nsAngle
    nsMapScale = nsAdjAngle / geo.GLOBE_WIDTH_GOOGLE
    # Calculate the zoom factor
    # http://stackoverflow.com/questions/6048975/google-maps-v3-how-to-calculate-the-zoom-level-for-a-given-bounds
    zoomRaw = Math.log(mapWidth * mapScale) / Math.LN2
    nsZoomRaw = Math.log(mapHeight * nsMapScale) / Math.LN2
    console.info "Calculated raw zoom", zoomRaw, nsZoomRaw
    console.info "Sources", mapWidth, mapScale, Math.LN2
    if nsZoomRaw < zoomOutThreshold
      nsZoomRaw = 100
    if zoomRaw < zoomOutThreshold
      zoomRaw = 100
    # Use the one most zoomed out, eg, lowed number
    zoomBasis = if nsZoomRaw < zoomRaw then nsZoomRaw else zoomRaw
    if zoomOutThreshold > zoomBasis or zoomBasis > 20
      zoomBasis = 7.5
    zoomCalc = toInt zoomBasis
    console.log "Diff between zoomBasis vs zoomCalc", zoomBasis - zoomCalc
    # At high zooms, .6 can be tight, at low zooms, almost nothing is
    # comfy
    refTight = .6
    refZoom = 16
    zoomCalcBoundaryScale = refTight / refZoom
    zoomComfy = zoomCalcBoundaryScale * zoomBasis
    if zoomBasis - zoomCalc < zoomComfy
      --zoomCalc # Zoom out one point, less tight fit
    # if zoomCalc < 1
    #   zoomCalc = 7
  else
    zoomCalc = 7
  if zoomIt
    if $(selector).exists()
      if $(selector).get(0).tagName.toLowerCase() is "google-map"
        console.log "Trying to assign zoom"
        try
          map = p$(selector)
          if map.isAttached
            console.info "Setting zoom on #{selector} to #{zoomCalc}"
            map.zoom = zoomCalc
            map.ready = ->
              map.zoom = zoomCalc
          else
            console.info "Deferring till ready"
            $(selector).on "google-map-ready", ->
              map.zoom = zoomCalc
        catch
          console.warn "Zoom setting failed!"
  zoomCalc

geo.getMapZoom = getMapZoom


defaultMapMouseOverBehaviour = (e, latlng, pos, data, layerNumber) ->
  console.log(e, latlng, pos, data, layerNumber);



createMap2 = (pointsObj, options, callback) ->
  ###
  # Essentially a copy of CreateMap
  # Redo with
  # https://elements.polymer-project.org/elements/google-map#event-google-map-click
  #
  # @param array|object pointsObj -> an array or object of points
  #  (many types supported). For infowindow, the key "data" should be
  #  specified with FIMS data keys, eg, {"lat":37, "lng":-122, "data":{"genus":"Bufo"}}
  # @param object options -> {onClickCallback:function(), classes:[]}
  ###
  console.log "createMap2 was provided options:", options
  unless options?
    options = new Object()
    # Create defaults
    options =
      polyParams:
        fillColor: defaultFillColor
        fillOpacity: defaultFillOpacity
      classes: ""
      onClickCallback: null
      skipHull: false
      skipPoints: false
      boundingBox: null
      selector: "#carto-map-container"
      bsGrid: "col-md-9 col-lg-6"
      resetMapBuilder: true
      onlyOne: true
  if options.selector?
    selector = options.selector
  else
    selector = "#carto-map-container"
  if isNull options.onlyOne
    options.onlyOne = true
  try
    if options?.polyParams?.fillColor? and options?.polyParams?.fillOpacity?
      poly = options.polyParams
    else
      poly =
        fillColor: defaultFillColor
        fillOpacity: defaultFillOpacity
    console.info "createMap2 working with data", pointsObj
    unless Object.size(pointsObj) < 3
      data = createConvexHull pointsObj, true
      hull = data.hull
      points = data.points # canonicalized
    else
      # Insufficient points
      try
        pointList = Object.toArray pointsObj
      catch
        pointList = new Array()
      points = new Array()
      options.skipHull = true
      if pointList.length is 0
        options.skipPoints = true
      else
        for point in pointList
          console.log "Checking", point, "in", pointList
          points.push canonicalizePoint point
      if options.boundingBox?
        if options.boundingBox.nw?
          points.push canonicalizePoint options.boundingBox.nw
          points.push canonicalizePoint options.boundingBox.ne
          points.push canonicalizePoint options.boundingBox.sw
          points.push canonicalizePoint options.boundingBox.se
        else
          for point in options.boundingBox
            points.push canonicalizePoint point
        hull = createConvexHull points
        options.skipHull = false
    console.info "createMap2 working with", points
    try
      zoom = getMapZoom points, selector
      console.info "Got zoom", zoom
    catch
      zoom = ""
    unless options.skipHull is true
      mapHtml = """
      <google-map-poly closed fill-color="#{poly.fillColor}" fill-opacity="#{poly.fillOpacity}" stroke-weight="1">
      """
      for point in hull
        mapHtml += """
        <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
        """
      mapHtml += "    </google-map-poly>"
    else
      mapHtml = ""
    # Points
    unless options.skipPoints is true
      i = 0
      for point in points
        markerHtml = ""
        markerTitle = ""
        try
          if pointsObj[i].infoWindow?
            # Direct infowindow
            iw = pointsObj[i].infoWindow
            markerTitle = escape iw.title ? ""
            markerHtml = iw.html
            if pointsObj[i].data?
              pointData = pointsObj[i].data
              detected = if pointData.diseasedetected? then pointData.diseasedetected else pointData.diseaseDetected
              catalog = if pointData.catalognumber? then pointData.catalognumber else pointData.catalogNumber
              species = if pointData.specificepithet? then pointData.specificepithet else pointData.specificEpithet
              ssp = if pointData.infraspecificepithet? then pointData.infraspecificepithet else pointData.infraspecificeEpithet
              ssp ?= ""
              if isNull markerTitle then "#{catalog}: #{pointData.genus} #{species} #{ssp}"
            else
              detected = ""
          else if pointsObj[i].data?
            pointData = pointsObj[i].data
            genus = pointData.genus
            species = if pointData.specificepithet? then pointData.specificepithet else pointData.specificEpithet
            note = if pointData.originaltaxa? then pointData.originaltaxa else pointData.originalTaxa
            detected = if pointData.diseasedetected? then pointData.diseasedetected else pointData.diseaseDetected
            tested = if pointData.diseasetested? then pointData.diseasetested else pointData.diseaseTested
            genus ?= "No Data"
            species ?= ""
            note = unless isNull note then "(#{note})" else ""
            testString = if detected? and tested? then "<br/> Tested <strong>#{detected}</strong> for #{tested}" else ""
            markerHtml = """
              <p>
                <em>#{genus} #{species}</em> #{note}
                #{testString}
              </p>
            """
            if pointData.catalogNumber? or pointData.catalognumber?
              cat = if pointData.catalognumber? then pointData.catalognumber else pointData.catalogNumber
              ssp = if pointData.infraspecificepithet? then pointData.infraspecificepithet else pointData.infraspecificEpithet
              markerTitle = "#{cat}: #{genus} #{species}"
        point = canonicalizePoint point
        marker = """
        <google-map-marker latitude="#{point.lat}" longitude="#{point.lng}" data-disease-detected="#{detected}" title="#{markerTitle}" animation="DROP">
          #{markerHtml}
        </google-map-marker>
        """
        mapHtml += marker
      center = getMapCenter points
    else
      unless window.locationData?
        try
          # Center on Berkeley
          window.locationData.lat = 37.871527
          window.locationData.lng = -122.262113
          # Now get the real location
          getLocation ->
            _adp.currentLocation = new Point window.locationData.lat, window.locationData.lng
      center = new Point window.locationData.lat, window.locationData.lng
      zoom = 14
    # Make the whole map
    mapObjAttr = if geo.googleMap? then "map=\"geo.googleMap\"" else ""
    idSuffix = $("google-map").length
    id = "transect-viewport-#{idSuffix}"
    mapSelector = "##{id}"
    if options?.classes?
      if typeof options.classes is "object"
        a = Object.toArray options.classes
        classes = a.join " "
      else
        classes = options.classes
      classes = escape classes
    else
      classes = ""
    # fit-to-markers disable-default-ui
    googleMap = """
      <google-map id="#{id}" latitude="#{center.lat}" longitude="#{center.lng}" map-type="hybrid" click-events  zoom="#{zoom}" class="col-xs-12 #{options.bsGrid} center-block clearfix google-map transect-viewport map-viewport #{classes}" api-key="#{gMapsApiKey}" #{mapObjAttr}>
            #{mapHtml}
      </google-map>
    """
    # Append it
    if options.onlyOne is true
      selector = $("google-map").get(0)
    unless $(selector).exists()
      try
        console.debug "Selector does not exist:", selector
      selector = "#carto-map-container"
      unless $(selector).exists()
        selector = "body"
    unless $(selector).get(0).tagName.toLowerCase() is "google-map"
      console.log "Appending map to selector #{selector}", $(selector)
      $(selector)
      .addClass "map-container has-map"
      .append googleMap
    else
      console.log "Replacing map at selector #{selector}"
      $(selector).replaceWith googleMap
    # Events
    # See
    # https://elements.polymer-project.org/elements/google-map#events
    console.log "Attaching events to #{mapSelector}"
    unless window.mapBuilder?
      window.mapBuilder = new Object()
      window.mapBuilder.points = new Array()
      window.mapBuilder.selector = "#" + $(mapSelector).attr "id"

    unless options?.resetMapBuilder is false
      window.mapBuilder.points = new Array()
    else
      window.mapBuilder.selector = "#" + $(mapSelector).attr "id"

    unless options?.onClickCallback?
      unless options?
        options = new Object()
      # Default click callback
      options.onClickCallback = (point, mapElement) ->
        unless window.mapBuilder?
          window.mapBuilder = new Object()
          window.mapBuilder.selector = "#" + $(mapElement).attr "id"
          window.mapBuilder.points = new Array()
        window.mapBuilder.points.push point
        try
          $("#using-computed-locality").remove()
        $("#init-map-build").removeAttr "disabled"
        $("#init-map-build .points-count").text window.mapBuilder.points.length
        # https://github.com/GoogleWebComponents/google-map/issues/180
        marker = document.createElement "google-map-marker"
        marker.setAttribute "latitude", point.lat
        marker.setAttribute "longitude", point.lng
        marker.setAttribute "animation", "DROP"
        Polymer.dom(mapElement).appendChild(marker)
        false
    # Bind the event
    $("#{mapSelector}")
    .on "google-map-click", (e) ->
      # https://developers.google.com/maps/documentation/javascript/3.exp/reference#MouseEvent
      ll = e.originalEvent.detail.latLng
      point = canonicalizePoint ll
      console.info "Clicked point #{point.toString()}", point, ll
      if typeof options.onClickCallback is "function"
        options.onClickCallback point, this
      else
        console.warn "google-map-click wasn't provided a callback"
      false
    r =
      # Compatible with mapBuilder objects
      selector: mapSelector
      html: googleMap
      points: points
      hull: hull
      center: center
    console.info "Map", r
    geo.googleMapWebComponent = googleMap
    # Callback
    if typeof callback is "function"
      console.log "createMap2 calling back"
      callback r
    r
  catch e
    console.error "Couldn't create map! #{e.message}"
    console.warn e.stack
  false

reInitMap = (selector) ->
  map = p$(selector)
  map.map = null
  o = map.objects
  map._initGMap()
  newObjects = new Array()
  for obj in o
    if obj.tagName.toLowerCase() is "google-map-poly"
      obj._points = new Array()
      $(obj).find("google-map-point").each ->
        lat = $(this).attr "latitude"
        lng = $(this).attr "longitude"
        newPoint =
          lat: toFloat lat
          lng: toFloat lng
        newLL = new google.maps.LatLng newPoint
        obj._points.push newLL
      obj.path = null
      obj.map = map.map
      polyOptions =
        # https://github.com/GoogleWebComponents/google-map/blob/master/google-map-poly.html#L500
        clickable: obj.clickable or obj.draggable
        draggable: obj.draggable
        editable: obj.editable
        geodesic: obj.geodesic
        map: obj.map
        strokeColor: obj.strokeColor
        strokeOpacity: obj.strokeOpacity
        strokePosition: obj._convertStrokePosition()
        strokeWeight: obj.strokeWeight
        visible: !obj.hidden
        zIndex: obj.zIndex
      poly = new google.maps.Polygon polyOptions
      poly.setPaths obj._points
      obj._setPoly poly
      # obj._mapChanged()
      newObjects.push obj
  # End loop
  map.objects = newObjects


buildMap = (mapBuilderObj = window.mapBuilder, options, callback) ->
  unless options?
    options =
      selector: mapBuilderObj.selector
      resetMapBuilder: false
  createMap2 mapBuilderObj.points, options, callback
  false


getPointsFromCartoResult = (cartoResultRows, sorted = false) ->
  ###
  # From a cartoDB result row, return an array of points
  #
  # @param obj|array cartoResultRows -> The returned carto result rows
  # @param bool sorted -> Should the results be sorted?
  #
  # @return array
  ###
  try
    rows = Object.toArray cartoResultRows
    points = new Array()
    for row in rows
      pointString = row.st_asgeojson
      pointObj = JSON.parse pointString
      cartoCoords = pointObj.coordinates
      coords =
        lat: cartoCoords[1]
        lng: cartoCoords[0]
      p = canonicalizePoint coords
      points.push p
    if sorted
      oldPoints = points.slice 0
      points = sortPoints oldPoints
    return points
  catch e
    console.error "Couldn't get points: #{e.message}"
    console.warn e.stack
  false


featureClickEvent = (e, latlng, pos, data, layer, template) ->
  ###
  # Generalized click event
  ###
  console.log "Clicked feature event", data, pos, latlng
  colNames = new Array()
  for col, val of data
    colNames.push col
  colNamesManual = [
    "genus"
    "specificepithet"
    "diseasedetected"
    "dateidentified"
    ]
  if template?
    options =
      infowindowTemplate: template
      templateType: 'mustache'
  else
    options = null
  # geo.infoWindow = cartodb.vis.Vis.addInfowindow geo.lMap, layer, colNames, options
  # try
  #   geo.infoWindow.on "close", ->
  #     this.remove()
  false


createRawCartoMap = (layers, callback, options, mapSelector = "#global-data-map", clickEvent = featureClickEvent) ->
  ###
  # Create a raw CartoDB map
  #
  # See
  # https://docs.cartodb.com/cartodb-platform/cartodb-js/getting-started/#creating-visualizations-at-runtime
  #
  ###
  if isNull options
    options = new Object()

  unless layers.user_name?
    params =
      user_name: options.user_name ? cartoAccount
      type: options.type ? "cartodb"
      sublayers: layers
      extra_params:
        map_key: window.apiKey # For testing and not leaking
        api_key: window.apiKey # For testing and not leaking
  else
    params = layers

  console.info "Creating map", params

  # The CartoDB layer options
  mapOptions =
    cartodb_logo: false
    https: true
    mobile_layout: true
    #gmaps_base_type: "hybrid"
    #center_lat: window.locationData.lat,
    #center_lon: window.locationData.lng
    #zoom: 5

  try
    # Google Map Setup
    googleMapOptions =
      center: new google.maps.LatLng(mapOptions.center_lat ? 0, mapOptions.center_lon ? 0)
      zoom: mapOptions.zoom
      mapTypeId: google.maps.MapTypeId.TERRAIN
    # geo.googleMap = new google.maps.Map
    geo.googleMap = p$(mapSelector).map
    # document.getElementById(mapSelector.slice(1)), googleMapOptions
    # BASE_MAP = p$(mapSelector).map
    # BASE_MAP = geo.googleMap

  ## Leflet Map Setup
  leafletOptions =
    center: [window.locationData.lat, window.locationData.lng]
    zoom: 5
  unless geo.lMap?
    lMap = new L.Map("global-map-container", leafletOptions)
    geo.lMap = lMap
    lTopoOptions =
      attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions).addTo lMap
  BASE_MAP = if localStorage.useTestMap then geo.googleMap else  geo.lMap

  cartodb
  .createLayer(BASE_MAP, params, mapOptions)
  .addTo(BASE_MAP, 1)
  .on "done", (layer) ->
    # console.info "Done, returned", layer, "for type #{params.type}"
    try
      layer.setParams "table_name", params.named_map.params.table_name
    catch
      console.warn "Couldn't explicitly set table"
    if isArray layers
      for dataLayer in layers
        console.info "Re-adding sublayer", dataLayer
        layer.createSubLayer dataLayer
      console.info "Added layers to map"
    unless geo.mapSublayers?
      geo.mapSublayers = new Array()
    max = layer.getSubLayerCount()
    try
      layer.setInteraction(true)
    try
      layer.unbind "featureClick"
    layer
    .on "featureClick", (e, latlng, pos, data, layerIndex) ->
      # console.log "Clicked feature", data, pos, latlng
      # if geo.infoWindow?
      #   geo.infoWindow.remove()
      tableName = params.named_map.params.table_name.slice 0, 63
      clickEvent.debounce 150, false, null, e, latlng, pos, data, layer, $("#infowindow_template_#{tableName}").outerHtml()
      false
    .on "error", (err) ->
      console.warn "Error on layer feature click", err
    i = 0
    setTemplate = (sublayerToSet, tableName, count = 0, carrySublayerIndex, workingLayer) ->
      selector = "#infowindow_template_#{tableName}"
      template = window._adp.templates?[tableName] ? $(selector).html()
      if isNull template
        template = $(selector).html()
        if isNull(template) and count %% 100 is 0 and count > 0
          console.warn "Warning: null template for table '#{tableName}' @ sublayer #{carrySublayerIndex}", template
      unless isNull template
        # https://carto.com/docs/carto-engine/carto-js/api-methods/#sublayerinfowindow
        # https://raw.githubusercontent.com/CartoDB/cartodb.js/develop/examples/custom_infowindow.html
        infoWindowTemplate =
          template: template
          width: 218
          maxHeight: 250
        #sublayerToSet.infowindow.set "template", template
        sublayerToSet.infowindow.set infoWindowTemplate
        console.info "Successfully set template #{selector} on sublayer #{carrySublayerIndex}"
        try
          colNamesManual = [
            "genus"
            "specificepithet"
            "diseasedetected"
            "dateidentified"
            ]
          infoWindowParser = (inputHtml) ->
            # Override the default sanitizer
            console.debug "Running infowindow parser on ", inputHtml
            $("body .temp-parser").remove()
            $("body").append """
            <div class='temp-parser'>
              #{inputHtml}
            </div>
            """
            # Trim dates to year only
            # See https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/174
            $(".temp-parser").find(".unix-date").each ->
              dateMs = $(this).text()
              if isNull dateMs
                $(this).parent().remove()
              if isNumber dateMs
                dateMs = toInt dateMs
              d = new Date(dateMs)
              y = d.getUTCFullYear()
              $(this).replaceWith y
            # Show the disposition, if avaiable
            # See
            # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/174
            $(".temp-parser").find(".disposition").each ->
              label = $(this).find(".disposition-label")
              if isNull label
                console.debug "Removed empty disposition from label"
                $(this).remove()
            # Store it
            outputHtml = $(".temp-parser").html()
            # Cleanup
            $(".temp-parser").remove()
            console.debug "Parser output", outputHtml
            outputHtml
          # https://carto.com/docs/carto-engine/carto-js/api-methods/#sublayerinfowindow
          options =
            infowindowTemplate: $(selector).html()
            templateType: 'mustache'
            sanitizeTemplate: infoWindowParser
          try
            workingLayer.getSubLayer(carrySublayerIndex).infowindow.sanitizeTemplate = infoWindowParser
            console.debug "Assigned template parser to sublayer"
          catch e
            console.warn "Couldn't assign template parser - #{e.message}"
            console.warn e.stack
          cartodb.vis.Vis.addInfowindow geo.lMap, workingLayer.getSubLayer(carrySublayerIndex), colNamesManual, options
          console.info "Successfully assigned template #{selector} to sublayer #{carrySublayerIndex} in vis"
          console.debug "template", template
          console.debug "selector", $(selector).html()
        if carrySublayerIndex is 0
          try
            workingLayer.infowindow.set "template", template
            console.info "Successfully assigned template to primary layer", template
        if carrySublayerIndex is workingLayer.getSubLayerCount() - 1
          console.info "Showing layer for '#{tableName}' after successful template assignment for all sublayers"
          workingLayer.show()
      else
        if count < 100
          delay 200, ->
            count = count + 1
            setTemplate sublayerToSet, tableName, count, carrySublayerIndex, workingLayer
        else
          console.warn "Timed out (count: #{count}) trying to assign a template for '#{tableName}'", selector, "https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/154"
          workingLayer.show()
      false # end setTemplate
    while i < max
      suTemp = layer.getSubLayer(i)
      suTemp.setInteraction(true)
      try
        shortTable = params.named_map.params.table_name.slice 0, 63
        setTemplate suTemp, shortTable, 0, i, layer
      geo.mapSublayers.push suTemp
      ++i
    # layer.show()
    try
      console.log "Layer counts:", BASE_MAP.overlayMapTypes.length
    if typeof callback is "function"
      callback()
    false
  .on "error", (errorString) ->
    toastStatusMessage("Couldn't load maps!")
    console.error "Couldn't get map - #{errorString}"
  false



createMap = (dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28", targetId = "carto-map-container", options, callback) ->
  ###
  # Creates a map and does some simple bindings.
  #
  # The default data is the one from the documentation, and shouldn't
  # be used in production.
  #
  # See:
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html#api-methods
  #
  ###
  unless dataVisIdentifier?
    console.info "Can't create map without a data visualization identifier"
  # Set up post-configuration helper
  geo.mapId = targetId
  geo.mapSelector = "##{targetId}"
  postConfig = ->
    options ?=
      cartodb_logo: false
      https: true
      mobile_layout: true
      gmaps_base_type: "hybrid"
      center_lat: window.locationData.lat
      center_lon: window.locationData.lng
      zoom: getMapZoom(geo.boundingBox)
    geo.mapParams = options
    unless $("##{targetId}").exists()
      fakeDiv = """
      <div id="#{targetId}" class="carto-map wide-map map-container">
        <!-- Dynamically inserted from unavailable target -->
      </div>
      """
      $("main #main-body").append fakeDiv
    unless typeof callback is "function"
      callback = (layer, cartoMap) ->
        # For whatever reason, we still need to manually add the data
        cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
        .done (layer) ->
          # The actual interaction infowindow popup is decided on the data
          # page in Carto
          geo.mapLayer = layer
          try
            layer.setInteraction true
            layer.on "featureOver", defaultMapMouseOverBehaviour
          catch
            console.warn "Can't set carto map interaction"
    # Create a map layer
    googleMapOptions =
      center: new google.maps.LatLng(options.center_lat, options.center_lon)
      zoom: options.zoom
      mapTypeId: google.maps.MapTypeId.HYBRID
    geo.googleMap = new google.maps.Map document.getElementById(targetId), googleMapOptions
    geo.cartoMap = geo.googleMap
    gMapCallback = (layer) ->
      console.info "Fetched data into Google Map from CartoDB account #{cartoAccount}, from data set #{dataVisIdentifier}"
      geo.mapLayer = layer
      geo.cartoMap = geo.googleMap
      clearTimeout forceCallback
      if typeof callback is "function"
        callback(layer, geo.cartoMap)
      false
    try
      console.info "About to render map with options", geo.cartoUrl, options
      cartodb.createLayer(geo.googleMap, geo.cartoUrl, options).addTo(geo.googleMap)
      .on "done", (layer) ->
        gMapCallback(layer)
      .on "error", (errorString) ->
        toastStatusMessage("Couldn't load maps!")
        console.error "Couldn't get map - #{errorString}"
      forceCallback = delay 1000, ->
        if typeof callback is "function"
          console.warn "Callback wasn't called, forcing"
          callback(null, geo.cartoMap)
    catch
      # Try the callback anyway
      console.warn "The map threw an error! #{e.message}"
      console.warn e.stack
      clearTimeout forceCallback
      if typeof callback is "function"
        callback(null, geo.cartoMap)
    false
  ###
  # Now that we have the helper function, let's get the viz data
  ###
  unless typeof dataVisIdentifier is "object"
    # Is the dataVisIdentifier the whole url?
    if /^https?:\/\/.*$/m.test(dataVisIdentifier)
      # For a complete URL, we just reassign
      dataVisUrl = dataVisIdentifier
    else
      dataVisUrl = "https://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataVisIdentifier}/viz.json"
    geo.cartoUrl = dataVisUrl
    postConfig()
  else
    # Construct our own data for viz.jon to use with our data
    # Sample
    # http://tigerhawkvok.cartodb.com/api/v2/viz/38544c04-5e56-11e5-8515-0e4fddd5de28/viz.json
    dataVisJson = new Object()
    sampleUrl = "http://tigerhawkvok.cartodb.com/api/v2/viz/38544c04-5e56-11e5-8515-0e4fddd5de28/viz.json"
    $.get sampleUrl, "", "json"
    .done (result) ->
      dataVisJson = result
      for key, value of dataVisIdentifier
        # Merge them
        # Overwrite full dataset with user provided one
        dataVisJson[key] = value
    .fail (result, status) ->
      # Get something!
      dataVisJson = dataVisIdentifier
    .always ->
      dataVisUrl = dataVisJson
      geo.cartoUrl = dataVisUrl
      postConfig()

getColumnObj = (forceBase = false) ->
  # http://www.biscicol.org/template
  columnDatatype =
    id: "int"
    collectionID: "varchar"
    catalogNumber: "varchar"
    sampleId: "varchar"
    diseaseTested: "varchar"
    diseaseStrain: "varchar"
    sampleMethod: "varchar"
    sampleDisposition: "varchar"
    diseaseDetected: "varchar"
    fatal: "boolean"
    cladeSampled: "varchar"
    genus: "varchar"
    specificEpithet: "varchar"
    infraspecificEpithet: "varchar"
    lifeStage: "varchar"
    dateIdentified: "date" # Should be ISO8601; coerce it!
    decimalLatitude: "decimal"
    decimalLongitude: "decimal"
    alt: "decimal"
    coordinateUncertaintyInMeters: "decimal"
    Collector: "varchar"
    originalTaxa: "varchar"
    sex: "varchar"
    datum: "text"
    fimsExtra: "json" # Text? http://www.postgresql.org/docs/9.3/static/datatype-json.html
    the_geom: "varchar"
  if _adp.activeCols? and not forceBase
    return _adp.activeCols
  columnDatatype


geo.requestCartoUpload = (totalData, dataTable, operation, callback) ->
  ###
  # Acts as a shim between the server-side uploader and the client.
  # Send a request to the server to authenticate the current user
  # status, then, if successful, do an authenticated upload to the
  # client.
  #
  # Among other things, this approach secures the cartoDB API on the server.
  ###
  startLoad()
  try
    data = totalData.data
  # How's the data?
  if typeof data isnt "object"
    console.info "This function requires the base data to be a JSON object."
    toastStatusMessage "Your data is malformed. Please double check your data and try again."
    return false

  # Is this a legitimate operation?
  allowedOperations = [
    "edit"
    "insert"
    "delete"
    "create"
    ]
  unless operation in allowedOperations
    console.error "#{operation} is not an allowed operation on a data set!"
    console.info "Allowed operations are ", allowedOperations
    toastStatusMessage "Sorry, '#{operation}' isn't an allowed operation."
    return false

  if isNull dataTable
    console.error "Must use a defined table name!"
    toastStatusMessage "You must name your data table"
    return false

  # Is the user allowed and logged in?
  link = $.cookie "#{uri.domain}_link"
  hash = $.cookie "#{uri.domain}_auth"
  secret = $.cookie "#{uri.domain}_secret"
  unless link? and hash? and secret?
    console.error "You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret
    toastStatusMessage "Sorry, you're not logged in. Please log in and try again."
    return false

  # We want the data tables to be unique, so we'll suffix them with
  # the user link.
  dataTable = "#{dataTable}_#{link}"
  # dataTable = dataTable.slice(0,63)
  # Start doing real things
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  ## NOTE THIS SHOULD ACTUALLY VERIFY THAT THE DATA COULD BE WRITTEN
  # TO THIS PROJECT BY THIS PERSON!!!
  #
  # Some of this could, in theory, be done via
  # http://docs.cartodb.com/cartodb-platform/cartodb-js/sql/
  unless adminParams?.apiTarget?
    console.warn "Administration file not loaded. Upload cannot continue"
    stopLoadError "Administration file not loaded. Upload cannot continue"
    return false
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    if result.status
      ###
      # Now that we've done an authenticated request, and handled that
      # sort of error, we can actually use CartoDB's SQL API and
      # upload the data.
      #
      # http://docs.cartodb.com/cartodb-platform/sql-api.html
      #
      # The data itself will be preprocessed as a GeoJSON:
      # http://geojson.org/geojson-spec.html
      # http://www.postgis.org/documentation/manual-svn/ST_SetSRID.html
      # http://www.postgis.org/documentation/manual-svn/ST_Point.html
      #
      # Assume Spatial Reference System 4326, http://spatialreference.org/ref/epsg/4326/
      # http://www.postgis.org/documentation/manual-svn/using_postgis_dbmanagement.html#spatial_ref_sys
      ###
      sampleLatLngArray = new Array()
      # Before we begin parsing, throw up an overlay for the duration
      # Loop over the data and clean it up
      # Create a GeoJSON from the data
      lats = new Array()
      lngs = new Array()
      for n, row of data
        ll = new Array()
        for column, value of row
          switch column
            when "decimalLongitude"
              ll[1] = value
              lngs.push value
            when "decimalLatitude"
              ll[0] = value
              lats.push value
        sampleLatLngArray.push ll
      bb_north = lats.max() ? 0
      bb_south = lats.min() ? 0
      bb_east = lngs.max() ? 0
      bb_west = lngs.min() ? 0
      defaultPolygon = [
          [bb_north, bb_west]
          [bb_north, bb_east]
          [bb_south, bb_east]
          [bb_south, bb_west]
        ]
      # See if the user provided a good transect polygon
      try
        # See if the user provided a valid JSON string of coordinates
        userTransectRing = JSON.parse totalData.transectRing
        userTransectRing = Object.toArray userTransectRing
        i = 0
        for coordinatePair in userTransectRing
          if coordinatePair instanceof Point
            # Coerce it into simple coords
            coordinatePair = coordinatePair.toGeoJson()
            userTransectRing[i] = coordinatePair
          # Is it just two long?
          if coordinatePair.length isnt 2
            throw
              message: "Bad coordinate length for '#{coordinatePair}'"
          for coordinate in coordinatePair
            unless isNumber coordinate
              throw
                message: "Bad coordinate number '#{coordinate}'"
          ++i
      catch e
        console.warn "Error parsing the user transect ring - #{e.message}"
        userTransectRing = undefined
      # Massive object row
      transectPolygon = userTransectRing ? defaultPolygon
      geoJson =
        type: "GeometryCollection"
        geometries: [
              type: "MultiPoint"
              coordinates: sampleLatLngArray # An array of all sample points
            ,
              type: "Polygon"
              coordinates: transectPolygon
          ]
      dataGeometry = "ST_AsBinary(#{JSON.stringify(geoJson)}, 4326)"
      # Rows per-sample ...
      # FIMS based
      # Uses DarwinCore terms
      # http://www.biscicol.org/biocode-fims/template#
      # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
      columnDatatype = getColumnObj(true)
      # Construct the SQL query
      switch operation
        when "edit"
          sqlQuery = "UPDATE #{dataTable} "
          foo()
          return false
          # Slice and dice!
        when "insert", "create"
          sqlQuery = ""
          if operation is "create"
            sqlQuery = "CREATE TABLE #{dataTable} "
          # Create a set of nice data blocks, then push that into the
          # query
          # First row, the big collection
          dataObject =
            the_geom: dataGeometry
          # All the others ...
          valuesList = new Array()
          columnNamesList = new Array()
          columnNamesList.push "id int"
          _adp.rowsCount = Object.size data
          for i, row of data
            i = toInt(i)
            ##console.log "Iter ##{i}", i is 0, `i == 0`
            # Each row ...
            valuesArr = new Array()
            lat = 0
            lng = 0
            alt = 0
            err = 0
            geoJsonGeom =
              type: "Point"
              coordinates: new Array()
            iIndex = i + 1
            valuesArr.push iIndex
            for column, value of row
              # Loop data ....
              if i is 0
                lowCol = column.toLowerCase()
                columnDef = columnDatatype[column] ? columnDatatype[lowCol]
                if typeof columnDef is "object"
                  columnDef = columnDef.type
                if isNull columnDef
                  columnDef = "text"
                columnNamesList.push "#{column} #{columnDef}"
              try
                # Strings only!
                value = value.replace("'", "&#95;")
              switch column
                # Assign geoJSON values
                when "decimalLongitude"
                  geoJsonGeom.coordinates[1] = value
                when "decimalLatitude"
                  geoJsonGeom.coordinates[0] = value
              if typeof value is "string"
                valuesArr.push "'#{value}'"
              else if isNull value
                valuesArr.push "null"
              else
                valuesArr.push value
            # Add a GeoJSON column and GeoJSON values
            if i is 0
              console.log "We're appending to col names list"
              columnNamesList.push "the_geom geometry"
              if operation is "create"
                sqlQuery = "#{sqlQuery} (#{columnNamesList.join(",")}); "
            # cartoDB stores in lng, lat
            geoJsonVal = "ST_SetSRID(ST_Point(#{geoJsonGeom.coordinates[1]},#{geoJsonGeom.coordinates[0]}),4326)"
            # geoJsonVal = "ST_AsBinary(#{JSON.stringify(geoJsonGeom)}, 4326)"
            valuesArr.push geoJsonVal
            valuesList.push "(#{valuesArr.join(",")})"
          # Create the final query
          # Remove the first comma of valuesList
          maxStatementLength = 4096
          insertMaxLength = 15
          insertPlace = 0
          console.info "Inserting statements of max length #{maxStatementLength}"
          longestStatement = 0
          shortestStatement = maxStatementLength
          tempList = new Array()
          while valuesList.slice(insertPlace, insertPlace + insertMaxLength).length > 0
            statements = 0
            while tempList.join(", ").length < maxStatementLength - 1
              ++statements
              tempList = valuesList.slice(insertPlace, insertPlace + statements)
              if statements > insertMaxLength
                break
            # Too big now by one
            statements--
            if statements > longestStatement
              longestStatement = statements
            if statements < shortestStatement
              shortestStatement = statements
            tempList = valuesList.slice(insertPlace, insertPlace + statements)
            insertPlace += statements
            sqlQuery += "INSERT INTO #{dataTable} VALUES #{tempList.join(", ")};"
          # For the last query, cartodbfy
          cdbfy = "SELECT cdb_cartodbfytable('#{dataTable}');"
          sqlQuery += cdbfy
          console.info "Constructed statements: maximum #{longestStatement} rows, minimum #{shortestStatement} rows"
        when "delete"
          sqlQuery = "DELETE FROM #{dataTable} WHERE "
          # Deletion criteria ...
          foo()
          return false
      try
        geo.postToCarto sqlQuery, dataTable, callback
      catch
        stopLoadBarsErrors()
    else
      console.error "Unable to authenticate session. Please log in."
      stopLoadError "Sorry, your session has expired. Please log in and try again."
  .fail (result, status) ->
    console.error "Couldn't communicate with server!", result, status
    console.warn "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
    stopLoadError "There was a problem communicating with the server. Please try again in a bit. (E-001)"
    $("#upload-data").removeAttr "disabled"
  false


geo.postToCarto = (sqlQuery, dataTable, callback) ->
  # Ping the server
  apiPostSqlQuery = encodeURIComponent encode64 sqlQuery
  args = "action=upload&sql_query=#{apiPostSqlQuery}"
  # console.info "Would query with args", args
  console.info "Querying:"
  console.info sqlQuery
  try
    _adp.postedSqlQuery = sqlQuery
    _adp.postedSqlQueryStatements = sqlQuery.split ");"
  # $("#main-body").append "<pre>Would send Carto:\n\n #{sqlQuery}</pre>"
  # console.info "GeoJSON:", geoJson
  # console.info "GeoJSON String:", dataGeometry
  console.info "POSTing to server"
  # console.warn "Want to post:", "#{uri.urlString}api.php?#{args}"
  # Big uploads can take a while, so let's put up a notice.
  $("#data-sync").removeAttr("indeterminate")
  postTimeStart = Date.now()
  workingIter = 0
  # http://birdisabsurd.blogspot.com/p/one-paragraph-stories.html
  story = ["A silly story for you, while you wait!","Everything had gone according to plan, up 'til this moment.","His design team had done their job flawlessly,","and the machine, still thrumming behind him,","a thing of another age,","was settled on a bed of prehistoric moss.","They'd done it.","But now,","beyond the protection of the pod","and facing an enormous Tyrannosaurus rex with dripping jaws,","Professor Cho reflected that,","had he known of the dinosaur's presence,","he wouldn’t have left the Chronoculator","- and he certainly wouldn't have chosen 'Staying&#39; Alive',","by The Beegees,","as his dying soundtrack.","Curse his MP3 player!", "The End.", "Yep, your data is still being processed", "And we're out of fun things to say", "We hope you think it's all worth it"]
  doStillWorking = ->
    extra = if story[workingIter]? then "(#{story[workingIter]})" else ""
    toastStatusMessage "Still working ... #{extra}"
    ++workingIter
    window._adp.secondaryTimeout = delay 15000, ->
      doStillWorking()
  try
    estimate = toInt(.7 * _adp.rowsCount)
    console.log "Estimate #{estimate} seconds"
    window._adp.uploader = true
    $("#data-sync").removeAttr "indeterminate"
    max = estimate * 30 # 30fps
    try
      p$("#data-sync").max = max
    do updateUploadProgress = (prog = 0) ->
      # Update a progress bar
      try
        p$("#data-sync").value = prog
      ++prog
      if window._adp.uploader and prog <= max
        delay 33, ->
          updateUploadProgress(prog)
      else if prog > max
        toastStatusMessage "This may take a few minutes. We'll give you an error if things go wrong."
        window._adp.secondaryTimeout = delay 15000, ->
          doStillWorking()
      else
        console.log "Not running upload progress indicator", prog, window._adp.uploader, max
  catch e
    console.warn "Can't show upload status - #{e.message}"
    console.warn e.stack
    # Alternate notices
    try
      window._adp.initialTimeout = delay 5000, ->
        estMin = toInt(estimate / 60) + 1
        minWord = if estMin > 1 then "minutes" else "minute"
        toastStatusMessage "Please be patient, it may take a few minutes (we guess #{estMin} #{minWord})"
        window._adp.secondaryTimeout = delay 15000, ->
          doStillWorking()
    catch e2
      console.error "Can't show backup upload notices! #{e2.message}"
      console.warn e2.stack
  estimateStartRef = Date.now()
  $.post "api.php", args, "json"
  .done (result) ->
    console.log "Got back response from carto", result
    try
      realDuration = roundNumber (Date.now() - estimateStartRef) / 1000, 1
      console.info "Really took #{realDuration}s (estimated #{estimate}s)", realDuration/estimate
    if result.status isnt true
      console.error "Got an error from the server!"
      console.warn result
      stopLoadError "There was a problem uploading your data. Please try again."
      bsAlert "<strong>There was a problem uploading your data</strong>: the server said <code>#{result.error}</code>", "danger"
      return false
    cartoResults = result.post_response
    cartoHasError = false
    for j, response of cartoResults
      if not isNull response?.error
        error = if response?.error? then response.error[0] else "Unspecified Error"
        cartoHasError = error
      try
        response = JSON.parse response
        for key, val of response
          if key is "error"
            cartoHasError = val
    unless cartoHasError is false
      console.error "There was an error communicating with cartoDB!"
      bsAlert "Error uploading your data to CartoDB: <code>#{cartoHasError}</code>", "danger"
      stopLoadError "CartoDB returned an error: #{cartoHasError}"
      return false
    console.info "Carto was successful! Got results", cartoResults
    try
      # http://marianoguerra.github.io/json.human.js/
      prettyHtml = JsonHuman.format cartoResults
      # $("#main-body").append "<div class='alert alert-success'><strong>Success! Carto said</strong>#{$(prettyHtml).html()}</div>"
    bsAlert("Upload to CartoDB of table <code>#{dataTable}</code> was successful", "success")
    $("#cancel-new-upload").remove()
    toastStatusMessage("Data parse and upload successful")
    geo.dataTable = dataTable
    # resultRows = cartoResults.rows
    # Update the overlay for sending to Carto
    # Post this data over to the back end
    # Update the UI
    # Get the blob URL ..
    # https://gis.stackexchange.com/questions/171283/get-a-viz-json-uri-from-a-table-name
    #
    dataBlobUrl = "" # The returned viz.json url
    unless isNull dataBlobUrl
      dataVisUrl = "https://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataBlobUrl}/viz.json"
    else if typeof dataBlobUrl is "object"
      # Parse the object
      dataVisUrl = dataBlobUrl
    else
      dataVisUrl = ""
    parentCallback = (coords) ->
      console.info "Initiating parent callback"
      stopLoad()
      try
        max = p$("#data-sync").max
        p$("#data-sync").value = max
      $("#data-sync").removeAttr("indeterminate")
      options =
        boundingBox: geo.boundingBox
        bsGrid: ""
      if window.mapBuilder?.selector?
        options.selector = window.mapBuilder.selector
      else if $("google-map").exists()
        options.selector = $($("google-map").get(0)).attr "id"
      else
        options.selector = "#carto-map-container"
      _adp.defaultMapOptions = options
      if typeof callback is "function"
        callback geo.dataTable, coords, options
      else
        console.info "requestCartoUpload recieved no callback"
    geo.init ->
      # Callback
      console.info "Post init"
      getCanonicalDataCoords geo.dataTable, null, (coords, options) ->
        console.info "gcdc callback successful", coords
        parentCallback(coords)
      false
  .fail (result, status) ->
    kbSize = args.length / 1024
    console.error "Couldn't communicate with server (#{result.status} #{result.statusText})! POST size #{kbSize} kiB", result, status
    console.warn "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
    stopLoadError "There was a problem communicating with the server. Please try again in a bit. (E-002)"
    bsAlert "Couldn't upload dataset. Please try again later.", "danger"
  .always ->
    try
      duration = Date.now() - postTimeStart
      console.info "POST and process took #{duration}ms"
      clearTimeout window._adp.initialTimeout
      clearTimeout window._adp.secondaryTimeout
      window._adp.uploader = false
      $("#upload-data").removeAttr "disabled"
  false



sortPoints = (pointArray, asObj = true) ->
  ###
  # Take an array of Points and return a Google Maps compatible array
  # of coordinate objects
  ###
  window.upper = upperLeft pointArray
  pointArray.sort pointSort
  sortedPoints = new Array()
  for coordPoint in pointArray
    if asObj
      sortedPoints.push coordPoint.getObj()
    else
      point = coordPoint.toSimplePoint()
      sortedPoints.push point
  delete window.upper
  sortedPoints


canonicalizePoint = (point, swapConvention = false) ->
  ###
  # Take really any type of point, and return a Point
  ###
  pointObj =
    lat: null
    lng: null
  # Type conversions
  try
    tempLat = toFloat point.lat
    if tempLat.toString() is point.lat
      unless swapConvention
        point.lat = toFloat point.lat
        point.lng = toFloat point.lng
      else
        point.lat = toFloat point.lng
        point.lng = toFloat point.lat
    else
      tempLat = toFloat point[0]
      if tempLat.toString() is point[0]
        unless swapConvention
          point[0] = toFloat point[0]
          point[1] = toFloat point[1]
        else
          point[0] = toFloat point[1]
          point[1] = toFloat point[0]
  # Tests
  if typeof point?.lat is "number"
    pointObj = point
  else if typeof point?[0] is "number"
    pointObj =
      lat: point[0]
      lng: point[1]
  else
    try
      # Test fPoint or Google LatLng
      if typeof point.lat() is "number"
        pointObj.lat = point.lat()
        pointObj.lng = point.lng()
      else
        throw "Not fPoint"
    catch
      # Test Point
      try
        if typeof point.getLat() is "number"
          pointObj = point.getObj()
        else
          throw "Not Point"
      catch
        # Test Google Map markers
        if google?.map?
          try
            gLatLng = point.getPosition()
            pointObj.lat = gLatLng.lat()
            pointObj.lng = gLatLng.lng()
          catch
            throw "Unable to determine point type"
  pReal = new Point pointObj.lat, pointObj.lng
  pReal



createConvexHull = (pointsArray, returnObj = false) ->
  ###
  # Take an array of points of multiple types and get a minimum convex
  # hull back
  #
  # @param obj|array pointsArray -> An array of points or simple
  #   object of points
  #
  # @return array -> an array of Point objects
  ###
  simplePointArray = new Array()
  realPointArray = new Array()
  startTime = Date.now()
  console.log "createConvexHull called with #{Object.size(pointsArray)} points"
  pointsArray = Object.toArray pointsArray
  # Quickly check conventions
  swapConventions = false
  for point in pointsArray
    if Math.abs(point.lng) > 90
      # We know that these are really lngs
      break
    if Math.abs(point.lat) > 90
      # These "lats" should be "lngs"
      swapConventions = true
      break
  for point in pointsArray
    canonicalPoint = canonicalizePoint point, swapConventions
    realPointArray.push canonicalPoint
  try
    console.info "Getting convex hull (original: #{pointsArray.length}; canonical: #{realPointArray.length})", realPointArray
    try
      chConfig = getConvexHull realPointArray
    catch
      console.warn "Couldn't run real way!"
      simplePointArray = sortPoints realPointArray, false
      cpHull = getConvexHullPoints simplePointArray
    cpHull = chConfig.paths
  catch e
    console.error "Unable to get convex hull - #{e.message}"
    console.warn e.stack
  geo.canonicalBoundingBox = new Array()
  for point in cpHull
    geo.canonicalBoundingBox.push point.getObj()
  obj =
    hull: cpHull
    points: realPointArray
  geo.canonicalHullObject = obj
  try
    elapsed = Date.now() - startTime
    console.debug "createConvexHull completed in #{elapsed}ms"
  if returnObj is true
    return obj
  cpHull


fPoint = (lat, lng) ->
  @latval = lat
  @lngval = lng
  @lat = ->
    @latval
  @lng = ->
    @lngval
  @toString = ->
    "(#{@x}, #{@y})"
  this.toString()


Point = (lat, lng) ->
  # From
  # http://stackoverflow.com/a/2863378
  @lat = toFloat lat
  @lng = toFloat lng
  @x = (@lng + 180) * 360
  @y = (@lat + 90) * 180
  @distance = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    Math.sqrt dx**2 + dy**2
  @slope = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    dy / dx
  @toString = ->
    "(#{@lat}, #{@lng})"
  @getObj = ->
    o =
      lat: @lat
      lng: @lng
    o
  @getLatLng = ->
    if google?.maps?
      # https://developers.google.com/maps/documentation/javascript/3.exp/reference#LatLng
      obj = @getObj()
      return new google.maps.LatLng(obj)
    else
      return @getObj()
  @getLat = ->
    @lat
  @getLng = ->
    @lng
  @toSimplePoint = ->
    p = new fPoint @lat, @lng
    p
  @toGeoJson = ->
    gj = [@lat, @lng]
    gj
  this.toString()

geo.Point = Point
# Find a minimum convex polygon
`
// A custom sort function that sorts p1 and p2 based on their slope
// that is formed from the upper most point from the array of points.
function pointSort(p1, p2) {
    // Exclude the 'upper' point from the sort (which should come first).
    if(p1 == upper) return -1;
    if(p2 == upper) return 1;

    // Find the slopes of 'p1' and 'p2' when a line is
    // drawn from those points through the 'upper' point.
    var m1 = upper.slope(p1);
    var m2 = upper.slope(p2);

    // 'p1' and 'p2' are on the same line towards 'upper'.
    if(m1 == m2) {
        // The point closest to 'upper' will come first.
        return p1.distance(upper) < p2.distance(upper) ? -1 : 1;
    }

    // If 'p1' is to the right of 'upper' and 'p2' is the the left.
    if(m1 <= 0 && m2 > 0) return -1;

    // If 'p1' is to the left of 'upper' and 'p2' is the the right.
    if(m1 > 0 && m2 <= 0) return 1;

    // It seems that both slopes are either positive, or negative.
    return m1 > m2 ? -1 : 1;
}

// Find the upper most point. In case of a tie, get the left most point.
function upperLeft(points) {
    var top = points[0];
    for(var i = 1; i < points.length; i++) {
        var temp = points[i];
        if(temp.y > top.y || (temp.y == top.y && temp.x < top.x)) {
            top = temp;
        }
    }
    return top;
}`

Number::toRad = ->
  this * Math.PI / 180

geo.distance = (lat1, lng1, lat2, lng2) ->
  ###
  # Distance across Earth curvature
  #
  # Measured in km
  ###
  # Radius of Earth, const (Volumentric Mean)
  # http://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
  R = 6371
  dLat = (lat2 - lat1).toRad()
  dLon = (lng2 - lng1).toRad()
  semiLat = dLat / 2
  semiLng = dLon / 2
  # Get the actual curves
  arc = Math.sin(semiLat)**2 + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(semiLng)**2
  curve = 2 * Math.atan2 Math.sqrt(arc), Math.sqrt(1-arc)
  # Return the real distance
  R * curve


geo.getBoundingRectangle = (coordinateSet = geo.boundingBox) ->
  coordinateSet = Object.toArray coordinateSet
  if isNull coordinateSet
    console.warn "Need a set of coordinates for the bounding rectangle!"
    return false
  northMost = -90
  southMost = 90
  westMost = 180
  eastMost = -180
  for coordinates in coordinateSet
    coords = canonicalizePoint coordinates
    lat = coords.lat
    lng = coords.lng
    if lat > northMost
      northMost = lat
    if lat < southMost
      southMost = lat
    if lng < westMost
      westMost = lng
    if lng > eastMost
      eastMost = lng
  boundingBox =
    nw: [northMost, westMost]
    ne: [northMost, eastMost]
    se: [southMost, eastMost]
    sw: [southMost, westMost]
    north: northMost
    east: eastMost
    west: westMost
    south: southMost
  geo.computedBoundingRectangle = boundingBox
  boundingBox

window.lastRanGeocoder = 0

wait = (ms) ->
  start = new Date().getTime()
  console.log "Will wait #{ms}ms after #{start}"
  end = start
  while end < start + ms
    end = new Date().getTime()
    if window.endWait is true
      end = start + ms + 1
  console.log "Waited #{ms}ms"
  end

localityFromMapBuilder = (builder = window.mapBuilder, callback) ->
  ###
  #
  #
  # @param builder -> an object with an array of (canonicalized) points under
  #   mapBuilder.points, and a selector under mapBuilder.selector
  ###
  MAX_QUERIES_PER_SECOND = 50
  maxQueryRateEff = MAX_QUERIES_PER_SECOND / 20
  maxQueryRate = 1000 / maxQueryRateEff
  sinceLastGeocoder = Date.now() - window.lastRanGeocoder - randomInt(1,25)
  if sinceLastGeocoder < maxQueryRate
    console.debug "It's been #{sinceLastGeocoder}ms since last attempt to geocode (min: #{maxQueryRate}ms), delaying"
    delay maxQueryRate, ->
      localityFromMapBuilder builder, callback
    return false
  window.lastRanGeocoder = Date.now()
  center = getMapCenter builder.points
  geo.reverseGeocode center.lat, center.lng, builder.points, (locality, googleResult) ->
    console.info "Got locality '#{locality}'", googleResult
    builder.views = googleResult
    if typeof callback is "function"
      try
        callback locality, builder
      catch
        callback locality
  false


doMapBuilder = (builder = window.mapBuilder, createMapOptions, callback)->
  unless createMapOptions?
    createMapOptions =
      selector: builder.selector
      resetMapBuilder: false
  # By default, preserve the builder
  unless createMapOptions.resetMapBuilder?
    createMapOptions.resetMapBuilder = false
  unless typeof builder?.points is "object"
    console.error "Invalid builder", builder
    return false
  buildMap builder, createMapOptions, (map) ->
    geo.boundingBox = map.hull
    localityFromMapBuilder map, (locality)  ->
      map.locality = locality
      console.info "Map results:", map
      if typeof callback is "function"
        callback map
      false


geo.geocode = (address, filter, callback) ->
  ###
  #
  #
  # @param string address -> Text address
  # @param obj filter -> A componentRestrictions object. See
  #   https://developers.google.com/maps/documentation/javascript/geocoding#ComponentFiltering
  # @param func callback
  ###
  try
    if geo.geocoder?
      geocoder = geo.geocoder
    else
      geocoder = new google.maps.Geocoder
      geo.geocoder = geocoder
  catch e
    console.error "Couldn't instance a google map geocoder - #{e.message}"
    console.warn e.stack
    return false
  # Function for geocoder
  doGeocoder = ->
    # https://developers.google.com/maps/documentation/javascript/geocoding#Geocoding
    geocoderData =
      address: address
      componentRestrictions: filter
    geocoder.geocode geocoderData, (result, status) ->
      console.log "Geocoder fetched", result, status
      console.log "Provided", geocoderData
      if status isnt google.maps.GeocoderStatus.OK
        console.warn "Geocoder failed -- Google said", status
        return false
      mainResult = result[0]
      tmp = new Object()
      tmp.google = new Object()
      tmp.human = mainResult.formatted_address
      try
        for part in mainResult.address_components
          try
            type = part.types[0]
            tmp.google[type] = part.long_name
          catch
            continue
      tmp.partial_match = mainResult.partial_match
      if typeof callback is "function"
        callback tmp
      else
        console.warn "No callback provided! Got address object", tmp
  # Well-defined addresses should use this API
  # https://developers.google.com/maps/documentation/geocoding/intro#geocoding
  restrictionlessApiKey = null # See API console to enable this
  if address? and restrictionlessApiKey?
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    componentsArr = new Array()
    for key, val of filter
      str = "#{key}:#{encodeURIComponent(val)}"
      componentsArr.push str
    componentsString = componentsArr.join "|"
    # Using the other key here returns
    # "Browser API keys cannot have referer restrictions when used with this API."
    args = "address=#{encodeURIComponent(address)}&components=#{componentsString}&key=#{restrictionlessApiKey}"
    console.log "Trying", "#{url}?#{args}"
    $.get url, args, "json"
    .done (result) ->
      console.log "API hit fetched", result
      mainResult = result.results[0]
      status = result.status
      if status isnt google.maps.GeocoderStatus.OK
        console.warn "Geocoder failed -- Google said", status
        doGeocoder()
        return false
      tmp = new Object()
      tmp.google = new Object()
      tmp.human = mainResult.formatted_address
      try
        for part in mainResult.address_components
          try
            type = part.types[0]
            tmp.google[type] = part.long_name
          catch
            continue
      tmp.partial_match = mainResult.partial_match
      if typeof callback is "function"
        callback tmp
      else
        console.warn "No callback provided! Got address object", tmp
    .fail (result, status) ->
      console.error "Error (#{status}): Couldn't post to Google, trying geocoder"
      doGeocoder()
  # For fuzzy data ...
  else
    doGeocoder()
  false

geo.reverseGeocode = (lat, lng, boundingBox = geo.boundingBox, callback) ->
  ###
  # https://developers.google.com/maps/documentation/javascript/examples/geocoding-reverse
  ###
  try
    if geo.geocoder?
      geocoder = geo.geocoder
    else
      geocoder = new google.maps.Geocoder
      geo.geocoder = geocoder
  catch e
    console.error "Couldn't instance a google map geocoder - #{e.message}"
    console.warn e.stack
    return false
  ll =
    lat: toFloat lat
    lng: toFloat lng
  request =
    location: ll
  console.debug "Starting reverse geocoder"
  geocoder.geocode request, (result, status) ->
    if status is google.maps.GeocoderStatus.OK
      console.info "Google said:", result
      geo.geocoderViews = result
      mustContain = geo.getBoundingRectangle(boundingBox)
      validView = null
      for view in result
        validView = view
        googleBounds = view.geometry.bounds
        unless googleBounds?
          continue
        ne = googleBounds.getNorthEast()
        sw = googleBounds.getSouthWest()
        north = ne.lat()
        south = sw.lat()
        east = ne.lng()
        west = sw.lng()
        # Check the coords
        if north < mustContain.north then continue
        if south > mustContain.south then continue
        if west > mustContain.west then continue
        if east < mustContain.east then continue
        # We're good
        break
      locality = validView.formatted_address
      # It's possible, though not likely, that the valid view doesn't
      # actually contain everything
      tooNorth = north < mustContain.north
      tooSouth = south > mustContain.south
      tooWest = west > mustContain.west
      tooEast = east < mustContain.east
      if tooNorth or tooSouth or tooWest or tooEast
        console.warn "The last locality, '#{locality}', doesn't contain all coordinates!"
        console.warn "North: #{!tooNorth}, South: #{!tooSouth}, East: #{!tooEast}, West: #{!tooWest}"
        console.info "Using", validView, mustContain
        # We merely want the "region" then
        locality = "near #{locality} (nearest region)"

      console.info "Computed locality: '#{locality}'"
      geo.computedLocality = locality
      window.lastRanGeocoder = Date.now()
      if typeof callback is "function"
        try
          callback locality, result
        catch
          callback(locality)
      else
        console.warn "No callback provided to geo.reverseGeocode()!"
    else
      console.error "There was a problem getting the locality", result, status
      if typeof callback is "function"
        console.warn "Proceeding anyway with fake locality 'Bad Locality'"
        geo.computedLocality = "Bad Locality"
        callback("Bad Locality")



toggleGoogleMapMarkers = (diseaseStatus = "positive", selector="#transect-viewport", callback) ->
  ###
  #
  ###
  selector = "#{selector} google-map-marker[data-disease-detected='#{diseaseStatus}']"
  markers = $(selector)
  console.info "Got #{markers.length} markers"
  state = undefined
  for marker in markers
    unless state?
      state = not p$(marker).open
      console.info "Setting #{diseaseStatus} markers open state to #{state}"
    p$(marker).open = state
  if typeof callback is "function"
    callback(state)
  false

setupMapMarkerToggles = ->
  ###
  #
  ###
  html = """
  <div class="row">
    <h3 class="col-xs-12">
      Toggle map markers
    </h3>
    <button class="btn btn-danger col-xs-3 toggle-marker" data-disease-status="positive">Positive</button>
    <button class="btn btn-primary col-xs-3 toggle-marker" data-disease-status="negative">Negative</button>
    <button class="btn btn-warning col-xs-3 toggle-marker" data-disease-status="no_confidence"><span class="hidden-xs">Inconclusive</span><span class="visible-xs-inline">?</span></button>
  </div>
  """
  unless $(".toggle-marker").exists()
    $("google-map + div").append html
  console.log "Setting up events for map marker toggles"
  $(".toggle-marker")
  .unbind()
  .click ->
    status = $(this).attr "data-disease-status"
    $(".aweb-link-species").removeAttr "hidden"
    console.log "Clicked '#{status}' toggle"
    toggleGoogleMapMarkers status, null, (isOpen) ->
      if status is "no_confidence"
        status = "inconclusive"
      if isOpen
        console.info "Hiding selector", ".aweb-link-species:not([data-#{status}='true'])"
        $(".aweb-link-species:not([data-#{status}='true'])").attr "hidden", "hidden"
      else
        console.info "Removing hidden attribute"
  false




###
# Minimum Convex Hull
# view-source:http://www.geocodezip.com/v3_map-markers_ConvexHull.asp
###
getConvexHull = (googleMapsMarkersArray) ->
  try
    test = googleMapsMarkersArray[0]
    ll = test.getPosition()
  catch
    # Not a Google Maps Marker array
    # https://developers.google.com/maps/documentation/javascript/3.exp/reference#Marker
    gmmReal = new Array()
    for point in googleMapsMarkersArray
      gmm = new google.maps.Marker
      try
        # Point object
        ll = point.getLatLng()
      catch
        # Just an object
        # Construct new LatLng
        # https://developers.google.com/maps/documentation/javascript/3.exp/reference#LatLng
        llObj =
          lat: point.lat
          lng: point.lng
        ll = new google.maps.LatLng llObj
      gmm.setPosition ll
      gmmReal.push gmm
    googleMapsMarkersArray = gmmReal.slice 0
  points = new Array()
  for marker in googleMapsMarkersArray
    points.push marker.getPosition()
  points.sort sortPointY
  points.sort sortPointX
  try
    console.debug "Convex hull being formed from", points.slice 0
  getConvexHullConfig(points)

sortPointX = (a, b) ->
  a.lng() - b.lng()

sortPointY = (a, b) ->
  a.lat() - b.lat()


sortPointsXY = (pointArray) ->
  ###
  # Sort an array of points by first Y then X
  ###
  pointArray.sort sortPointY
  pointArray.sort sortPointX
  pointArray


getConvexHullPoints = (points) ->
  ###
  # Get the actual convex hull.
  #
  # You almost never want to call this directly -- call
  # createConvexHull() instead.
  #
  # @param array points -> pre-configured and pre-sorted points.
  #
  # @return array
  ###
  hullPoints = new Array() # The array to be filled
  unless isArray points
    console.error "Function requires an array"
    return false
  realHull = new Array()
  try
    ###
    # Set up for algorithm from
    # https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain#JavaScript
    #
    #
    # This successfully plots project 9eb9fc11cf289dd2c7b68665a5eaa018
    ###
    unless points[0] instanceof Point
      oldPoints = points.slice 0
      points = new Array()
      for point in oldPoints
        points.push canonicalizePoint point
      hullPoints = convexHull points
    for point in hullPoints
      pObj = new Point point.lat, point.lng
      realHull.push pObj
  catch
    ###
    # Set up for algorith from
    # https://github.com/mgomes/ConvexHull
    #
    # Usually works, but fails for
    # 9eb9fc11cf289dd2c7b68665a5eaa018
    ###
    if points[0] instanceof Point
      oldPoints = points.slice 0
      points = new Array()
      for point in oldPoints
        points.push point.toSimplePoint()
      console.debug "Converted Point array to fPoint array", points.slice 0
    chainHull_2D points, points.length, hullPoints
    for point in hullPoints
      pObj = new Point point.lat(), point.lng()
      realHull.push pObj
  console.info "Got hull from #{points.length} points:", realHull
  realHull

getConvexHullConfig = (points, map = geo.googleMap) ->
  ###
  # Gets the convex hull with all the standard configuration helpers
  # for a Google Map object.
  #
  # Expects everything to be "pretty" -- you almost certainly want to
  # call createConvexHull() instead.
  #
  # @param array points -> well-formed array of points
  # @param GoogleMap map -> Google Map object
  ###
  hullPoints = getConvexHullPoints points
  polygonConfig =
    map: map
    paths: hullPoints
    fillColor: defaultFillColor
    fillOpacity: defaultFillOpacity
    strokeWidth: 2
    strokeColor: "#0000FF"
    strokeOpacity: 0.5
  # cHullPoly = new google.maps.Polygon polygonConfig
  # false


`
function cross(o, a, b) {
   return (a.lat - o.lat) * (b.lng - o.lng) - (a.lng - o.lng) * (b.lat - o.lat)
}

/**
 * @param points An array of [X, Y] coordinates
 */
function convexHull(points) {
   points.sort(function(a, b) {
      return a.lat == b.lat ? a.lng - b.lng : a.lat - b.lat;
   });

   var lower = [];
   for (var i = 0; i < points.length; i++) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], points[i]) <= 0) {
         lower.pop();
      }
      lower.push(points[i]);
   }

   var upper = [];
   for (var i = points.length - 1; i >= 0; i--) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], points[i]) <= 0) {
         upper.pop();
      }
      upper.push(points[i]);
   }

   upper.pop();
   lower.pop();
   return lower.concat(upper);
}
`

`
    var gmarkers = [];
    var points = [];
    var hullPoints = [];
    var map = null;
      var polyline;
     function calculateConvexHull() {
      if (polyline) polyline.setMap(null);
      document.getElementById("hull_points").innerHTML = "";
      points = [];
      for (var i=0; i < gmarkers.length; i++) {
        points.push(gmarkers[i].getPosition());
      }
      points.sort(sortPointY);
      points.sort(sortPointX);
      DrawHull();
}

     function DrawHull() {
     hullPoints = [];
     chainHull_2D( points, points.length, hullPoints );
     polyline = new google.maps.Polygon({
      map: map,
      paths:hullPoints,
      fillColor:"#FF0000",
      strokeWidth:2,
      fillOpacity:0.5,
      strokeColor:"#0000FF",
      strokeOpacity:0.5
     });
     displayHullPts();
}

function displayHullPts() {
     document.getElementById("hull_points").innerHTML = "";
     for (var i=0; i < hullPoints.length; i++) {
       document.getElementById("hull_points").innerHTML += hullPoints[i].toUrlValue()+"<br>";
     }
   }
`


`
// Copyright 2001, softSurfer (www.softsurfer.com)
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.
// http://softsurfer.com/Archive/algorithm_0203/algorithm_0203.htm
// Assume that a class is already given for the object:
//    Point with coordinates {float x, y;}
//===================================================================

// isLeft(): tests if a point is Left|On|Right of an infinite line.
//    Input:  three points P0, P1, and P2
//    Return: >0 for P2 left of the line through P0 and P1
//            =0 for P2 on the line
//            <0 for P2 right of the line

function isLeft(P0, P1, P2) {
    return (P1.lng() - P0.lng()) * (P2.lat() - P0.lat()) - (P2.lng() - P0.lng()) * (P1.lat() - P0.lat());
}
//===================================================================

// chainHull_2D(): A.M. Andrew's monotone chain 2D convex hull algorithm
// http://softsurfer.com/Archive/algorithm_0109/algorithm_0109.htm
//
//     Input:  P[] = an array of 2D points
//                   presorted by increasing x- and y-coordinates
//             n = the number of points in P[]
//     Output: H[] = an array of the convex hull vertices (max is n)
//     Return: the number of points in H[]


function chainHull_2D(P, n, H) {
    // the output array H[] will be used as the stack
    var bot = 0,
    top = (-1); // indices for bottom and top of the stack
    var i; // array scan index
    // Get the indices of points with min x-coord and min|max y-coord
    var minmin = 0,
        minmax;

    var xmin = P[0].lng();
    for (i = 1; i < n; i++) {
        if (P[i].lng() != xmin) {
            break;
        }
    }

    minmax = i - 1;
    if (minmax == n - 1) { // degenerate case: all x-coords == xmin
        H[++top] = P[minmin];
        if (P[minmax].lat() != P[minmin].lat()) // a nontrivial segment
            H[++top] = P[minmax];
        H[++top] = P[minmin]; // add polygon endpoint
        return top + 1;
    }

    // Get the indices of points with max x-coord and min|max y-coord
    var maxmin, maxmax = n - 1;
    var xmax = P[n - 1].lng();
    for (i = n - 2; i >= 0; i--) {
        if (P[i].lng() != xmax) {
            break;
        }
    }
    maxmin = i + 1;

    // Compute the lower hull on the stack H
    H[++top] = P[minmin]; // push minmin point onto stack
    i = minmax;
    while (++i <= maxmin) {
        // the lower line joins P[minmin] with P[maxmin]
        if (isLeft(P[minmin], P[maxmin], P[i]) >= 0 && i < maxmin) {
            continue; // ignore P[i] above or on the lower line
        }

        while (top > 0) { // there are at least 2 points on the stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break; // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    // Next, compute the upper hull on the stack H above the bottom hull
    if (maxmax != maxmin) { // if distinct xmax points
        H[++top] = P[maxmax]; // push maxmax point onto stack
    }

    bot = top; // the bottom point of the upper hull stack
    i = maxmin;
    while (--i >= minmax) {
        // the upper line joins P[maxmax] with P[minmax]
        if (isLeft(P[maxmax], P[minmax], P[i]) >= 0 && i > minmax) {
            continue; // ignore P[i] below or on the upper line
        }

        while (top > bot) { // at least 2 points on the upper stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break;  // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

// breaks algorithm
//        if (P[i].lng() == H[0].lng() && P[i].lat() == H[0].lat()) {
//            return top + 1; // special case (mgomes)
//        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    if (minmax != minmin) {
        H[++top] = P[minmin]; // push joining endpoint onto stack
    }

    return top + 1;
}
`


$ ->
  if $("google-maps-api").exists()
    $("google-maps-api").on "api-load", ->
      try
        window.gMapsCallback()
  speculativeApiLoader()
