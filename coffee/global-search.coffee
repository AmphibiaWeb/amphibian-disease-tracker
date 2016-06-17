###
#
###


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
      data: $("#taxa-input").val()
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


doSearch = (search = getSearchObject(), goDeep = false) ->
  ###
  #
  ###
  startLoad()
  data = jsonTo64 search
  args = "perform=advanced_project_search&q=#{data}"
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
      table = project.carto_id.table.slice 0, 63
      unless isNull table
        # Create named map layers
        layer =
          name: "adp_generic_heatmap-v8"
          type: "namedmap"
          layers: [
            layer_name: "layer-#{layers.length}"
            interactivity: "id, diseasedetected, genus, specificepithet"
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
      try
        p$("#global-data-map").latitude = mapCenter.lat
        p$("#global-data-map").longitude = mapCenter.lng
      catch
        try
          geo.lMap.panTo [mapCenter.lat, mapCenter.lng]
      zoom = getMapZoom boundingBoxArray, ".map-container"
      if geo.lMap?
        geo.lMap.setZoom zoom
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
      console.warn e.stack
    if goDeep
      # If we're going deep, we'll let the deep take care of the rest
      doDeepSearch(results)
      return false
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
    stopLoadError "Server error, couldn't perform search"
  false


doDeepSearch = (shallowResults) ->
  ###
  # Follows up on doSearch() to then look at the shallow matches and
  # do a Carto query
  ###
  toastStatusMessage "Deep search not yet implemented"
  stopLoad()
  false


$ ->
  geo.initLocation()
  # If the user hasn't granted location permissions, default to Berkeley
  leafletOptions =
    center: [window.locationData.lat, window.locationData.lng]
    zoom: 5 # Roughly equivalent to fitting the whole US centered on Kansas
  lMap = new L.Map("global-map-container", leafletOptions)
  lTopoOptions =
    attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
  L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions).addTo lMap
  geo.lMap = lMap
  $(".coord-input").keyup ->
    checkCoordinateSanity()
  $(".do-search").click ->
    ok = checkCoordinateSanity()
    unless ok
      toastStatusMessage "Please check your coordinates"
      return false
    deep = $(this).attr("data-deep").toBool()
    doSearch(getSearchObject(), deep)
    false
