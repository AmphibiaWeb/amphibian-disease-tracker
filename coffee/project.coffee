###
# Project-specific code
###

_adp.mapRendered = false
_adp.zcClient = null

publicData = null

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
  stopLoad()
  dest = "#{uri.urlString}api.php"
  args = "action=is_human&recaptcha_response=#{response}&project=#{_adp.projectId}"
  $.post dest, args, "json"
  .done (result) ->
    console.info "Checked response"
    console.log result
    authorData = result.author_data
    showEmailField authorData.contact_email
    stopLoad()
  .fail (result, status) ->
    stopLoadError "Sorry, there was a problem getting the contact email"
    false
  false


showEmailField = (email) ->
  html = """
  <div class="row">
    <paper-input readonly class="col-xs-8 col-md-11" label="Contact Email" value="#{email}"></paper-input>
    <paper-fab icon="communication:email" class="click materialblue" id="contact-email-send" data-href="mailto:#{email}" data-toggle="tooltip" title="Send Email"></paper-fab>
  </div>
  """
  $("#email-fill").replaceWith html
  bindClicks("#contact-email-send")
  false


renderMapWithData = (projectData, force = false) ->
  if _adp.mapRendered is true and force isnt true
    console.warn "The map was asked to be rendered again, but it has already been rendered!"
    return false
  cartoData = JSON.parse deEscape projectData.carto_id
  raw = cartoData.raw_data
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
  try
    zoom = getMapZoom cartoData.bounding_polygon.paths, "#transect-viewport"
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

  cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
  console.info "Would ping cartodb with", cartoQuery
  apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
  args = "action=fetch&sql_query=#{apiPostSqlQuery}"
  $.post "api.php", args, "json"
  .done (result) ->
    if _adp.mapRendered is true
      console.warn "Duplicate map render! Skipping thread"
      return false
    console.info "Carto query got result:", result
    unless result.status
      error = result.human_error ? result.error
      unless error?
        error = "Unknown error"
      stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
      return false
    rows = result.parsed_responses[0].rows
    points = new Array()
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      lat = geoJson.coordinates[0]
      lng = geoJson.coordinates[1]
      points.push [lat,lng]
      # Fill the points as markers
      row.diseasedetected = switch row.diseasedetected.toString().toLowerCase()
        when "true"
          "positive"
        when "false"
          "negative"
        else
          row.diseasedetected.toString()
      taxa = "#{row.genus} #{row.specificepithet}"
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
          <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" map-type="hybrid" disable-default-ui zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6">
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
          buttonText: "Download Species List"
          splitValues: " " # Split genus, species, ssp into their own cols
          header: ["Genus","Species","Subspecies"]
        downloadCSVFile _adp.pageSpeciesList, options
    bindClicks(".download-file")
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
      # Create copy event
      ZeroClipboard.config _adp.zcConfig
      zcClientInitial = new ZeroClipboard $(".copy-ark-context").get 0
      ark = $(this).attr "data-ark"
      url = "https://n2t.net/#{ark}"
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
    stopLoad()
  .fail (result, status) ->
    console.error result, status
    stopLoadError "Couldn't render map"
  false




postAuthorizeRender = (projectData, authorizationDetails) ->
  ###
  # Takes in project data, then renders the appropriate bits
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
  bindClicks(".authorized-action")
  cartoData = JSON.parse deEscape projectData.carto_id
  renderMapWithData(projectData) # Stops load
  false


copyLink = (zeroClipObj = _adp.zcClient, zeroClipEvent, html5 = true) ->
  ark = p$(".ark-identifier").value
  if html5
    # http://caniuse.com/#feat=clipboard
    try
      url = "https://n2t.net/#{ark}"
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
  # Handler to search projects
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
    projects = Object.toArray result.result
    if projects.length > 0
      for project in projects
        showList.push project.project_id
        publicState = project.public.toBool()
        icon = if publicState then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
        button = """
        <button class="btn btn-primary search-proj-link" data-href="#{uri.urlString}project.php?id=#{project.project_id}" data-toggle="tooltip" data-placement="right" title="Project ##{project.project_id.slice(0,8)}...">
          #{icon} #{project.project_title}
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
    nw =
      lat: projectData.bounding_box_n
      lng: projectData.bounding_box_w
    ne =
      lat: projectData.bounding_box_n
      lng: projectData.bounding_box_e
    se =
      lat: projectData.bounding_box_s
      lng: projectData.bounding_box_e
    sw =
      lat: projectData.bounding_box_s
      lng: projectData.bounding_box_w
    paths = [
      nw
      ne
      se
      sw
      ]
    coordArr = getPointsFromBoundingBox(projectData)
    try
      zoom = getMapZoom coordArr, "#transect-viewport"
      console.info "Got zoom", zoom
    catch
      zoom = ""
    for point in paths
      unless point in usedPoints
        usedPoints.push point
        mapHtml += """
        <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
        """
    mapHtml += "    </google-map-poly>"
    googleMap = """
    <div class="row" id="public-map">
      <h2 class="col-xs-12">Project Area of Interest</h2>
      <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" map-type="hybrid" disable-default-ui zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map"  apiKey="#{gMapsApiKey}">
            #{mapHtml}
      </google-map>
    </div>
    """
    $("#auth-block").append googleMap
    try
      zoom = getMapZoom paths, "#transect-viewport"
      p$("#transect-viewport").zoom = zoom
    catch error

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
    # Use options instead of true when that changes
    $(selector).get(0).scrollIntoView(true)
  selector



sqlQueryBox = ->
  ###
  # Render and bind events for a box to directly execute queries on a
  # project. 
  ###
  # Function definitions
  queryCarto = ->
    false
  formatQuery = ->
    # Lower-caseify
    # Replace "@@" with TABLENAME
    false
  queryResultDialog = ->
    false
  queryResultSummaryHistory = ->
    false  
  # If it doesn't exist, inject into the DOM
  unless $("#project-sql-query-box").exists()
    html = """
    <div id="project-sql-query-box">
      <textarea class="form-control code" rows="3" id="query-input" placeholder="SQL Query" aria-describedby="query-cheats"></textarea>
      <span class="help-block" id="query-cheats">Tips: <ol><li>Type <kbd>@@</kb> as a placeholder for the table name</li><li>Type <kb>!@</kb> as a placeholder for <code>SELECT * FROM @@</code><li>Your queries will be case insensitive</li><li>Multiple queries at once is just fine</li></ol></span>
        
    </div>
    """
    $("main").append html
  # Events
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
    map = p$("#community-map")
    if _adp.aggregateHulls?
      boundaryPoints = new Array()
      hulls = Object.toArray _adp.aggregateHulls
      for hull in hulls
        points = Object.toArray hull
        for point in points
          p = new Point point.lat, point.lng
          boundaryPoints.push p
      console.info "Adjusting zoom from #{map.zoom}"
      zoom = getMapZoom boundaryPoints, "#community-map"
      console.info "Calculated new zoom #{zoom}"
      map.zoom = zoom
    false
