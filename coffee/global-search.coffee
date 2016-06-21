###
# Do global searches, display global points.
###

namedMapSource = "adp_generic_heatmap-v15"
namedMapAdvSource = "adp_specific_heatmap-v2"


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


getSearchObject = ->
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
  search



getSearchContainsObject = ->
  bounds =
    n: $("#north-coordinate").val()
    w: $("#west-coordinate").val()
    s: $("#south-coordinate").val()
    e: $("#east-coordinate").val()
  taxaSearch = $("#taxa-input").val().toLowerCase()
  taxaSplit = taxaSearch.split(" ")
  ssp = if taxaSplit.length is 3 then taxaSplit.pop() else "*"
  sp = if taxaSplit.length is 2 then taxaSplit.pop() else "*"
  genus = if taxaSplit.length is 1 then taxaSplit.pop() else "*"
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
        table = project.carto_id.table.slice 0, 63
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
        geo.lMap.setZoom zoom
      try
        p$("#global-data-map").latitude = mapCenter.lat
        p$("#global-data-map").longitude = mapCenter.lng
      catch
        try
          geo.lMap.panTo [mapCenter.lat, mapCenter.lng]
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
      console.warn e.stack
    speciesCount = totalSpecies.length
    console.info "Projects containing your search returned #{totalSamples} (#{posSamples} positive) among #{speciesCount} species", boundingBox
    $("#post-map-subtitle").text "Viewing projects containing #{totalSamples} samples (#{posSamples} positive) among #{speciesCount} species"
    # Render the vis
    try
      # https://docs.cartodb.com/cartodb-platform/maps-api/named-maps/#cartodbjs-for-named-maps
      for layer in layers
        layerSourceObj =
          user_name: cartoAccount
          type: "namedmap"
          named_map: layer
        createRawCartoMap layerSourceObj
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
        table = project.carto_id.table.slice 0, 63
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
            disease_detected: search.disease_positive ? "*"
            morbidity: search.disease_morbidity ? "*"
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
      zoom = getMapZoom boundingBoxArray, ".map-container"
      console.info "Found @ zoom = #{zoom} center", mapCenter, "for bounding box", boundingBoxArray
      if geo.lMap?
        geo.lMap.setZoom zoom
      try
        p$("#global-data-map").latitude = mapCenter.lat
        p$("#global-data-map").longitude = mapCenter.lng
      catch
        try
          geo.lMap.panTo [mapCenter.lat, mapCenter.lng]
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
      console.warn e.stack
    speciesCount = totalSpecies.length
    console.info "Projects containing your search returned #{totalSamples} (#{posSamples} positive) among #{speciesCount} species", boundingBox
    subText = "viewing data points"
    if search.sampled_species?.genus?
      spText = " of '#{search.sampled_species.genus} #{search.sampled_species.species} #{search.sampled_species.subspecies}'"
      subText += spText.replace(/( \*)/img, "")
    if search.disease_positive?
      subText += " with disease status '#{search.disease_positive}'"
    subText += " in bounds defined by [{lat: #{search.bounding_box_n.data},lng: #{search.bounding_box_w.data}},{lat: #{search.bounding_box_s.data},lng: #{search.bounding_box_e.data}}]"
    $("#post-map-subtitle").text subText
    # Render the vis
    try
      # https://docs.cartodb.com/cartodb-platform/maps-api/named-maps/#cartodbjs-for-named-maps
      for layer in layers
        layerSourceObj =
          user_name: cartoAccount
          type: "namedmap"
          named_map: layer
        createRawCartoMap layerSourceObj
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
      console.log "Colors", data.creation, generateColorByRecency(data.creation), generateColorByRecency2(data.creation)
      unless isNull table
        # Create named map layers
        table = table.slice 0, 63
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



resetMap = (map = geo.lMap, showTables = true) ->
  unless geo.mapSublayers?
    console.error "geo.mapSublayers is not defined."
    return false
  # Iterate over sublayers
  try
    for sublayer in geo.mapSublayers
      # Call hide() or remove() on each sublayer
      sublayer.remove()
  catch
    for layer in map._layers
      unless layer.url?
        # Not the base layer
        layer.remove()
  geo.lMap.setZoom geo.defaultLeafletOptions.zoom
  geo.lMap.panTo geo.defaultLeafletOptions.center
  if showTables
    showAllTables()
  foo()
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
    color = "#000"
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
  color



generateColorByRecency2 = (timestamp, oldCutoff = 1420070400) ->
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
    color = "#000"
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
  color



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
  # Initial load
  showAllTables()
  false
