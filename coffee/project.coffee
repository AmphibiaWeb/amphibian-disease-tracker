###
# Project-specific code
###

_adp.mapRendered = false
_adp.zcClient = null

publicData = null

try
  do createOverflowMenu = ->
    ###
    # Create the overflow menu lazily
    ###
    checkLoggedIn (result) ->
      accountSettings = if result.status then """    <paper-item data-href="https://amphibiandisease.org/admin" class="click">
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
        <paper-item data-href="#{uri.urlString}dashboard.php" class="click">
          <iron-icon icon="icons:donut-small"></iron-icon>
          Data Dashboard
        </paper-item>
        <paper-item data-href="https://amphibian-disease-tracker.readthedocs.org" class="click">
          <iron-icon icon="icons:chrome-reader-mode"></iron-icon>
          Documentation
        </paper-item>
        <paper-item data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker" class="click">
          <iron-icon icon="glyphicon-social:github"></iron-icon>
          Github
        </paper-item>
        <paper-item data-href="https://amphibiandisease.org/about.php" class="click">
          About / Legal
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

fillSorterWithDropdown = (selector = ".sort-by-placeholder-text") ->
  ###
  # Replace .sort-by-placeholder-text with a dropdown for the various
  # sort options.
  #
  # This should also have a corresponding list in ../project.php
  ###
  sortOptions =
    date:
      title: "sampling date"
      key: "date"
    affiliation:
      title: "affiliation"
      key: "affiliation"
    lab:
      title: "PI lab"
      key: "lab"
    contact:
      title: "PI contact"
      key: "contact"
  matchKey = $(selector).attr "data-order-key"
  dropdownHtml = ""
  i = 0
  selectedIndex = 0
  for k, data of sortOptions
    if data.key is matchKey
      selectedIndex = i
    ++i
    dropdownHtml += """
    <paper-item data-sort-key="#{data.key}">#{data.title}</paper-item>
    """
  html = """
  <paper-dropdown-menu label="Sort Options" id="sort-options">
    <paper-listbox class="dropdown-content" selected="#{selectedIndex}">
      #{dropdownHtml}
    </paper-listbox>
  </paper-dropdown-menu>
  """
  $(selector).replaceWith html
  selectCounter = 0
  $("#sort-options").on "iron-select", ->
    selected = p$(this).selectedItem
    sortKey = $(selected).attr "data-sort-key"
    console.debug "Selected '#{sortKey}'"
    if selectCounter > 0
      # Load the new sort
      goTo "https://#{uri.domain}.org/project.php?sort=#{sortKey}"
    ++selectCounter
  false

checkProjectAuthorization = (projectId = _adp.projectId, callback = postAuthorizeRender) ->
  startLoad()
  console.info "Checking authorization for #{projectId}"
  checkLoggedIn (result) ->
    unless projectId?
      if result.status
        console.info "Logged in user, no project"
        adminButton = """
        <paper-icon-button icon="icons:dashboard" class="authorized-action" id="show-actions" data-href="#{uri.urlString}admin-page.html" data-toggle="tooltip" title="Administration Dashboard"> </paper-icon-button>
        """
        # $("#title").append adminButton
        # bindClicks ".authorized-action"
      else
        console.info "Not logged in"
      stopLoad()
      return false
    unless result.status
      console.info "Non logged-in user or unauthorized user"
      renderPublicMap()
      stopLoad()
      return false
    else
      # Check if the user is authorized
      dest = "#{uri.urlString}admin-api.php"
      args = "perform=check_access&project=#{projectId}"
      $.post dest, args, "json"
      .done (result) ->
        if result.status
          console.info "User is authorized"
          project = result.detail.project
          if typeof callback is "function"
            callback project, result.detailed_authorization
          else
            console.warn "No callback specified!"
            console.info "Got project data", project
        else
          console.info "User is unauthorized"
      .fail (result, status) ->
        console.log "Error checking server", result, status
      .always ->
        stopLoad()
  false

renderEmail = (response) ->
  animateLoad()
  dest = "#{uri.urlString}api.php"
  args = "action=is_human&recaptcha_response=#{response}&project=#{_adp.projectId}"
  $.post dest, args, "json"
  .done (result) ->
    console.info "Checked response"
    console.log result
    authorData = result.author_data
    showEmailField authorData.contact_email
    if not isNull(result.technical?.name) and not isNull(result.technical?.email)
      label = "Technical Contact #{result.technical.name}"
      showEmailField result.technical.email, label, "technical-email-send"
    stopLoad()
  .fail (result, status) ->
    stopLoadError "Sorry, there was a problem getting the contact email"
    false
  false


showEmailField = (email, fieldLabel = "Contact Email", fieldId = "contact-email-send") ->
  html = """
  <div class="row appended-email-field">
    <paper-input readonly class="col-xs-8 col-md-11" label="#{fieldLabel}" value="#{email}"></paper-input>
    <paper-fab icon="communication:email" class="click materialblue" id="#{fieldId}" data-href="mailto:#{email}" data-toggle="tooltip" title="Send Email"></paper-fab>
  </div>
  """
  if $("#email-fill").exists()
    $("#email-fill").replaceWith html
  else
    fields = $(".appended-email-field")
    i = fields.length - 1
    lastField = $(".appended-email-field").get i
    $(lastField).after html
  bindClicks("##{fieldId}")
  false


renderMapWithData = (projectData, force = false) ->
  showKml = ->
    try
      unless isNull projectData.transect_file
        kmlLoader projectData.transect_file, ->
          console.debug "Loaded KML file successfully"
  if _adp.mapRendered is true and force isnt true
    console.warn "Carto: The map was asked to be rendered again, but it has already been rendered!"
    showKml()
    return false
  cartoObj = projectData.carto_id
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
          console.error "cartoObj must be JSON string or obj, given", cartoObj
          console.warn "Cleaned obj:", deEscape cartoObj
          console.warn "Told '#{err1}' then", e.message
          stopLoadError "Couldn't parse data"
          return false
  else
    cartoData = cartoObj
  _adp.cartoDataParsed = cartoData
  raw = cartoData.raw_data
  if isNull raw
    console.warn "No raw data to render"
    showKml()
    return false
  if raw.hasDataFile
    helperDir = "helpers/"
    filePath = raw.filePath
    if filePath.search(helperDir) is -1
      filePath = "#{helperDir}#{filePath}"
    # most recent download
    downloadButton = ""
    arkIdentifiers = projectData.dataset_arks.split ","
    if arkIdentifiers.length > 0
      baseFilePath = filePath.split "/"
      baseFilePath.pop()
      baseFilePath = baseFilePath.join "/"
      # Add other small buttons
      i = 0
      for ark in arkIdentifiers
        data = ark.split "::"
        arkId = data[0]
        filePath = "#{baseFilePath}/#{data[1]}"
        extraClasses = if i is 0 then "" else "btn-xs download-alt-datafile"
        title = if i is 0 then "Download Newest Datafile" else "#{arkId} dataset"
        html = """
          <button class="btn btn-primary click download-file download-data-file #{extraClasses}" data-href="#{filePath}" data-newtab="true" data-toggle="tooltip" title="#{arkId} (right-click to copy)" data-ark="#{arkId}">
            <iron-icon icon="editor:insert-chart"></iron-icon>
            #{title}
          </button>
        """
        downloadButton += html
        ++i
  downloadButton ?= ""
  cartoTable = cartoData.table
  if isNull cartoTable
    console.warn "WARNING: This project has no data associated with it. Not doing map render."
    showKml()
    return false
  try
    try
      if cartoData.bounding_polygon.paths.toBool() is false and not isNull cartoData.bounding_polygon.multibounds
        cartoData.bounding_polygon.paths = cartoData.bounding_polygon.multibounds[0]
    zoomPaths = cartoData.bounding_polygon.paths ? cartoData.bounding_polygon
    zoom = getMapZoom zoomPaths, "#transect-viewport"
    console.info "Got zoom", zoom
  catch
    zoom = ""
  poly = cartoData.bounding_polygon
  if isArray(poly) or not poly?.paths?
    paths = poly
    tmp = toObject poly
    if typeof tmp isnt "object"
      tmp = new Object()
    tmp.paths = poly
    unless isArray tmp.paths
      tmp.paths = new Array()
    poly = tmp
  poly.fillColor ?= defaultFillColor
  poly.fillOpacity ?= defaultFillOpacity
  mapHtml = """
  <google-map-poly closed fill-color="#{poly.fillColor}" fill-opacity="#{poly.fillOpacity}" stroke-weight="1">
  """
  usedPoints = new Array()
  for point in poly.paths
    unless point in usedPoints
      usedPoints.push point
      mapHtml += """
      <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
      """
  mapHtml += "    </google-map-poly>"

  cartoQuery = "SELECT genus, specificepithet, diseasetested, diseasedetected, originaltaxa, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
  console.info "Would ping cartodb with", cartoQuery
  apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
  args = "action=fetch&sql_query=#{apiPostSqlQuery}"
  console.debug "Hitting endpoint for carto lookup", "#{uri.urlString}api.php?#{args}"
  $.post "api.php", args, "json"
  .done (result) ->
    if _adp.mapRendered is true
      console.warn "Duplicate map render! Skipping thread"
      showKml()
      return false
    console.info "Carto query got result:", result
    unless result.status
      error = result.human_error ? result.error
      unless error?
        error = "Unknown error"
      stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
      showKml()
      return false
    rows = result.parsed_responses[0].rows
    points = new Array()
    pointPoints = new Array()
    console.log "Running swapped cartoDB order (lng, lat)"
    perTaxaStatus = new Object()
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      # cartoDB works in lng, lat
      lat = geoJson.coordinates[1]
      lng = geoJson.coordinates[0]
      points.push [lat,lng]
      try
        pointPoints.push canonicalizePoint [lat, lng]
      # Fill the points as markers
      taxa = "#{row.genus} #{row.specificepithet}"
      unless perTaxaStatus[taxa]?
        perTaxaStatus[taxa] =
          positive: false
          negative: false
          no_confidence: false
          counts:
            total: 0
            positive: 0
            negative: 0
            no_confidence: 0
      # Get disease status
      row.diseasedetected = switch row.diseasedetected.toString().toLowerCase()
        when "true"
          perTaxaStatus[taxa].positive = true
          perTaxaStatus[taxa].counts.positive++
          "positive"
        when "false"
          perTaxaStatus[taxa].negative = true
          perTaxaStatus[taxa].counts.negative++
          "negative"
        else
          perTaxaStatus[taxa].no_confidence = true
          perTaxaStatus[taxa].counts.no_confidence++
          row.diseasedetected.toString()
      perTaxaStatus[taxa].counts.total++
      note = ""
      if taxa isnt row.originaltaxa
        note = "(<em>#{row.originaltaxa}</em>)"
      marker = """
      <google-map-marker latitude="#{lat}" longitude="#{lng}" data-disease-detected="#{row.diseasedetected}">
        <p>
          <em>#{row.genus} #{row.specificepithet}</em> #{note}
          <br/>
          Tested <strong>#{row.diseasedetected}</strong> for #{row.diseasetested}
        </p>
      </google-map-marker>
      """
      if row.diseasedetected isnt "positive" and row.diseasedetected isnt "negative"
        row.diseasedetected = "inconclusive"
      $(".aweb-link-species[data-species='#{row.genus} #{row.specificepithet}']").attr "data-#{row.diseasedetected}", "true"
      # $("#transect-viewport").append marker
      mapHtml += marker
    unless poly?.paths?
      try
        _adp.canonicalHull = createConvexHull points, true
    # Looped over all of them
    googleMap = """
          <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" map-type="hybrid" zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6" api-key="#{gMapsApiKey}">
            #{mapHtml}
          </google-map>
    """
    monthPretty = ""
    months = projectData.sampling_months.split(",")
    i = 0
    for month in months
      ++i
      if i > 1 and i is months.length
        if months.length > 2
          # Because "January, and February" looks silly
          # But "January, February, and March" looks fine
          monthPretty += ","
        monthPretty += " and "
      else if i > 1
        monthPretty += ", "
      if isNumber month
        month = dateMonthToString month
      monthPretty += month
    i = 0
    yearPretty = ""
    years = projectData.sampling_years.split(",")
    i = 0
    for year in years
      ++i
      if i > 1 and i is years.length
        if years.length > 2
          # Because "2012, and 2013" looks silly
          # But "2012, 2013, and 2014" looks fine
          yearPretty += ","
        yearPretty += " and "
      else if i > 1
        yearPretty += ", "
      yearPretty += year
    if years.length is 1
      yearPretty = "the year #{yearPretty}"
    else
      yearPretty = "the years #{yearPretty}"
    d1 = new Date toInt projectData.sampled_collection_start
    d2 = new Date toInt projectData.sampled_collection_end
    collectionRangePretty = "#{dateMonthToString d1.getMonth()} #{d1.getFullYear()} &#8212; #{dateMonthToString d2.getMonth()} #{d2.getFullYear()}"
    mapData = """
    <div class="row">
      <h2 class="col-xs-12">Mapping Data</h2>
      #{googleMap}
      <div class="col-xs-12 col-md-3 col-lg-6">
        <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were taken from #{collectionRangePretty}</p>
        <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were taken in #{monthPretty}</p>
        <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were sampled in #{yearPretty}</p>
        <p class="text-muted"><iron-icon icon="icons:language"></iron-icon> The effective project center is at (#{roundNumberSigfig projectData.lat, 6}, #{roundNumberSigfig projectData.lng, 6}) with a sample radius of #{projectData.radius}m and a resulting locality <strong class='locality'>#{projectData.locality}</strong></p>
        <p class="text-muted"><iron-icon icon="editor:insert-chart"></iron-icon> The dataset contains #{projectData.disease_positive} positive samples (#{roundNumber(projectData.disease_positive * 100 / projectData.disease_samples)}%), #{projectData.disease_negative} negative samples (#{roundNumber(projectData.disease_negative *100 / projectData.disease_samples)}%), and #{projectData.disease_no_confidence} inconclusive samples (#{roundNumber(projectData.disease_no_confidence * 100 / projectData.disease_samples)}%)</p>
        <div class="download-buttons" id="data-download-buttons">
          #{downloadButton}
        </div>
      </div>
    </div>
    """
    mapData = mapData.replace /NaN/mg, "0"
    unless _adp.mapRendered is true
      $("#auth-block").append mapData
      setupMapMarkerToggles()
      _adp.mapRendered = true
      unless isNull _adp.pageSpeciesList
        console.log "Creating CSV downloader for species list"
        d = new Date()
        options =
          create: true
          downloadFile: "species-list-#{projectData.project_id}-#{d.toISOString()}.csv"
          selector: ".download-buttons"
          buttonText: "Download Species Stats"
          splitValues: " " # Split genus, species, ssp into their own cols
          header: ["Genus","Species","Subspecies", "Positive Samples?", "Negative Samples?", "Inconclusive Samples?", "Positive Count", "Negative Count", "Inconclusive Count", "Totals"]
        adjustedList = new Array()
        for speciesItem in _adp.pageSpeciesList
          tmp = speciesItem.split options.splitValues
          if tmp.length < 3
            while tmp.length < 3
              tmp.push ""
          # Now we have the right spacing
          # If we have species in right category, append it
          if perTaxaStatus[speciesItem]?
            tmp.push perTaxaStatus[speciesItem].positive.toString()
            tmp.push perTaxaStatus[speciesItem].negative.toString()
            tmp.push perTaxaStatus[speciesItem].no_confidence.toString()
            tmp.push perTaxaStatus[speciesItem].counts.positive.toString()
            tmp.push perTaxaStatus[speciesItem].counts.negative.toString()
            tmp.push perTaxaStatus[speciesItem].counts.no_confidence.toString()
            tmp.push perTaxaStatus[speciesItem].counts.total.toString()
          else
            console.warn "CSV downloader couldn't find #{speciesItem} in perTaxaStatus"
            window.perTaxaStatus = perTaxaStatus
          adjustedList.push tmp.join(options.splitValues)
        downloadCSVFile adjustedList, options
    bindClicks(".download-file")
    sqlQueryBox()
    $(".download-data-file").contextmenu (event) ->
      event.preventDefault()
      console.log "Event details", event
      elPos = $(this).offset()
      html = """
      <paper-material class="ark-context-wrapper" style="top:#{event.pageY}px;left:#{event.pageX}px;position:absolute">
        <paper-menu class=context-menu">
          <paper-item class="copy-ark-context">
            Copy ARK to clipboard
          </paper-item>
        </paper-menu>
      </paper-material>
      """
      $(".ark-context-wrapper").remove()
      # Append to DOM
      $("body").append html
      getMapZoom(pointPoints, "#transect-viewport")
      # Create copy event
      ZeroClipboard.config _adp.zcConfig
      zcClientInitial = new ZeroClipboard $(".copy-ark-context").get 0
      ark = $(this).attr "data-ark"
      #url = "https://n2t.net/#{ark}"
      url = "http://biscicol.org/id/#{ark}"
      clipboardData =
        dataType: "text/plain"
        data: url
        "text/plain": url
      zcClientInitial.setData clipboardData
      zcClientInitial.on "aftercopy", (e) ->
        if e.data["text/plain"]
          toastStatusMessage "ARK resolver path copied to clipboard"
        else
          console.error "ZeroClipboard had an error - ", e
          console.warn clipboardData
          toastStatusMessage "Error copying to clipboard"
      zcClientInitial.on "error", (e) ->
        console.error "Initial error"
        zcClient = new ZeroClipboard $(".copy-ark-context").get 0
        copyFn(zcClient)
      #
      # Copy helper
      copyFn = (zcClient = zcClientInitial, zcEvent = null) ->
        # http://caniuse.com/#feat=clipboard
        try
          clip = new ClipboardEvent("copy", clipboardData)
          document.dispatchEvent(clip)
          toastStatusMessage "ARK resolver path copied to clipboard"
          return false
        catch e
          console.error "Error creating copy: #{e.message}"
          console.warn e.stack
          console.warn "Can't use HTML5"
        zcClient.setData clipboardData
        unless isNull zcEvent
          zcEvent.setData clipboardData
        zcClient.on "aftercopy", (e) ->
          if e.data["text/plain"]
            toastStatusMessage "ARK resolver path copied to clipboard"
          else
            console.error "ZeroClipboard had an error - ", e
            console.warn clipboardData
            toastStatusMessage "Error copying to clipboard"
        zcClient.on "error", (e) ->
          #https://github.com/zeroclipboard/zeroclipboard/blob/master/docs/api/ZeroClipboard.md#error
          console.error "Error copying to clipboard"
          console.warn "Got", e
          if e.name is "flash-overdue"
            # ZeroClipboard.destroy()
            if _adp.resetClipboard is true
              console.error "Resetting ZeroClipboard didn't work!"
              return false
            ZeroClipboard.on "ready", ->
              # Re-call
              _adp.resetClipboard = true
              zcClient = new ZeroClipboard $(".copy-ark-context").get 0
              copyFn(zcClient)
          # Case for no flash at all
          if e.name is "flash-disabled"
            # stuff
            console.info "No flash on this system"
            ZeroClipboard.destroy()
            toastStatusMessage "Clipboard copying isn't available on your system"
      ##
      # Events
      inFn = (el) ->
        $(this).addClass "iron-selected"
        false
      outFn = (el) ->
        $(this).removeClass "iron-selected"
        false
      caller = this
      $(".ark-context-wrapper paper-item")
      .hover inFn, outFn
      .click ->
        _adp.resetClipboard = false
        # Remove wrapper
        $(".ark-context-wrapper").remove()
        false
      .contextmenu ->
        $(".ark-context-wrapper").remove()
        false
      false
    checkArkDataset(projectData)
    setPublicData(projectData)
    for el in $(".aweb-link-species")
      isPositive = $(el).attr("data-positive").toBool()
      if isPositive
        $(el)
        .attr "data-negative", "false"
        .attr "data-inconclusive", "false"
    console.info "Carto lookup complete"
    showKml()
    stopLoad()
  .fail (result, status) ->
    console.error "Couldn't render map and carto data"
    console.error result, status
    showKml()
    stopLoadError "Couldn't render map"
  false




postAuthorizeRender = (projectData, authorizationDetails) ->
  ###
  # Takes in project data, then renders the appropriate bits
  #
  # @param object projectData -> the full projectData array from an
  #   authorized lookup
  # @param object authorizationDetails -> the permissions object
  ###
  if projectData.public
    console.info "Project is already public, not rerendering"
    false
  startLoad()
  console.info "Should render stuff", projectData
  editButton = adminButton = ""
  if authorizationDetails.can_edit
    editButton = """
    <paper-icon-button icon="icons:create" class="authorized-action" data-href="#{uri.urlString}admin-page.html?id=#{projectData.project_id}" data-toggle="tooltip" title="Edit Project"></paper-icon-button>
    """
  adminButton = """
  <paper-icon-button icon="icons:dashboard" class="authorized-action" id="show-actions" data-href="#{uri.urlString}admin-page.html" data-toggle="tooltip" title="Administration Dashboard"> </paper-icon-button>
  """
  $("#title").append editButton # + adminButton
  authorData = JSON.parse projectData.author_data
  showEmailField authorData.contact_email
  try
    if not isNull(projectData.technical_contact) and not isNull(projectData.technical_contact_email)
      label = "Technical Contact #{projectData.technical_contact}"
      showEmailField projectData.technical_contact_email, label, "technical-email-send"
  bindClicks(".authorized-action")
  cartoObj = projectData.carto_id
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
          console.error "cartoObj must be JSON string or obj, given", cartoObj
          console.warn "Cleaned obj:", deEscape cartoObj
          console.warn "Told '#{err1}' then", e.message
          stopLoadError "Couldn't parse data"
          return false
  else
    cartoData = cartoObj
  renderMapWithData(projectData) # Stops load
  try
    prepParsedDataDownload projectData
  false



kmlLoader = (path, callback) ->
  ###
  # Load a KML file. The parser handles displaying it on any
  # google-map compatible objects.
  #
  # @param string path -> the  relative path to the file
  # @param function callback -> Callback function to execute
  ###
  try
    if typeof path is "object"
      kmlData = path
      path = kmlData.path
    else
      try
        kmlData = JSON.parse path
        path = kmlData.path
      catch
        kmlData =
          path: path
    console.debug "Loading KML file", path
  geo.inhibitKMLInit = true
  jsPath = if isNull(_adp?.lastMod?.kml) then "js/kml.min.js" else "js/kml.min.js?t=#{_adp.lastMod.kml}"
  startLoad()
  unless $("google-map").exists()
    # We don't yet have a Google Map element.
    # Create one.
    googleMap = """
    <google-map id="transect-viewport" class="col-xs-12 col-md-9 col-lg-6 kml-lazy-map" api-key="#{gMapsApiKey}" map-type="hybrid">
    </google-map>
    """
    mapData = """
    <div class="row">
      <h2 class="col-xs-12">Mapping Data</h2>
      #{googleMap}
    </div>
    """
    if $("#auth-block").exists()
      $("#auth-block").append mapData
    else
      console.warn "Couldn't find an authorization block to render the KML map in!"
      return false
    _adp.mapRendered = true
  loadJS jsPath, ->
    initializeParser null, ->
      loadKML path, ->
        # At this point, any map elements should be rendered.
        try
          # UI handling after parsing
          parsedKmlData = geo.kml.parser.docsByUrl[path]
          if isNull parsedKmlData
            # When it's in a subdirectory, the path needs a leading slash
            path = "/#{path}"
            parsedKmlData = geo.kml.parser.docsByUrl[path]
            if isNull parsedKmlData
              console.warn "Could not resolve KML by url, using first doc"
              parsedKmlData = geo.kml.parser.docs[0]
          if isNull parsedKmlData
            allError "Bad KML provided"
            return false
          console.debug "Using parsed data from path '#{path}'", parsedKmlData
          if typeof callback is "function"
            callback(parsedKmlData)
          else
            console.info "kmlHandler wasn't given a callback function"
          stopLoad()
        catch e
          allError "There was a importing the data from this KML file"
          console.warn e.message
          console.warn e.stack
        false # Ends loadKML callback
      false #
    false
  false



copyLink = (zeroClipObj = _adp.zcClient, zeroClipEvent, html5 = true) ->
  ark = p$(".ark-identifier").value
  if html5
    # http://caniuse.com/#feat=clipboard
    try
      #url = "https://n2t.net/#{ark}"
      url = "http://biscicol.org/id/#{ark}"
      clipboardData =
        dataType: "text/plain"
        data: url
        "text/plain": url
      clip = new ClipboardEvent("copy", clipboardData)
      document.dispatchEvent(clip)
      toastStatusMessage "ARK resolver path copied to clipboard"
      return false
    catch e
      console.error "Error creating copy: #{e.message}"
      console.warn e.stack
  console.warn "Can't use HTML5"
  # http://zeroclipboard.org/
  # https://github.com/zeroclipboard/zeroclipboard
  if zeroClipObj?
    zeroClipObj.setData clipboardData
    if zeroClipEvent?
      zeroClipEvent.setData clipboardData
    zeroClipObj.on "aftercopy", (e) ->
      if e.data["text/plain"]
        toastStatusMessage "ARK resolver path copied to clipboard"
      else
        toastStatusMessage "Error copying to clipboard"
    zeroClipObj.on "error", (e) ->
      #https://github.com/zeroclipboard/zeroclipboard/blob/master/docs/api/ZeroClipboard.md#error
      console.error "Error copying to clipboard"
      console.warn "Got", e
      if e.name is "flash-overdue"
        # ZeroClipboard.destroy()
        if _adp.resetClipboard is true
          console.error "Resetting ZeroClipboard didn't work!"
          return false
        ZeroClipboard.on "ready", ->
          # Re-call
          _adp.resetClipboard = true
          copyLink()
        _adp.zcClient = new ZeroClipboard $("#copy-ark").get 0
      # Case for no flash at all
      if e.name is "flash-disabled"
        # stuff
        console.info "No flash on this system"
        ZeroClipboard.destroy()
        $("#copy-ark")
        .tooltip("destroy") # Otherwise stays on click: http://getbootstrap.com/javascript/#tooltipdestroy
        .remove()
        $(".ark-identifier")
        .removeClass "col-xs-9 col-md-11"
        .addClass "col-xs-12"
        toastStatusMessage "Clipboard copying isn't available on your system"
  else
    console.error "Can't use HTML, and ZeroClipboard wasn't passed"
  false


searchProjects = ->
  ###
  # Handler to search projects on the top-level project page
  #
  ###
  search = $("#project-search").val()
  if isNull search
    $("google-map-poly").removeAttr "hidden"
    return false
  item = p$("#search-filter").selectedItem
  cols = $(item).attr "data-cols"
  console.info "Searching on #{search} ... in #{cols}"
  # POST a request to the server for projects matching this
  args = "action=search_project&q=#{search}&cols=#{cols}"
  $.post "#{uri.urlString}api.php", args, "json"
  .done (result) ->
    console.info result
    html = ""
    showList = new Array()
    maxTitleLength = 40
    # Smaller than bootstrap "small" it's full width
    bootstrapSmallBreakpoint = 768
    if bootstrapSmallBreakpoint < $(window).width() < 1050
      maxTitleLength = 20
    else if $(window).width() < 1280
      maxTitleLength = 30
    projects = Object.toArray result.result
    if projects.length > 0
      for project in projects
        showList.push project.project_id
        publicState = project.public.toBool()
        icon = if publicState then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
        shortTitle = project.project_title.slice(0, maxTitleLength)
        if project.project_title isnt shortTitle
          tooltipTitle = project.project_title
          shortTitle += "..."
        else
          tooltipTitle = "Project ##{project.project_id.slice(0,8)}..."
        button = """
        <button class="btn btn-info search-proj-link" data-href="#{uri.urlString}project.php?id=#{project.project_id}" data-toggle="tooltip" data-placement="top" title="#{tooltipTitle}">
          #{icon} #{shortTitle}
        </button>
        """
        html += "<li class='project-search-result'>#{button}</li>"
    else
      s = result.search ? search
      html = "<p><em>No results found for \"<strong>#{s}</strong>\""
    $("#project-result-container").html html
    bindClicks(".search-proj-link")
    $("google-map-poly").attr "hidden", "hidden"
    for projectId in showList
      $("google-map-poly[data-project='#{projectId}']").removeAttr "hidden"
  .fail (result, status) ->
    console.error result, status
  false


setPublicData = (projectData) ->
  publicData = projectData
  false


renderPublicMap = (projectData = publicData) ->
  ###
  #
  ###
  try
    if projectData.public.toBool()
      # We're going to already be rendered more fully
      console.info "Not rendering low-data public map for public project"
      return false
  catch
    console.error "Invalid project data passed!"
    console.warn projectData
    return false
  try
    console.info "Working with limited data", projectData
    cartoData = projectData.carto_id
    poly = cartoData.bounding_polygon
    poly.fillColor ?= "#ff7800"
    poly.fillOpacity ?= 0.35
    mapHtml = """
    <google-map-poly closed fill-color="#{poly.fillColor}" fill-opacity="#{poly.fillOpacity}" stroke-weight="1">
    """
    usedPoints = new Array()
    coordArr = getPointsFromBoundingBox projectData
    unless coordArr[0].lat?
      coordArr = getCorners coordArr
    nw =
      lat: coordArr[0].lat
      lng: coordArr[0].lng
    ne =
      lat: coordArr[1].lat
      lng: coordArr[1].lng
    se =
      lat: coordArr[2].lat
      lng: coordArr[2].lng
    sw =
      lat: coordArr[3].lat
      lng: coordArr[3].lng
    paths = [
      nw
      ne
      se
      sw
      ]
    try
      zoom = getMapZoom coordArr, "#transect-viewport"
      console.info "Got public zoom", zoom
    catch
      zoom = ""
    for point in paths
      unless point in usedPoints
        usedPoints.push point
        mapHtml += """
        <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
        """
    mapHtml += "    </google-map-poly>"
    mapCenter = getMapCenter coordArr
    googleMap = """
    <div class="row" id="public-map">
      <h2 class="col-xs-12">Project Area of Interest</h2>
      <google-map id="transect-viewport" latitude="#{mapCenter.lat}" longitude="#{mapCenter.lng}" map-type="hybrid" zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map"  api-key="#{gMapsApiKey}">
            #{mapHtml}
      </google-map>
    </div>
    """
    $("#auth-block").append googleMap
    try
      zoom = getMapZoom paths, "#transect-viewport"
      p$("#transect-viewport").zoom = zoom
    catch error
      try
        zoom = getMapZoom coordArr, "#transect-viewport"
        p$("#transect-viewport").zoom = zoom
  catch e
    stopLoadError "Couldn't render map"
    console.error "Map rendering error - #{e.message}"
    console.warn e.stack



checkArkDataset = (projectData, forceDownload = false, forceReparse = false) ->
  ###
  # See if the URL tag "#dataset:" exists. If so, take the user there
  # and "notice" it.
  #
  # @param projectData -> required so that an unauthorized user can't
  #  invoke this to get data.
  ###
  unless _adp?
    window._adp = new Object()
  fragment = uri.o.attr "fragment"
  fragList = fragment.split ","
  if forceReparse or not _adp.fragmentData?
    console.info "Examining fragment list"
    data = new Object()
    for arg in fragList
      params = arg.split ":"
      data[params[0]] = params[1]
    _adp.fragmentData = data
  dataset = _adp.fragmentData?.dataset
  unless dataset?
    return false
  # Find the dataset that matches
  console.info "Checking  ARK identifiers for dataset #{dataset} ..."
  arkIdentifiers = projectData.dataset_arks.split ","
  canonical = ""
  match = false
  for ark in arkIdentifiers
    if ark.search(dataset) isnt -1
      canonical = ark
      match = true
      break
  unless match is true
    console.warn "Could not find matching dataset in", arkIdentifiers
    return false
  data = canonical.split "::"
  dataId = data[1]
  console.info "Got matching identifier #{canonical} -> #{dataId}"
  # We don't necessarily know the file type, so * rather than $ suffix
  selector = ".download-file[data-href*='#{dataId}']"
  selector = $(selector).get(0) # Only ever get one
  if forceDownload
    url = $(selector).attr "data-href"
    openTab url
  else
    # Mark and highlight the download button
    $(selector)
    .removeClass "btn-xs btn-primary"
    .addClass "btn-success success-glow"
    .click ->
      $(this).removeClass "success-glow"
    # https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
    options =
      behavior: "smooth"
      block: "start"
    # http://caniuse.com/#feat=scrollintoview
    # All major browsers support it, but can't do much fancy yet
    # Use options instead of false when that changes
    $(selector).get(0).scrollIntoView(false) # Bottom
  selector


prepParsedDataDownload = (projectData) ->
  d = new Date()
  options =
    selector: "#data-download-buttons"
    create: true
    objectAsValues: true
    buttonText: "Download Parsed Dataset"
    downloadFile: "datalist-#{projectData.project_id}-#{d.toISOString()}.csv"
  parseableData = new Object()
  # Ping carto for full dataset
  cartoObj = projectData.carto_id
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
          console.error "cartoObj must be JSON string or obj, given", cartoObj
          console.warn "Cleaned obj:", deEscape cartoObj
          console.warn "Told '#{err1}' then", e.message
          stopLoadError "Couldn't parse data"
          return false
  else
    cartoData = cartoObj
  cartoTable = cartoData.table
  if isNull cartoTable
    console.warn "WARNING: This project has no data associated with it. Not creating download."
    return false
  cartoQuery = "SELECT *, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
  console.info "Would ping cartodb with", cartoQuery
  apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
  args = "action=fetch&sql_query=#{apiPostSqlQuery}"
  _adp.dataPoints = new Array()
  $.post "api.php", args, "json"
  .done (result) ->
    unless result.status
      error = result.human_error ? result.error
      unless error?
        error = "Unknown error"
      stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
      return false
    # take fimsExtra for each and slot into own columns
    rows = result.parsed_responses[0].rows
    dataObj = new Array()
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      # cartoDB works in lng, lat
      lat = geoJson.coordinates[1]
      lng = geoJson.coordinates[0]
      coordObj =
        lat: lat
        lng: lng
      pTmp = canonicalizePoint coordObj
      _adp.dataPoints.push pTmp
      row.decimalLatitude = lat
      row.decimalLongitude = lng
      delete row.st_asgeojson
      try
        try
          fims = JSON.parse row.fimsextra
        catch
          fims = row.fimsextra
        if typeof fims is "object"
          for col, data of fims
            row[col] = data
          delete row.fimsextra
      delete row.cartodb_id
      delete row.id
      delete row.the_geom
      delete row.the_geom_webmercator
      dataObj.push row
    downloadCSVFile dataObj, options
  .fail (result, status) ->
    console.error "Couldn't create"
    console.error result, status
  false


sqlQueryBox = ->
  ###
  # Render and bind events for a box to directly execute queries on a
  # project.
  ###
  unless _adp.cartoDataParsed?
    console.error "CartoDB data not available. Are you logged in?"
    return false
  # Function definitions
  queryCarto = (query) ->
    animateLoad()
    console.info "Querying with"
    console.log query
    args = "action=fetch&sql_query=#{post64(query)}"
    _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
    .done (result) ->
      console.log result
      if result.status isnt true
        err = result.human_error ? result.error ? "Unknown error"
        console.error err
        extended = switch err
          when "UNAUTHORIZED_QUERY_TYPE"
            result.query_type
          else
            ex = "(no details for error #{result.error})"
        $("#query-immediate-result").text "#{err}: #{extended}"
        $(".do-sql-query").removeAttr "disabled"
        stopLoad()
        return false
      try
        r = JSON.parse(result.post_response[0])
      catch e
        console.error "Error parsing result"
        $("#query-immediate-result").text "Error parsing result from CartoDB"
        $(".do-sql-query").removeAttr "disabled"
        stopLoad()
        return false
      if r.error?
        console.error "Error in result: #{r.error}"
        $("#query-immediate-result").text r.error
        $(".do-sql-query").removeAttr "disabled"
        stopLoad()
        return false
      console.log "Using responses", result.parsed_responses
      output = ""
      for n, sqlQuery of result.parsed_responses
        nHuman = toInt(n) + 1
        output += "##{nHuman}: "
        try
          json = JSON.stringify sqlQuery.rows
          output += """<code class="language-json">#{json}</code>"""
        catch
          output += "BAD QUERY"
        output += "\n\n"
      $("#query-immediate-result").html output
      try
        Prism.highlightAll(true)
      $(".do-sql-query").removeAttr "disabled"
      stopLoad()
      false
    .error ->
      $("#query-immediate-result").text "Error executing query"
      $(".do-sql-query").removeAttr "disabled"
      stopLoadError()
    false
  formatQuery = (rawQuery, dontReplace = false) ->
    # # Lower-caseify
    # lowQuery = rawQuery.trim().toLowerCase()
    lowQuery = rawQuery.trim()
    # Replace "@@" with TABLENAME
    query = lowQuery.replace /@@/mig, _adp.cartoDataParsed.table
    query = query.replace /!@/mig, "SELECT * FROM #{_adp.cartoDataParsed.table}"
    unless dontReplace
      $("#query-input").val query
    query
  queryResultDialog = ->
    false
  queryResultSummaryHistory = ->
    false
  # If it doesn't exist, inject into the DOM
  unless $("#project-sql-query-box").exists()
    html = """
    <div id="project-sql-query-box" class="row">
      <h2 class="col-xs-12">Raw Project Queries</h2>
      <textarea class="form-control code col-xs-10 col-xs-offset-1" rows="3" id="query-input" placeholder="SQL Query" aria-describedby="query-cheats"></textarea>
      <div class="col-xs-12">
        <label class="text-muted col-xs-2 col-md-1" for="interpreted-query">Real Query:</label>
        <code class="language-sql col-xs-10 col-md-11" id="interpreted-query">
        </code>
      </div>
      <div class="col-xs-12 col-sm-9">
        <span class="text-muted" id="query-cheats">Tips: <ol><li>You're querying PostgreSQL</li><li>Type <kbd>@@</kbd> as a placeholder for the table name</li><li>Type <kbd>!@</kbd> as a placeholder for <code>SELECT * FROM @@</code></li><li>Multiple queries at once is just fine. They're broken at <kbd>);</kbd>, so enclosing your <code>WHERE</code> in parentheses is good enough.</li></ol></span>
      </div>
      <div class="col-xs-12 col-sm-3">
        <button class="btn btn-default do-sql-query pull-right">Execute Query</button>
      </div>
      <h3 class="col-xs-12">Result:</h3>
      <pre class="code col-xs-12" id="query-immediate-result"></pre>
    </div>
    """
    if $("h2.project-identifier").exists()
      $("h2.project-identifier").before html
    else
      $("main").append html
  # Events
  startQuery = ->
    console.info "Executing query ..."
    input = $("#query-input").val()
    query = formatQuery input
    if query.search(_adp.cartoDataParsed.table) is -1
      console.error "Query didn't specify a table!"
      toastStatusMessage "You forgot to include the table identifier in your query."
      return false
    $(".do-sql-query").attr "disabled", "disabled"
    queryCarto query
  $("#query-input").keyup (e) ->
    kc = if e.keyCode then e.keyCode else e.which
    if kc is 13
      try
        e.preventDefault()
      startQuery()
    else
      query = formatQuery $(this).val(), true
      $("code#interpreted-query").text query
      Prism.highlightElement($("code#interpreted-query")[0], true)
    false
  $(".do-sql-query").click ->
    startQuery()
  false



showCitation = ->
  doi = p$("paper-input[label='DOI']").value
  unless $("#citation-pop").exists()
    animateLoad()
    fetchCitation doi, (citation, url) ->
      try
        pdfButton = if isNull url then "" else """
            <paper-button class="click" data-newtab="true" data-href="#{url}">
              <iron-icon icon="icons:open-in-new"></iron-icon>
              Open
            </paper-button>
        """
        html = """
        <paper-dialog id="citation-pop" modal>
          <h2>Citation</h2>
          <paper-dialog-scrollable>
            <div class="pop-contents">
              <paper-textarea label="Citation" id="popped-citation" readonly>
                #{citation}
              </paper-textarea>
            </div>
          </paper-dialog-scrollable>
          <div class="buttons">
            <paper-button id="copy-citation" class="click-copy" data-copy-selector="#popped-citation">
              <iron-icon icon="icons:content-copy"></iron-icon>
              Copy Citation
            </paper-button>
            <paper-button id="copy-doi" class="click-copy" data-copy-selector="#doi-input">
              <iron-icon icon="icons:content-copy"></iron-icon>
              Copy DOI
            </paper-button>
            #{pdfButton}
            <paper-button dialog-dismiss>Close</paper-button>
          </div>
        </paper-dialog>
        """
        $("body").append html
        try
          p$("#popped-citation").value = citation
        catch
          delay 500, ->
            try
              p$("#popped-citation").value = citation
        bindClicks()
        bindCopyEvents()
        safariDialogHelper "#citation-pop"
        stopLoad()
      catch e
        console.error "Couldn't show citation - #{e.message}"
        try
          p$("#citation-pop").open()
        catch
          stopLoadError "Failed to display citation"
  else
    p$("#citation-pop").open()
  false

window.showCitation = showCitation


disableMapViewFilter = ->
  $("google-map#community-map").unbind("google-map-idle")
  _adp.hasBoundMapEvent = false
  $("nav#project-pagination").removeAttr "hidden"
  true


restrictProjectsToMapView = (edges = false) ->
  ###
  # When we're on the top-level project page, we should only see
  # projects in the list that are visible in the map.
  #
  # See:
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/208
  ###
  unless $("google-map#community-map").exists()
    return false
  unless _adp.hasBoundMapEvent
    # When zooming/panning in map, fire this
    _adp.hasBoundMapEvent = true
    # Events:
    # https://www.webcomponents.org/element/GoogleWebComponents/google-map/google-map#events
    # p$("google-map").dragEvents = true
    callback = null
    do updateWidthAttr = (callback) ->
      $("google-map#community-map").removeAttr "width"
      delay 25, ->
        try
          width = $("google-map#community-map").width()
          $("google-map#community-map").attr("width","#{width}px")
        try
          if typeof callback is "function"
            callback()
      false
    $("window").on "resize", ->
      updateWidthAttr ->
        restrictProjectsToMapView.debounce 50, null, null, edges
      false
    $("google-map#community-map").on "google-map-idle", ->
      # Fires after pans and zooms
      # See:
      # https://www.webcomponents.org/element/GoogleWebComponents/google-map/google-map#event-google-map-idle
      updateWidthAttr ->
        restrictProjectsToMapView.debounce 50, null, null, edges
      false
    $("#projects-by-map-view").on "iron-change", ->
      # Fires for all change events
      # https://www.webcomponents.org/element/PolymerElements/paper-toggle-button/paper-toggle-button
      for control in $(".map-view-control:not(.map-view-master)")
        p$(control).disabled = not p$(this).checked
      false
    $(".map-view-control").on "iron-change", ->
      restrictProjectsToMapView.debounce 50, null, null, edges
      false
    console.log "Bound events for RPTMV"
  # Stop the script unless the option is enabled
  unless p$("#projects-by-map-view").checked
    $("#project-list li").removeAttr "hidden"
    $("h2.status-notice.project-list").removeAttr "hidden"
    $("nav#project-pagination").removeAttr "hidden"
    $("button.js-lazy-project").remove()
    $("#map-view-title").remove()
    return false
  # Find the bounds
  $("nav#project-pagination").attr "hidden", "hidden"
  $("h2.status-notice.project-list").attr "hidden", "hidden"
  map = p$("google-map#community-map").map
  mapBounds = map.getBounds()
  corners =
    north: mapBounds.getNorthEast().lat()
    east: mapBounds.getNorthEast().lng()
    south: mapBounds.getSouthWest().lat()
    west: mapBounds.getSouthWest().lng()
  # Fix potential wraparound
  if corners.west > corners.east
    # We only have to check East-West
    # See:
    # https://developers.google.com/maps/documentation/javascript/reference#LatLngBoundsLiteral
    corners.west = -180
    corners.east = 180
  validProjects = new Array()
  if p$("#show-dataless-projects").checked
    # Add those projects to the valid projects list
    for button in $("#project-list button")
      try
        projectId = $(button).attr "data-project"
        unless $(button).attr("data-has-locale").toBool()
          validProjects.push projectId
        else
          console.debug "#{projectId} has a locale, handling normally"
      catch e
        console.warn "Error checking button -- #{e.message}"
        console.warn e.stack
  for poly in $("google-map#community-map").find("google-map-poly")
    projectId = $(poly).attr "data-project"
    if projectId in validProjects or isNull projectId
      continue
    try
      if $("button[data-project='#{projectId}']").exists()
        # Only check present buttons
        if $("button[data-project='#{projectId}']").attr("data-has-locale").toBool() isnt true
          continue
    test =
      north: -90
      south: 90
      east: -180
      west: 180
    for point in $(poly).find "google-map-point"
      if p$(point).latitude > test.north then test.north = p$(point).latitude
      if p$(point).longitude > test.east then test.east = p$(point).longitude
      if p$(point).longitude < test.west then test.west = p$(point).longitude
      if p$(point).latitude < test.south then test.south = p$(point).latitude
    includeProject = false
    if edges is true
      # Check if any edges of the project are visible
      console.log "Checking edges of", projectId
      if corners.south < test.north < corners.north
        includeProject = true
      if corners.south < test.south < corners.north
        includeProject = true
      if corners.west < test.east < corners.east
        includeProject = true
      if corners.west < test.west < corners.east
        includeProject = true
    else
      console.log "Checking containement of", projectId
      if test.south > corners.south and test.north < corners.north
        # At least one edge needs to be visible
        if corners.west < test.east < corners.east or corners.west < test.west < corners.east
          console.log "Project is wholly NS contained"
          includeProject = true
      if test.west > corners.west and test.east < corners.east
        # at least one edge should be visible
        if corners.south < test.north < corners.north or corners.south < test.south < corners.north
          console.log "Project is wholly EW contained"
          includeProject = true
    if includeProject
      validProjects.push projectId
  # We have a list of projects that are OK to show
  $("#project-list li").attr "hidden", "hidden"
  for button in $("#project-list button")
    if $(button).attr("data-project") in validProjects
      $(button).parent("li").removeAttr "hidden"
  # Query all projects, render all that match
  $.get "#{uri.urlString}admin-api.php", "action=list", "json"
  .done (result) ->
    console.log "Got project list", result
    $("button.js-lazy-project").remove()
    publicProjects = Object.toArray result.public_projects
    for project, title of result.projects
      if project in validProjects
        unless $("button[data-project='#{project}']").exists()
          # Add a button
          console.log "Should add visible project '#{title}'", project
          shortTitle = title.slice(0,40)
          if shortTitle isnt title
            tooltipTitle = title
            shortTitle +=  "..."
          else
            tooltipTitle = "Project ##{project.slice(0,8)}..."
          icon = if project in publicProjects then "social:public" else "icons:lock"
          html = """
          <li>
          <button class="js-lazy-project btn btn-primary" data-href="#{uri.urlString}project.php?id=#{project}" data-project="#{project}" data-toggle="tooltip" title="#{tooltipTitle}">
            <iron-icon icon="#{icon}"></iron-icon>
            #{shortTitle}
          </button>
          </li>
          """
          $("#project-list").append html
        else console.log "Not re-adding button for", project
      else console.log "Not adding invalid project", project

  .fail (result, status) ->
    console.warn "Failed to get project list", result, status
  .always ->
    count = $("#project-list button:visible").length
    html = """
    <h2 class="col-xs-12 status-notice hidden-xs project-list project-list-page map-view-title" id="map-view-title">
      Showing #{count} projects in view
    </h2>
    """
    $("#map-view-title").remove()
    $("h2.status-notice.project-list").before html
  console.log "Showing projects", validProjects, "within", corners
  validProjects



paginationBinder = ->
  ###
  # Set up events for the pagination binder
  ###
  dropdownSelector = "paper-dropdown-menu#pagination-selector-dropdown"
  unless $(dropdownSelector).exists()
    console.error "Selector does not exist:", dropdownSelector
    return false
  defaultPaginationNumber = 10
  # Delay setup until bind is ready
  delayPolymerBind dropdownSelector, ->
    if p$(dropdownSelector).disabled
      # do the base selection
      currentCount = uri.o.param("pagination") ? $("#project-list li button:not(.js-lazy-project)").length
      currentCount = toInt currentCount
      selectedItem = false
      selected = 0
      for paginationNumberItem in $("paper-dropdown-menu#pagination-selector-dropdown paper-listbox.dropdown-content paper-item")
        try
          paginationNumber = toInt $(paginationNumberItem).text().trim()
        catch e
          paginationNumber = defaultPaginationNumber
        if paginationNumber is currentCount
          selectedItem = true
          break
        selected++
      unless selectedItem
        selected = 0
      p$("paper-dropdown-menu#pagination-selector-dropdown paper-listbox.dropdown-content").selected = selected
      console.log "Pre-selected item", selected
    # Setup
    p$(dropdownSelector).disabled = false
    $("paper-dropdown-menu#pagination-selector-dropdown paper-listbox.dropdown-content")
    .unbind("iron-select")
    .on "iron-select", ->
      console.log "iron-select fired"
      getPaginationNumber.debounce 50, null, null, this
    $("paper-dropdown-menu#pagination-selector-dropdown paper-listbox.dropdown-content paper-item")
    .unbind("click")
    .click ->
      console.log "paper-item click event fired"
      getPaginationNumber.debounce 50, null, null, $(this).parent("paper-listbox")
    getPaginationNumber = (el) ->
      paginationNumberItem = p$(el).selectedItem
      try
        paginationNumber = toInt $(paginationNumberItem).text().trim()
      catch e
        console.warn "Unable to read pagination number -- #{e.message}"
        paginationNumber = defaultPaginationNumber
      console.log "Dropdown selected paginator", paginationNumber
      page = uri.o.param("page") ? 1
      currentCount = uri.o.param("pagination") ? $("#project-list li button:not(.js-lazy-project)").length
      currentCount = toInt currentCount
      if currentCount < defaultPaginationNumber
        currentCount = defaultPaginationNumber
      if currentCount is paginationNumber
        return false
      projectCountStart = ((page - 1) * currentCount) + 1
      newPage = (projectCountStart // paginationNumber) + 1
      args = "page=#{newPage}&pagination=#{paginationNumber}"
      destinationUrl = "#{uri.urlString}project.php?#{args}"
      console.log destinationUrl, args
      goTo destinationUrl
      false
    false
  false



$ ->
  _adp.projectId = uri.o.param "id"
  checkProjectAuthorization()
  $("#project-list button")
  .unbind()
  .click ->
    project = $(this).attr("data-project")
    goTo "#{uri.urlString}project.php?id=#{project}"
  $("#project-search")
  .unbind()
  .keyup ->
    searchProjects.debounce()
  $("paper-radio-button").click ->
    cue = $(this).attr "data-cue"
    $("#project-search").attr "placeholder", cue
    searchProjects.debounce()
  zcConfig =
    swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
  _adp.zcConfig = zcConfig
  ZeroClipboard.config zcConfig
  _adp.zcClient = new ZeroClipboard $("#copy-ark").get 0
  # client.on "copy", (e) =>
  #   copyLink(this, e)
  $("#copy-ark").click ->
    copyLink _adp.zcClient
  checkFileVersion(false, "js/project.js")
  # Mobile project viewer toggle
  $("#toggle-project-viewport").click ->
    $(".project-list-page").toggleClass "hidden-xs"
    if $(".project-search").hasClass "hidden-xs"
      $(this).text "Show Project Search"
    else
      $(this).text "Show Project List"
  $("#community-map google-map-poly").on "google-map-poly-click", (e) ->
    proj = $(this).attr "data-project"
    dest = "#{uri.urlString}project.php?id=#{proj}"
    goTo dest
    false
  $("#community-map").on "google-map-ready", ->
    try
      fillSorterWithDropdown()
    map = p$("#community-map")
    if _adp.aggregateHulls?
      boundaryPoints = new Array()
      hulls = Object.toArray _adp.aggregateHulls
      for hull in hulls
        points = Object.toArray hull
        for point in points
          badLat = isNull(point.lat) or Math.abs(point.lat) is 90
          badLng = isNull(point.lng) or Math.abs(point.lng) is 180
          if badLat or badLng
            continue
          p = new Point point.lat, point.lng
          boundaryPoints.push p
      console.info "Adjusting zoom from #{map.zoom}"
      zoom = getMapZoom boundaryPoints, "#community-map"
      console.info "Calculated new zoom #{zoom}"
      try
        center = getMapCenter(boundaryPoints)
        map.latitude = center.lat
        map.longitude = center.lng
        console.info "Recentered map"
      map.zoom = zoom
    false
  try
    # Set up easy citation highlight
    $(".self-citation").click ->
      $(this).selectText()
      false
  restrictProjectsToMapView()
  delay 500, ->
    try
      paginationBinder()
    catch e
      console.error "Unable to bind events to pagination - #{e.message}"
      console.warn e.stack
      $(".pagination-selection-container").attr "hidden", "hidden"
