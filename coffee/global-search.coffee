###
# Do global searches, display global points.
###

namedMapSource = "adp_generic_heatmap-v16"
namedMapAdvSource = "adp_specific_heatmap-v11"


checkCoordinateSanity = ->
  isGood = true
  bounds =
    n: toFloat $("#north-coordinate").val()
    w: toFloat $("#west-coordinate").val()
    s: toFloat $("#south-coordinate").val()
    e: toFloat $("#east-coordinate").val()
  console.log "User Bounds", bounds
  # Check that north is north, west is west
  unless bounds.n > bounds.s
    isGood = false
    $(".lat-input").parent().addClass "has-error"
  unless bounds.e > bounds.w
    isGood = false
    $(".lng-input").parent().addClass "has-error"
  unless isGood
    $(".do-search").attr "disabled", "disabled"
    return false
  $(".coord-input").parent().removeClass "has-error"
  $(".do-search").removeAttr "disabled"
  true


createTemplateByProject = (table = "t2627cbcbb4d7597f444903b2e7a5ce5c_6d6d454828c05e8ceea03c99cc5f5") ->
  start = Date.now()
  templateId = "infowindow_template_#{table}"
  if $("##{templateId}").exists()
    return false
  query = "SELECT cartodb_id FROM #{table}"
  args = "action=fetch&sql_query=#{post64(query)}"
  $.post "#{uri.urlString}api.php", args, "json"
  .done (result) ->
    unless isNull result.project_id
      html = """
          <script type="infowindow/html" id="#{templateId}">
            <div class="cartodb-popup v2">
              <a href="#close" class="cartodb-popup-close-button close">x</a>
              <div class="cartodb-popup-content-wrapper">
                <div class="cartodb-popup-header">
                  <img style="width: 100%" src="https://cartodb.com/assets/logos/logos_full_cartodb_light.png"/>
                </div>
                <div class="cartodb-popup-content">
                  <!-- content.data contains the field info -->
                  <h4>Species: </h4>
                  <p>{{content.data.genus}} {{content.data.specificepithet}}</p>
                  <p>Tested {{content.data.diseasetested}} as {{content.data.diseasedetected}} (Fatal: {{content.data.fatal}})</p>
                  <p><a href="https://amphibiandisease.org/project.php?id=#{result.project_id}">View Project</a></p>
                </div>
              </div>
              <div class="cartodb-popup-tip-container"></div>
            </div>
          </script>
      """
      $("body").append html
      elapsed = Date.now() - start
      console.info "Template set for ##{templateId} (took #{elapsed}ms)"
    else
      console.warn "Couldn't find project ID for table #{table}", result
  false


setViewerBounds = (map = geo.lMap) ->
  bounds = map.getBounds()
  sw = bounds._southWest
  ne = bounds._northEast
  if ne.lng - sw.lng > 360
    sw.lng = -180
    ne.lng = 180
  $("#north-coordinate").val(ne.lat)
  $("#west-coordinate").val(sw.lng)
  $("#south-coordinate").val(sw.lat)
  $("#east-coordinate").val(ne.lng)
  false



getSearchObject = ->
  try
    if p$("#use-viewport-bounds").checked then setViewerBounds()
  bounds =
    n: $("#north-coordinate").val()
    w: $("#west-coordinate").val()
    s: $("#south-coordinate").val()
    e: $("#east-coordinate").val()
  search =
    sampled_species:
      data: $("#taxa-input").val().toLowerCase()
    bounding_box_n:
      data: bounds.n
      search_type: "<="
    bounding_box_e:
      data: bounds.e
      search_type: "<="
    bounding_box_w:
      data: bounds.w
      search_type: ">="
    bounding_box_s:
      data: bounds.s
      search_type: ">="
  diseaseStatus = $(p$("#disease-status").selectedItem).attr "data-search"
  if diseaseStatus isnt "*"
    search.disease_positive =
      data: 0
      search_type: if diseaseStatus.toBool() then ">" else "="
  morbidityStatus = $(p$("#morbidity-status").selectedItem).attr "data-search"
  if morbidityStatus isnt "*"
    search.disease_morbidity =
      data: 0
      search_type: if morbidityStatus.toBool() then ">" else "="
  pathogen = $(p$("#pathogen-choice").selectedItem).attr "data-search"
  if pathogen isnt "*"
    search.disease =
      data: pathogen
  search



getSearchContainsObject = ->
  try
    if p$("#use-viewport-bounds").checked then setViewerBounds()
  bounds =
    n: $("#north-coordinate").val()
    w: $("#west-coordinate").val()
    s: $("#south-coordinate").val()
    e: $("#east-coordinate").val()
  taxaSearch = $("#taxa-input").val().toLowerCase()
  taxaSplit = taxaSearch.split(" ")
  ssp = if taxaSplit.length is 3 then taxaSplit.pop() else ""
  sp = if taxaSplit.length is 2 then taxaSplit.pop() else ""
  genus = if taxaSplit.length is 1 then taxaSplit.pop() else ""
  search =
    sampled_species:
      data: taxaSearch
      genus: genus
      species: sp
      subspecies: ssp
    bounding_box_n:
      data: bounds.s
      search_type: ">"
    bounding_box_e:
      data: bounds.w
      search_type: ">"
    bounding_box_w:
      data: bounds.e
      search_type: "<"
    bounding_box_s:
      data: bounds.n
      search_type: "<"
  diseaseStatus = $(p$("#disease-status").selectedItem).attr "data-search"
  if diseaseStatus isnt "*"
    search.disease_positive =
      data: 0
      search_type: if diseaseStatus.toBool() then ">" else "="
  morbidityStatus = $(p$("#morbidity-status").selectedItem).attr "data-search"
  if morbidityStatus isnt "*"
    search.disease_morbidity =
      data: 0
      search_type: if morbidityStatus.toBool() then ">" else "="
  pathogen = $(p$("#pathogen-choice").selectedItem).attr "data-search"
  if pathogen isnt "*"
    search.disease =
      data: pathogen
  search


doSearch = (search = getSearchObject(), goDeep = false) ->
  ###
  #
  ###
  startLoad()
  data = jsonTo64 search
  action = "advanced_project_search" # if goDeep then "" else "advanced_project_search"
  namedMap = if goDeep then namedMapAdvSource else namedMapSource
  args = "perform=#{action}&q=#{data}"
  $.post "#{uri.urlString}admin-api.php", args, "json"
  .done (result) ->
    console.info "Adv. search result", result
    if result.status isnt true
      console.error result.error
      stopLoadError "There was a problem fetching the results"
      return false
    results = Object.toArray result.result
    if results.length is 0
      console.warn "No results"
      stopLoadError "No results"
      return false
    if goDeep
      # If we're going deep, we'll let the deep take care of the rest
      doDeepSearch(results, namedMap)
      return false
    totalSamples = 0
    posSamples = 0
    totalSpecies = new Array()
    layers = new Array()
    boundingBox =
      n: -90
      s: 90
      e: -180
      w: 180
    i = 0
    console.info "Using standard named map #{namedMap}"
    for project in results
      if project.bounding_box_n > boundingBox.n
        boundingBox.n = project.bounding_box_n
      if project.bounding_box_e > boundingBox.e
        boundingBox.e = project.bounding_box_e
      if project.bounding_box_s < boundingBox.s
        boundingBox.s = project.bounding_box_s
      if project.bounding_box_w < boundingBox.w
        boundingBox.w = project.bounding_box_w
      totalSamples += project.disease_samples
      posSamples += project.disease_positive
      spArr = project.sampled_species.split(",")
      for species in spArr
        species = species.trim()
        unless species in totalSpecies
          totalSpecies.push species
      # Visualize it
      # See
      # https://docs.cartodb.com/cartodb-platform/cartodb-js/getting-started/#creating-visualizations-at-runtime
      unless project.carto_id?.table?
        try
          cartoPreParsed = JSON.parse project.carto_id
          cartoParsed = new Object()
          for key, val of cartoPreParsed
            cleanKey = key.replace "&#95;", "_"
            try
              cleanVal = val.replace "&#95;", "_"
            catch
              cleanVal = val
            cartoParsed[cleanKey] = cleanVal
          project.carto_id = cartoParsed
      try
        table = project.carto_id.table
        table = table.unescape()
      unless isNull table
        # Create named map layers
        try
          createTemplateByProject table
        layer =
          name: namedMap
          type: "namedmap"
          layers: [
            layer_name: "layer-#{layers.length}"
            ]
          params:
            table_name: table
            color: "#FF6600"
        layers.push layer
      else
        console.warn "Unable to get a table id from this carto data:", project.carto_id
      results[i] = project
      ++i
    try
      boundingBoxArray = [
        [boundingBox.n, boundingBox.w]
        [boundingBox.n, boundingBox.e]
        [boundingBox.s, boundingBox.e]
        [boundingBox.s, boundingBox.w]
        ]
      mapCenter = getMapCenter boundingBoxArray
      # Zoom
      zoom = getMapZoom boundingBoxArray, ".map-container"
      console.info "Found @ zoom = #{zoom} center", mapCenter, "for bounding box", boundingBoxArray
      if geo.lMap?
        # http://leafletjs.com/reference.html#events-once
        geo.lMap.once "zoomend", =>
          # http://leafletjs.com/reference.html#map-zoomend
          console.info "ZoomEnd is ensuring centering"
          ensureCenter(0)
        geo.lMap.setZoom zoom
      try
        p$("#global-data-map").latitude = mapCenter.lat
        p$("#global-data-map").longitude = mapCenter.lng
        p$("#global-data-map").zoom = zoom
      try
        geo.lMap.setView mapCenter.getObj()
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
      console.warn e.stack
    speciesCount = totalSpecies.length
    console.info "Projects containing your search returned #{totalSamples} (#{posSamples} positive) among #{speciesCount} species", boundingBox
    # Render the vis
    try
      # https://docs.cartodb.com/cartodb-platform/maps-api/named-maps/#cartodbjs-for-named-maps
      resetMap geo.lMap, false, false
      for layer in layers
        layerSourceObj =
          user_name: cartoAccount
          type: "namedmap"
          named_map: layer
        createRawCartoMap layerSourceObj
      $("#post-map-subtitle").text "Viewing projects containing #{totalSamples} samples (#{posSamples} positive) among #{speciesCount} species"
      $(".show-result-list").remove()
      rlButton = """
      <paper-icon-button class="show-result-list" icon="icons:subject" data-toggle="tooltip" title="Show Project list" raised></paper-icon-button>
      """
      $("#post-map-subtitle").append rlButton
      getProjectResultDialog results
      do ensureCenter = (count = 0, maxCount = 100, timeout = 100) ->
        ###
        # Make sure the center is right
        ###
        rndLat = roundNumber mapCenter.lat, 3
        rndLng = roundNumber mapCenter.lng, 3
        try
          lat = roundNumber p$("#global-data-map").latitude, 3
          lng = roundNumber p$("#global-data-map").longitude, 3
          center =
            type: "google-map-element"
            lat: lat
            lng: lng
        try
          center = geo.lMap.getCenter()
          lat = roundNumber center.lat, 3
          lng = roundNumber center.lng, 3
        pctOffLat = Math.abs((lat - rndLat)/rndLat) * 100
        pctOffLng = Math.abs((lng - rndLng)/rndLng) * 100
        if pctOffLat < 2 and pctOffLng < 2 and count > 5
          console.info "Correctly centered", mapCenter, center, [pctOffLat, pctOffLng]
          if geo.lMap.getZoom() isnt zoom
            console.warn "The map was centered before the zoom finished -- this may need to fire again"
          clearTimeout _adp.centerTimeout
          return false
        else
          unless count <= 15
            console.warn "Centering too deviant", pctOffLat < 2, pctOffLng < 2, pctOffLat < 2 and pctOffLng < 2, lat, lng, rndLat, rndLng
        if not isNumber maxCount
          maxCount = 100
        if count > maxCount
          waited = timeout * maxCount
          console.info "Map could not be correctly centered in #{waited}ms"
          clearTimeout _adp.centerTimeout
          return false
        ++count
        _adp.centerTimeout = delay timeout, ->
          if not isNumber maxCount
            maxCount = 100
          try
            p$("#global-data-map").latitude = mapCenter.lat
            p$("#global-data-map").longitude = mapCenter.lng
          try
            console.log "##{count}/#{maxCount} General setting view to", mapCenter.getObj(), [pctOffLat, pctOffLng]
            geo.lMap.setView mapCenter.getObj()
          catch e
            console.warn "Error setting view - #{e.message}"
          if count < maxCount
            ensureCenter(count)
    catch e
      console.error "Couldn't create map! #{e.message}"
      console.warn e.stack
    stopLoad()
    false
  .fail (result, status) ->
    console.error result, status
    console.warn "Attempted to do", "#{uri.urlString}admin-api.php?#{args}"
    stopLoadError "Server error, couldn't perform search"
  false


doDeepSearch = (results, namedMap = namedMapAdvSource) ->
  ###
  # Follows up on doSearch() to then look at the shallow matches and
  # do a Carto query
  ###
  try
    search = getSearchContainsObject()
    totalSamples = 0
    posSamples = 0
    totalSpecies = new Array()
    layers = new Array()
    boundingBox =
      n: -90
      s: 90
      e: -180
      w: 180
    i = 0
    console.info "Using deep named map #{namedMap}"
    detected = ""
    if search.disease_positive?.data?
      if search.disease_positive.search_type is ">"
        detected = "true"
      else
        detected = "false"
    fatal = ""
    if search.disease_morbidity?.data?
      if search.disease_morbidity.search_type is ">"
        fatal = "and fatal = true"
        fatalSimple = true
      else
        fatal = "and fatal = false"
        fatalSimple = false
    pathogen = ""
    if search.disease?.data?
      pathogen = switch search.disease.data
        when "Batrachochytrium dendrobatidis"
          "bd"
        when "Batrachochytrium salamandrivorans"
          "bsal"
        else ""
    projectTableMap = new Object()
    for project in results
      if project.bounding_box_n > boundingBox.n
        boundingBox.n = project.bounding_box_n
      if project.bounding_box_e > boundingBox.e
        boundingBox.e = project.bounding_box_e
      if project.bounding_box_s < boundingBox.s
        boundingBox.s = project.bounding_box_s
      if project.bounding_box_w < boundingBox.w
        boundingBox.w = project.bounding_box_w
      totalSamples += project.disease_samples
      posSamples += project.disease_positive
      spArr = project.sampled_species.split(",")
      for species in spArr
        species = species.trim()
        unless species in totalSpecies
          totalSpecies.push species
      # Visualize it
      # See
      # https://docs.cartodb.com/cartodb-platform/cartodb-js/getting-started/#creating-visualizations-at-runtime
      unless project.carto_id?.table?
        try
          cartoPreParsed = JSON.parse project.carto_id
          cartoParsed = new Object()
          for key, val of cartoPreParsed
            cleanKey = key.replace "&#95;", "_"
            try
              cleanVal = val.replace "&#95;", "_"
            catch
              cleanVal = val
            cartoParsed[cleanKey] = cleanVal
          project.carto_id = cartoParsed
      try
        table = project.carto_id.table
        table = table.unescape()
      unless isNull table
        # Create named map layers
        layer =
          name: namedMap
          type: "namedmap"
          layers: [
            layer_name: "layer-#{layers.length}"
            ]
          params:
            table_name: table
            color: "#FF6600"
            genus: search.sampled_species.genus
            specific_epithet: search.sampled_species.species
            disease_detected: detected
            morbidity: fatal
            pathogen: pathogen
        layers.push layer
        projectTableMap[table] =
          id: project.project_id
          name: project.project_title
      else
        console.warn "Unable to get a table id from this carto data:", project.carto_id
      results[i] = project
      ++i
    try
      # Configure the map
      boundingBoxArray = [
        [boundingBox.n, boundingBox.w]
        [boundingBox.n, boundingBox.e]
        [boundingBox.s, boundingBox.e]
        [boundingBox.s, boundingBox.w]
        ]
      mapCenter = getMapCenter boundingBoxArray
      zoom = getMapZoom boundingBoxArray, ".map-container"
      console.info "Found @ zoom = #{zoom} center", mapCenter, "for bounding box", boundingBoxArray
      # For leaflet, if we don't zoom first the map gets cranky with
      # its baseLayer
      if geo.lMap?
        # http://leafletjs.com/reference.html#events-once
        geo.lMap.once "zoomend", =>
          # http://leafletjs.com/reference.html#map-zoomend
          console.info "ZoomEnd is ensuring centering"
          ensureCenter(0)
        geo.lMap.setZoom zoom
      try
        # If we're using a Polymer map, set it's configs
        p$("#global-data-map").latitude = mapCenter.lat
        p$("#global-data-map").longitude = mapCenter.lng
        p$("#global-data-map").zoom = zoom
      try
        # NOW we can set the leafelet center
        geo.lMap.setView mapCenter.getObj()
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
      console.warn e.stack
    speciesCount = totalSpecies.length
    # Label the results
    console.info "Projects containing your search returned #{totalSamples} (#{posSamples} positive) among #{speciesCount} species", boundingBox
    subText = "Viewing data points"
    unless isNull search.sampled_species?.genus
      spText = " of '#{search.sampled_species.genus} #{search.sampled_species.species} #{search.sampled_species.subspecies}'"
      subText += spText.replace(/( \*)/img, "")
    diseaseWord = if search.pathogen? then search.pathogen.data else "disease"
    if search.disease?
      subText += " for #{search.disease.data}"
    if search.disease_positive?
      subText += " with disease status '#{detected}'"
    if search.disease_morbidity?
      subText += " with morbidity status '#{fatalSimple}'"
    subText += " in bounds defined by [{lat: #{search.bounding_box_n.data},lng: #{search.bounding_box_w.data}},{lat: #{search.bounding_box_s.data},lng: #{search.bounding_box_e.data}}]"
    # Render the vis
    try
      # https://docs.cartodb.com/cartodb-platform/maps-api/named-maps/#cartodbjs-for-named-maps
      resetMap geo.lMap, false, false
      resultQueryPile = ""
      for layer in layers
        layerSourceObj =
          user_name: cartoAccount
          type: "namedmap"
          named_map: layer
        createRawCartoMap layerSourceObj
        # Now do an SQL query to get the legitimate results for a
        # summary dialog
        tempQuery = "select * from #{layer.params.table_name } where (genus ilike '%#{layer.params.genus }%' and specificepithet ilike '%#{layer.params.specific_epithet }%' and diseasedetected ilike '%#{layer.params.disease_detected }%' #{layer.params.morbidity } and diseasetested ilike '%#{layer.params.pathogen }%');"
        resultQueryPile += tempQuery
      # Label the subtext
      $("#post-map-subtitle").text subText
      # Initiate a query against the found tables
      args = "action=fetch&sql_query=#{post64(resultQueryPile)}"
      $.post "#{uri.urlString}api.php", args, "json"
      .done (result) ->
        console.info "Detailed results: ", result
        try
          results = Object.toArray result.parsed_responses
          getSampleSummaryDialog results, projectTableMap
        catch
          console.warn "Couldn't parse responses from server"
        false
      .fail (result, status) ->
        console.error "Couldn't fetch detailed results"
      do ensureCenter = (count = 0, maxCount = 100, timeout = 100) ->
        ###
        # Make sure the center is right
        ###
        rndLat = roundNumber mapCenter.lat, 3
        rndLng = roundNumber mapCenter.lng, 3
        try
          lat = roundNumber p$("#global-data-map").latitude, 3
          lng = roundNumber p$("#global-data-map").longitude, 3
          center =
            type: "google-map-element"
            lat: lat
            lng: lng
        try
          center = geo.lMap.getCenter()
          lat = roundNumber center.lat, 3
          lng = roundNumber center.lng, 3
        # Get the percent deviation from the center, in case the
        # precise center doesn't have zero error
        pctOffLat = Math.abs((lat - rndLat)/rndLat) * 100
        pctOffLng = Math.abs((lng - rndLng)/rndLng) * 100
        # we want to keep an eye on the centering for at least a
        # little while
        if pctOffLat < 2 and pctOffLng < 2 and count > 5
          console.info "Correctly centered", mapCenter, center, [pctOffLat, pctOffLng]
          if geo.lMap.getZoom() isnt zoom
            console.warn "The map was centered before the zoom finished -- this may need to fire again"
          clearTimeout _adp.centerTimeout
          return false
        else
          # We can be quiet for initial center attempts
          unless count <= 15
            console.warn "Centering too deviant", pctOffLat < 2, pctOffLng < 2, pctOffLat < 2 and pctOffLng < 2, lat, lng, rndLat, rndLng
        # For whatever reason, this was getting wiped. Fuck if I know why.
        if not isNumber maxCount
          maxCount = 100
        if count > maxCount
          waited = timeout * maxCount
          console.info "Map could not be correctly centered in #{waited}ms"
          clearTimeout _adp.centerTimeout
          return false
        ++count
        _adp.centerTimeout = delay timeout, ->
          # For whatever reason, this was getting wiped. Fuck if I know why.
          if not isNumber maxCount
            maxCount = 100
          try
            p$("#global-data-map").latitude = mapCenter.lat
            p$("#global-data-map").longitude = mapCenter.lng
          try
            console.log "##{count}/#{maxCount} Deep setting view to", mapCenter.getObj(), [pctOffLat, pctOffLng]
            geo.lMap.setView mapCenter.getObj()
          catch e
            console.warn "Error setting view - #{e.message}"
          if count < maxCount
            ensureCenter(count)
    catch e
      console.error "Couldn't create map! #{e.message}"
      console.warn e.stack
    stopLoad()
  catch e
    stopLoadError "There was a problem performing a sample search"
    console.error "Problem performing sample search! #{e.message}"
    console.warn e.stack
  false


showAllTables = ->
  ###
  # Looks up all table names with permissions and shows
  # their data on the map
  ###
  console.log "Starting table list"
  url = "#{uri.urlString}admin-api.php"
  args = "perform=list"
  $.post url, args, "json"
  .done (result) ->
    if result.status is false
      console.error "Got bad result", result
      return false
    console.info "Good result", result
    cartoTables = result.carto_table_map
    layers = new Array()
    validTables = new Array()
    i = 0
    for pid, data of cartoTables
      # Build params
      table = data.table
      console.log "Colors", data.creation, generateColorByRecency2(data.creation)
      unless isNull table
        # Create named map layers
        table = table.unescape()
        validTables.push table
        # TODO Calculate a color based on recency ...
        layer =
          name: namedMapSource
          type: "namedmap"
          layers: [
            layer_name: "layer-#{layers.length}"
            interactivity: "cartodb_id, id, diseasedetected, genus, specificepithet"
            ]
          params:
            table_name: table
            color: generateColorByRecency2 data.creation
        layers.push layer
      else
        console.warn "Bad table ##{i}", table
      ++i
    # Finished adding layer structures,
    # now try making the aggregate table
    console.info "Got tables", validTables
    console.info "Got layers", layers
    try
      # https://docs.cartodb.com/cartodb-platform/maps-api/named-maps/#cartodbjs-for-named-maps
      for layer in layers
        layerSourceObj =
          user_name: cartoAccount
          type: "namedmap"
          named_map: layer
        console.log "Creating raw map from", layerSourceObj
        createRawCartoMap layerSourceObj
    catch e
      console.error "Couldn't create map! #{e.message}"
      console.warn e.stack
    false
  .error (result, status) ->
    console.error "AJAX failure showing tables", result, status
  false



resetMap = (map = geo.lMap, showTables = true, resetZoom = true) ->
  unless geo.mapSublayers?
    console.error "geo.mapSublayers is not defined."
    return false
  # Iterate over sublayers
  try
    for sublayer in geo.mapSublayers
      # Call hide() or remove() on each sublayer
      sublayer.remove()
  catch
    for id, layer of map._layers
      try
        p = layer._url.search "arcgisonline"
        if p is -1
          # Not the base layer
          try
            layer.removeLayer()
          catch
            layer.remove()
  $("#post-map-subtitle").text ""
  if resetZoom
    geo.lMap.setZoom geo.defaultLeafletOptions.zoom
    geo.lMap.panTo geo.defaultLeafletOptions.center
  if showTables
    showAllTables()
    $("#post-map-subtitle").text "All Projects"
  false



generateColorByRecency = (timestamp, oldCutoff = 1420070400) ->
  ###
  # Start with white, then lose one color channel at a time to get
  # color recency
  #
  # @param int oldCutoff -> Linux Epoch "old" cutoff. 2015-01-01
  ###
  unless isNumber timestamp
    temp = new Date(timestamp)
    timestamp = temp.getTime() / 1000
  if timestamp > Date.now() / 1000
    timestamp = timestamp / 1000
  age = (Date.now() / 1000) - timestamp
  maxAge = timestamp - oldCutoff
  if age > maxAge
    color = "#000000"
  else
    # Break down the region into 255*3 steps
    stepSize = maxAge / (255 * 3)
    stepCount = age / stepSize
    b = 255
    g = 255
    r = 255 - stepCount
    r = if r < 0 then 0 else toInt r
    if stepCount > 255
      g = 255 + 255 - stepCount
      g = if g < 0 then 0 else toInt g
      if stepCount > 255 * 2
        b = 255 + 255 + 255 - stepCount
        b = if b < 0 then 0 else toInt b
    console.log "Base channels", r, g, b
    hexArray = [
      r.toString(16)
      g.toString(16)
      b.toString(16)
      ]
    i = 0
    for cv in hexArray
      if cv.length is 1
        hexArray[i] = "0#{cv}"
      ++i
    color = "##{hexArray.join("")}"
  # After #124
  color = "#ff0000"
  color



generateColorByRecency2 = (timestamp, oldCutoff = 1420070400) ->
  ###
  # Mix and match color channels based on age. Newest is fully red,
  # then green is added in and red removed till fully green, then blue
  # is added in and green removed until fully blue, then blue removed
  # until fully black.
  #
  # @param int timestamp -> Javascript linux epoch (ms)
  # @param int oldCutoff -> Linux Epoch "old" cutoff. 2015-01-01
  ###
  unless isNumber timestamp
    temp = new Date(timestamp)
    timestamp = temp.getTime() / 1000
  if timestamp > Date.now() / 1000
    timestamp = timestamp / 1000
  age = (Date.now() / 1000) - timestamp
  maxAge = timestamp - oldCutoff
  if age > maxAge
    color = "#000000"
  else
    # Break down the region into 255*3 steps
    stepSize = maxAge / (255 * 3)
    stepCount = age / stepSize
    r = 255 - stepCount
    g = if r < 0 then 0 - r else 255 - r
    r = if r < 0 then 0 else toInt r
    b = if g > 255 then toInt(g - 255) else 0
    g = if g > 255 then 255 - (g - 255) else toInt g
    b = if b < 0 then 0 else toInt b
    console.log "Base channels 2", r, g, b
    hexArray = [
      r.toString(16)
      g.toString(16)
      b.toString(16)
      ]
    i = 0
    for cv in hexArray
      if cv.length is 1
        hexArray[i] = "0#{cv}"
      ++i
    color = "##{hexArray.join("")}"
  console.log "Recency2 generated", hexArray, color
  # After #124
  color = "#ff0000"
  color



getProjectResultDialog = (projectList) ->
  ###
  # From a list of projects, show a modal dialog with some basic
  # metadata for that list
  ###
  unless isArray projectList
    projectList = Object.toArray projectList
  if projectList.length is 0
    console.warn "There were no projects in the result list"
    return false
  projectTableRows = new Array()
  for project in projectList
    anuraIcon = if project.includes_anura then "<iron-icon icon='icons:check-circle'></iron-icon>" else "<iron-icon icon='icons:clear'></iron-icon>"
    caudataIcon = if project.includes_caudata then "<iron-icon icon='icons:check-circle'></iron-icon>" else "<iron-icon icon='icons:clear'></iron-icon>"
    gymnophionaIcon = if project.includes_gymnophiona then "<iron-icon icon='icons:check-circle'></iron-icon>" else "<iron-icon icon='icons:clear'></iron-icon>"
    row = """
    <tr>
      <td>#{project.project_title}</td>
      <td class="text-center">#{anuraIcon}</td>
      <td class="text-center">#{caudataIcon}</td>
      <td class="text-center">#{gymnophionaIcon}</td>
      <td class="text-center"><paper-icon-button data-toggle="tooltip" title="Visit Project" raised class="click" data-href="https://amphibiandisease.org/project.php?id=#{project.project_id}" icon="icons:arrow-forward"></paper-icon-button></td>
    </tr>
    """
    projectTableRows.push row
  html = """
  <paper-dialog id="modal-project-list" modal always-on-top auto-fit-on-attach>
    <h2>Project Result List</h2>
    <paper-dialog-scrollable>
      <div>
        <table class="table table-striped">
          <tr>
            <th>Project Name</th>
            <th>Caudata</th>
            <th>Anura</th>
            <th>Gymnophiona</th>
            <th>Visit</th>
          </tr>
          #{projectTableRows.join("\n")}
        </table>
      </div>
    </paper-dialog-scrollable>
    <div class="buttons">
      <paper-button dialog-dismiss>Close</paper-button>
    </div>
  </paper-dialog>
  """
  $("#modal-project-list").remove()
  $("body").append html
  $("#modal-project-list")
  .on "iron-overlay-closed", ->
    $(".leaflet-control-attribution").removeAttr "hidden"
    $(".leaflet-control").removeAttr "hidden"
  $(".show-result-list")
  .unbind()
  .click ->
    console.log "Calling dialog helper"
    safariDialogHelper "#modal-project-list", 0, ->
      console.info "Successfully opened dialog"
      $(".leaflet-control-attribution").attr "hidden", "hidden"
      $(".leaflet-control").attr "hidden", "hidden"
  bindClicks()
  console.info "Generated project result list"
  false




getSampleSummaryDialog = (resultsList, tableToProjectMap) ->
  ###
  # Show a SQL-query like dataset in a modal dialog
  #
  # See
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/146
  #
  # @param array resultList -> array of Carto responses. Data expected
  #   in "rows" field
  # @param object tableToProjectMap -> Map the table name onto project id
  ###
  unless isArray resultsList
    resultsList = Object.toArray resultsList
  if resultsList.length is 0
    console.warn "There were no results in the result list"
    return false
  console.log "Generating dialog from", resultsList
  projectTableRows = new Array()
  i = 0
  for projectResults in resultsList
    ++i
    dataWidthMax = $(window).width() * .7
    dataWidthMin = $(window).width() * .4
    try
      data = JSON.stringify projectResults.rows
      if isNull data
        console.warn "Got bad data for row ##{i}!", projectResults, projectResults.rows, data
        continue
    catch
      data = "Invalid data from server"
    table =
    project = tableToProjectMap[projectResults.table]
    row = """
    <tr>
      <td colspan="4"><textarea readonly class="code-box" style="max-width:#{dataWidthMax}px;min-width:#{dataWidthMin}px">#{data}</textarea></td>
      <td class="text-center"><paper-icon-button data-toggle="tooltip" raised class="click" data-href="https://amphibiandisease.org/project.php?id=#{project.project_id}" icon="icons:arrow-forward" title="#{project.name}"></paper-icon-button></td>
    </tr>
    """
    projectTableRows.push row
  html = """
  <paper-dialog id="modal-sql-details-list" modal always-on-top auto-fit-on-attach>
    <h2>Project Result List</h2>
    <paper-dialog-scrollable>
      <div class="row">
        <div class="col-xs-12">
          <table class="table table-striped">
            <tr>
              <th colspan="4">Query Data</th>
              <th>Visit Project</th>
            </tr>
            #{projectTableRows.join("\n")}
          </table>
        </div>
      </div>
    </paper-dialog-scrollable>
    <div class="buttons">
      <paper-button dialog-dismiss>Close</paper-button>
    </div>
  </paper-dialog>
  """
  $("#modal-sql-details-list").remove()
  $("body").append html
  $("#modal-sql-details-list")
  .on "iron-overlay-closed", ->
    $(".leaflet-control-attribution").removeAttr "hidden"
    $(".leaflet-control").removeAttr "hidden"
  $(".show-result-list").remove()
  rlButton = """
  <paper-icon-button class="show-result-list" icon="editor:insert-chart" data-toggle="tooltip" title="Show Sample Details" raised></paper-icon-button>
  """
  $("#post-map-subtitle").append rlButton
  $(".show-result-list")
  .unbind()
  .click ->
    console.log "Calling dialog helper"
    safariDialogHelper "#modal-sql-details-list", 0, ->
      console.info "Successfully opened dialog"
      $(".leaflet-control-attribution").attr "hidden", "hidden"
      $(".leaflet-control").attr "hidden", "hidden"
  bindClicks()
  console.info "Generated project result list"
  false


$ ->
  geo.initLocation()
  # If the user hasn't granted location permissions, default to Berkeley
  leafletOptions =
    center: [17.811456088564483, -37.265625]
    zoom: 2
  geo.defaultLeafletOptions = leafletOptions
  lMap = new L.Map("global-map-container", leafletOptions)
  lTopoOptions =
    attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
  L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions).addTo lMap
  geo.lMap = lMap
  $(".coord-input").keyup ->
    checkCoordinateSanity()
  # Project search event handling
  initProjectSearch = (clickedElement) ->
    ok = checkCoordinateSanity()
    unless ok
      toastStatusMessage "Please check your coordinates"
      return false
    search = getSearchObject()
    try
      deep = $(clickedElement).attr("data-deep").toBool()
      if deep
        search = getSearchContainsObject()
    catch
      deep = false
    doSearch(search, deep)
    false
  # Hit enter on a field
  $("input.submit-project-search").keyup (e) ->
    kc = if e.keyCode then e.keyCode else e.which
    if kc is 13
      initProjectSearch()
    else
      false
  # Click the search button
  $(".do-search").click ->
    initProjectSearch(this)
  # Click reset
  $("#reset-global-map").click ->
    resetMap()
    false
  $("#toggle-global-search-filters").click ->
    isOpened = p$("#global-search-filters").opened
    p$("#global-search-filters").toggle()
    # The actions are now switched, since the state just changed
    actionWord = unless isOpened then "Hide" else "Show"
    $(this).find(".action-word").text actionWord
    false
  # Update the bounds when the viewport changes
  updateViewportBounds = ->
    if p$("#use-viewport-bounds").checked
      console.info "Setting viewer bounds, checkbox is checked"
      setViewerBounds()
    else
      console.info "Not using viewport bounds"
  # http://leafletjs.com/reference.html#map-events
  geo.lMap
  .on "moveend", ->
    updateViewportBounds()
  .on "zoomend", ->
    updateViewportBounds()
  # Initial load
  showAllTables()
  checkFileVersion false, "js/global-search.min.js"
  false
