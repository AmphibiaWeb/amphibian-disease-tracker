###
# Do global searches, display global points.
###

namedMapSource = "adp_generic_heatmap-v16"
namedMapAdvSource = "adp_specific_heatmap-v15" #11

try
  if p$("#exact-species-search").checked
    namedMapAdvSource = "adp_specific_exact_heatmap-v1"

checkCoordinateSanity = ->
  ###
  #
  ###
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




createTemplateByProject = (table = "t2627cbcbb4d7597f444903b2e7a5ce5c_6d6d454828c05e8ceea03c99cc5f5", limited = false, callback) ->
  start = Date.now()
  unless window._adp?.templateReady?
    unless window._adp?
      window._adp = new Object()
    window._adp.templateReady = new Object()
    window._adp.templates = new Object()
  doAsObject = false
  if typeof table is "object"
    if not isNull(table.table)
      if not isNull(table.project)
        pid = table.project
        table = table.table
        doAsObject = true
      else
        table = table.table
    else
      console.error "Couldn't create template for project -- undefined table", table
      return false
  templateId = "infowindow_template_#{table.slice(0,63)}"
  if $("##{templateId}").exists()
    if limited
      if typeof callback is "function"
        callback()
      return false
    else
      $("##{templateId}").remove()
  window._adp.templateReady[table] = false
  query = "SELECT cartodb_id FROM #{table} LIMIT 1"
  args = "action=fetch&sql_query=#{post64(query)}"
  createInfoWindow = (projectId, scriptTemplateId, tableName) ->
    detail = if limited then "" else """<p>Tested {{content.data.diseasetested}} as <strong>{{content.data.diseasedetected}}</strong> (Fatal: <strong>{{content.data.fatal}}</strong>)</p><p><span class="date-group">Sample was taken in <span class="unix-date">{{content.data.dateidentified}}</span>.</span></p>"""
    html = """
        <script type="infowindow/html" id="#{scriptTemplateId}">
          <div class="cartodb-popup v2">
            <a href="#close" class="cartodb-popup-close-button close">x</a>
            <div class="cartodb-popup-content-wrapper">
              <div class="cartodb-popup-header">
                <h2>Sample Info</h2>
              </div>
              <div class="cartodb-popup-content">
                <!-- content.data contains the field info -->
                <h4>Species: </h4>
                <p><i>{{content.data.genus}} {{content.data.specificepithet}}</i></p>
                #{detail}
                <p><a href="https://amphibiandisease.org/project.php?id=#{projectId}">View Project</a></p>
              </div>
            </div>
            <div class="cartodb-popup-tip-container"></div>
          </div>
        </script>
    """
    $("head").append html
    window._adp.templates[tableName] = html
    window._adp.templates[tableName.slice(0,63)] = html
    window._adp.templateReady[tableName] = true
    elapsed = Date.now() - start
    console.info "Template set for ##{scriptTemplateId} (took #{elapsed}ms)"
    if typeof callback is "function"
      callback()
    false # end createInfoWindow
  if doAsObject
    console.info "Directly provided project id"
    createInfoWindow pid, templateId, table
    return false
  console.info "Creating template after pinging API endpoint"
  $.post "#{uri.urlString}api.php", args, "json"
  .done (result) ->
    projectId = result.parsed_responses?[0]?.project_id
    unless isNull projectId
      createInfoWindow projectId, templateId, table
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


doSearch = (search = getSearchObject(), goDeep = false, hasRunValidated = false) ->
  ###
  # Main search bootstrapper.
  #
  # Looks up a taxon, and gets a list of projects to search within.
  ###
  startLoad()
  $("#post-map-subtitle").removeClass "bg-success"
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
      searchFailed = (isGoodSpecies = false) ->
        console.warn "The search failed!"
        unless isNull search.sampled_species?.data
          # Mark the field
          inputErrorHtml = """
          <span id="taxa-input-error" class="help-block">
            Invalid taxon: Please check your spelling. <a href="http://amphibiaweb.org/search/index.html" class="click" data-newtab="true">Check AmphibiaWeb for valid taxa</a>
          </span>
          """
          if isGoodSpecies
            inputErrorHtml = """
            <span id="taxa-input-error" class="help-block">
              No matching samples found.
            </span>
            """
          $("#taxa-input-container").addClass "has-error"
          $("#taxa-input-error").remove()
          $("#taxa-input")
          .attr "aria-describedby", "taxa-input-error"
          .after inputErrorHtml
          .keyup ->
            try
              $("#taxa-input-container").removeClass "has-error"
              $("#taxa-input-error").remove()
          bindClicks()
        console.warn "No results"
        stopLoadError "No results"
        false
      if not isNull(search.sampled_species?.data) and not hasRunValidated
        # Do a smarter taxon lookup
        console.warn "The initial search failed, we're going to validate the taxon and re-check"
        taxonRaw = search.sampled_species.data
        taxonArray = taxonRaw.split " "
        taxon =
          genus: taxonArray[0] ? ""
          species: taxonArray[1] ? ""
        # Check it against AmphibiaWeb
        validateAWebTaxon taxon, (validatedTaxon) ->
          if validatedTaxon.invalid is true
            # This thing simply doesn't exist
            console.error "This taxon is invalid!", validatedTaxon
            searchFailed()
            return false
          taxonString = "#{validatedTaxon.genus} #{validatedTaxon.species} #{validatedTaxon.subspecies ? ""}"
          taxonString = taxonString.trim()
          $("#taxa-input").val taxonString
          # Try again
          doSearch getSearchObject(), goDeep, true
          return false
      else
        # We already ran the AWeb async
        console.warn "No need to validate", isNull(search.sampled_species?.data), hasRunValidated
        searchFailed(true)
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
          templateParam =
            project: project.project_id
            table: table
          createTemplateByProject templateParam
        catch e
          console.error "Warning: couldn't create project template: #{e.message}"
          console.warn e.stack
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
        # delay 5, ->
        do delayedLayerRender = (count = 0, renderLayer = layer) ->
          ###
          # Delay the render until the template is ready
          ###
          if window._adp?.templateReady?[renderLayer.params.table_name] isnt true
            if count > 50
              console.error "Error -- timed out waiting for template to be ready"
              overrideSkip = true
            else
              overrideSkip = false
            unless overrideSkip
              delay 50, ->
                ++count
                delayedLayerRender count, renderLayer
              return false
          # Template is ready
          console.info "Template script ready for table '#{window._adp.templateReady[renderLayer.params.table_name]}' after #{count} iterations, rendering on map"
          layerSourceObj =
            user_name: cartoAccount
            type: "namedmap"
            named_map: renderLayer
          createRawCartoMap layerSourceObj
          false # end delayedLayerRender
      $("#post-map-subtitle").text "Viewing projects containing #{totalSamples} samples (#{posSamples} positive) among #{speciesCount} species"
      $("#post-map-subtitle")
      .removeClass "text-muted"
      .addClass "bg-success"
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
  goDeep = true
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
    mapBounds = getSearchObject()
    for project in results
      # In a deep search, we don't want a project defined by these
      # bounds -- we want just the bounds as-is
      if mapBounds.bounding_box_n.data > boundingBox.n
        boundingBox.n = mapBounds.bounding_box_n.data
      if mapBounds.bounding_box_e.data > boundingBox.e
        boundingBox.e = mapBounds.bounding_box_e.data
      if mapBounds.bounding_box_s.data < boundingBox.s
        boundingBox.s = mapBounds.bounding_box_s.data
      if mapBounds.bounding_box_w.data < boundingBox.w
        boundingBox.w = mapBounds.bounding_box_w.data
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
          templateParam =
            project: project.project_id
            table: table
          createTemplateByProject templateParam
        catch e
          console.error "Warning: couldn't create project template: #{e.message}"
          console.warn e.stack
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
    #   # For leaflet, if we don't zoom first the map gets cranky with
    #   # its baseLayer
    #   if geo.lMap?
    #     # http://leafletjs.com/reference.html#events-once
    #     geo.lMap.once "zoomend", =>
    #       # http://leafletjs.com/reference.html#map-zoomend
    #       console.info "ZoomEnd is ensuring centering"
    #       ensureCenter(0)
    #     geo.lMap.setZoom zoom
    #   try
    #     # If we're using a Polymer map, set it's configs
    #     p$("#global-data-map").latitude = mapCenter.lat
    #     p$("#global-data-map").longitude = mapCenter.lng
    #     p$("#global-data-map").zoom = zoom
    #   try
    #     # NOW we can set the leafelet center
    #     geo.lMap.setView mapCenter.getObj()
    # catch e
    #   console.warn "Failed to rezoom/recenter map - #{e.message}", boundingBoxArray
    #   console.warn e.stack
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
        # Different tables may have a different col set, so we have to
        # select *
        tempQuery = "select * from #{layer.params.table_name } where (genus ilike '%#{layer.params.genus }%' and specificepithet ilike '%#{layer.params.specific_epithet }%' and diseasedetected ilike '%#{layer.params.disease_detected }%' and diseasetested ilike '%#{layer.params.pathogen }%' and decimallatitude between #{boundingBox.s} and #{boundingBox.n} and decimallongitude between #{boundingBox.w} and #{boundingBox.e});"
        resultQueryPile += tempQuery
      # Label the subtext
      $("#post-map-subtitle").text subText
      $("#post-map-subtitle")
      .removeClass "text-muted"
      .addClass "bg-success"
      # Initiate a query against the found tables
      args = "action=fetch&sql_query=#{post64(resultQueryPile)}"
      $.post "#{uri.urlString}api.php", args, "json"
      .done (result) ->
        console.info "Detailed results: ", result
        try
          results = Object.toArray result.parsed_responses
          getSampleSummaryDialog results, projectTableMap
          coordArray = new Array()
          for tableResults in results
            rows = Object.toArray tableResults.rows
            for row in rows
              p =
                lat: row.decimallatitude
                lng: row.decimallongitude
              coordArray.push canonicalizePoint p
          zoom = getMapZoom coordArray, ".map-container"
          mapCenter = getMapCenter coordArray
          console.info "Recalculate data zoom = #{zoom} center", mapCenter, "for points array", coordArray
          try
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
              console.warn "Failed to recenter map - #{e.message}", coordArray
              console.warn e.stack
          catch e
            console.warn "Failed to rezoom/recenter map - #{e.message}", coordArray
            console.warn e.stack
        catch e
          console.error "Couldn't parse responses from server: #{e.message}"
          console.warn e.stack
          console.log "Got", result
          console.debug "#{uri.urlString}api.php?#{args}"
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
        try
          templateParam =
            project: pid
            table: table
          createTemplateByProject templateParam, true
        validTables.push table
        # TODO Calculate a color based on recency ...
        layer =
          name: namedMapSource
          type: "namedmap"
          layers: [
            layer_name: "layer-#{layers.length}"
            interactivity: "cartodb_id, id, diseasedetected, genus, specificepithet, dateidentified"
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
  $("#post-map-subtitle")
  .removeClass "bg-success"
  .addClass "text-muted"
  .text ""
  if resetZoom
    geo.lMap.setZoom geo.defaultLeafletOptions.zoom
    geo.lMap.panTo geo.defaultLeafletOptions.center
  if showTables
    showAllTables()
    $("#post-map-subtitle").text "All Projects"
  false


getPrettySpecies = (rowData) ->
  genus = rowData.genus
  species = rowData.specificEpithet ? rowData.specificepithet
  ssp = rowData.infraspecificEpithet ? rowData.infraspecificEpithet
  pretty = genus
  unless isNull species
    pretty += " #{species}"
    unless isNull ssp
      pretty += " #{ssp}"
  pretty


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
  startRenderTime = Date.now()
  try
    ###
    # Default: Use a web-worker to do this "expensive" operation off-thread
    ###
    console.info "Starting Web Worker to do hard work"
    postMessageContent =
      action: "summary-dialog"
      resultsList: resultsList
      tableToProjectMap: tableToProjectMap
      windowWidth: $(window).width()
    worker = new Worker "js/global-search-worker.min.js"
    worker.addEventListener "message", (e) ->
      # Web worker callback
      html = e.data.html
      outputData = e.data.summaryRowData
      #outputData = e.data.data.data
      #outputData = e.data.rawProjectData
      #outputData = e.data.outputData
      console.info "Web worker returned", e.data
      console.log "Sending to setupDisplay", outputData
      setupDisplay html, outputData
    worker.postMessage postMessageContent
  catch e
    ###
    # Classic way -- do this on thread.
    # Based on version at
    #
    # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/e042dae2c07beb34fd80c64a86b3a843f8172528/coffee/global-search.coffee#L938-L1145
    #
    # May lock up browser UI thread during execution
    ###
    console.warn "Warning: This browser doesn't support Web Workers. Using fallback."
    unless isArray resultsList
      resultsList = Object.toArray resultsList
    if resultsList.length is 0
      console.warn "There were no results in the result list"
      return false
    console.log "Generating dialog from", resultsList
    projectTableRows = new Array()
    outputData = new Array()
    i = 0
    unhelpfulCols = [
      "cartodb_id"
      "the_geom"
      "the_geom_webmercator"
      "id"
      ]
    window.dataSummary =
      species: []
      diseases: []
      data: {}
    for projectResults in resultsList
      ++i
      dataWidthMax = $(window).width() * .5
      dataWidthMin = $(window).width() * .3
      try
        rowSet = projectResults.rows
        try
          # Clean up the provided view
          altRows = new Object()
          for n, row of projectResults.rows
            # Remove the useless-to-people cols
            for col in unhelpfulCols
              delete row[col]
            altRows[n] = row
            # Add a few others for the CSV download
            row.carto_table = projectResults.table
            row.project_id = projectResults.project_id
            species = getPrettySpecies row
            unless species in dataSummary.species
              dataSummary.species.push species
            d = row.diseasetested
            unless d in dataSummary.diseases
              dataSummary.diseases.push d
            if isNull dataSummary.data[species]
              dataSummary.data[species] = {}
            if isNull dataSummary.data[species][d]
              dataSummary.data[species][d] =
                samples: 0
                positive: 0
                negative: 0
                no_confidence: 0
                prevalence: 0
            if row.diseasedetected.toBool()
              dataSummary.data[species][d].positive++
            else
              if row.diseasedetected.toLowerCase() is "no_confidence"
                dataSummary.data[species][d].no_confidence++
              else
                dataSummary.data[species][d].negative++
            dataSummary.data[species][d].samples++
            prevalence = dataSummary.data[species][d].positive / dataSummary.data[species][d].samples
            dataSummary.data[species][d].prevalence = prevalence
            outputData.push row
          rowSet = altRows
        catch
          # Make sure we have the dat for the CSV download
          for n, row of projectResults.rows
            row.carto_table = projectResults.table
            row.project_id = projectResults.project_id
            outputData.push row
        data = JSON.stringify rowSet
        if isNull data
          console.warn "Got bad data for row ##{i}!", projectResults, projectResults.rows, data
          continue
        data = """#{data}"""
      catch
        data = "Invalid data from server"
      table =
      project = tableToProjectMap[projectResults.table]
      row = """
      <tr>
        <td colspan="4" class="code-box-container"><pre readonly class="code-box language-json" style="max-width:#{dataWidthMax}px;min-width:#{dataWidthMin}px">#{data}</pre></td>
        <td class="text-center"><paper-icon-button data-toggle="tooltip" raised class="click" data-href="https://amphibiandisease.org/project.php?id=#{project.id}" icon="icons:arrow-forward" title="#{project.name}"></paper-icon-button></td>
      </tr>
      """
      projectTableRows.push row
    # Create the pretty table
    window.summaryTableRows = new Object()
    for species, diseases of dataSummary.data
      for disease, data of diseases
        unless summaryTableRows[disease]?
          summaryTableRows[disease] = new Array()
        prevalence = data.prevalence * 100
        prevalence = roundNumberSigfig prevalence, 2
        summaryTableRows[disease].push """
        <tr>
          <td>#{species}</td>
          <td>#{data.samples}</td>
          <td>#{data.positive}</td>
          <td>#{data.negative}</td>
          <td>#{prevalence}%</td>
        </tr>
        """
    summaryTable = ""
    for disease, tableRows of summaryTableRows
      summaryTable += """
      <div class="row">
        <div class="col-xs-12">
          <h3>#{disease}</h3>
          <table class="table table-striped">
            <tr>
              <th>Species</th>
              <th>Samples</th>
              <th>Disease Positive</th>
              <th>Disease Negative</th>
              <th>Disease Prevalence</th>
            </tr>
            #{tableRows.join("\n")}
          </table>
        </div>
      </div>
      """
    # Create the whole thing
    html = """
    <paper-dialog id="modal-sql-details-list" modal always-on-top auto-fit-on-attach>
      <h2>Project Result List</h2>
      <paper-dialog-scrollable>
        #{summaryTable}
        <div class="row">
          <div class="col-xs-12">
            <h3>Raw Data For Developers</h3>
            <table class="table table-striped">
              <tr>
                <th colspan="4">Query Data (JSON)</th>
                <th>Visit Project</th>
              </tr>
              #{projectTableRows.join("\n")}
            </table>
          </div>
        </div>
      </paper-dialog-scrollable>
      <div class="buttons">
        <paper-button id="generate-download">Create Download</paper-button>
        <paper-button dialog-dismiss>Close</paper-button>
      </div>
    </paper-dialog>
    """
    setupDisplay html, outputData
    # End no web worker fallback
  ###
  # Cleanup function with binds
  #
  # Both the web worker callback and the "classic" run need this
  ###
  setupDisplay = (html, outputData) ->
    downloadSelector = "#generate-download"
    csvOptions =
      objectAsValues: true
    $("#modal-sql-details-list").remove()
    $("body").append html
    console.log "SetupDisplay about to generate using", outputData
    $(downloadSelector).click ->
      generateCSVFromResults(outputData, this)
    # Pre-populate download immediately, if possible
    try
      generateCSVFromResults outputData, document.getElementById(downloadSelector.slice(1))
    for el in $(".code-box")
      try
        Prism.highlightElement(el, true)
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
      animateLoad()
      startTime = Date.now()
      console.log "Calling dialog helper"
      safariDialogHelper "#modal-sql-details-list", 0, ->
        elapsed = Date.now() - startTime
        console.info "Successfully opened dialog in #{elapsed}ms via safariDialogHelper"
        $(".leaflet-control-attribution").attr "hidden", "hidden"
        $(".leaflet-control").attr "hidden", "hidden"
        i = 0
        timeout = 100
        maxTime = 30000
        do checkIsVisible = ->
          delay timeout, ->
            ++i
            if (i * timeout) < maxTime and not $("#modal-sql-details-list").isVisible()
              checkIsVisible()
            else
              stopLoad()
              appxTime = (timeout * i) - (timeout / 2) + elapsed
              if appxTime > 500
                console.warn "It took about #{appxTime}ms to render the dialog visible!"
              else
                console.info "Dialog ready in about #{appxTime}ms"

    bindClicks()
    elapsed = Date.now() - startRenderTime
    console.info "Generated project result list in #{elapsed}ms"
  false


createOverflowMenu = ->
  ###
  # Create the overflow menu lazily
  ###
  checkLoggedIn (result) ->
    accountSettings = if result.status then """<paper-menu class="dropdown-content">
    <paper-item data-href="https://amphibiandisease.org/admin" class="click">
      <iron-icon icon="icons:settings-applications"></iron-icon>
      Account Settings
    </paper-item>
    <paper-item data-href="https://amphibiandisease.org/admin-login.php?q=logout" class="click">
      <span class="glyphicon glyphicon-log-out"></span>
      Log Out
    </paper-item>
    """ else ""
    menu = """
  <paper-menu-button id="header-overflow-menu" vertical-align="bottom" horizontal-offset="-15" horizontal-align="right" vertical-offset="30">
    <paper-icon-button icon="icons:more-vert" class="dropdown-trigger"></paper-icon-button>
    <paper-menu class="dropdown-content">
      #{accountSettings}
      <paper-item data-href="https://amphibian-disease-tracker.readthedocs.org" class="click">
        <iron-icon icon="icons:chrome-reader-mode"></iron-icon>
        Documentation
      </paper-item>
      <paper-item data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker" class="click">
        <iron-icon icon="glyphicon-social:github"></iron-icon>
        Github
      </paper-item>
        <paper-item data-href="#{uri.urlString}dashboard.php" class="click">
          <iron-icon icon="icons:donut-small"></iron-icon>
          Data Dashboard
        </paper-item>
      <paper-item data-function="firstLoadInstructionPrompt" data-args="true" class="click">
        Show Welcome
      </paper-item>
      <paper-item data-href="https://amphibiandisease.org/about.php" class="click">
        About
      </paper-item>
    </paper-menu>
  </paper-menu-button>
    """
    $("#header-overflow-menu").remove()
    $("header#header-bar .logo-container + p").append menu
    unless isNull accountSettings
      $("header#header-bar paper-icon-button[icon='icons:settings-applications']").remove()
    bindClicks()
  false


firstLoadInstructionPrompt = (force = false) ->
  loadCookie = "#{uri.domain}_firstLoadPrompt"
  try
    hasLoaded = $.cookie(loadCookie).toBool()
  catch
    hasLoaded = false
  if force or not hasLoaded
    # Logged in is the same
    if hasLoaded
      console.info "Forced to continue showing prompt to user who has seen it already"
    checkLoggedIn (result) ->
      if result.status
        console.info "User is logged in, and does not need an instruction prompt"
        $.cookie loadCookie, true
        hasLoaded = true
      if hasLoaded and not force
        return false
      if hasLoaded
        console.warn "Force-showing the prompt to a logged in user"
      # First load: Let's show a prompt to read up
      # See:
      # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/168

      # Create a alert box to let users know
      html = """
      <div class="alert alert-warning alert-dismissable slide-alert slide-out" role="alert" id="first-load-prompt">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <div class="alert-message">
          <p class="center-block text-center"><strong>Welcome!</strong></p>
          <p>
            Need help getting started? We've put together some resources for you below.
          </p>
          <div class="center-block text-center">
            <a href="http://updates.amphibiandisease.org/portal/2016/06/30/Uploadingdata.html" class="btn btn-default click" data-newtab="true">Get Involved</a>  <a href="http://updates.amphibiandisease.org/posts/" class="click btn btn-default" data-newtab="true">Learn More</a>  <a href="https://amphibian-disease-tracker.readthedocs.io/en/latest/User%20Workflow/" class="btn btn-default click" data-newtab="true">Read Documentation</a>
          </div>
          <p>
            You can also find these resources by scrolling down on this page later.
          </p>
        </div>
      </div>
      """
      # Add it to the dom
      $("#first-load-prompt").remove()
      $("body").append html
      bindClicks()
      # Animate it in
      $("#first-load-prompt")
      .removeClass "slide-out"
      .addClass "slide-in"
      # Add the cookie that it's shown
      $.cookie loadCookie, true
  false




###
# Startup initializations
###

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
  geo.tileLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions)
  geo.tileLayer.addTo lMap
  geo.lMap = lMap
  geo.tileLayer.on "load", ->
    console.info "Map ready"
    firstLoadInstructionPrompt()
  # # CartoDB is throwing 400 bad request right now on some high zooms ...
  # # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/175
  # geo.lMap.options.maxZoom = 6
  $(".coord-input").keyup ->
    checkCoordinateSanity()
  # Project search event handling
  initProjectSearch = (clickedElement, forceDeep = false) ->
    ok = checkCoordinateSanity()
    unless ok
      toastStatusMessage "Please check your coordinates"
      return false
    search = getSearchObject()
    try
      try
        deep = $(clickedElement).attr("data-deep").toBool()
      catch
        deep = false
      if forceDeep
        deep = true
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
      initProjectSearch(null, true)
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
  #
  $("#use-viewport-bounds").on "iron-change", ->
    if not p$("#use-viewport-bounds").checked
      console.debug "Resetting search bounds on uncheck"
      $("#north-coordinate").val 90
      $("#west-coordinate").val -180
      $("#south-coordinate").val -90
      $("#east-coordinate").val 180
    else
      setViewerBounds()
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
  $("#show-more-tips").click ->
    isOpened = !p$("#more-tips").opened
    p$("#more-tips").toggle()
    text = if isOpened then "Fewer tips..." else "More tips..."
    $("#show-more-tips").text text
  $("#reset-global-map").contextmenu ->
    resetMap()
    $("#taxa-input").val ""
    p$("#use-viewport-bounds").checked = true
    for radioGroup in $("paper-radio-group")
      try
        p$(radioGroup).selectIndex 0
    false
  createOverflowMenu()
  false
