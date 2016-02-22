###
# The main coffeescript file for administrative stuff
# Bootstraps some of the other loads, sets up parameters, and contains
# code for the main creator/uploader.
#
# Triggered from admin-page.html
#
# Compiles into ./js/admin.js via ./Gruntfile.coffee
#
# For administrative editor code, look at ./coffee/admin-editor.coffee
# For adminstrative viewer code, look at ./coffee/admin-viewer.coffee
#
# @path ./coffee/admin.coffee
# @author Philip Kahn
###


window.adminParams = new Object()
adminParams.domain = "amphibiandisease"
adminParams.apiTarget = "admin-api.php"
adminParams.adminPageUrl = "https://#{adminParams.domain}.org/admin-page.html"
adminParams.loginDir = "admin/"
adminParams.loginApiTarget = "#{adminParams.loginDir}async_login_handler.php"

dataFileParams = new Object()
dataFileParams.hasDataFile = false
dataFileParams.fileName = null
dataFileParams.filePath = null

dataAttrs = new Object()

uploadedData = null;

helperDir = "helpers/"
user =  $.cookie "#{adminParams.domain}_link"
userEmail =  $.cookie "#{adminParams.domain}_user"
userFullname =  $.cookie "#{adminParams.domain}_fullname"

window.loadAdminUi = ->
  ###
  # Main wrapper function. Checks for a valid login state, then
  # fetches/draws the page contents if it's OK. Otherwise, boots the
  # user back to the login page.
  ###
  try
    verifyLoginCredentials (data) ->
      # Post verification
      articleHtml = """
      <h3>
        Welcome, #{$.cookie("#{adminParams.domain}_name")}
        <span id="pib-wrapper-settings" class="pib-wrapper" data-toggle="tooltip" title="User Settings" data-placement="bottom">
          <paper-icon-button icon='icons:settings-applications' class='click' data-href='#{data.login_url}'></paper-icon-button>
        </span>

      </h3>
      <section id='admin-actions-block' class="row center-block text-center">
        <div class='bs-callout bs-callout-info'>
          <p>Please be patient while the administrative interface loads.</p>
        </div>
      </section>
      """
      $("main #main-body").before(articleHtml)
      populateAdminActions()
      bindClicks()
      false
  catch e
    $("main #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>")
  false

populateAdminActions = ->
  adminActions = """
        <paper-button id="new-project" class="admin-action col-md-3 col-sm-4 col-xs-12" raised>
          <iron-icon icon="icons:add"></iron-icon>
            Create New Project
        </paper-button>
        <paper-button id="edit-project" class="admin-action col-md-3 col-sm-4 col-xs-12" raised>
          <iron-icon icon="icons:create"></iron-icon>
            Edit Existing Project
        </paper-button>
        <paper-button id="view-project" class="admin-action col-md-3 col-sm-4 col-xs-12" raised>
          <iron-icon icon="icons:visibility"></iron-icon>
            View All My Projects
        </paper-button>
  """
  $("#admin-actions-block").html adminActions
  $("#show-actions").remove()
  # Remove the previous project progress or any placeholders
  $("main #main-body").empty()
  $("#new-project").click -> loadCreateNewProject()
  $("#edit-project").click -> loadEditor()
  $("#view-project").click -> loadProjectBrowser()
  verifyLoginCredentials (result) ->
    rawSu = toInt result.detail.userdata.su_flag
    if rawSu.toBool()
      console.info "NOTICE: This is an SUPERUSER Admin"
      html = """
      <paper-button id="su-view-projects" class="admin-action su-action col-md-3 col-sm-4 col-xs-12">
        <iron-icon icon="icons:supervisor-account"></iron-icon>
         <iron-icon icon="icons:create"></iron-icon>
        (SU) Administrate All Projects
      </paper-button>
      """
      $("#admin-actions-block").append html
      $("#su-view-projects").click ->
        loadSUProjectBrowser()
    false
  false


verifyLoginCredentials = (callback) ->
  ###
  # Checks the login credentials against the server.
  # This should not be used in place of sending authentication
  # information alongside a restricted action, as a malicious party
  # could force the local JS check to succeed.
  # SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
  ###
  hash = $.cookie("#{adminParams.domain}_auth")
  secret = $.cookie("#{adminParams.domain}_secret")
  link = $.cookie("#{adminParams.domain}_link")
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  $.post(adminParams.loginApiTarget,args,"json")
  .done (result) ->
    if result.status is true
      callback(result)
    else
      goTo(result.login_url)
  .fail (result,status) ->
    # Throw up some warning here
    $("main #main-body").html("<div class='bs-callout-danger bs-callout'><h4>Couldn't verify login</h4><p>There's currently a server problem. Try back again soon.</p></div>")
    console.log(result,status)
    false
  false


startAdminActionHelper = ->
  # Empty out admin actions block
  $("#admin-actions-block").empty()
  $("#pib-wrapper-dashboard").remove()
  showActionsHtml = """
  <span id="pib-wrapper-dashboard" class="pib-wrapper" data-toggle="tooltip" title="Administration Home" data-placement="bottom">
    <paper-icon-button icon="icons:dashboard" class="admin-action" id="show-actions">
    </paper-icon-button>
  </span>
  """
  $("#pib-wrapper-settings").after showActionsHtml
  $("#show-actions").click ->
    $(this).tooltip("hide")
    $(".tooltip").tooltip("hide")
    populateAdminActions()





getInfoTooltip = (message = "No Message Provided") ->
  html = """
      <div class="col-xs-1 adjacent-info">
        <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip" title="#{message}"></span>
      </div>
  """
  html


alertBadProject = (projectId) ->
  # Unified "Bad Project" toast.
  projectId = if projectId? then "project #{projectId}" else "this project"
  stopLoadError "Sorry, #{projectId} doesn't exist"
  false



loadCreateNewProject = ->
  startAdminActionHelper()
  html = """
  <h2 class="new-title col-xs-12">Project Title</h2>
  <paper-input label="Project Title" id="project-title" class="project-field col-md-6 col-xs-12" required auto-validate data-field="project_title"></paper-input>
  <h2 class="new-title col-xs-12">Project Parameters</h2>
  <section class="project-inputs clearfix col-xs-12">
    <div class="row">
      <paper-input label="Primary Pathogen Studied" id="project-disease" class="project-field col-md-6 col-xs-11" required auto-validate data-field="disease"></paper-input>#{getInfoTooltip("Bd, Bsal, or other")}
      <paper-input label="Pathogen Strain" id="project-disease-strain" class="project-field col-md-6 col-xs-11" data-field="disease_strain"></paper-input>#{getInfoTooltip("For example, Hepatitus A, B, C would enter the appropriate letter here")}
      <paper-input label="Project Reference" id="reference-id" class="project-field col-md-6 col-xs-11" data-field="reference_id"></paper-input>
      #{getInfoTooltip("E.g.  a DOI or other reference")}
      <paper-input label="Publication DOI" id="pub-doi" class="project-field col-md-6 col-xs-11" data-field="publication"></paper-input>
      <h2 class="new-title col-xs-12">Lab Parameters</h2>
      <paper-input label="Project PI" id="project-pi" class="project-field col-md-6 col-xs-12"  required auto-validate data-field="pi_lab"></paper-input>
      <paper-input label="Project Contact" id="project-author" class="project-field col-md-6 col-xs-12" value="#{userFullname}"  required auto-validate></paper-input>
      <gold-email-input label="Contact Email" id="author-email" class="project-field col-md-6 col-xs-12" value="#{userEmail}"  required auto-validate></gold-email-input>
      <paper-input label="Diagnostic Lab" id="project-lab" class="project-field col-md-6 col-xs-12"  required auto-validate></paper-input>
      <paper-input label="Affiliation" id="project-affiliation" class="project-field col-md-6 col-xs-11"  required auto-validate></paper-input> #{getInfoTooltip("e.g., UC Berkeley")}
      <h2 class="new-title col-xs-12">Project Notes</h2>
      <iron-autogrow-textarea id="project-notes" class="project-field col-md-6 col-xs-11" rows="3" data-field="sample_notes"></iron-autogrow-textarea>#{getInfoTooltip("Project notes or brief abstract; accepts Markdown ")}
      <marked-element class="project-param col-md-6 col-xs-12" id="note-preview">
        <div class="markdown-html"></div>
      </marked-element>
      <h2 class="new-title col-xs-12">Data Permissions</h2>
      <div class="col-xs-12">
        <span class="toggle-off-label iron-label">Private Dataset</span>
        <paper-toggle-button id="data-encumbrance-toggle" class="red">Public Dataset</paper-toggle-button>
        <p><strong>Smart selector here for registered users</strong>, only show when "private" toggle set</p>
      </div>
      <h2 class="new-title col-xs-12">Project Area of Interest</h2>
      <div class="col-xs-12">
        <p>
          This represents the approximate collection region for your samples.
          <strong>
            Leave blank for a bounding box to be calculated from your sample sites
          </strong>.
        </p>
        <span class="toggle-off-label iron-label">Locality Name</span>
        <paper-toggle-button id="transect-input-toggle">Coordinate List</paper-toggle-button>
      </div>
      <p id="transect-instructions" class="col-xs-12"></p>
      <div id="transect-input" class="col-md-6 col-xs-12">
      </div>
      <div id="carto-rendered-map" class="col-md-6">
        <div id="carto-map-container" class="carto-map map">
        </div>
      </div>
      <div class="col-xs-12">
        <br/>
        <paper-checkbox checked id="has-data">My project already has data</paper-checkbox>
        <br/>
      </div>
    </div>
  </section>
  <section id="uploader-container-section" class="data-section col-xs-12">
    <h2 class="new-title">Uploading your project data</h2>
    <p>Drag and drop as many files as you need below. </p>
    <p>
      To save your project, we need at least one file with structured data containing coordinates.
      Please note that the data <strong>must</strong> have a header row,
      and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>elevation</code>, and <code>coordinateUncertaintyInMeters</code>.
    </p>
    <div class="alert alert-info" role="alert">
      We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href="http://biscicol.org/biocode-fims/templates.jsp" class="newwindow alert-link">biscicol.org <span class="glyphicon glyphicon-new-window"></span></a>. Your data will be validated with the same service.
    </div>
    <div class="alert alert-warning" role="alert">
      <strong>If the data is in Excel</strong>, ensure that it is in a single-sheet workbook. Data across multiple sheets in one workbook may be improperly processed.
    </div>
  </section>
  <section class="project-inputs clearfix data-section col-xs-12">
    <div class="row">
      <h2 class="new-title col-xs-12">Project Data Summary</h2>
      <h3 class="new-title col-xs-12">Calculated Data Parameters</h3>
      <paper-input label="Samples Counted" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="samplecount" readonly type="number" data-field="disease_samples"></paper-input>
      <paper-input label="Positive Samples" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="positive-samples" readonly type="number" data-field="disease_positive"></paper-input>
      <paper-input label="Negative Samples" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="negative-samples" readonly type="number" data-field="disease_negative"></paper-input>
      <paper-input label="No Confidence Samples" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="no_confidence-samples" readonly type="number" data-field="disease_no_confidence"></paper-input>
      <paper-input label="Disease Morbidity" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="morbidity-count" readonly type="number" data-field="disease_morbidity"></paper-input>
      <paper-input label="Disease Mortality" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="mortality-count" readonly type="number" data-field="disease_mortality"></paper-input>
      <h4 class="new-title col-xs-12">Species in dataset</h4>
      <iron-autogrow-textarea id="species-list" class="project-field col-md-6 col-xs-12" rows="3" placeholder="Taxon List" readonly></iron-autogrow-textarea>
      <p class="col-xs-12">Etc</p>
    </div>
  </section>
  <section id="submission-section col-xs-12">
    <div class="pull-right">
      <button id="upload-data" class="btn btn-success click" data-function="finalizeData"><iron-icon icon="icons:lock-open"></iron-icon> <span class="label-with-data">Save Data &amp;</span> Create Private Project</button>
      <button id="reset-data" class="btn btn-danger click" data-function="resetForm">Reset Form</button>
    </div>
  </section>
  """
  $("main #main-body").append html
  ta = p$("#project-notes").textarea
  $(ta).keyup ->
    p$("#note-preview").markdown = $(this).val()
  bootstrapUploader()
  bootstrapTransect()
  $("#has-data").on "iron-change", ->
    unless $(this).get(0).checked
      $(".data-section").attr("hidden","hidden")
      $(".label-with-data").attr("hidden","hidden")
    else
      $(".data-section").removeAttr("hidden")
      $(".label-with-data").removeAttr("hidden")
  $("#data-encumbrance-toggle").on "iron-change", ->
    buttonLabel = if p$("#data-encumbrance-toggle").checked then """<iron-icon icon="social:public"></iron-icon> <span class="label-with-data">Save Data &amp;</span> Create Public Project""" else """<iron-icon icon="icons:lock"></iron-icon> <span class="label-with-data">Save Data &amp;</span> Create Private Project"""
    $("#upload-data").html buttonLabel
  bindClicks()
  false

finalizeData = ->
  ###
  # Make sure everythign is uploaded, validate, and POST to the server
  ###
  startLoad()
  dataCheck = true
  $("[required]").each ->
    # Make sure each is really filled out
    try
      val = $(this).val()
      if isNull val
        $(this).get(0).focus()
        dataCheck = false
        return false
  unless dataCheck
    stopLoadError "Please fill out all required fields"
    return false
  postData = new Object()
  for el in $(".project-field")
    if $(el).hasClass("iron-autogrow-textarea-0")
      input = $($(el).get(0).textarea).val()
    else
      input = $(el).val()
    key = $(el).attr("data-field")
    unless isNull key
      if $(el).attr("type") is "number"
        postData[key] = toInt input
      else
        postData[key] = input
  # postData.boundingBox = geo.boundingBox
  # Species lookup for includes_anura, includes_caudata, and includes_gymnophiona
  # Sampled species
  # sample_collection_start
  # sample_collection_end
  # sampling_months
  # sampling_years
  # sampling_methods_used
  # sample_dispositions_used
  # sample_catalog_numbers
  # sample_field_numbers
  # Have some fun times with uploadedData
  if uploadedData?
    # Loop through it
    dates = new Array()
    for row in Object.toArray uploadedData
      dates.push excelDateToUnixTime row.dateIdentified
  console.info "Got uploaded data", uploadedData
  console.info "Got date ranges", dates
  center = getMapCenter(geo.boundingBox)
  postData.lat = center.lat
  postData.lng = center.lng
  # Bounding box coords
  postData.author = $.cookie("#{adminParams.domain}_link")
  authorData =
    name: p$("#project-author")
    contact_email: p$("#author-email").value
    affiliation: p$("#project-affiliation").value
    lab: p$("#pi_lab").value
    diagnostic_lab: p$("#project-lab").value
    entry_date: Date.now()
  postData.author_data = JSON.stringify authorData
  cartoData =
    table: geo.dataTable
    raw_data: dataFileParams
    bounding_polygon: geo?.canonicalBoundingBox
    bounding_polygon_geojson: geo?.geoJsonBoundingBox
  postData.carto_id = JSON.stringify cartoData
  uniqueId = md5("#{geo.dataTable}#{postData.author}#{Date.now()}")
  postData.project_id = uniqueId
  # Public or private?
  postData.public = p$("#data-encumbrance-toggle").checked
  taxonData = _adp.data.taxa.validated
  postData.sampled_clades = _adp.data.taxa.clades.join ","
  postData.sampled_species = _adp.data.taxa.list.join ","
  for taxonObject in taxonData
    aweb = taxonObject.response.validated_taxon
    console.info "Aweb taxon result:", aweb
    clade = aweb.order.toLowerCase()
    key = "includes_#{clade}"
    postData[key] = true
    # If we have all three, stop checking
    # if postData.includes_anura and postData.includes_caudata and postData.includes_gymnophiona then break
  args = "perform=new&data=#{jsonTo64(postData)}"
  console.info "Data object constructed:", postData
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    if result.status is true
      toastStatusMessage "Data successfully saved to server (Warning: Parsing incomplete! Test Mode!)"
      bsAlert("Project ID #<strong>#{postData.project_id}</strong> created","success")
      stopLoad()
    else
      console.error result.error.error
      console.log result
      stopLoadError result.human_error
    false
  .error (result, status) ->
    stopLoadError "There was a problem saving your data. Please try again"
    false

resetForm = ->
  ###
  # Kill it dead
  ###
  foo()


getTableCoordinates = (table = "tdf0f1bc730325de59d48a5c80df45931_6d6d454828c05e8ceea03c99cc5f547e52fcb5fb") ->
  ###
  #
  #
  # Sample:
  # https://tigerhawkvok.cartodb.com/api/v2/sql?q=SELECT+ST_AsText(the_geom)+FROM+t62b61b0091e633029be9332b5f20bf74_6d6d454828c05e8ceea03c99cc5f547e52fcb5fb&api_key=4837dd9b4df48f6f7ca584bd1c0e205d618bd723
  ###
  false


pointStringToLatLng = (pointString) ->
  ###
  # Take point of form
  #
  # "POINT(37.878086 37.878086)"
  #
  # and return a json obj
  ###
  unless pointString.search "POINT" is 0
    console.warn "Invalid point string"
    return false
  pointSSV = pointString.slice 6, -1
  pointArr = pointSSV.split " "
  pointObj =
    lat: pointArr[0]
    lng: pointArr[1]
  pointObj

pointStringToPoint = (pointString) ->
  ###
  # Take point of form
  #
  # "POINT(37.878086 37.878086)"
  #
  # and return a json obj
  ###
  unless pointString.search "POINT" is 0
    console.warn "Invalid point string"
    return false
  pointSSV = pointString.slice 6, -1
  pointArr = pointSSV.split " "
  point = new Point(pointArr[0], pointArr[1])
  point



bootstrapTransect = ->
  ###
  # Load up the region of interest UI into the DOM, and bind all the
  # events, and set up helper functions.
  ###

  # Helper function: Do the geocoding
  window.geocodeLookupCallback = ->
    ###
    # Reverse geocode locality search
    #
    ###
    startLoad()
    locality = p$("#locality-input").value
    # https://developers.google.com/maps/documentation/javascript/examples/geocoding-simple
    geocoder = new google.maps.Geocoder()
    request =
      address: locality
    geocoder.geocode request, (result, status) ->
      if status is google.maps.GeocoderStatus.OK
        console.info "Google said:", result
        unless $("#locality-lookup-result").exists()
          $("#carto-rendered-map").prepend """
          <div class="alert alert-info alert-dismissable" role="alert" id="locality-lookup-result">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            <strong>Location Found</strong>: <span class="lookup-name"></span>
          </div>
          """
        $("#locality-lookup-result .lookup-name").text result[0].formatted_address
        # Render the carto map
        loc = result[0].geometry.location
        lat = loc.lat()
        lng = loc.lng()
        bounds = result[0].geometry.viewport
        try
          bbEW = bounds.N
          bbNS = bounds.j
          boundingBox =
            nw: [bbEW.j, bbNS.N]
            ne: [bbEW.j, bbNS.j]
            se: [bbEW.N, bbNS.N]
            sw: [bbEW.N, bbNS.j]
        catch e
          console.warn "Danger: There was an error calculating the bounding box (#{e.message})"
          console.warn e.stack
          console.info "Got bounds", bounds
          console.info "Got geometry", result[0].geometry
        console.info "Got bounds: ", [lat, lng], boundingBox
        geo.boundingBox = boundingBox
        doCallback = ->
          geo.renderMapHelper(boundingBox, lat, lng)
        loadJS "https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false
        #stopLoad()
      else
        stopLoadError "Couldn't find location: #{status}"


  geo.renderMapHelper = (overlayBoundingBox = geo.boundingBox, centerLat, centerLng) ->
    ###
    # Helper function to consistently render the map
    #
    # @param Object overlayBoundingBox -> an object with values of
    # [lat,lng] arrays
    # @param float centerLat -> the centering for the latitude
    # @param float centerLng -> the centering for the longitude
    ###
    startLoad()
    unless google?.maps?
      # Load it
      window.recallMapHelper = ->
        geo.renderMapHelper(overlayBoundingBox, centerLat, centerLng)
      loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=recallMapHelper"
      return false
    try
      geo.boundingBox = overlayBoundingBox
      unless typeof centerLat is "number"
        i = 0
        totalLat = 0.0
        for k, coords of overlayBoundingBox
          ++i
          totalLat += coords[0]
          console.info coords, i, totalLat
        centerLat = toFloat(totalLat) / toFloat(i)
      unless typeof centerLng is "number"
        i = 0
        totalLng = 0.0
        for k, coords of overlayBoundingBox
          ++i
          totalLng += coords[1]
        centerLng = toFloat(totalLng) / toFloat(i)
      centerLat = toFloat(centerLat)
      centerLng = toFloat(centerLng)
      options =
        cartodb_logo: false
        https: true # Secure forcing is leading to resource errors
        mobile_layout: true
        gmaps_base_type: "hybrid"
        center_lat: centerLat
        center_lon: centerLng
        zoom: getMapZoom(overlayBoundingBox)
      geo.mapParams = options
      $("#carto-map-container").empty()
      # Ref:
      # http://academy.cartodb.com/courses/cartodbjs-ground-up/createvis-vs-createlayer/#vizjson-nice-to-meet-you
      # http://documentation.cartodb.com/api/v2/viz/23f2abd6-481b-11e4-8fb1-0e4fddd5de28/viz.json
      # geo?.dataTable ?= "tdf0f1bc730325de59d48a5c80df45931_6d6d454828c05e8ceea03c99cc5f547e52fcb5fb"
      # vizJsonElements =
      #   layers: [
      #     options:
      #       sql: "SELECT * FROM #{geo.dataTable}"
      #     ]
      createMap null, "carto-map-container", options, (layer, map) ->
        # Map has been created, play with the data!
        try
          mapOverlayPolygon(overlayBoundingBox)
          stopLoad()
        catch e
          console.error "There was an error drawing your bounding box - #{e.emssage}"
          stopLoadError "There was an error drawing your bounding box - #{e.emssage}"
        false
    catch e
      console.error "There was an error rendering the map - #{e.message}"
      stopLoadError "There was an error rendering the map - #{e.message}"


  geocodeEvent = ->
    ###
    # Event handler for the geocoder
    ###
    # Do reverse geocode
    unless google?.maps?
      # Load the JS
      loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=geocodeLookupCallback"
    else
      geocodeLookupCallback()
    false

  # Actual boostrapping
  do setupTransectUi = ->
    ###
    # Create the toggles and instructions, then place them into the DOM
    ###
    if p$("#transect-input-toggle").checked
      # Coordinates
      instructions = """
      Please input a list of coordinates, in the form <code>lat, lng</code>, with one set on each line. <strong>Please press <kbd>enter</kbd> to insert a new line after your last coordinate</strong>.
      """
      transectInput = """
      <iron-autogrow-textarea id="coord-input" class="" rows="3"></iron-autogrow-textarea>
      """
    else
      instructions = """
      Please enter a name of a locality
      """
      transectInput = """
      <paper-input id="locality-input" label="Locality" class="pull-left"></paper-input> <paper-icon-button class="pull-left" id="do-search-locality" icon="icons:search"></paper-icon-button>
      """
    $("#transect-instructions").html instructions
    $("#transect-input").html transectInput
    ## Conditionals based on the checked state of the toggle
    if p$("#transect-input-toggle").checked
      # Toggle is on = coordinate list
      $(p$("#coord-input").textarea).keyup (e) =>
        kc = if e.keyCode then e.keyCode else e.which
        if kc is 13
          # New line
          val = $(p$("#coord-input").textarea).val()
          lines = val.split("\n").length
          if lines > 3
            # Count the new lines
            # if 3+, send the polygon to be drawn
            coords = new Array()
            coordsRaw = val.split("\n")
            console.info "Raw coordinate info:", coordsRaw
            for coordPair in coordsRaw
              if coordPair.search(",") > 0 and not isNull coordPair
                coordSplit = coordPair.split(",")
                if coordSplit.length is 2
                  tmp = [toFloat(coordSplit[0]), toFloat(coordSplit[1])]
                  coords.push tmp
            if coords.length >= 3
              console.info "Coords:", coords
              # Objectify!
              i = 0
              bbox = new Object()
              for coord in coords
                ++i
                bbox[i] = coord
              doCallback = ->
                geo.renderMapHelper(bbox)
              geo.boundingBox = bbox
              loadJS "https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false
            else
              console.warn "There is one or more invalid coordinates preventing the UI from being shown."
    else # Toggle is off = locality search
      $("#locality-input").keyup (e) ->
        kc = if e.keyCode then e.keyCode else e.which
        if kc is 13
          geocodeEvent()
      $("#do-search-locality").click ->
        geocodeEvent()
    false
  ## Events
  # Toggle switch
  $("#transect-input-toggle").on "iron-change", ->
    setupTransectUi()
  false



mapOverlayPolygon = (polygonObjectParams, regionProperties = null, overlayOptions = new Object(), map = geo.googleMap) ->
  ###
  #
  #
  # @param polygonObjectParams ->
  #  an array of point arrays: http://geojson.org/geojson-spec.html#multipolygon
  ###
  gMapPoly = new Object()
  if typeof polygonObjectParams isnt "object"
    console.warn "mapOverlayPolygon() got an invalid data type to overlay!"
    return false
  if typeof overlayOptions isnt "object"
    overlayOptions = new Object()
  overlayOptions.fillColor ?= "#ff7800"
  gMapPoly.fillColor = overlayOptions.fillColor
  gMapPoly.fillOpacity = 0.35
  if typeof regionProperties isnt "object"
    regionProperties = null
  console.info "Should overlay polygon from bounds here"
  if $("#carto-map-container").exists() and geo.cartoMap?
    # Example:
    # http://leafletjs.com/examples/geojson.html
    mpArr = new Array()
    chPoints = new Array()
    chAltPoints = new Array()
    gMapPaths = new Array()
    gMapPathsAlt = new Array()
    northCoord = -90
    southCoord = 90
    eastCoord = -180
    westCoord = 180
    for k, points of polygonObjectParams
      mpArr.push points
      temp = new Object()
      temp.lat = points[0]
      temp.lng = points[1]
      chAltPoints.push new fPoint(temp.lat, temp.lng)
      gMapPathsAlt.push new Point(temp.lat, temp.lng)
    gMapPaths = sortPoints gMapPathsAlt
    chPoints = sortPoints gMapPathsAlt, false
    chSortedPoints = chAltPoints
    chSortedPoints.sort sortPointY
    chSortedPoints.sort sortPointX
    coordinateArray = new Array()
    coordinateArray.push mpArr
    try
      cpHull = getConvexHullPoints chSortedPoints
    catch e
      console.error "Convex hull points CHP failed! - #{e.message}"
      console.warn e.stack
      console.info chSortedPoints
    console.info "Got hulls", cpHull
    console.info "Sources", chPoints, chAltPoints, chSortedPoints
    gMapPoly.paths = cpHull # gMapPaths
    geoMultiPoly =
      type: "Polygon"
      coordinates: cpHull # coordinateArray
    geoJSON =
      type: "Feature"
      properties: regionProperties
      geometry: geoMultiPoly
    console.info "Rendering GeoJSON MultiPolygon", geoMultiPoly
    geo.geoJsonBoundingBox = geoJSON
    geo.overlayOptions = overlayOptions
    console.info "Rendering Google Maps polygon", gMapPoly
    geo.canonicalBoundingBox = gMapPoly
    # See
    # https://developers.google.com/maps/documentation/javascript/examples/polygon-simple
    gPolygon = new google.maps.Polygon(gMapPoly)
    if geo.googlePolygon?
      # Set the map to null to remove it
      # https://developers.google.com/maps/documentation/javascript/reference#Polygon
      geo.googlePolygon.setMap(null) #setVisible(false)
    geo.googlePolygon = gPolygon
    gPolygon.setMap map
    # Try to get data for this
    unless isNull dataAttrs.coords or isNull geo.dataTable
      getCanonicalDataCoords(geo.dataTable)
  else
    # No map yet ...
    console.warn "There's no map yet! Can't overlay polygon"
  false


mapAddPoints = (pointArray, pointInfoArray, map = geo.googleMap) ->
  ###
  #
  #
  # @param array pointArray -> an array of geo.Point instances
  # @param array pointInfoArray -> An array of objects of type
  #   {"title":"Point Title","html":"Point infoWindow HTML"}
  #   If this is empty, no such popup will be added.
  # @param google.maps.Map map -> A google Map object
  ###
  # Check the list of points
  for point in pointArray
    unless point instanceof geo.Point
      console.warn "Invalid datatype in array -- array must be constructed of Point objects"
      return false
  markers = new Object()
  infoWindows = new Array()
  # Add points to geo.googleMap
  # https://developers.google.com/maps/documentation/javascript/examples/marker-simple
  i = 0
  for point in pointArray
    title = if pointInfoArray? then pointInfoArray[i]?.title else ""
    pointLatLng = point.getObj()
    gmLatLng = new google.maps.LatLng(pointLatLng.lat, pointLatLng.lng)
    markerConstructor =
      position: gmLatLng
      map: map
      title: title
    marker = new google.maps.Marker markerConstructor
    markers[i] =
      marker: marker
    # If we have a non-empty title, we should fill out information for
    # the point, too.
    unless isNull title
      iwConstructor =
        content: pointInfoArray[i].html
      infoWindow = new google.maps.InfoWindow iwConstructor
      markers[i].infoWindow = infoWindow
      infoWindows.push infoWindow
      # markers[i].addListener "click", ->
      #   infoWindows[i].open map, markers[i]
    else
      console.info "Key #{i} has no title in pointInfoArray", pointInfoArray[i]
    ++i
  # Bind all those info windows
  unless isNull infoWindows
    dataAttrs.coordInfoWindows = infoWindows
    for k, markerContainer of markers
      marker = markerContainer.marker
      marker.unbind("click")
      marker.self = marker
      marker.iw = markerContainer.infoWindow
      marker.iwk = k
      marker.addListener "click", ->
        try
          @iw.open map, this #geo.markers[@iwk]
          console.info "Opening infoWindow ##{@iwk}"
        catch e
          console.error "Invalid infowindow @ #{@iwk}!", infoWindows, markerContainer, @iw
    geo.markers = markers
  markers


getCanonicalDataCoords = (table, callback = mapAddPoints) ->
  ###
  # Fetch data coordinate points
  ###
  if isNull table
    console.error "A table must be specified!"
    return false
  if typeof callback isnt "function"
    console.error "This function needs a callback function as the second argument"
    return false
  # Validate the user
  verifyLoginCredentials (data) ->
    # Try to get the data straight from the CartoDB database
    sqlQuery = "SELECT ST_AsText(the_geom), genus, specificEpithet, infraspecificEpithet, dateIdentified, sampleMethod, diseaseDetected, diseaseTested, catalogNumber FROM #{table}"
    apiPostSqlQuery = encodeURIComponent encode64 sqlQuery
    args = "action=fetch&sql_query=#{apiPostSqlQuery}"
    $.post "api.php", args, "json"
    .done (result) ->
      cartoResponse = result.parsed_responses[0]
      coords = new Array()
      info = new Array()
      for i, row of cartoResponse.rows
        textPoint = row.st_astext
        if isNull row.infraspecificepithet
          row.infraspecificepithet = ""
        point = pointStringToPoint textPoint
        data =
          title: "#{row.catalognumber}: #{row.genus} #{row.specificepithet} #{row.infraspecificepithet}"
          html: """
          <p>
            <span class="sciname italic">#{row.genus} #{row.specificepithet} #{row.infraspecificepithet}</span> collected on #{row.dateidentified}
          </p>
          <p>
            <strong>Status:</strong>
            Sampled by #{row.samplemethod}, disease status #{row.diseasedetected} for #{row.diseasetested}
          </p>
          """
        coords.push point
        info.push data
      # Push the coordinates and the formatted infowindows
      dataAttrs.coords = coords
      dataAttrs.markerInfo = info
      callback coords, info
    .error (result, status) ->
      # On error, return direct from file upload
      if dataAttrs?.coords?
        callback dataAttrs.coords, dataAttrs.markerInfo
      else
        stopLoadError "Couldn't get bounding coordinates from data"
        console.error "No valid coordinates accessible!"
  false



bootstrapUploader = (uploadFormId = "file-uploader", bsColWidth = "col-md-4") ->
  ###
  # Bootstrap the file uploader into existence
  ###
  # Check for the existence of the uploader form; if it's not there,
  # create it
  selector = "##{uploadFormId}"
  unless $(selector).exists()
    # Create it
    html = """
    <form id="#{uploadFormId}-form" class="#{bsColWidth} clearfix">
      <p class="visible-xs-block">Tap the button to upload a file</p>
      <fieldset class="hidden-xs">
        <legend>Upload Files</legend>
        <div id="#{uploadFormId}" class="media-uploader outline media-upload-target">
        </div>
      </fieldset>
    </form>
    """
    $("main #uploader-container-section").append html
    console.info "Appended upload form"
    $(selector).submit (e) ->
      e.preventDefault()
      e.stopPropagation()
      return false
  # Validate the user before guessing
  verifyLoginCredentials ->
    window.dropperParams ?= new Object()
    window.dropperParams.dropTargetSelector = selector
    window.dropperParams.uploadPath = "uploaded/#{user}/"
    # Need to make this re-initialize ...
    needsInit = window.dropperParams.hasInitialized is true
    loadJS "helpers/js-dragdrop/client-upload.min.js", ->
      # Successfully loaded the file
      console.info "Loaded drag drop helper"
      if needsInit
        console.info "Reinitialized dropper"
        try
          window.dropperParams.initialize()
        catch
          console.warn "Couldn't reinitialize dropper!"
      window.dropperParams.postUploadHandler = (file, result) ->
        ###
        # The callback function for handleDragDropImage
        #
        # The "file" object contains information about the uploaded file,
        # such as name, height, width, size, type, and more. Check the
        # console logs in the demo for a full output.
        #
        # The result object contains the results of the upload. The "status"
        # key is true or false depending on the status of the upload, and
        # the other most useful keys will be "full_path" and "thumb_path".
        #
        # When invoked, it calls the "self" helper methods to actually do
        # the file sending.
        ###
        # Clear out the file uploader
        window.dropperParams.dropzone.removeAllFiles()

        if typeof result isnt "object"
          console.error "Dropzone returned an error - #{result}"
          toastStatusMessage "There was a problem with the server handling your image. Please try again."
          return false
        unless result.status is true
          # Yikes! Didn't work
          result.human_error ?= "There was a problem uploading your image."
          toastStatusMessage "#{result.human_error}"
          console.error("Error uploading!",result)
          return false
        try
          console.info "Server returned the following result:", result
          console.info "The script returned the following file information:", file
          pathPrefix = "helpers/js-dragdrop/uploaded/#{user}/"
          # Replace full_path and thumb_path with "wrote"
          result.full_path = result.wrote_file
          result.thumb_path = result.wrote_thumb
          mediaType = result.mime_provided.split("/")[0]
          longType = result.mime_provided.split("/")[1]
          linkPath = if file.size < 5*1024*1024 or mediaType isnt "image" then "#{pathPrefix}#{result.full_path}" else "#{pathPrefix}#{result.thumb_path}"
          previewHtml = switch mediaType
            when "image"
              """
              <div class="uploaded-media center-block" data-system-file="#{result.full_path}">
                <img src="#{linkPath}" alt='Uploaded Image' class="img-circle thumb-img img-responsive"/>
                  <p class="text-muted">
                    #{file.name} -> #{result.full_path}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Image
                </a>)
                  </p>
              </div>
              """
            when "audio" then """
            <div class="uploaded-media center-block" data-system-file="#{result.full_path}">
              <audio src="#{linkPath}" controls preload="auto">
                <span class="glyphicon glyphicon-music"></span>
                <p>
                  Your browser doesn't support the HTML5 <code>audio</code> element.
                  Please download the file below.
                </p>
              </audio>
              <p class="text-muted">
                #{file.name} -> #{result.full_path}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Media
                </a>)
              </p>
            </div>
            """
            when "video" then """
            <div class="uploaded-media center-block" data-system-file="#{result.full_path}">
              <video src="#{linkPath}" controls preload="auto">
                <img src="#{pathPrefix}#{result.thumb_path}" alt="Video Thumbnail" class="img-responsive" />
                <p>
                  Your browser doesn't support the HTML5 <code>video</code> element.
                  Please download the file below.
                </p>
              </video>
              <p class="text-muted">
                #{file.name} -> #{result.full_path}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Media
                </a>)
              </p>
            </div>
            """
            else
              """
              <div class="uploaded-media center-block" data-system-file="#{result.full_path}">
                <span class="glyphicon glyphicon-file"></span>
                <p class="text-muted">#{file.name} -> #{result.full_path}</p>
              </div>
              """
          # Append the preview HTML
          $(window.dropperParams.dropTargetSelector).before previewHtml
          # Finally, execute handlers for different file types
          switch mediaType
            when "application"
              # Another switch!
              console.info "Checking #{longType} in application"
              switch longType
                # Fuck you MS, and your terrible MIME types
                when "vnd.openxmlformats-officedocument.spreadsheetml.sheet", "vnd.ms-excel"
                  excelHandler(linkPath)
                when "zip", "x-zip-compressed"
                  # Some servers won't read it as the crazy MS mime type
                  # But as a zip, instead. So, check the extension.
                  #
                  if file.type is "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or linkPath.split(".").pop() is "xlsx"
                    excelHandler(linkPath)
                  else
                    zipHandler(linkPath)
                when "x-7z-compressed"
                  _7zHandler(linkPath)
            when "text" then csvHandler()
            when "image" then imageHandler()
        catch e
          toastStatusMessage "Your file uploaded successfully, but there was a problem in the post-processing."
    false


singleDataFileHelper = (newFile, callback) ->
  if typeof callback isnt "function"
    console.error "Second argument must be a function"
    return false
  if dataFileParams.hasDataFile is true
    # Show a popup that conditionally calls callback
    if $("#single-data-file-modal").exists()
      $("#single-data-file-modal").remove()
    html = """
    <paper-dialog modal id="single-data-file-modal">
      <h2>You can only have one primary data file</h2>
      <div>
        Continuing will remove your previous one
      </div>
      <div class="buttons">
        <paper-button id="cancel-parse">Cancel Upload</paper-button>
        <paper-button id="overwrite">Replace Previous</paper-button>
      </div>
    </paper-dialog>
    """
    $("body").append html
    $("#cancel-parse").click ->
      # We're done here. Remove the new file.
      removeDataFile newFile, false
      p$("#single-data-file-modal").close()
      false
    $("#overwrite").click ->
      # Remove the old file
      removeDataFile()
      p$("#single-data-file-modal").close()
      # Now, continue with the callback
      callback()
    safariDialogHelper("#single-data-file-modal")
  else
    callback()


excelHandler = (path, hasHeaders = true) ->
  startLoad()
  toastStatusMessage "Processing ..."
  helperApi = "#{helperDir}excelHelper.php"
  correctedPath = path
  if path.search helperDir isnt -1
    correctedPath = path.slice helperDir.length
  console.info "Pinging for #{correctedPath}"
  args = "action=parse&path=#{correctedPath}"
  $.get helperApi, args, "json"
  .done (result) ->
    console.info "Got result", result
    singleDataFileHelper path, ->
      dataFileParams.hasDataFile = true
      dataFileParams.fileName = path
      dataFileParams.filePath = correctedPath
      rows = Object.size(result.data)
      randomData = ""
      if rows > 0
        randomRow = randomInt(1,rows) - 1
        randomData = "\n\nHere's a random row: " + JSON.stringify(result.data[randomRow])
      html = """
      <pre>
      From upload, fetched #{rows} rows.#{randomData}
      </pre>
      """
      # $("#main-body").append html
      uploadedData = result.data
      newGeoDataHandler(result.data)
      stopLoad()
  .fail (result, error) ->
    console.error "Couldn't POST"
    console.warn result, error
    stopLoadError()
  false

csvHandler = (path) ->
  dataFileParams.hasDataFile = true
  dataFileParams.fileName = path
  dataFileParams.filePath = correctedPath
  geoDataHandler()
  false

imageHandler = (path) ->
  foo()
  false

zipHandler = (path) ->
  foo()
  false

_7zHandler = (path) ->
  foo()
  false


removeDataFile = (removeFile = dataFileParams.fileName, unsetHDF = true) ->
  removeFile = removeFile.split("/").pop()
  if unsetHDF
    dataFileParams.hasDataFile = false
  $(".uploaded-media[data-system-file='#{removeFile}']").remove()
  # Now, actually delete the file remotely
  serverPath = "#{helperDir}/js-dragdrop/uploaded/#{user}/#{removeFile}"
  # Server will validate the user, and only a user can remove their
  # own files
  args = "action=removefile&path=#{encode64 removeFile}&user=#{user}"
  # TODO FINISH THIS
  false

newGeoDataHandler = (dataObject = new Object()) ->
  ###
  # Data expected in form
  #
  # Obj {ROW_INDEX: {"col1":"data", "col2":"data"}}
  #
  # FIMS data format:
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
  #
  # Requires columns "decimalLatitude", "decimalLongitude", "coordinateUncertaintyInMeters", "alt"
  ###
  try
    try
      sampleRow = dataObject[0]
    catch
      toastStatusMessage "Your data file was malformed, and could not be parsed. Please try again."
      removeDataFile()
      return false

    unless sampleRow.decimalLatitude? and sampleRow.decimalLongitude? and sampleRow.coordinateUncertaintyInMeters? and sampleRow.alt?
      toastStatusMessage "Data are missing required geo columns. Please reformat and try again."
      console.info "Missing: ", sampleRow.decimalLatitude?, sampleRow.decimalLongitude?, sampleRow.coordinateUncertaintyInMeters?, sampleRow.alt?
      # Remove the uploaded file
      removeDataFile()
      return false
    unless isNumber(sampleRow.decimalLatitude) and isNumber(sampleRow.decimalLongitude) and isNumber(sampleRow.coordinateUncertaintyInMeters) and isNumber(sampleRow.alt)
      toastStatusMessage "Data has invalid entries for geo columns. Please be sure they're all numeric and try again."
      removeDataFile()
      return false
    rows = Object.size(dataObject)
    p$("#samplecount").value = rows
    if isNull $("#project-disease").val()
      p$("#project-disease").value = sampleRow.diseaseTested
    # Clean up the data for CartoDB
    # FIMS it up
    parsedData = new Object()
    dataAttrs.coords = new Array()
    dataAttrs.coordsFull = new Array()
    dataAttrs.fimsData = new Array()
    fimsExtra = new Object()
    # Iterate over the data, coerce some data types
    toastStatusMessage "Please wait, parsing your data"
    for n, row of dataObject
      tRow = new Object()
      for column, value of row
        switch column
          # Change FIMS to internal structure:
          # http://www.biscicol.org/biocode-fims/templates.jsp
          # Expects:
          #  id: "int"
          #  collectionID: "varchar"
          #  catalogNumber: "varchar"
          #  fieldNumber: "varchar"
          #  diseaseTested: "varchar"
          #  diseaseStrain: "varchar"
          #  sampleMethod: "varchar"
          #  sampleDisposition: "varchar"
          #  diseaseDetected: "varchar"
          #  fatal: "boolean"
          #  cladeSampled: "varchar"
          #  genus: "varchar"
          #  specificEpithet: "varchar"
          #  infraspecificEpithet: "varchar"
          #  lifeStage: "varchar"
          #  dateIdentified: "date" # Should be ISO8601; coerce it!
          #  decimalLatitude: "decimal"
          #  decimalLongitude: "decimal"
          #  alt: "decimal"
          #  coordinateUncertaintyInMeters: "decimal"
          #  Collector: "varchar"
          #  the_geom: "varchar"
          #
          when "ContactName", "basisOfRecord", "occurrenceID", "institutionCode", "collectionCode", "labNumber", "originalsource", "datum", "georeferenceSource", "depth", "Collector2", "Collector3", "verbatimLocality", "Habitat", "Test_Method", "eventRemarks", "quantityDetected", "dilutionFactor", "cycleTimeFirstDetection"
            fimsExtra[column] = value
          when "specimenDisposition"
            column = "sampleDisposition"
          when "elevation"
            column = "alt"
          # Data handling
          when "dateIdentified"
            # Coerce to ISO8601
            t = excelDateToUnixTime(value)
            d = new Date(t)
            date = d.getUTCDate()
            if date < 10
              date = "0#{date}"
            month = d.getUTCMonth() + 1
            if month < 10
              month = "0#{month}"
            cleanValue = "#{d.getUTCFullYear()}-#{month}-#{date}"
          when "fatal"
            cleanValue = value.toBool()
          when "decimalLatitude", "decimalLongitude", "alt", "coordinateUncertaintyInMeters"
            # Sanity -- do the coordinates exist on earth?
            if not isNumber value
              stopLoadError "Detected an invalid number for #{column} at row #{n} ('#{value}')"
              return false
            if column is "decimalLatitude" and -90 > value > 90
              stopLoadError "Detected an invalid latitude #{value} at row #{n}"
              return false
            if column is "decimalLongitude" and -180 > value > 180
              stopLoadError "Detected an invalid longitude #{value} at row #{n}"
              return false
            if column is "coordinateUncertaintyInMeters" and value <= 0
              stopLoadError "Coordinate uncertainty must be >= 0 at row #{n}"
              return false
            cleanValue = toFloat value
          when "diseaseDetected"
            if isBool value
              cleanValue = value.toBool()
            else
              cleanValue = "NO_CONFIDENCE"
          else
            try
              cleanValue = value.trim()
            catch
              # Non-string
              cleanValue = value
        tRow[column] = cleanValue
      coords =
        lat: tRow.decimalLatitude
        lng: tRow.decimalLongitude
        alt: tRow.alt
        uncertainty: tRow.coordinateUncertaintyMeters
      coordsPoint = new Point(coords.lat, coords.lng)
      dataAttrs.coords.push coordsPoint
      dataAttrs.coordsFull.push coords
      dataAttrs.fimsData.push fimsExtra
      try
        tRow.fimsExtra = JSON.stringify fimsExtra
      catch
        console.warn "Couldn't store FIMS extra data", fimsExtra
      parsedData[n] = tRow
      if n %% 500 is 0 and n > 0
        toastStatusMessage "Processed #{n} rows ..."
    try
      # http://marianoguerra.github.io/json.human.js/
      prettyHtml = JsonHuman.format parsedData
      # $("#main-body").append prettyHtml
    catch e
      console.warn "Couldn't pretty set!"
      console.warn e.stack
      console.info parsedData
    # Create a project identifier from the user hash and project title
    projectIdentifier = "t" + md5(p$("#project-title").value + $.cookie "#{uri.domain}_link")
    # Define the transect ring
    # If it's not already picked, let's get it from the dataset
    getCoordsFromData = ->
      ###
      # We need to do some smart trimming in here for total inclusion
      # points ...
      ###
      i = 0
      j = new Object()
      sorted = sortPoints(dataAttrs.coords)
      textEntry = ""
      for coordsObj in sorted
        j[i] = [coordsObj.lat, coordsObj.lng]
        textEntry += """
        #{coordsObj.lat},#{coordsObj.lng}

        """
        ++i
      try
        p$("#transect-input-toggle").checked = true
        textEntry += "\n"
        $(p$("#coord-input").textarea).val(textEntry)
      j
    geo.boundingBox ?= getCoordsFromData()
    samplesMeta =
      mortality: 0
      morbidity: 0
      positive: 0
      negative: 0
      no_confidence: 0
    for k, data of parsedData
      switch data.diseaseDetected
        when true
          samplesMeta.morbidity++
          samplesMeta.positive++
        when false
          samplesMeta.negative++
        when "NO_CONFIDENCE"
          samplesMeta.no_confidence++
      if data.fatal
        samplesMeta.mortality++
    p$("#positive-samples").value = samplesMeta.positive
    p$("#negative-samples").value = samplesMeta.negative
    p$("#no_confidence-samples").value = samplesMeta.no_confidence
    p$("#morbidity-count").value = samplesMeta.morbidity
    p$("#mortality-count").value = samplesMeta.mortality
    totalData =
      transectRing: geo.boundingBox
      data: parsedData
      samples: samplesMeta
    validateData totalData, (validatedData) ->
      # Save the upload
      taxonListString = ""
      taxonList = new Array()
      cladeList = new Array()
      i = 0
      for taxon in validatedData.validated_taxa
        taxonString = "#{taxon.genus} #{taxon.species}"
        unless isNull taxon.subspecies
          taxonString += " #{taxon.subspecies}"
        if i > 0
          taxonListString += "\n"
        taxonListString += "#{taxonString}"
        taxonList.push taxonString
        try
          unless taxon.response.validated_taxon.family in cladeList
            cladeList.push taxon.response.validated_taxon.family
        catch e
          console.warn "Couldn't get the family! #{e.message}", taxon.response
          console.warn e.stack
        ++i
      p$("#species-list").bindValue = taxonListString
      dataAttrs.dataObj = validatedData
      unless _adp?.data?
        unless _adp?
          window._adp = new Object()
        window._adp.data = new Object()
      _adp.data.dataObj = validatedData
      _adp.data.taxa = new Object()
      _adp.data.taxa.list = taxonList
      _adp.data.taxa.clades = cladeList
      _adp.data.taxa.validated = validatedData.validated_taxa
      geo.requestCartoUpload validatedData, projectIdentifier, "create", (table) ->
        mapOverlayPolygon validatedData.transectRing
        # getCanonicalDataCoords(table)
  catch e
    console.error e.message
    toastStatusMessage "There was a problem parsing your data"
  false



excelDateToUnixTime = (excelTime) ->
  try
    if 0 < excelTime < 10e5
      ###
      # Excel is INSANE, and marks time as DAYS since 1900-01-01
      # on Windows, and 1904-01-01 on OSX. Because reasons.
      #
      # Therefore, 2015-11-07 is "42315"
      #
      # The bounds of this check represent true Unix dates
      # of
      # Wed Dec 31 1969 16:16:40 GMT-0800 (Pacific Standard Time)
      # to
      # Wed Dec 31 1969 16:00:00 GMT-0800 (Pacific Standard Time)
      #
      # I hope you weren't collecting between 4 & 4:17 PM
      # New Years Eve in 1969.
      #
      #
      # This check will correct Excel dates until
      # Sat Nov 25 4637 16:00:00 GMT-0800 (Pacific Standard Time)
      #
      # TODO: Fix before Thanksgiving 4637. Devs, you have
      # 2,622 years. Don't say I didn't warn you.
      ###
      # See http://stackoverflow.com/a/6154953/1877527
      daysFrom1900to1970 = 25569 # Windows + Mac Excel 2011+
      daysFrom1904to1970 = 24107 # Mac Excel 2007 and before
      secondsPerDay = 86400
      t = ((excelTime - daysFrom1900to1970) * secondsPerDay) * 1000 # Unix Milliseconds
    else
      # Standard date parsing
      t = Date.parse(excelTime)
  catch
    t = Date.now()
  t



$ ->
  if $("#next").exists()
    $("#next")
    .unbind()
    .click ->
      openTab(adminParams.adminPageUrl)
  loadJS "bower_components/bootstrap/dist/js/bootstrap.min.js", ->
    $("body").tooltip
      selector: "[data-toggle='tooltip']"
  # The rest of the onload for the admin has been moved to the core.coffee file.
  checkFileVersion false, "js/admin.min.js"
