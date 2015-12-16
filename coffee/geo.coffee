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
    getLocation()
  cartoDBCSS = """
  <link rel="stylesheet" href="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css" />
  """
  $("head").append cartoDBCSS
  doCallback ?= ->
    createMap adData.cartoRef
    false
  window.gMapsCallback = ->
    # Now that that's loaded, we can load CartoDB ...
    loadJS "https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false
  # First, we have to load the Google Maps library
  loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=gMapsCallback"


defaultMapMouseOverBehaviour = (e, latlng, pos, data, layerNumber) ->
  console.log(e, latlng, pos, data, layerNumber);

createMap = (dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28", targetId = "map", options, callback) ->
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
  # Set up post-configuration helper
  geo.mapId = targetId
  geo.mapSelector = "##{targetId}"
  postConfig = ->
    options ?=
      cartodb_logo: false
      https: true # Secure forcing is leading to resource errors
      mobile_layout: true
      gmaps_base_type: "hybrid"
      center_lat: window.locationData.lat
      center_lon: window.locationData.lng
      zoom: 7
    unless $("##{targetId}").exists()
      fakeDiv = """
      <div id="#{targetId}" class="carto-map wide-map">
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
      console.wan e.stack
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

geo.requestCartoUpload = (totalData, dataTable, operation, callback) ->
  ###
  # Acts as a shim between the server-side uploader and the client.
  # Send a request to the server to authenticate the current user
  # status, then, if successful, do an authenticated upload to the
  # client.
  #
  # Among other things, this approach secures the cartoDB API on the server.
  ###
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
      dataGeometry = "ST_AsBinary(#{JSON.stringify(geoJson)}, 4326)"
      # Rows per-sample ...
      # FIMS based
      # Uses DarwinCore terms
      # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
      columnDatatype =
        id: "int"
        collectionID: "varchar"
        catalogNumber: "varchar"
        fieldNumber: "varchar"
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
        the_geom: "varchar"
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
          valuesList = ""
          # First row, the big collection
          dataObject =
            the_geom: dataGeometry
          # All the others ...
          valuesList = new Array()
          columnNamesList = new Array()
          columnNamesList.push "id int"
          for i, row of data
            i = toInt(i)
            console.log "Iter ##{i}", i is 0, `i == 0`
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
                columnNamesList.push "#{column} #{columnDatatype[column]}"
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
            geoJsonVal = "ST_SetSRID(ST_Point(#{geoJsonGeom.coordinates[0]},#{geoJsonGeom.coordinates[1]}),4326)"
            # geoJsonVal = "ST_AsBinary(#{JSON.stringify(geoJsonGeom)}, 4326)"
            valuesArr.push geoJsonVal
            valuesList.push "(#{valuesArr.join(",")})"
          # Create the final query
          # Remove the first comma of valuesList
          sqlQuery = "#{sqlQuery}INSERT INTO #{dataTable} VALUES #{valuesList.join(", ")};"
        when "delete"
          sqlQuery = "DELETE FROM #{dataTable} WHERE "
          # Deletion criteria ...
          foo()
          return false
      # Ping the server
      apiPostSqlQuery = encodeURIComponent encode64 sqlQuery
      args = "action=upload&sql_query=#{apiPostSqlQuery}"
      console.info "STOPPING INCOMPLETE EXECUTION"
      console.info "Would query with args", args
      console.info "Have query:"
      console.info sqlQuery
      $("#main-body").append "<pre>Would send Carto:\n\n #{sqlQuery}</pre>"
      console.info "GeoJSON:", geoJson
      console.info "GeoJSON String:", dataGeometry
      console.warn "Want to post:", "#{uri.urlString}api.php?#{args}"
      $.post "api.php", args, "json"
      .done (result) ->
        console.log "Got back", result
        if result.status isnt true
          console.error "Got an error from the server!"
          console.warn result
          toastStatusMessage "There was a problem uploading your data. Please try again."
          return false
        cartoResults = result.post_response
        cartoHasError = false
        for j, response of cartoResults
          unless isNull response?.error
            cartoHasError = response.error[0]
        unless cartoHasError is false
          stopLoadError "CartoDB returned an error: #{cartoHasError}"
          return false
        console.info "Carto was succesfful! Got results", cartoResults
        try
          # http://marianoguerra.github.io/json.human.js/
          prettyHtml = JsonHuman.format cartoResults
          $("#main-body").append "<div class='alert alert-success'><strong>Success! Carto said</strong>#{$(prettyHtml).html()}</div>"
        bsAlert("Upload to CartoDB of table <code>#{dataTable}</code> was successful", "success")
        geo.dataTable = dataTable
        foo()
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
        parentCallback = ->
          if typeof callback is "function"
            callback(geo.dataTable)
          else
            console.info "requestCartoUpload recieved no callback"
        unless isNull cartoMap
          cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
          .done (layer) ->
            # The actual interaction infowindow popup is decided on the data
            # page in Carto
            layer.setInteraction true
            layer.on "featureOver", defaultMapMouseOverBehaviour
            parentCallback()
        else
          geo.init ->
            # Callback
            createMap dataVisUrl, undefined, undefined, ->
              parentCallback()
            false
    else
      console.error "Unable to authenticate session. Please log in."
      toastStatusMessage "Sorry, your session has expired. Please log in and try again."
  .error (result, status) ->
    console.error "Couldn't communicate with server!", result, status
    console.warn "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
    toastStatusMessage "There was a problem communicating with the server. Please try again in a bit."
  false


sortPoints = (pointArray) ->
  ###
  # Take an array of points and return a Google Maps compatible array
  # of coordinate objects
  ###
  window.upper = upperLeft pointArray
  pointArray.sort pointSort
  sortedPoints = new Array()
  for coordPoint in pointArray
    sortedPoints.push coordPoint.getObj()
  delete window.upper
  sortedPoints


Point = (lat, lng) ->
  # From
  # http://stackoverflow.com/a/2863378
  @x = (lng + 180) * 360
  @y = (lat + 90) * 180
  @lat = lat
  @lng = lng
  @distance = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    Math.sqrt dx**2 + dy**2
  @slope = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    dy / dx
  @toString = ->
    "(#{@x}, #{@y})"
  @getObj = ->
    o =
      lat: @lat
      lng: @lng
    o
  @getLatLng = ->
    if google?.maps?
      return new google.maps.LatLng(@lat,@lng)
    else
      return @getObj()
  @getLat = ->
    @lat
  @getLng = ->
    @lng
  this.toString()

geo.Point = Point

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

geo.distance = (lat1, lng1, lat2, lng2) ->
  ###
  # Distance across Earth curvature
  ###
  # Radius of Earth, const (Volumentric Mean)
  # http://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
  R = 6371
  dLat = (lat2 - lat2).toRad()
  dLon = (lng2 - lng1).toRad()
  semiLat = dLat / 2
  semiLng = dLon / 2
  # Get the actual curves
  arc = Math.sin(semiLat)**2 + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(smiLng)**2
  curve = 2 * Math.atan2 Math.sqrt(arc), Math.sqrt(1-arc)
  # Return the real distance
  R * curve



$ ->
  # init()
