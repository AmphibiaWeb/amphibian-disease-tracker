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
      .error (result, status) ->
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
  .error (result, status) ->
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
    downloadButton = """
    <button class="btn btn-primary click download-file download-data-file" data-href="#{raw.filePath}" data-newtab="true">
      <iron-icon icon="editor:insert-chart"></iron-icon>
      Download Data File
    </button>
    """
  downloadButton ?= ""
  cartoTable = cartoData.table
  try
    zoom = getMapZoom cartoData.bounding_polygon.paths, "#transect-viewport"
    console.info "Got zoom", zoom
  catch
    zoom = ""
  poly = cartoData.bounding_polygon
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
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      lat = geoJson.coordinates[0]
      lng = geoJson.coordinates[1]
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
      # $("#transect-viewport").append marker
      mapHtml += marker
    # Looped over all of them
    googleMap = """
          <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" fit-to-markers map-type="hybrid" disable-default-ui zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6">
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
    bindClicks(".download-file")
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
    stopLoad()
  .error (result, status) ->
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
    projects = Object.toArray result.result
    if projects.length > 0
      for project in projects
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
  .error (result, status) ->
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
    try
      zoom = getMapZoom paths, "#transect-viewport"
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
      <h2 class="col-xs-12">Approximate Mapping Data</h2>
      <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" fit-to-markers map-type="hybrid" disable-default-ui zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map"  apiKey="#{gMapsApiKey}">
            #{mapHtml}
      </google-map>
    </div>
    """
    $("#auth-block").append googleMap
  catch e
    stopLoadError "Couldn't render map"
    console.error "Map rendering error - #{e.message}"
    console.warn e.stack



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
  ZeroClipboard.config zcConfig
  _adp.zcClient = new ZeroClipboard $("#copy-ark").get 0
  # client.on "copy", (e) =>
  #   copyLink(this, e)
  $("#copy-ark").click ->
    copyLink _adp.zcClient
  checkFileVersion(true, "js/project.js")
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
