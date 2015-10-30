###
# Do Georeferencing from data
#
# Plug into CartoDB via
# http://docs.cartodb.com/cartodb-platform/cartodb-js.html
###

# CartoDB account name
cartoAccount = "tigerhawkvok"

cartoMap = null
cartoVis = null

adData = new Object()
window.geo = new Object()

geo.init = ->
  ###
  # Initialization script for the mapping protocols.
  # Urls are taken from
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html
  ###
  cartoDBCSS = """
  <link rel="stylesheet" href="http://libs.cartocdn.com/cartodb.js/v3/3.15/themes/css/cartodb.css" />
  """
  $("head").append cartoDBCSS
  doCallback = ->
    createMap "map", adData.cartoRef
    false
  loadJS "http://libs.cartocdn.com/cartodb.js/v3/3.15/cartodb.js", doCallback, false


defaultMapMouseOverBehaviour = (e, latlng, pos, data, layerNumber) ->
  console.log(e, latlng, pos, data, layerNumber);

createMap = (targetId = "map", dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28") ->
  ###
  # Creates a map and does some simple bindings.
  #
  # The default data is the one from the documentation, and shouldn't
  # be used in production.
  #
  # See:
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html#api-methods
  ###
  unless dataVisIdentifier?
    console.info "Can't create map without a data visualization identifier"
  dataVisUrl = "http://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataVisIdentifier}/viz.json"
  options =
    cartodb_logo: false
    https: true
    mobile_layout: true
    gmaps_base_type: "hybrid"
  unless $("##{targetId}").exists()
    fakeDiv = """
    <div id="#{targetId}" class="carto-map map">
      <!-- Dynamically inserted from unavailable target -->
    </div>
    """
    $("main").append fakeDiv
  cartodb.createVis targetId, dataVisUrl, options
  .done (vis, layers) ->
    console.info "Fetched data from CartoDB account #{cartoAccount}, from data set #{dataVisIdentifier}"
    cartoVis = vis
    cartoMap = vis.getNativeMap()
    layers[1].setInteraction(true)
    layers[1].on "featureOver", defaultMapMouseOverBehaviour
  .error (errorString) ->
    toastStatusMessage("Couldn't load maps!")
    console.error "Couldn't get map - #{errorString}"

requestCartoUpload = (data) ->
  ###
  # Acts as a shim between the server-side uploader and the client.
  # Send a request to the server to authenticate the current user
  # status, then, if successful, do an authenticated upload to the
  # client.
  #
  # Among other things, this approach secures the cartoDB API on the server.
  ###
  if typeof data isnt "object"
    console.info "This function requires the base data to be a JSON object."
    return false
  link = $.cookie "#{uri.domain}_link"
  hash = $.cookie "#{uri.domain}_auth"
  secret = $.cookie "#{uri.domain}_secret"
  unless link? and hash? and secret?
    console.error "You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret
    toastStatusMessage "Sorry, you're not logged in. Please log in and try again."
    return false
  args = "hash=#{hash}&secret=#{secret}&dblink=#{dblink}"
  $.post "admin_api.php", args, "json"
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

      foo()
      sampleLatLngArray = new Array()
      # Before we begin parsing, throw up an overlay for the duration
      # Loop over the data and clean it up
      # Create a GeoJSON from the data
      defaultPolygon = [
          [bb_north, bb_west]
          [bb_north, bb_east]
          [bb_south, bb_east]
          [bb_south, bb_west]
        ]
      # See if the user provided a good transect polygon
      try
        # See if the user provided a valid JSON string of coordinates
        userTransectRing = JSON.parse data.transectRing
        for coordinatePair in userTransectRing
          # Is it just two long?
          if coordinatePair.length isnt 2
            throw
              message: "Bad coordinate length for '#{coordinatePair}'"
          for coordinate in coordinatePair
            unless isNumber coordinate
              throw
                message: "Bad coordinate number '#{coordinate}'"
      catch e
        console.warn "Error parsing the user transect ring - #{e.message}"
        userTransectRing = undefined
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
      dataGeometry = "ST_AsGeoJSON(#{stringifiedObj})"
      # Update the overlay for sending to Carto
      # Post this data over to the back end
    else
      console.error "Unable to authenticate session. Please log in."
      toastStatusMessage "Sorry, your session has expired. Please log in and try again."
  .error (result, status) ->
    console.error "Couldn't communicate with server!", result, status
    toastStatusMessage "There was a problem communicating with the server. Please try again in a bit."
  false


$ ->
  # init()
