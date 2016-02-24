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
  try
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
    # Mint it!
    author = $.cookie("#{adminParams.domain}_link")
    if isNull(_adp.projectId)
      _adp.projectId = md5("#{geo.dataTable}#{author}#{Date.now()}")
    title = p$("#project-title").value
    mintBcid _adp.projectId, title, (result) ->
      try
        unless result.status
          console.error result.error
          stopLoadError result.human_error
          return false
        dataAttrs.ark = result.ark
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
          months = new Array()
          years = new Array()
          methods = new Array()
          catalogNumbers = new Array()
          fieldNumbers = new Array()
          dispositions = new Array()
          for row in Object.toArray uploadedData
            uTime = excelDateToUnixTime row.dateIdentified
            dates.push uTime
            uDate = new Date(uTime)
            mString = dateMonthToString uDate.getUTCMonth()
            unless mString in months
              months.push mString
            unless uDate.getFullYear() in years
              years.push uDate.getFullYear()
            if row.catalogNumber? # Not mandatory
              catalogNumbers.push row.catalogNumber
            fieldNumbers.push row.fieldNumber
        console.info "Got uploaded data", uploadedData
        console.info "Got date ranges", dates
        postData.sampled_collection_start = dates.min()
        postData.sampled_collection_end = dates.max()
        postData.sample_catalog_numbers = catalogNumbers.join(",")
        postData.sample_field_numbers = fieldNumbers.join(",")
        postData.sampling_months = months
        postData.sampling_years = years
        center = getMapCenter(geo.boundingBox)
        postData.lat = center.lat
        postData.lng = center.lng
        # Bounding box coords
        postData.author = $.cookie("#{adminParams.domain}_link")
        authorData =
          name: p$("#project-author").value
          contact_email: p$("#author-email").value
          affiliation: p$("#project-affiliation").value
          lab: p$("#project-pi").value
          diagnostic_lab: p$("#project-lab").value
          entry_date: Date.now()
        postData.author_data = JSON.stringify authorData
        cartoData =
          table: geo.dataTable
          raw_data: dataFileParams
          bounding_polygon: geo?.canonicalBoundingBox
          bounding_polygon_geojson: geo?.geoJsonBoundingBox
        postData.carto_id = JSON.stringify cartoData
        postData.project_id = _adp.projectId
        postData.project_obj_id = dataAttrs.ark
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
          if postData.includes_anura? isnt false and postData.includes_caudata? isnt false and postData.includes_gymnophiona? isnt false then break
        args = "perform=new&data=#{jsonTo64(postData)}"
        console.info "Data object constructed:", postData
        $.post adminParams.apiTarget, args, "json"
        .done (result) ->
          if result.status is true
            toastStatusMessage "Data successfully saved to server"
            bsAlert("Project ID #<strong>#{postData.project_id}</strong> created","success")
            stopLoad()
            delay 1000, ->
              loadEditor _adp.projectId
          else
            console.error result.error.error
            console.log result
            stopLoadError result.human_error
          false
        .error (result, status) ->
          stopLoadError "There was a problem saving your data. Please try again"
          false
      catch e
        # Mint try
        stopLoadError "There was a problem with the application. Please try again later. (E-003)"
        console.error "JavaScript error in saving data (E-003)! FinalizeData said: #{e.message}"
        console.warn e.stack
  catch e
    # Function try
    stopLoadError "There was a problem with the application. Please try again later. (E-004)"
    console.error "JavaScript error in saving data (E-004)! FinalizeData said: #{e.message}"
    console.warn e.stack

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
          $("#validator-progress-container").remove()
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
  $("#validator-progress-container").remove()
  renderValidateProgress()
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
      $("#upload-data").attr "disabled", "disabled"
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
  $("#validator-progress-container paper-progress").removeAttr "indeterminate"
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

    unless sampleRow.decimalLatitude? and sampleRow.decimalLongitude? and sampleRow.coordinateUncertaintyInMeters?
      toastStatusMessage "Data are missing required geo columns. Please reformat and try again."
      console.info "Missing: ", sampleRow.decimalLatitude?, sampleRow.decimalLongitude?, sampleRow.coordinateUncertaintyInMeters?
      # Remove the uploaded file
      removeDataFile()
      return false
    unless isNumber(sampleRow.decimalLatitude) and isNumber(sampleRow.decimalLongitude) and isNumber(sampleRow.coordinateUncertaintyInMeters)
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
    $("#data-parsing").removeAttr "indeterminate"
    p$("#data-parsing").max = rows
    for n, row of dataObject
      tRow = new Object()
      for column, value of row
        column = column.trim()
        skipCol = false
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
            skipCol = true
          when "specimenDisposition"
            column = "sampleDisposition"
          when "sampleType"
            column = "sampleMethod"
          when "elevation"
            column = "alt"
          # Data handling
          when "dateCollected", "dateIdentified"
            column = "dateIdentified"
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
        unless skipCol
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
      p$("#data-parsing").value = n + 1

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
    if isNull _adp.projectId
      author = $.cookie("#{adminParams.domain}_link")
      _adp.projectId = md5("#{projectIdentifier}#{author}#{Date.now()}")
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
        if taxon.response.original_taxon?
          # Append a notice
          console.info "Taxon obj", taxon
          originalTaxon = "#{taxon.response.original_taxon.slice(0,1).toUpperCase()}#{taxon.response.original_taxon.slice(1)}"
          noticeHtml = """
          <div class="alert alert-info alert-dismissable amended-taxon-notice col-md-6 col-xs-12 project-field" role="alert">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              Your entry '<em>#{originalTaxon}</em>' was a synonym in the AmphibiaWeb database. It was automatically converted to '<em>#{taxonString}</em>' below. <a href="#{taxon.response.validated_taxon.uri_or_guid}" target="_blank">See the AmphibiaWeb entry <span class="glyphicon glyphicon-new-window"></span></a>
          </div>
          """
          $("#species-list").before noticeHtml
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


dateMonthToString = (month) ->
  conversionObj =
    0: "January"
    1: "February"
    2: "March"
    3: "April"
    4: "May"
    5: "June"
    6: "July"
    7: "August"
    8: "September"
    9: "October"
    10: "November"
    11: "December"
  try
    rv = conversionObj[month]
  catch
    rv = month
  month


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


renderValidateProgress = ->
  ###
  # Show paper-progress bars as validation goes
  #
  # https://elements.polymer-project.org/elements/paper-progress
  ###
  # Draw it
  html = """
  <div id="validator-progress-container" class="col-md-6 col-xs-12">
    <label for="data-parsing">Data Parsing:</label><paper-progress id="data-parsing" class="blue" indeterminate></paper-progress>
    <label for="data-validation">Data Validation:</label><paper-progress id="data-validation" class="cyan" indeterminate></paper-progress>
    <label for="taxa-validation">Taxa Validation:</label><paper-progress id="taxa-validation" class="teal" indeterminate></paper-progress>
    <label for="data-sync">Estimated Data Sync Progress:</label><paper-progress id="data-sync" indeterminate></paper-progress>
  </div>
  """
  unless $("#validator-progress-container").exists()
    $("#file-uploader-form").after html
  false


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

###
# Split-out coffeescript file for adminstrative editor.
#
# This is included in ./js/admin.js via ./Gruntfile.coffee
#
# For adminstrative viewer code, look at ./coffee/admin-viewer.coffee
#
# @path ./coffee/admin-editor.coffee
# @author Philip Kahn
###


loadEditor = (projectPreload) ->
  ###
  # Load up the editor interface for projects with access
  ###
  startAdminActionHelper()

  editProject = (projectId) ->
    ###
    # Load the edit interface for a specific project
    ###
    # Empty out the main view
    startAdminActionHelper()
    startLoad()
    window.projectParams = new Object()
    window.projectParams.pid = projectId
    # Is the user good?
    verifyLoginCredentials (credentialResult) ->
      userDetail =  credentialResult.detail
      user = userDetail.uid
      # Get the details for the project
      opid = projectId
      projectId = encodeURIComponent projectId
      args = "perform=get&project=#{projectId}"
      $.post adminParams.apiTarget, args, "json"
      .done (result) ->
        try
          console.info "Server said", result
          # Check the result
          unless result.status is true
            error = result.human_error ? result.error
            unless error?
              error = "Unidentified Error"
            stopLoadError "There was a problem loading your project (#{error})"
            console.error "Couldn't load project! (POST OK) Error: #{result.error}"
            console.warn "Attempted", "#{adminParams.apiTarget}?#{args}"
            return false
          unless result.user.has_edit_permissions is true
            if result.user.has_view_permissions or result.project.public.toBool() is true
              # Not eligible to edit. Load project viewer instead.
              loadProject opid, "Ineligible to edit #{opid}, loading as read-only"
              return false
            # No edit or view permissions, and project isn't public.
            # Give generic error
            alertBadProject opid
            return false
          # Populate the UI, prefilling the data
          ## DO THE THING
          toastStatusMessage "Good user, would load editor for project"
          project = result.project
          # Listify some stuff for easier functions
          project.access_data.total = Object.toArray project.access_data.total
          project.access_data.total.sort()
          project.access_data.editors_list = Object.toArray project.access_data.editors_list
          project.access_data.viewers_list = Object.toArray project.access_data.viewers_list
          project.access_data.editors = Object.toArray project.access_data.editors
          project.access_data.viewers = Object.toArray project.access_data.viewers
          console.info "Project access lists:", project.access_data
          # Helper functions to bind to upcoming buttons
          popManageUserAccess = ->
            verifyLoginCredentials (credentialResult) ->
              # For each user in the access list, give some toggles
              userHtml = ""
              for user in project.access_data.total
                theirHtml = "#{user} <span class='set-permission-block'>"
                isAuthor = user is project.access_data.author
                isEditor =  user in project.access_data.editors_list
                isViewer = not isEditor
                editDisabled = if isEditor or isAuthor then "disabled" else "data-toggle='tooltip' title='Make Editor'"
                viewerDisabled = if isViewer or isAuthor then "disabled" else "data-toggle='tooltip' title='Make Read-Only'"
                authorDisabled = if isAuthor then "disabled" else "data-toggle='tooltip' title='Grant Ownership'"
                uid = project.access_data.composite[user]["user_id"]
                theirHtml += """
                <paper-icon-button icon="image:edit" #{editDisabled} class="set-permission" data-permission="edit" data-user="#{uid}"> </paper-icon-button>
                <paper-icon-button icon="image:remove-red-eye" #{viewerDisabled} class="set-permission" data-permission="read" data-user="#{uid}"> </paper-icon-button>
                """
                # Only the current author can change authors
                if result.user.is_author
                  theirHtml += """
                  <paper-icon-button icon="social:person" #{authorDisabled} class="set-permission" data-permission="author" data-user="#{uid}"> </paper-icon-button>
                  """
                if result.user.has_edit_permissions and user isnt isAuthor and user isnt result.user.user.userdata.username
                  # Delete button
                  theirHtml += """
                  <paper-icon-button icon="icons:delete" class="set-permission" data-permission="delete" data-user="#{uid}">
                  </paper-icon-button>
                  """
                userHtml += """
                <li>#{theirHtml}</span></li>
                """
              userHtml = """
              <ul class="simple-list">
                #{userHtml}
              </ul>
              """
              if project.access_data.total.length is 1
                userHtml += """
                <div id="single-user-warning">
                  <iron-icon icon="icons:warning"></iron-icon> <strong>Head's-up</strong>: You can't change permissions when a project only has one user. Consider adding another user first.
                </div>
                """
              # Put it in a dialog
              dialogHtml = """
              <paper-dialog modal id="user-setter-dialog">
                <h2>Manage "#{project.project_title}" users</h2>
                <paper-dialog-scrollable>
                  #{userHtml}
                </paper-dialog-scrollable>
                <div class="buttons">
                  <paper-button class="add-user" dialog-confirm><iron-icon icon="social:group-add"></iron-icon> Add Users</paper-button>
                  <paper-button class="close-dialog" dialog-dismiss>Done</paper-button>
                </div>
              </paper-dialog>
              """
              # Add it to the DOM
              $("#user-setter-dialog").remove()
              $("body").append dialogHtml
              # Event the buttons
              $(".set-permission")
              .unbind()
              .click ->
                user = $(this).attr "data-user"
                permission = $(this).attr "data-permission"
                # Handle it
                permissionsObj = new Object()
                userList = new Array()
                userList.push user
                permissionsObj[permission] = userList
                j64 = jsonTo64 permissionsObj
                args = "perform=editaccess&project=#{window.projectParams.pid}&deltas=#{j64}"
                # Push needs to be server authenticated, to prevent API spoofs
                toastStatusMessage "Would grant #{user} permission '#{permission}'"
                console.log "Would push args to", "#{adminParams.apiTarget}?#{args}"
                false
              $(".add-user")
              .unbind()
              .click ->
                showAddUserDialog(project.access_data.total)
                false
              # Open the dialog
              safariDialogHelper "#user-setter-dialog"
              false
          ## End Bindings
          ## Real DOM stuff
          # Userlist
          userHtml = ""
          for user in project.access_data.total
            icon = ""
            if user is project.access_data.author
              icon = """
              <iron-icon icon="social:person"></iron-icon>
              """
            else if user in project.access_data.editors_list
              icon = """
              <iron-icon icon="image:edit"></iron-icon>
              """
            else if user in project.access_data.viewers_list
              icon = """
              <iron-icon icon="image:remove-red-eye"></iron-icon>
              """
            userHtml += """
            <tr>
              <td colspan="5">#{user}</td>
              <td class="text-center">#{icon}</td>
            </tr>
            """
          # Prepare States
          icon = if project.public.toBool() then """<iron-icon icon="social:public" class="material-green" data-toggle="tooltip" title="Public Project"></iron-icon>""" else """<iron-icon icon="icons:lock" class="material-red" data-toggle="tooltip" title="Private Project"></iron-icon>"""
          publicToggle =
            unless project.public.toBool()
              if result.user.is_author
                """
                <div class="col-xs-12">
                  <paper-toggle-button id="public" class="project-params danger-toggle red">
                    <iron-icon icon="icons:warning"></iron-icon>
                    Make this project public
                  </paper-toggle-button> <span class="text-muted small">Once saved, this cannot be undone</span>
                </div>
                """
              else
                "<!-- This user does not have permission to toggle the public state of this project -->"
            else "<!-- This project is already public -->"
          # dangerToggleStyle = """
          # paper-toggle-button
          # """
          # $("style[is='custom-style']")
          conditionalReadonly = if result.user.has_edit_permissions then "" else "readonly"
          anuraState = if project.includes_anura.toBool() then "checked disabled" else "disabled"
          caudataState = if project.includes_caudata.toBool() then "checked disabled" else "disabled"
          gymnophionaState = if project.includes_gymnophiona.toBool() then "checked disabled" else "disabled"
          try
            cartoParsed = JSON.parse deEscape project.carto_id
          catch
            console.error "Couldn't parse the carto JSON!", project.carto_id
            stopLoadError "We couldn't parse your data. Please try again later."
            cartoParsed = new Object()
          mapHtml = ""
          if cartoParsed.bounding_polygon?.paths?
            # Draw a map web component
            # https://github.com/GoogleWebComponents/google-map/blob/eecb1cc5c03f57439de6b9ada5fafe30117057e6/demo/index.html#L26-L37
            # https://elements.polymer-project.org/elements/google-map
            # Poly is cartoParsed.bounding_polygon.paths
            poly = cartoParsed.bounding_polygon
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
          googleMap = """
                <google-map id="transect-viewport" latitude="#{project.lat}" longitude="#{project.lng}" fit-to-markers map-type="hybrid" disable-default-ui>
                  #{mapHtml}
                </google-map>
          """
          geo.googleMapWebComponent = googleMap
          deleteCardAction = if result.user.is_author then """
          <div class="card-actions">
                <paper-button id="delete-project"><iron-icon icon="icons:delete" class="material-red"></iron-icon> Delete this project</paper-button>
              </div>
          """ else ""
          # The actual HTML
          mdNotes = if isNull(project.sample_notes) then "*No notes for this project*" else project.sample_notes
          noteHtml = """
          <h3>Project Notes</h3>
          <ul class="nav nav-tabs" id="markdown-switcher">
            <li role="presentation" class="active" data-view="md"><a href="#markdown-switcher">Preview</a></li>
            <li role="presentation" data-view="edit"><a href="#markdown-switcher">Edit</a></li>
          </ul>
          <iron-autogrow-textarea id="project-notes" class="markdown-pair project-param" rows="3" data-field="sample_notes" hidden>#{project.sample_notes}</iron-autogrow-textarea>
          <marked-element class="markdown-pair project-param" id="note-preview">
            <div class="markdown-html"></div>
            <script type="text/markdown">#{mdNotes}</script>
          </marked-element>
          """
          try
            authorData = JSON.parse project.author_data
            creation = new Date(authorData.entry_date)
          catch
            authorData = new Object()
            creation = new Object()
            creation.toLocaleString = ->
              return "Error retrieving creation time"
          html = """
          <h2 class="clearfix newtitle col-xs-12">Managing #{project.project_title} #{icon}<br/><small>Project ##{opid}</small></h2>
          #{publicToggle}
          <section id="manage-users" class="col-xs-12 col-md-4 pull-right">
            <paper-card class="clearfix" heading="Project Collaborators" elevation="2">
              <div class="card-content">
                <table class="table table-striped table-condensed table-responsive table-hover clearfix">
                  <thead>
                    <tr>
                      <td colspan="5">User</td>
                      <td>Permissions</td>
                    </tr>
                  </thead>
                  <tbody>
                    #{userHtml}
                  </tbody>
                </table>
              </div>
              <div class="card-actions">
                <paper-button class="manage-users" id="manage-users">Manage Users</paper-button>
              </div>
            </paper-card>
          </section>
          <section id="project-basics" class="col-xs-12 col-md-8 clearfix">
            <h3>Project Basics</h3>
            <paper-input readonly label="Project Identifier" value="#{project.project_id}" id="project_id" class="project-param"></paper-input>
            <paper-input readonly label="Project Creation" value="#{creation.toLocaleString()}" id="project_creation" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Title" value="#{project.project_title}" id="project-title" data-field="project_title"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Primary Pathogen" value="#{project.disease}" data-field="disease"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="PI Lab" value="#{project.pi_lab}" id="project-title" data-field="pi_lab"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Reference" value="#{project.reference_id}" id="project-reference" data-field="reference_id"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Publication DOI" value="#{project.publication}" id="doi" data-field="publication"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Contact" value="#{authorData.name}" id="project-contact"></paper-input>
            <gold-email-input #{conditionalReadonly} class="project-param" label="Contact Email" value="#{authorData.contact_email}" id="contact-email"></gold-email-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Diagnostic Lab" value="#{authorData.diagnostic_lab}" id="project-lab"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Affiliation" value="#{authorData.affiliation}" id="project-affiliation"></paper-input>
          </section>
          <section id="notes" class="col-xs-12 col-md-8 clearfix">
            #{noteHtml}
          </section>
          <section id="data-management" class="col-xs-12 col-md-4 pull-right">
            <paper-card class="clearfix" heading="Project Data" elevation="2" id="data-card">
              <div class="card-content">
                <div class="variable-card-content">
                Your project does/does not have data associated with it. (Does should note overwrite, and link to cartoParsed.raw_data.filePath for current)
                </div>
                <div id="append-replace-data-toggle">
                  <span class="toggle-off-label iron-label">Append Data</span>
                  <paper-toggle-button id="replace-data-toggle" checked>Replace Data</paper-toggle-button>
                </div>
                <div id="uploader-container-section">
                </div>
              </div>
            </paper-card>
            <paper-card class="clearfix" heading="Project Status" elevation="2" id="save-card">
              <div class="card-content">
                <p>Notice if there's unsaved data or not. Buttons below should dynamically disable/enable based on appropriate state.</p>
              </div>
              <div class="card-actions">
                <paper-button id="save-project"><iron-icon icon="icons:save" class="material-green"></iron-icon> Save Project</paper-button>
              </div>
              <div class="card-actions">
                <paper-button id="discard-changes-exit"><iron-icon icon="icons:undo"></iron-icon> Discard Changes &amp; Exit</paper-button>
              </div>
              #{deleteCardAction}
            </paper-card>
          </section>
          <section id="project-data" class="col-xs-12 col-md-8 clearfix">
            <h3>Project Data Overview</h3>
              <h4>Project Studies:</h4>
                <paper-checkbox #{anuraState}>Anura</paper-checkbox>
                <paper-checkbox #{caudataState}>Caudata</paper-checkbox>
                <paper-checkbox #{gymnophionaState}>Gymnophiona</paper-checkbox>
                <paper-input readonly label="Sampled Species" value="#{project.sampled_species.split(",").join(", ")}"></paper-input>
                <paper-input readonly label="Sampled Clades" value="#{project.sampled_clades.split(",").join(", ")}"></paper-input>
              <h4>Sample Metrics</h4>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
              <h4>Locality &amp; Transect Data</h4>
                #{googleMap}
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
            <h3>Project Meta Parameters</h3>
              <h4>Project funding status</h4>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id=""></paper-input>
          </section>
          """
          $("#main-body").html html
          # Watch for changes and toggle save watcher state
          # Events
          ta = p$("#project-notes").textarea
          $(ta).keyup ->
            p$("#note-preview").markdown = $(this).val()
          $("#markdown-switcher li").click ->
            $("#markdown-switcher li").removeClass "active"
            $(".markdown-pair").removeAttr "hidden"
            $(this).addClass "active"
            switch $(this).attr "data-view"
              when "md"
                $("#project-notes").attr "hidden", "hidden"
              when "edit"
                $("#note-preview").attr "hidden", "hidden"

          $("#delete-project").click ->
            confirmButton = """
            <paper-button id="confirm-delete-project" class="materialred">
              <iron-icon icon="icons:warning"></iron-icon> Confirm Project Deletion
            </paper-button>
            """
            $(this).replaceWith confirmButton
            $("#confirm-delete-project").click ->
              toastStatusMessage "TODO Would delete this project"
              # Return home
              # showEditList()
              false
            false
          $("#save-project").click ->
            # Replace the delete button
            if $("#confirm-delete-project").exists()
              button = """
                <paper-button id="delete-project"><iron-icon icon="icons:delete" class="material-red"></iron-icon> Delete this project</paper-button>
              """
              $("#confirm-delete-project").replaceWith button
            # Save it
            toastStatusMessage "TODO Would save this project"
            false
          $("#discard-changes-exit").click ->
            showEditList()
            false
          topPosition = $("#data-management").offset().top
          affixOptions =
            top: topPosition
            bottom: 0
            target: window
          # $("#data-management").affix affixOptions
          # console.info "Affixed at #{topPosition}px", affixOptions
          $("#manage-users").click ->
            popManageUserAccess()
          $(".danger-toggle").on "iron-change", ->
            if $(this).get(0).checked
              $(this).find("iron-icon").addClass("material-red")
            else
              $(this).find("iron-icon").removeClass("material-red")
          # Load more detailed data from CartoDB
          getProjectCartoData project.carto_id
        catch e
          stopLoadError "There was an error loading your project"
          console.error "Unhandled exception loading project! #{e.message}"
          console.warn e.stack
          return false
      .error (result, status) ->
        stopLoadError "We couldn't load your project. Please try again."
    false

  unless projectPreload?
    do showEditList = ->
      ###
      # Show a list of icons for editable projects. Blocked on #22, it's
      # just based on authorship right now.
      ###
      startLoad()
      args = "perform=list"
      $.get adminParams.apiTarget, args, "json"
      .done (result) ->
        html = """
        <h2 class="new-title col-xs-12">Editable Projects</h2>
        <ul id="project-list" class="col-xs-12 col-md-6">
        </ul>
        """
        $("#main-body").html html
        authoredList = new Array()
        for k, projectId of result.authored_projects
          authoredList.push projectId
        for projectId, projectTitle of result.projects
          icon = if projectId in authoredList then """<iron-icon icon="social:person" data-toggle="tooltip" title="Author"></iron-icon>""" else """<iron-icon icon="social:group" data-toggle="tooltip" title="Collaborator"></iron-icon>"""
          if projectId in authoredList
            html = """
            <li>
              <button class="btn btn-primary" data-project="#{projectId}">
                #{projectTitle} / ##{projectId.substring(0,8)}
              </button>
              #{icon}
            </li>
            """
            $("#project-list").append html
        $("#project-list button")
        .unbind()
        .click ->
          project = $(this).attr("data-project")
          editProject(project)
        stopLoad()
      .error (result, status) ->
        stopLoadError "There was a problem loading viable projects"
  else
    # We have a requested project preload
    editProject(projectPreload)
  false


showAddUserDialog = (refAccessList) ->
  ###
  # Open up a dialog to show the "Add a user" interface
  #
  # @param Array refAccessList  -> array of emails already with access
  ###
  dialogHtml = """
  <paper-dialog modal id="add-new-user">
  <h2>Add New User To Project</h2>
  <paper-dialog-scrollable>
    <p>Search by email, real name, or username below. Click on a search result to queue a user for adding.</p>
    <div class="form-horizontal" id="search-user-form-container">
      <div class="form-group">
        <label for="search-user" class="sr-only form-label">Search User</label>
        <input type="text" id="search-user" name="search-user" class="form-control"/>
      </div>
      <paper-material id="user-search-result-container" class="pop-result" hidden>
        <div class="result-list">
          <div class="user-search-result" data-uid="456"><span class="email">foo@bar.com</span> | <span class="name">Jane Smith</span> | <span class="user">FooBar</span></div>
          <div class="user-search-result" data-uid="123"><span class="email">foo2@bar.com</span> | <span class="name">John Smith</span> | <span class="user">FooBar2</span></div>
        </div>
      </paper-material>
    </div>
    <p>Adding users:</p>
    <ul class="simple-list" id="user-add-queue">
      <!--
        <li class="list-add-users" data-uid="789">
          jsmith@sample.com
        </li>
      -->
    </ul>
  </paper-dialog-scrollable>
  <div class="buttons">
    <paper-button id="add-user"><iron-icon icon="social:person-add"></iron-icon> Save Additions</paper-button>
    <paper-button dialog-dismiss>Cancel</paper-button>
  </div>
</paper-dialog>
  """
  unless $("#add-new-user").exists()
    $("body").append dialogHtml
  safariDialogHelper "#add-new-user"
  # Events
  # Bind type-to-search
  $("#search-user").keyup ->
    console.log "Should search", $(this).val()
    unless $("#debug-alert").exists()
      debugHtml = """
      <div class="alert alert-warning" id="debug-alert">
        Would search against "<span id="debug-placeholder"></span>". Incomplete. Sample result shown.
      </div>
      """
      $(this).before debugHtml
    $("#debug-placeholder").text $(this).val()
    if isNull $(this).val()
      $("#user-search-result-container").prop "hidden", "hidden"
    else
      $("#user-search-result-container").removeAttr "hidden"

  $("body .user-search-result").click ->
    uid = $(this).attr "data-uid"
    console.info "Clicked on #{uid}"
    email = $(this).find(".email").text()
    currentQueueUids = new Array()
    for user in $("#user-add-queue .list-add-users")
      currentQueueUids.push $(user).attr "data-uid"
    unless email in refAccessList
      unless uid in currentQueueUids
        listHtml = """
        <li class="list-add-users" data-uid="#{uid}">#{email}</li>
        """
        $("#user-add-queue").append listHtml
        $("#search-user").val ""
        $("#user-search-result-container").prop "hidden", "hidden"
      else
        toastStatusMessage "#{email} is already in the addition queue"
        return false
    else
      toastStatusMessage "#{email} already has access to this project"
      return false
  # bind add button
  $("#add-user").click ->
    toAddUids = new Array()
    for user in $("#user-add-queue .list-add-users")
      toAddUids.push $(user).attr "data-uid"
    if toAddUids.length < 1
      toastStatusMessage "Please add at least one user to the access list."
      return false
    console.info "Saving list of #{toAddUids.length} UIDs to #{window.projectParams.pid}", toAddUids
    jsonUids =
      add: toAddUids
    uidArgs = jsonTo64 jsonUids
    args = "perform=editaccess&project=#{window.projectParams.pid}&deltas=#{uidArgs}"
    # Push needs to be server authenticated, to prevent API spoofs
    toastStatusMessage "Would save the list above of #{toAddUids.length} UIDs to #{window.projectParams.pid}"
    console.log "Would push args to", "#{adminParams.apiTarget}?#{args}"
  false



getProjectCartoData = (cartoObj) ->
  ###
  # Get the data from CartoDB, map it out, show summaries, etc.
  #
  # @param string|Object cartoObj -> the (JSON formatted) carto data blob.
  ###
  unless typeof cartoObj is "object"
    try
      cartoData = JSON.parse deEscape cartoObj
    catch
      console.error "cartoObj must be JSON string or obj, given", cartoObj
      console.warn "Cleaned obj:", deEscape cartoObj
      stopLoadError "Couldn't parse data"
      return false
  else
    cartoData = cartoObj
  cartoTable = cartoData.table
  console.info "Working with Carto data base set", cartoData
  try
    zoom = getMapZoom cartoData.bounding_polygon.paths, "#transect-viewport"
    console.info "Got zoom", zoom
    $("#transect-viewport").attr "zoom", zoom
  # Ping Carto on this and get the data
  toastStatusMessage "Would ping CartoDB and fetch data for table #{cartoTable}"
  cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
  console.info "Would ping cartodb with", cartoQuery
  apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
  args = "action=fetch&sql_query=#{apiPostSqlQuery}"
  $.post "api.php", args, "json"
  .done (result) ->
    console.info "Carto query got result:", result
    unless result.status
      error = result.human_error ? result.error
      unless error?
        error = "Unknown error"
      stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
      return false
    rows = result.parsed_responses[0].rows
    truncateLength = 0 - "</google-map>".length
    workingMap = geo.googleMapWebComponent.slice 0, truncateLength
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
        console.warn "#{taxa} was changed from #{row.originaltaxa}"
        note = "(<em>#{row.originaltaxa}</em>)"
      marker = """
      <google-map-marker latitude="#{lat}" longitude="#{lng}">
        <p>
          <em>#{row.genus} #{row.specificepithet}</em> #{note}
          <br/>
          Tested <strong>#{row.diseasedetected}</strong> for #{row.diseasetested}
        </p>
      </google-map-marker>
      """
      # $("#transect-viewport").append marker
      workingMap += marker
    # p$("#transect-viewport").resize()
    workingMap += "</google-map>"
    $("#transect-viewport").replaceWith workingMap
    stopLoad()
  .fail (result, status) ->
    console.error "Couldn't talk to back end server to ping carto!"
    stopLoadError "There was a problem communicating with the server. Please try again in a bit. (E-002)"
  window.dataFileparams = cartoData.raw_data
  if cartoData.raw_data.hasDataFile
    # We already have a data file
    html = """
    <p>
      Your project already has data associated with it. <span id="last-modified-file"></span>
    </p>
    <button id="download-project-file" class="btn btn-primary center-block click" data-href="#{cartoData.raw_data.fileName}"><iron-icon icon="icons:cloud-download"></iron-icon> Download File</button>
    <p>You can upload more data below, or replace this existing data.</p>
    """
    $("#data-card .card-content .variable-card-content").html html
    $.get "meta.php", "do=get_last_mod&file=#{cartoData.raw_data.fileName}", "json"
    .done (result) ->
      time = toInt(result.last_mod) * 1000 # Seconds -> Milliseconds
      console.log "Last modded", time, result
      if isNumber time
        t = new Date(time)
        iso = t.toISOString()
        #  Not good enough time resolution to use t.toTimeString().split(" ")[0]
        timeString = "#{iso.slice(0, iso.search("T"))}"
        $("#last-modified-file").text "Last uploaded on #{timeString}."
      else
        console.warn "Didn't get a number back to check last mod time for #{cartoData.raw_data.fileName}"
      false
    .fail (result, status) ->
      # We don't really care, actually.
      console.warn "Couldn't get last mod time for #{cartoData.raw_data.fileName}"
      false
  else
    # We don't already have a data file
    $("#data-card .card-content .variable-card-content").html "<p>You can upload data to your project here:</p>"
    $("#append-replace-data-toggle").attr "hidden", "hidden"
  bootstrapUploader("data-card-uploader", "")
  false

###
#
#
# This is included in ./js/admin.js via ./Gruntfile.coffee
#
# For administrative editor code, look at ./coffee/admin-editor.coffee
#
# @path ./coffee/admin-viewer.coffee
# @author Philip Kahn
###


loadProjectBrowser = ->
  startAdminActionHelper()
  startLoad()
  args = "perform=list"
  $.get adminParams.apiTarget, args, "json"
  .done (result) ->
    html = """
    <h2 class="new-title col-xs-12">Available Projects</h2>
    <ul id="project-list" class="col-xs-12 col-md-6">
    </ul>
    """
    $("#main-body").html html
    publicList = new Array()
    for k, projectId of result.public_projects
      publicList.push projectId
    for projectId, projectTitle of result.projects
      # Or lock-outline ??
      icon = if projectId in publicList then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock-open"></iron-icon>"""
      html = """
      <li>
        <button class="btn btn-primary" data-project="#{projectId}" data-toggle="tooltip" title="Project ##{projectId.substring(0,8)}...">
          #{icon} #{projectTitle}
        </button>
      </li>
      """
      $("#project-list").append html
    $("#project-list button")
    .unbind()
    .click ->
      project = $(this).attr("data-project")
      loadProject(project)
    stopLoad()
  .error (result, status) ->
    stopLoadError "There was a problem loading viable projects"

  false


loadProject = (projectId, message = "") ->
  toastStatusMessage "Would load project #{projectId} to view"
  false


loadSUProjectBrowser = ->
  startAdminActionHelper()
  startLoad()
  verifyLoginCredentials (result) ->
    rawSu = toInt result.detail.userdata.su_flag
    unless rawSu.toBool()
      stopLoadError "Sorry, you must be an admin to do this"
      return false
    args = "perform=sulist"
    $.get adminParams.apiTarget, args, "json"
    .done (result) ->
      unless result.status is true
        error = result.human_error ? "Sorry, you can't do that right now"
        stopLoadError error
        console.error "Can't do SU listing!"
        console.warn result
        populateAdminActions()
        return false
      html = """
      <h2 class="new-title col-xs-12">All Projects</h2>
      <ul id="project-list" class="col-xs-12 col-md-6">
      </ul>
      """
      $("#main-body").html html
      list = new Array()
      for projectId, projectDetails of result.projects
        list.push projectId
        # Or lock-outline ??
        icon = if projectDetails.public.toBool() then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
        html = """
        <li>
          <button class="btn btn-primary" data-project="#{projectId}" data-toggle="tooltip" title="Project ##{projectId.substring(0,8)}...">
            #{icon} #{projectDetails.title}
          </button>
        </li>
        """
        $("#project-list").append html
      $("#project-list button")
      .unbind()
      .click ->
        project = $(this).attr("data-project")
        loadEditor(project)
      stopLoad()
    .error (result, status) ->
      stopLoadError "There was a problem loading projects"
  false

###
# Split-out coffeescript file for data validation.
# This file contains async validation code to check entries.
#
# This is included in ./js/admin.js via ./Gruntfile.coffee
#
# For administrative functions for project creation, editing, or
# viewing, check ./coffee/admin.coffee, ./coffee/admin-editor.coffee,
# and ./coffee/admin-viewer.coffee (respectively).
#
# @path ./coffee/admin-validation.coffee
# @author Philip Kahn
###

unless typeof window.validationMeta is "object"
  window.validationMeta = new Object()



validateData = (dataObject, callback = null) ->
  ###
  #
  ###
  console.info "Doing nested validation"
  timer = Date.now()
  renderValidateProgress()
  validateFimsData dataObject, ->
    validateTaxonData dataObject, ->
      # When we're successful, run the dependent callback
      elapsed = Date.now() - timer
      console.info "Validation took #{elapsed}ms", dataObject
      cleanupToasts()
      toastStatusMessage "Your dataset has been successfully validated"
      if typeof callback is "function"
        callback(dataObject)
      else
        console.warn "validateData had no defined callback!"
        console.info "Got back", dataObject
  false

validateFimsData = (dataObject, callback = null) ->
  ###
  #
  #
  # @param Object dataObject -> object with at least one key, "data",
  #  containing the parsed data to be validated by FIMS
  # @param function callback -> callback function
  ###
  console.info "FIMS Validating", dataObject.data
  $("#data-validation").removeAttr "indeterminate"
  p$("#data-validation").max = Object.size dataObject.data
  fimsPostTarget = ""
  # Format the JSON for FIMS
  # Post the object over to FIMS
  # Get back an ARK
  # When we're successful, run the dependent callback
  if typeof callback is "function"
    p$("#data-validation").value = Object.size dataObject.data
    callback(dataObject)
  false


mintBcid = (projectId, title, callback) ->
  ###
  #
  # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
  #
  # Resolve the ARK with
  # https://n2t.net/
  ###
  if typeof callback isnt "function"
    console.warn "mintBcid() requires a callback function"
    return false
  resultObj = new Object()
  args = "link=#{projectId}&title=#{post64(title)}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadError result.human_error
      console.error result.error      
      return false
    resultObj = result
  .error (result, status) ->
    resultObj.ark = null
    false
  .always ->
    console.info "mintBcid is calling back", resultObj
    callback(resultObj)
  false


validateTaxonData = (dataObject, callback = null) ->
  ###
  #
  ###
  data = dataObject.data
  taxa = new Array()
  taxaPerRow = new Object()
  for n, row of data
    taxon =
      genus: row.genus
      species: row.specificEpithet
      subspecies: row.infraspecificEpithet
      clade: row.cladeSampled
    unless taxa.containsObject taxon
      taxa.push taxon
    taxaString = "#{taxon.genus} #{taxon.species}"
    unless isNull taxon.subspecies
      taxaString += " #{taxon.subspecies}"
    unless taxaPerRow[taxaString]?
      taxaPerRow[taxaString] = new Array()
    taxaPerRow[taxaString].push n
  console.info "Found #{taxa.length} unique taxa:", taxa
  grammar = if taxa.length > 1 then "taxa" else "taxon"
  toastStatusMessage "Validating #{taxa.length} uniqe #{grammar}"
  console.info "Replacement tracker", taxaPerRow
  $("#taxa-validation").removeAttr "indeterminate"
  p$("#taxa-validation").max = taxa.length
  do taxonValidatorLoop = (taxonArray = taxa, key = 0) ->
    taxaString = "#{taxonArray[key].genus} #{taxonArray[key].species}"
    unless isNull taxonArray[key].subspecies
      taxaString += " #{taxonArray[key].subspecies}"
    validateAWebTaxon taxonArray[key], (result) ->
      if result.invalid is true
        cleanupToasts()
        stopLoadError result.response.human_error
        console.error result.response.error
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. #{result.response.human_error} We stopped validation at that point. Please correct taxonomy issues and try uploading again."
        bsAlert(message)
        removeDataFile()
        return false
      try
        replaceRows = taxaPerRow[taxaString]
        console.info "Replacing rows @ #{taxaString}", replaceRows, taxonArray[key]
        # Replace entries
        for row in replaceRows
          dataObject.data[row].genus = result.genus
          dataObject.data[row].specificEpithet = result.species
          unless result.subspecies?
            result.subspecies = ""
          dataObject.data[row].infraspecificEpithet = result.subspecies
          dataObject.data[row].originalTaxa = taxaString
      catch e
        console.warn "Problem replacing rows! #{e.message}"
        console.warn e.stack
      taxonArray[key] = result
      p$("#taxa-validation").value = key
      key++
      if key < taxonArray.length
        if key %% 50 is 0
          toastStatusMessage "Validating taxa #{key} of #{taxonArray.length} ..."
        taxonValidatorLoop(taxonArray, key)
      else
        p$("#taxa-validation").value = key
        dataObject.validated_taxa  = taxonArray
        console.info "Calling back!", dataObject
        callback(dataObject)
  false

validateAWebTaxon = (taxonObj, callback = null) ->
  ###
  #
  #
  # @param Object taxonObj -> object with keys "genus", "species", and
  #   optionally "subspecies"
  # @param function callback -> Callback function
  ###
  unless window.validationMeta?.validatedTaxons?
    # Just being thorough on this check
    unless typeof window.validationMeta is "object"
      window.validationMeta = new Object()
    # Create the array if it doesn't exist yet
    window.validationMeta.validatedTaxons = new Array()
  doCallback = (validatedTaxon) ->
    if typeof callback is "function"
      callback(validatedTaxon)
    false
  # Check the taxon against pre-validated ones
  if window.validationMeta.validatedTaxons.containsObject taxonObj
    console.info "Already validated taxon, skipping revalidation", taxonObj
    doCallback(taxonObj)
    return false
  args = "action=validate&genus=#{taxonObj.genus}&species=#{taxonObj.species}"
  if taxonObj.subspecies?
    args += "&subspecies=#{taxonObj.subspecies}"
  $.post "api.php", args, "json"
  .done (result) ->
    if result.status
      # Success! Save validated taxon, and run callback
      taxonObj.genus = result.validated_taxon.genus
      taxonObj.species = result.validated_taxon.species
      taxonObj.subspecies = result.validated_taxon.subspecies
      window.validationMeta.validatedTaxons.push taxonObj
    else
      taxonObj.invalid = true
    taxonObj.response = result
    doCallback(taxonObj)
    return false
  .fail (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false
