###
# Do Georeferencing from data
#
# Plug into CartoDB via
# http://docs.cartodb.com/cartodb-platform/cartodb-js.html
###

uri.domain = uri.o.attr("host").split(".").reverse().pop()

# CartoDB account name
cartoAccount = "tigerhawkvok"

# Google Maps API key
# This can be public, since we've restricted the referrer
gMapsApiKey = "AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"


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
  try
    # Center on Berkeley
    window.locationData.lat = 37.871527
    window.locationData.lng = -122.262113
    # Now get the real location
    getLocation()
  cartoDBCSS = """
  <link rel="stylesheet" href="http://libs.cartocdn.com/cartodb.js/v3/3.15/themes/css/cartodb.css" />
  """
  $("head").append cartoDBCSS
  doCallback = ->
    createMap adData.cartoRef
    false
  window.gMapsCallback = ->
    # Now that that's loaded, we can load CartoDB ...
    loadJS "http://libs.cartocdn.com/cartodb.js/v3/3.15/cartodb.js", doCallback, false
  # First, we have to load the Google Maps library
  loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=gMapsCallback"


defaultMapMouseOverBehaviour = (e, latlng, pos, data, layerNumber) ->
  console.log(e, latlng, pos, data, layerNumber);

createMap = (dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28", targetId = "map") ->
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
    https: true # Secure forcing is leading to resource errors
    mobile_layout: true
    gmaps_base_type: "hybrid"
    center_lat: window.locationData.lat
    center_lon: window.locationData.lng
    zoom: 7
  unless $("##{targetId}").exists()
    fakeDiv = """
    <div id="#{targetId}" class="carto-map map">
      <!-- Dynamically inserted from unavailable target -->
    </div>
    """
    $("main #main-body").append fakeDiv
  cartodb.createVis targetId, dataVisUrl, options
  .done (vis, layers) ->
    console.info "Fetched data from CartoDB account #{cartoAccount}, from data set #{dataVisIdentifier}"
    cartoVis = vis
    cartoMap = vis.getNativeMap()
    # For whatever reason, we still need to manually add the data
    cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
    .done (layer) ->
      # The actual interaction infowindow popup is decided on the data
      # page in Carto
      layer.setInteraction true
      layer.on "featureOver", defaultMapMouseOverBehaviour
  .error (errorString) ->
    toastStatusMessage("Couldn't load maps!")
    console.error "Couldn't get map - #{errorString}"

geo.requestCartoUpload = (data, dataTable, operation) ->
  ###
  # Acts as a shim between the server-side uploader and the client.
  # Send a request to the server to authenticate the current user
  # status, then, if successful, do an authenticated upload to the
  # client.
  #
  # Among other things, this approach secures the cartoDB API on the server.
  ###

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
  # Start doing real things
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  ## NOTE THIS SHOULD ACTUALLY VERIFY THAT THE DATA COULD BE WRITTEN
  # TO THIS PROJECT BY THIS PERSON!!!
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
      bb_east = lngs.max ? 0
      bb_west = lngs.min ? 0
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
      dataGeometry = "ST_AsGeoJSON(#{JSON.stringify(geoJson)})"
      # Rows per-sample ...
      # FIMS based
      # Uses DarwinCore terms
      # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
      columnDatatype =
        id: "int(10) NOT NULL AUTO_INCREMENT"
        collectionID: "varchar(255)"
        catalogNumber: "varchar(255)"
        fieldNumber: "varchar(255)"
        diseaseTested: "varchar(255)"
        diseaseStrain: "varchar(255)"
        sampleMethod: "varchar(255)"
        sampleDisposition: "varchar(255)"
        diseaseDetected: "varchar(14)"
        fatal: "boolean"
        cladeSampled: "varchar(255)"
        genus: "varchar(255)"
        specificEpithet: "varchar(255)"
        infraspecificEpithet: "varchar(255)"
        lifeStage: "varchar(255)"
        dateIdentified: "datetime" # Should be ISO8601; coerce it!
        decimalLatitude: "decimal"
        decimalLongitude: "decimal"
        alt: "decimal"
        coordinateUncertaintyInMeters: "decimal"
        Collector: "varchar(255)"
      # Construct the SQL query
      switch operation
        when "edit"
          sqlQuery = "UPDATE #{dataTable} "
          # Slice and dice!
        when "insert", "create"
          sqlQuery = ""
          if operation is "create"
            sqlQuery = "CREATE TABLE #{dataTable}; "
          sqlQuery += "INSERT INTO #{dataTable} "
          # Create a set of nice data blocks, then push that into the
          # query
          valuesList = ""
          # First row, the big collection
          dataObject =
            the_geom: dataGeometry
          # All the others ...
          valuesList = new Array()
          columnNamesList = new Array()
          columnNamesList.push "`id`  int(10) NOT NULL AUTO_INCREMENT"
          for n, row of data
            # Each row ...
            valuesArr = new Array()
            lat = 0
            lng = 0
            alt = 0
            err = 0
            geoJsonGeom =
              type: "Point"
              coordinates: new Array()
            for column, value of row
              # Loop data ....
              if n is 0
                columnNamesList.push "`#{column}` #{columnDatatype[column]}"
              try
                # Strings only!
                value = value.replace("'", "&#95;")
              switch column
                # Assign geoJSON values
                when "decimalLongitude"
                  geoJsonGeom.coordinates[1] = value
                when "decimalLatitude"
                  geoJsonGeom.coordinates[0] = value
              valuesArr.push "'#{value}'"
            # Add a GeoJSON column and GeoJSON values
            if n is 0
              columnNamesList.push "`the_geom`"
            geoJsonVal = "ST_AsGeoJSON(#{JSON.stringify(geoJsonGeom)})"            
            valuesList.push "(#{valuesArr.join(",")})"
          # Create the final query
          # Remove the first comma of valuesList
          sqlQuery = "#{sqlQuery} #{columnNamesList.join(",")} VALUES #{valuesList.join(", ")};"
        when "delete"
          sqlQuery = "DELETE FROM #{dataTable} WHERE "
          # Deletion criteria ...
      # Ping the server
      apiPostSqlQuery = encodeURIComponents encode64 sqlQuery
      args = "action=upload&sql_query=#{apiPostSqlQuery}"
      console.info "STOPPING INCOMPLETE EXECUTION"
      console.info "Would query with args", args
      console.info "Have query:"
      console.info sqlQuery
      return false
      $.post "api.php", args
      .done (result) ->
        if result.status isnt true
          console.error "Got an error from the server!"
          console.warn result
          toastStatusMessage "There was a problem uploading your data. Please try again."
          return false
        cartoResult = result.post_response
        resultRows = cartoResult.rows
        # Update the overlay for sending to Carto
        # Post this data over to the back end
        # Update the UI
        dataBlobUrl = "" # The returned viz.json url
        dataVisUrl = "http://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataBlobUrl}/viz.json"
        if cartoMap?
          cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
          .done (layer) ->
            # The actual interaction infowindow popup is decided on the data
            # page in Carto
            layer.setInteraction true
            layer.on "featureOver", defaultMapMouseOverBehaviour
        else
          createMap dataVisUrl
    else
      console.error "Unable to authenticate session. Please log in."
      toastStatusMessage "Sorry, your session has expired. Please log in and try again."
  .error (result, status) ->
    console.error "Couldn't communicate with server!", result, status
    console.warn "#{uri.urlString}admin_api.php?#{args}"
    toastStatusMessage "There was a problem communicating with the server. Please try again in a bit."
  false


$ ->
  # init()
