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
      </h3>
      <section id='admin-actions-block' class="row center-block text-center">
        <div class='bs-callout bs-callout-info'>
          <p>Please be patient while the administrative interface loads.</p>
        </div>
      </section>
      """
      $("main #main-body").before(articleHtml)
      $(".fill-user-fullname").text $.cookie("#{adminParams.domain}_fullname")
      checkInitLoad ->
        populateAdminActions()
        bindClicks()
      false
  catch e
    $("main #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>")
  false

populateAdminActions = ->
  # Reset the URI
  url = "#{uri.urlString}admin-page.html"
  state =
    do: "home"
    prop: null
  history.pushState state, "Admin Home", url
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
  url = "#{uri.urlString}admin-page.html#action:create-project"
  state =
    do: "action"
    prop: "create-project"
  history.pushState state, "Create New Project", url
  startAdminActionHelper()
  html = """
  <h2 class="new-title col-xs-12">Project Title</h2>
  <paper-input label="Project Title" id="project-title" class="project-field col-md-6 col-xs-12" required auto-validate data-field="project_title"></paper-input>
  <h2 class="new-title col-xs-12">Project Parameters</h2>
  <section class="project-inputs clearfix col-xs-12">
    <div class="row">
      <paper-input label="Primary Pathogen Studied" id="project-disease" class="project-field col-md-6 col-xs-8" required auto-validate data-field="disease"></paper-input>
        #{getInfoTooltip("Bd, Bsal, or other. If empty, we'll take it from your data.")}
        <button class="btn btn-default fill-pathogen col-xs-1" data-pathogen="Batrachochytrium dendrobatidis">Bd</button>
        <button class="btn btn-default fill-pathogen col-xs-1" data-pathogen="Batrachochytrium salamandrivorans ">Bsal</button>
      <paper-input label="Pathogen Strain" id="project-disease-strain" class="project-field col-md-6 col-xs-11" data-field="disease_strain"></paper-input>#{getInfoTooltip("For example, Hepatitus A, B, C would enter the appropriate letter here")}
      <paper-input label="Project Reference" id="reference-id" class="project-field col-md-6 col-xs-11" data-field="reference_id"></paper-input>
      #{getInfoTooltip("E.g.  a DOI or other reference")}
      <paper-input label="Publication DOI" id="pub-doi" class="project-field col-md-6 col-xs-11" data-field="publication"></paper-input>
      <h2 class="new-title col-xs-12">Lab Parameters</h2>
      <paper-input label="Project PI" id="project-pi" class="project-field col-md-6 col-xs-12"  required auto-validate data-field="pi_lab"></paper-input>
      <paper-input label="Project Contact" id="project-author" class="project-field col-md-6 col-xs-12" value="#{userFullname}"  required auto-validate></paper-input>
      <gold-email-input label="Contact Email" id="author-email" class="project-field col-md-6 col-xs-12" value="#{userEmail}"  required auto-validate></gold-email-input>
      <paper-input label="Diagnostic Lab" id="project-lab" class="project-field col-md-6 col-xs-12"  required auto-validate></paper-input>
      <paper-input label="Affiliation" id="project-affiliation" class="project-field col-md-6 col-xs-11"  required auto-validate></paper-input> #{getInfoTooltip("Of project PI. e.g., UC Berkeley")}
      <h2 class="new-title col-xs-12">Project Notes</h2>
      <iron-autogrow-textarea id="project-notes" class="project-field col-md-6 col-xs-11" rows="3" data-field="sample_notes"></iron-autogrow-textarea>#{getInfoTooltip("Project notes or brief abstract; accepts Markdown ")}
      <marked-element class="project-param col-md-6 col-xs-12" id="note-preview">
        <div class="markdown-html"></div>
      </marked-element>
      <h2 class="new-title col-xs-12">Data Permissions</h2>
      <div class="col-xs-12">
        <span class="toggle-off-label iron-label">Private Dataset</span>
        <paper-toggle-button id="data-encumbrance-toggle" class="red">Public Dataset</paper-toggle-button>
      </div>
      <h2 class="new-title col-xs-12">Project Area of Interest</h2>
      <div class="col-xs-12">
        <p>
          This represents the approximate collection region for your samples.
          <br/>
          <strong>
            The last thing you do (search, build a locality, or upload data) will be your dataset's canonical locality.
          </strong>.
        </p>
        <span class="toggle-off-label iron-label">Locality Name</span>
        <paper-toggle-button id="transect-input-toggle">Coordinate List</paper-toggle-button>
      </div>
      <p id="transect-instructions" class="col-xs-12"></p>
      <div id="transect-input" class="col-md-6 col-xs-12">
        <div id="transect-input-container" class="clearfix">
        </div>
        <p class="computed-locality" id="computed-locality">
          You may also click on the map to outline a region of interest, then click "Build Map" below to calculate a locality.
        </p>
        <br/><br/>
        <button class="btn btn-primary" disabled id="init-map-build">
          <iron-icon icon="maps:map"></iron-icon>
          Build Map
          <small>
            (<span class="points-count">0</span> points)
          </small>
        </button>
        <paper-icon-button icon="icons:restore" id="reset-map-builder" data-toggle="tooltip" title="Reset Points"></paper-icon-button>
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
      Please note that the data <strong>must</strong> have a header row,
      and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, and <code>coordinateUncertaintyInMeters</code>. Your project must also be titled before uploading data.
    </p>
    <div class="alert alert-info" role="alert">
      We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href="http://biscicol.org/biocode-fims/templates.jsp" class="newwindow alert-link" data-newtab="true">biscicol.org <span class="glyphicon glyphicon-new-window"></span></a>. Select "Amphibian Disease" from the dropdown menu, and select your fields for your template. Your data will be validated with the same service.
    </div>
    <div class="alert alert-warning" role="alert">
      <strong>If the data is in Excel</strong>, ensure that it is the first sheet in the workbook. Data across multiple sheets in one workbook may be improperly processed.
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
  <section id="submission-section" class="col-xs-12">
    <div class="pull-right">
      <button id="upload-data" class="btn btn-success click" data-function="finalizeData"><iron-icon icon="icons:lock-open"></iron-icon> <span class="label-with-data">Save Data &amp;</span> Create Private Project</button>
      <button id="reset-data" class="btn btn-danger click" data-function="resetForm">Reset Form</button>
    </div>
  </section>
  """
  $("main #main-body").append html
  mapNewWindows()
  try
    for input in $("paper-input[required]")
      p$(input).validate()
  catch
    console.warn "Couldn't pre-validate fields"
  # Events
  $(".fill-pathogen").click ->
    pathogen = $(this).attr "data-pathogen"
    p$("#project-disease").value = pathogen
    false
  $("#init-map-build").click ->
    doMapBuilder window.mapBuilder, null, (map) ->
      html = """
      <p class="text-muted" id="computed-locality">
        Computed locality: <strong>#{map.locality}</strong>
      </p>
      """
      $("#computed-locality").remove()
      $("#transect-input-container").after html
      false
  $("#reset-map-builder").click ->
    window.mapBuilder.points = new Array()
    $("#init-map-build").attr "disabled", "disabled"
    $("#init-map-build .points-count").text window.mapBuilder.points.length
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
  console.log "Getting location, prerequisite to setting up map ..."
  getLocation ->
    _adp.currentLocation = new Point window.locationData.lat, window.locationData.lng
    mapOptions =
      bsGrid: ""
    console.log "Location fetched, setting up map ..."
    createMap2 null, mapOptions
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
    file = dataFileParams?.filePath ? null
    mintBcid _adp.projectId, file, title, (result) ->
      try
        unless result.status
          console.error result.error
          bsAlert result.human_error, "danger"
          stopLoadError result.human_error
          return false
        dataAttrs.ark = result.ark
        dataAttrs.data_ark ?= new Array()
        dataAttrs.data_ark.push  "#{result.ark}::#{dataFileParams.fileName}"
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
        center = getMapCenter(geo.boundingBox)
        # Have some fun times with uploadedData
        excursion = 0
        if uploadedData?
          # Loop through it
          dates = new Array()
          months = new Array()
          years = new Array()
          methods = new Array()
          catalogNumbers = new Array()
          fieldNumbers = new Array()
          dispositions = new Array()
          sampleMethods = new Array()
          for row in Object.toArray uploadedData
            # sanify the dates
            date = row.dateCollected ? row.dateIdentified
            uTime = excelDateToUnixTime date
            dates.push uTime
            uDate = new Date(uTime)
            mString = dateMonthToString uDate.getUTCMonth()
            unless mString in months
              months.push mString
            unless uDate.getFullYear() in years
              years.push uDate.getFullYear()
            # Get the catalog number list
            if row.catalogNumber? # Not mandatory
              catalogNumbers.push row.catalogNumber
            fieldNumbers.push row.fieldNumber
            # Prepare to calculate the radius
            rowLat = row.decimalLatitude
            rowLng = row.decimalLongitude
            distanceFromCenter = geo.distance rowLat, rowLng, center.lat, center.lng
            if distanceFromCenter > excursion then excursion = distanceFromCenter
            # Samples
            if row.sampleType?
              unless row.sampleType in sampleMethods
                sampleMethods.push row.sampleType
            if row.specimenDisposition?
              unless row.specimenDisposition in dispositions
                dispositions.push row.sampleDisposition
          console.info "Got date ranges", dates
          months.sort()
          years.sort()
          postData.sampled_collection_start = dates.min()
          postData.sampled_collection_end = dates.max()
          console.info "Collected from", dates.min(), dates.max()
          postData.sampling_months = months.join(",")
          postData.sampling_years = years.join(",")
          console.info "Got uploaded data", uploadedData
          postData.sample_catalog_numbers = catalogNumbers.join(",")
          postData.sample_field_numbers = fieldNumbers.join(",")
          postData.sample_methods_used = sampleMethods.join(",")
        else
          # No data, check bounding box
          if geo.canonicalHullObject?
            hull = geo.canonicalHullObject.hull
            for point in hull
              distanceFromCenter = geo.distance point.lat, point.lng, center.lat, center.lng
              if distanceFromCenter > excursion then excursion = distanceFromCenter
        if dataFileParams?.hasDataFile
          if dataFileParams.filePath.search helperDir is -1
            dataFileParams.filePath = "#{helperDir}#{dataFileParams.filePath}"
          postData.sample_raw_data = "https://amphibiandisease.org/#{dataFileParams.filePath}"
        postData.lat = center.lat
        postData.lng = center.lng
        postData.radius = toInt excursion * 1000
        # Do this after locality calcs
        postBBLocality = ->
          console.info "Computed locality #{_adp.locality}"
          postData.locality = _adp.locality
          if geo.computedBoundingRectangle?
            # Bounding box coords
            postData.bounding_box_n = geo.computedBoundingRectangle.north
            postData.bounding_box_s = geo.computedBoundingRectangle.south
            postData.bounding_box_e = geo.computedBoundingRectangle.east
            postData.bounding_box_w = geo.computedBoundingRectangle.west
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
          try
            postData.project_obj_id = _adp.fims.expedition.ark
          catch
            mintExpedition _adp.projectId, null, ->
              postBBLocality()
            return false
          dataAttrs.data_ark ?= new Array()
          postData.dataset_arks = dataAttrs.data_ark.join ","
          postData.project_dir_identifier = getUploadIdentifier()
          # Public or private?
          postData.public = p$("#data-encumbrance-toggle").checked
          if _adp?.data?.taxa?.validated?
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
              bsAlert("Project ID #<strong>#{postData.project_id}</strong> created","success")
              stopLoad()
              delay 1000, ->
                loadEditor _adp.projectId
              toastStatusMessage "Data successfully saved to server"
            else
              console.error result.error.error
              console.log result
              stopLoadError result.human_error
            false
          .error (result, status) ->
            stopLoadError "There was a problem saving your data. Please try again"
            false
        # End postBBLocality
        console.info "Checking locality ..."
        if geo.computedLocality? or not dataFileParams.hasDataFile
          # We either have a computed locality, or have no data file
          if geo.computedLocality?
            console.info "Already have locality"
            _adp.locality = geo.computedLocality
          else
            # No locality and no data file
            try
              console.info "Took written locality"
              _adp.locality = p$("#locality-input").value
            catch
              console.info "Can't figure out locality"
              _adp.locality = ""
          if not dataFileParams.hasDataFile
            # Foo
            mintExpedition _adp.projectId, null, ->
              postBBLocality()
          else
            postBBLocality()
        else if dataFileParams.hasDataFile
          # No locality and have a data file
          # First, get the locality
          center ?= getMapCenter(geo.boundingBox)
          console.info "Computing locality with reverse geocode from", center, geo.boundingBox
          geo.reverseGeocode center.lat, center.lng, geo.boundingBox, (result) ->
            console.info "Computed locality #{result}"
            _adp.locality = result
            postBBLocality()
        else
            try
              _adp.locality = p$("#locality-input").value
            catch
              _adp.locality = ""
            console.warn "How did we get to this state? No locality precomputed, no data file"
            postBBLocality()
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
        _adp.locality = result[0].formatted_address
        # Render the carto map
        loc = result[0].geometry.location
        lat = loc.lat()
        lng = loc.lng()
        bounds = result[0].geometry.viewport
        try
          bbEW = bounds.R
          bbNS = bounds.j
          boundingBox =
            nw: [bbEW.j, bbNS.R]
            ne: [bbEW.j, bbNS.j]
            se: [bbEW.R, bbNS.R]
            sw: [bbEW.R, bbNS.j]
            north: bbEW.j
            south: bbEW.R
            east: bbNS.j
            west: bbNS.R
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
      $("#carto-map-container").empty()
      mapOptions =
        selector: "#carto-map-container"
        bsGrid: ""
      $(mapOptions.selector).empty()

      postRunCallback = ->
        stopLoad()
        false

      if geo.dataTable?
        getCanonicalDataCoords geo.dataTable, mapOptions, ->
          postRunCallback()
      else
        mapOptions.boundingBox = overlayBoundingBox
        p = new Point centerLat, centerLng
        createMap2 [p], mapOptions, ->
          postRunCallback()
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
    $("#transect-input-container").html transectInput
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


getCanonicalDataCoords = (table, options = _adp.defaultMapOptions, callback = createMap2) ->
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
        #point = pointStringToPoint textPoint
        point = pointStringToLatLng textPoint
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
        point.infoWindow = data
        coords.push point
        info.push data
      # Push the coordinates and the formatted infowindows
      dataAttrs.coords = coords
      dataAttrs.markerInfo = info
      console.info "Calling back with", coords, options
      callback coords, options
      # callback coords, info
    .error (result, status) ->
      # On error, return direct from file upload
      if dataAttrs?.coords?
        callback dataAttrs.coords, options
        # callback dataAttrs.coords, dataAttrs.markerInfo
      else
        stopLoadError "Couldn't get bounding coordinates from data"
        console.error "No valid coordinates accessible!"
  false

getUploadIdentifier = ->
  if isNull _adp.uploadIdentifier
    if isNull _adp.projectId
      author = $.cookie("#{adminParams.domain}_link")
      if isNull _adp.projectIdentifierString
        seed = if isNull p$("#project-title").value then randomString(16) else p$("#project-title").value
        projectIdentifier = "t" + md5(seed + author)
        _adp.projectIdentifierString = projectIdentifier
      _adp.projectId = md5("#{projectIdentifier}#{author}#{Date.now()}")
    _adp.uploadIdentifier = md5 "#{user}#{_adp.projectId}"
  _adp.uploadIdentifier



bootstrapUploader = (uploadFormId = "file-uploader", bsColWidth = "col-md-4") ->
  ###
  # Bootstrap the file uploader into existence
  ###
  # Check for the existence of the uploader form; if it's not there,
  # create it
  selector = "##{uploadFormId}"
  author = $.cookie("#{adminParams.domain}_link")
  uploadIdentifier = getUploadIdentifier()
  projectIdentifier = _adp.projectIdentifierString
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
    window.dropperParams.uploadPath = "uploaded/#{getUploadIdentifier()}/"
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
          pathPrefix = "helpers/js-dragdrop/uploaded/#{getUploadIdentifier()}/"
          # path = "helpers/js-dragdrop/#{result.full_path}"
          # Replace full_path and thumb_path with "wrote"
          fileName = result.full_path.split("/").pop()
          thumbPath = result.wrote_thumb
          mediaType = result.mime_provided.split("/")[0]
          longType = result.mime_provided.split("/")[1]
          linkPath = if file.size < 5*1024*1024 or mediaType isnt "image" then "#{pathPrefix}#{result.wrote_file}" else "#{pathPrefix}#{thumbPath}"
          previewHtml = switch mediaType
            when "image"
              """
              <div class="uploaded-media center-block" data-system-file="#{fileName}">
                <img src="#{linkPath}" alt='Uploaded Image' class="img-circle thumb-img img-responsive"/>
                  <p class="text-muted">
                    #{file.name} -> #{fileName}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Image
                </a>)
                  </p>
              </div>
              """
            when "audio" then """
            <div class="uploaded-media center-block" data-system-file="#{fileName}">
              <audio src="#{linkPath}" controls preload="auto">
                <span class="glyphicon glyphicon-music"></span>
                <p>
                  Your browser doesn't support the HTML5 <code>audio</code> element.
                  Please download the file below.
                </p>
              </audio>
              <p class="text-muted">
                #{file.name} -> #{fileName}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Media
                </a>)
              </p>
            </div>
            """
            when "video" then """
            <div class="uploaded-media center-block" data-system-file="#{fileName}">
              <video src="#{linkPath}" controls preload="auto">
                <img src="#{pathPrefix}#{thumbPath}" alt="Video Thumbnail" class="img-responsive" />
                <p>
                  Your browser doesn't support the HTML5 <code>video</code> element.
                  Please download the file below.
                </p>
              </video>
              <p class="text-muted">
                #{file.name} -> #{fileName}
                (<a href="#{linkPath}" class="newwindow" download="#{file.name}">
                  Original Media
                </a>)
              </p>
            </div>
            """
            else
              """
              <div class="uploaded-media center-block" data-system-file="#{fileName}" data-link-path="#{linkPath}">
                <span class="glyphicon glyphicon-file"></span>
                <p class="text-muted">#{file.name} -> #{fileName}</p>
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


excelHandler = (path, hasHeaders = true, skipGeoHandler = false) ->
  startLoad()
  $("#validator-progress-container").remove()
  renderValidateProgress()
  helperApi = "#{helperDir}excelHelper.php"
  correctedPath = path
  if path.search helperDir isnt -1
    # The helper file lives in /helpers/ so we want to remove that
    console.info "removing '#{helperDir}'"
    correctedPath = path.slice helperDir.length
  console.info "Pinging for #{correctedPath}"
  args = "action=parse&path=#{correctedPath}&sheets=Samples"
  $.get helperApi, args, "json"
  .done (result) ->
    console.info "Got result", result
    if result.status is false
      bsAlert "There was a problem verifying your upload. Please try again.", "danger"
      stopLoadError "There was a problem processing your data"
      return false
    singleDataFileHelper path, ->
      $("#upload-data").attr "disabled", "disabled"
      nameArr = path.split "/"
      dataFileParams.hasDataFile = true
      dataFileParams.fileName = nameArr.pop()
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
      _adp.parsedUploadedData = result.data
      unless skipGeoHandler
        newGeoDataHandler(result.data)
      stopLoad()
  .fail (result, error) ->
    console.error "Couldn't POST"
    console.warn result, error
    stopLoadError()
  false

csvHandler = (path) ->
  nameArr = path.split "/"
  dataFileParams.hasDataFile = true
  dataFileParams.fileName = nameArr.pop()
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
  serverPath = "#{helperDir}/js-dragdrop/uploaded/#{_adp.uploadIdentifier}/#{removeFile}"
  # Server will validate the user, and only a user can remove their
  # own files
  args = "action=removefile&path=#{encode64 serverPath}&user=#{user}"
  # TODO FINISH THIS
  false

newGeoDataHandler = (dataObject = new Object(), skipCarto = false) ->
  ###
  # Data expected in form
  #
  # Obj {ROW_INDEX: {"col1":"data", "col2":"data"}}
  #
  # FIMS data format:
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
  #
  # Requires columns "decimalLatitude", "decimalLongitude", "coordinateUncertaintyInMeters"
  ###
  try
    unless geo.geocoder?
      try
        geo.geocoder = new google.maps.Geocoder
    try
      sampleRow = dataObject[0]
    catch
      toastStatusMessage "Your data file was malformed, and could not be parsed. Please try again."
      removeDataFile()
      return false

    if isNull(sampleRow.decimalLatitude) or isNull(sampleRow.decimalLongitude) or isNull(sampleRow.coordinateUncertaintyInMeters)
      toastStatusMessage "Data are missing required geo columns. Please reformat and try again."
      missingStatement = "You're missing "
      missingRequired = new Array()
      if isNull sampleRow.decimalLatitude
        missingRequired.push "decimalLatitude"
      if isNull sampleRow.decimalLongitude
        missingRequired.push "decimalLongitude"
      if isNull sampleRow.coordinateUncertaintyInMeters
        missingRequired.push "coordinateUncertaintyInMeters"
      missingStatement += if missingRequired.length > 1 then "some required columns: " else "a required column: "
      missingHtml = missingRequired.join "</code>, <code>"
      missingStatement += "<code>#{missingHtml}</code>"
      bsAlert missingStatement, "danger"
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
              stopLoadBarsError null, "Detected an invalid number for #{column} at row #{n} ('#{value}')"
              return false
            if column is "decimalLatitude" and -90 > value > 90
              stopLoadBarsError null, "Detected an invalid latitude #{value} at row #{n}"
              return false
            if column is "decimalLongitude" and -180 > value > 180
              stopLoadBarsError null, "Detected an invalid longitude #{value} at row #{n}"
              return false
            if column is "coordinateUncertaintyInMeters" and value <= 0
              stopLoadBarsError null, "Coordinate uncertainty must be >= 0 at row #{n}"
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

    if isNull _adp.projectIdentifierString
      # Create a project identifier from the user hash and project title
      projectIdentifier = "t" + md5(p$("#project-title").value + author)
      _adp.projectIdentifierString = projectIdentifier
    else
      projectIdentifier = _adp.projectIdentifierString
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
    center = getMapCenter(geo.boundingBox)
    geo.reverseGeocode center.lat, center.lng, geo.boundingBox, (locality) ->
      _adp.locality = locality
      dataAttrs.locality = locality
      try
        p$("#locality-input").value = locality
        p$("#locality-input").readonly = true

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
      dataSrc: "#{helperDir}#{dataFileParams.filePath}"
    unless _adp?.data?
      unless _adp?
        window._adp = new Object()
      window._adp.data = new Object()
    _adp.data.pushDataUpload = totalData
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
      _adp.data.dataObj = validatedData
      _adp.data.taxa = new Object()
      _adp.data.taxa.list = taxonList
      _adp.data.taxa.clades = cladeList
      _adp.data.taxa.validated = validatedData.validated_taxa
      unless skipCarto
        geo.requestCartoUpload validatedData, projectIdentifier, "create", (table, coords, options) ->
          #mapOverlayPolygon validatedData.transectRing
          createMap2 coords, options, ->
            # Reset the biulder
            window.mapBuilder.points = new Array()
            $("#init-map-build").attr "disabled", "disabled"
            $("#init-map-build .points-count").text window.mapBuilder.points.length
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


checkInitLoad = (callback) ->
  $("#please-wait-prefill").remove()
  projectId = uri.o.param "id"
  unless isNull projectId
    loadEditor projectId
  else
    # Load the input state
    if typeof callback is "string"
      fragment = callback
    else if typeof callback is "object"
      fragment = "#{callback.do}:#{callback.prop}"
    else
      fragment = uri.o.attr "fragment"
    unless isNull fragment
      fragmentSettings = fragment.split ":"
      console.info "Looking at fragment", fragment, fragmentSettings
      switch fragmentSettings[0]
        when "edit"
          loadEditor fragmentSettings[1]
        when "action"
          switch fragmentSettings[1]
            when "show-editable"
              loadEditor()
            when "create-project"
              loadCreateNewProject()
            when "show-viewable"
              loadProjectBrowser()
            when "show-su-viewable"
              loadSUProjectBrowser()
        when "home"
          populateAdminActions()
    else if typeof callback is "function"
      callback()
  false


window.onpopstate = (event) ->
  # https://developer.mozilla.org/en-US/docs/Web/Events/popstate
  # https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
  console.log "State popped", event, event.state
  checkInitLoad(event.state)
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
  $("paper-icon-button[icon='icons:dashboard']")
  .removeAttr("data-href")
  .unbind("click")
  .click ->
    populateAdminActions()

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
    url = "#{uri.urlString}admin-page.html#edit:#{projectId}"
    state =
      do: "edit"
      prop: projectId
    history.pushState state, "Editing ##{projectId}", url
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
              delay 1000, ->
                loadProject projectId
              return false
            # No edit or view permissions, and project isn't public.
            # Give generic error
            alertBadProject opid
            return false
          # Populate the UI, prefilling the data
          ## DO THE THING
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
          _adp.projectData = project
          _adp.fetchResult = result
          ## End Bindings
          ## Real DOM stuff
          # Userlist
          userHtml = ""
          for user in project.access_data.total
            try
              uid = project.access_data.composite[user]["user_id"]
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
              <iron-icon icon="icons:visibility"></iron-icon>
              """
            userHtml += """
            <tr class="user-permission-list-row" data-user="#{uid}">
              <td colspan="5">#{user}</td>
              <td class="text-center user-current-permission">#{icon}</td>
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
          try
            bb = Object.toArray cartoParsed.bounding_polygon
          catch
            bb = null
          createMapOptions =
            boundingBox: bb
            classes: "carto-data map-editor"
            bsGrid: ""
            skipPoints: false
            skipHull: false
            onlyOne: true
          geo.mapOptions = createMapOptions
          unless cartoParsed.bounding_polygon?.paths?
            googleMap = """
                  <google-map id="transect-viewport" latitude="#{project.lat}" longitude="#{project.lng}" fit-to-markers map-type="hybrid" disable-default-ui  apiKey="#{gMapsApiKey}">
                  </google-map>
            """
          googleMap ?= ""
          geo.googleMapWebComponent = googleMap
          deleteCardAction = if result.user.is_author then """
          <div class="card-actions">
                <paper-button id="delete-project"><iron-icon icon="icons:delete" class="material-red"></iron-icon> Delete this project</paper-button>
              </div>
          """ else ""
          # The actual HTML
          mdNotes = if isNull(project.sample_notes) then "*No notes for this project*" else project.sample_notes.unescape()
          noteHtml = """
          <h3>Project Notes</h3>
          <ul class="nav nav-tabs" id="markdown-switcher">
            <li role="presentation" class="active" data-view="md"><a href="#markdown-switcher">Preview</a></li>
            <li role="presentation" data-view="edit"><a href="#markdown-switcher">Edit</a></li>
          </ul>
          <iron-autogrow-textarea id="project-notes" class="markdown-pair project-param" rows="3" data-field="sample_notes" hidden #{conditionalReadonly}>#{project.sample_notes}</iron-autogrow-textarea>
          <marked-element class="markdown-pair" id="note-preview">
            <div class="markdown-html"></div>
            <script type="text/markdown">#{mdNotes}</script>
          </marked-element>
          """
          mdFunding = if isNull(project.extended_funding_reach_goals) then "*No funding reach goals*" else project.extended_funding_reach_goals.unescape()
          fundingHtml = """
          <ul class="nav nav-tabs" id="markdown-switcher-funding">
            <li role="presentation" class="active" data-view="md"><a href="#markdown-switcher-funding">Preview</a></li>
            <li role="presentation" data-view="edit"><a href="#markdown-switcher-funding">Edit</a></li>
          </ul>
          <iron-autogrow-textarea id="project-funding" class="markdown-pair project-param" rows="3" data-field="extended_funding_reach_goals" hidden #{conditionalReadonly}>#{project.extended_funding_reach_goals}</iron-autogrow-textarea>
          <marked-element class="markdown-pair" id="preview-funding">
            <div class="markdown-html"></div>
            <script type="text/markdown">#{mdFunding}</script>
          </marked-element>
          """
          try
            authorData = JSON.parse project.author_data
            creation = new Date(toInt authorData.entry_date)
          catch
            authorData = new Object()
            creation = new Object()
            creation.toLocaleString = ->
              return "Error retrieving creation time"
          monthPretty = ""
          months = project.sampling_months.split(",")
          monthsReal = new Array()
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
              monthsReal.push month
              month = dateMonthToString month
            monthPretty += month
          i = 0
          # months = monthsReal
          yearPretty = ""
          years = project.sampling_years.split(",")
          yearsReal = new Array()
          i = 0
          for year in years
            ++i
            if isNumber year
              yearsReal.push toInt year
              if i > 1 and i is years.length
                if yearsReal.length > 2
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
          years = yearsReal
          if toInt(project.sampled_collection_start) > 0
            d1 = new Date toInt project.sampled_collection_start
            d2 = new Date toInt project.sampled_collection_end
            collectionRangePretty = "#{dateMonthToString d1.getMonth()} #{d1.getFullYear()} &#8212; #{dateMonthToString d2.getMonth()} #{d2.getFullYear()}"
          else
            collectionRangePretty = "<em>(no data)</em>"
          if months.length is 0 or isNull monthPretty then monthPretty = "<em>(no data)</em>"
          if years.length is 0 or isNull yearPretty then yearPretty = "<em>(no data)</em>"
          html = """
          <h2 class="clearfix newtitle col-xs-12">Managing #{project.project_title} #{icon} <paper-icon-button icon="icons:visibility" class="click" data-href="#{uri.urlString}/project.php?id=#{opid}" data-toggle="tooltip" title="View in Project Viewer" data-newtab="true"></paper-icon-button><br/><small>Project ##{opid}</small></h2>
          #{publicToggle}
          <section id="manage-users" class="col-xs-12 col-md-4 pull-right">
            <paper-card class="clearfix" heading="Project Collaborators" elevation="2">
              <div class="card-content">
                <table class="table table-striped table-condensed table-responsive table-hover clearfix" id="permissions-table">
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
            <paper-input readonly label="Project Creation" value="#{creation.toLocaleString()}" id="project_creation" class="author-param" data-key="entry_date" data-value="#{authorData.entry_date}"></paper-input>
            <paper-input readonly label="Project ARK" value="#{project.project_obj_id}" id="project_creation" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Title" value="#{project.project_title}" id="project-title" data-field="project_title"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Primary Pathogen" value="#{project.disease}" data-field="disease"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="PI Lab" value="#{project.pi_lab}" id="project-title" data-field="pi_lab"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Reference" value="#{project.reference_id}" id="project-reference" data-field="reference_id"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Publication DOI" value="#{project.publication}" id="doi" data-field="publication"></paper-input>
            <paper-input #{conditionalReadonly} class="author-param" data-key="name" label="Project Contact" value="#{authorData.name}" id="project-contact"></paper-input>
            <gold-email-input #{conditionalReadonly} class="author-param" data-key="contact_email" label="Contact Email" value="#{authorData.contact_email}" id="contact-email"></gold-email-input>
            <paper-input #{conditionalReadonly} class="author-param" data-key="diagnostic_lab" label="Diagnostic Lab" value="#{authorData.diagnostic_lab}" id="project-lab"></paper-input>
            <paper-input #{conditionalReadonly} class="author-param" data-key="affiliation" label="Affiliation" value="#{authorData.affiliation}" id="project-affiliation"></paper-input>
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
                  <span class="toggle-off-label iron-label">Append Data
                    <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip" title="If you upload a dataset, append all rows as additional data"></span>
                  </span>
                  <paper-toggle-button id="replace-data-toggle" checked disabled>Replace Data</paper-toggle-button>
                  <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip" title="If you upload data, archive current data and only have new data parsed"></span>
                </div>
                <p><strong>PLEASE NOTE UPLOADS ARE CURRENTLY DISABLED HERE PENDING DEBUGGING</strong></p>
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
                <paper-input readonly label="Sampled Species" value="#{project.sampled_species.split(",").sort().join(", ")}"></paper-input>
                <paper-input readonly label="Sampled Clades" value="#{project.sampled_clades.split(",").sort().join(", ")}"></paper-input>
                <p class="text-muted">
                  <span class="glyphicon glyphicon-info-sign"></span> There are #{project.sampled_species.split(",").length} species in this dataset, across #{project.sampled_clades.split(",").length} clades
                </p>
              <h4>Sample Metrics</h4>
                <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were taken from #{collectionRangePretty}</p>
                <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were taken in #{monthPretty}</p>
                <p class="text-muted"><span class="glyphicon glyphicon-calendar"></span> Data were sampled in #{yearPretty}</p>
                <p class="text-muted"><iron-icon icon="icons:language"></iron-icon> The effective project center is at (#{roundNumberSigfig project.lat, 6}, #{roundNumberSigfig project.lng, 6}) with a sample radius of #{project.radius}m and a resulting locality <strong class='locality'>#{project.locality}</strong></p>
                <p class="text-muted"><iron-icon icon="editor:insert-chart"></iron-icon> The dataset contains #{project.disease_positive} positive samples (#{roundNumber(project.disease_positive * 100 / project.disease_samples)}%), #{project.disease_negative} negative samples (#{roundNumber(project.disease_negative *100 / project.disease_samples)}%), and #{project.disease_no_confidence} inconclusive samples (#{roundNumber(project.disease_no_confidence * 100 / project.disease_samples)}%)</p>
              <h4 id="map-header">Locality &amp; Transect Data</h4>
                <div id="carto-map-container" class="clearfix">
                #{googleMap}
                </div>
            <h3>Project Meta Parameters</h3>
              <h4>Project funding status</h4>
                #{fundingHtml}
                <div class="row">
                  <span class="pull-left" style="margin-top:1.75em;vertical-align:bottom;padding-left:15px">$</span><paper-input #{conditionalReadonly} class="project-param col-xs-11" label="Additional Funding Request" value="#{project.more_analysis_funding_request}" id="more-analysis-funding" data-field="more_analysis_funding_request" type="number"></paper-input>
                </div>
          </section>
          """
          $("#main-body").html html
          if cartoParsed.bounding_polygon?.paths?
            # Draw a map web component
            # https://github.com/GoogleWebComponents/google-map/blob/eecb1cc5c03f57439de6b9ada5fafe30117057e6/demo/index.html#L26-L37
            # https://elements.polymer-project.org/elements/google-map
            # Poly is cartoParsed.bounding_polygon.paths
            centerPoint = new Point project.lat, project.lng
            geo.centerPoint = centerPoint
            geo.mapOptions = createMapOptions
            createMap2 [centerPoint], createMapOptions, (map) ->
              geo.mapOptions.selector = map.selector
              if not $(map.selector).exists()
                do tryReload = ->
                  if $("#map-header").exists()
                    $("#map-header").after map.html
                    googleMap = map.html
                  else
                    delay 250, ->
                      tryReload()
            poly = cartoParsed.bounding_polygon
            googleMap = geo.googleMapWebComponent ? ""
          try
            p$("#project-notes").bindValue = project.sample_notes.unescape()
          try
            p$("#project-funding").bindValue = project.extended_funding_reach_goals.unescape()
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
          ta = p$("#project-funding").textarea
          $(ta).keyup ->
            p$("#preview-funding").markdown = $(this).val()
          $("#markdown-switcher-funding li").click ->
            $("#markdown-switcher-funding li").removeClass "active"
            $(".markdown-pair").removeAttr "hidden"
            $(this).addClass "active"
            switch $(this).attr "data-view"
              when "md"
                $("#project-funding").attr "hidden", "hidden"
              when "edit"
                $("#preview-funding").attr "hidden", "hidden"

          $("#delete-project").click ->
            confirmButton = """
            <paper-button id="confirm-delete-project" class="materialred">
              <iron-icon icon="icons:warning"></iron-icon> Confirm Project Deletion
            </paper-button>
            """
            $(this).replaceWith confirmButton
            $("#confirm-delete-project").click ->
              startLoad()
              el = this
              args = "perform=delete&id=#{project.id}"
              $.post adminParams.apiTarget, args, "json"
              .done (result) ->
                if result.status is true
                  stopLoad()
                  toastStatusMessage "Successfully deleted Project ##{project.project_id}"
                  delay 1000, ->
                    populateAdminActions()
                else
                  stopLoadError result.human_error
                  $(el).remove()
              .error (result, status) ->
                console.error "Server error", result, status
                stopLoadError "Error deleting project"
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
            saveEditorData(true)
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
            popManageUserAccess(_adp.projectData)
          $(".danger-toggle").on "iron-change", ->
            if $(this).get(0).checked
              $(this).find("iron-icon").addClass("material-red")
            else
              $(this).find("iron-icon").removeClass("material-red")
          # Load more detailed data from CartoDB
          console.info "Getting carto data with id #{project.carto_id} and options", createMapOptions
          getProjectCartoData project.carto_id, createMapOptions
          try
            # TODO TEST AND FIX UPLOADS
            window.dropperParams.dropzone.disable()
          catch e
            delay 1500, ->
              try
                # TODO TEST AND FIX UPLOADS
                window.dropperParams.dropzone.disable()
        catch e
          stopLoadError "There was an error loading your project"
          console.error "Unhandled exception loading project! #{e.message}"
          console.warn e.stack
          loadEditor()
          return false
      .error (result, status) ->
        stopLoadError "We couldn't load your project. Please try again."
        loadEditor()
    false

  unless projectPreload?
    do showEditList = ->
      ###
      # Show a list of icons for editable projects. Blocked on #22, it's
      # just based on authorship right now.
      ###
      url = "#{uri.urlString}admin-page.html#action:show-editable"
      state =
        do: "action"
        prop: "show-editable"
      history.pushState state, "Viewing Editable Projects", url
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
        publicList = new Array()
        for k, projectId of result.public_projects
          publicList.push projectId
        authoredList = new Array()
        for k, projectId of result.authored_projects
          authoredList.push projectId
        for projectId, projectTitle of result.projects
          accessIcon = if projectId in publicList then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
          icon = if projectId in authoredList then """<iron-icon icon="social:person" data-toggle="tooltip" title="Author"></iron-icon>""" else """<iron-icon icon="social:group" data-toggle="tooltip" title="Collaborator"></iron-icon>"""
          if projectId in authoredList
            html = """
            <li>
              <button class="btn btn-primary" data-project="#{projectId}">
                #{accessIcon} #{projectTitle} / ##{projectId.substring(0,8)}
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




popManageUserAccess = (project = _adp.projectData, result = _adp.fetchResult) ->
  verifyLoginCredentials (credentialResult) ->
    # For each user in the access list, give some toggles
    userHtml = ""
    for user in project.access_data.total
      uid = project.access_data.composite[user]["user_id"]
      theirHtml = "#{user} <span class='set-permission-block' data-user='#{uid}'>"
      isAuthor = user is project.access_data.author
      isEditor =  user in project.access_data.editors_list
      isViewer = not isEditor
      editDisabled = if isEditor or isAuthor then "disabled" else "data-toggle='tooltip' title='Make Editor'"
      viewerDisabled = if isViewer or isAuthor then "disabled" else "data-toggle='tooltip' title='Make Read-Only'"
      authorDisabled = if isAuthor then "disabled" else "data-toggle='tooltip' title='Grant Ownership'"
      currentRole = if isAuthor then "author" else if isEditor then "edit" else "read"
      currentPermission = "data-current='#{currentRole}'"
      theirHtml += """
      <paper-icon-button icon="image:edit" #{editDisabled} class="set-permission" data-permission="edit" data-user="#{uid}" #{currentPermission}> </paper-icon-button>
      <paper-icon-button icon="icons:visibility" #{viewerDisabled} class="set-permission" data-permission="read" data-user="#{uid}" #{currentPermission}> </paper-icon-button>
      """
      # Only the current author can change authors
      if result.user.is_author
        theirHtml += """
        <paper-icon-button icon="social:person" #{authorDisabled} class="set-permission" data-permission="author" data-user="#{uid}" #{currentPermission}> </paper-icon-button>
        """
      if result.user.has_edit_permissions and user isnt isAuthor and user isnt result.user
        # Delete button
        theirHtml += """
        <paper-icon-button icon="icons:delete" class="set-permission" data-permission="delete" data-user="#{uid}" #{currentPermission}>
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
    userEmail = user
    $(".set-permission")
    .unbind()
    .click ->
      user = $(this).attr "data-user"
      permission = $(this).attr "data-permission"
      current = $(this).attr "data-current"
      el = this
      # Handle it
      if permission isnt "delete"
        permissionsObj =
          changes:
            0:
              newRole: permission
              currentRole: current
              uid: user
      else
        # Confirm the delete
        try
          confirm = $(this).attr("data-confirm").toBool()
        catch
          confirm = false
        unless confirm
          $(this)
          .addClass "extreme-danger"
          .attr "data-confirm", "true"
          return false
        permissionsObj =
          delete:
            0:
              currentRole: current
              uid: user
      startLoad()
      j64 = jsonTo64 permissionsObj
      args = "perform=editaccess&project=#{window.projectParams.pid}&deltas=#{j64}"
      # Push needs to be server authenticated, to prevent API spoofs
      console.log "Would push args to", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
      $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
      .done (result) ->
        console.log "Server permissions alter said", result
        if result.status isnt true
          error = result.human_error ? result.error ? "We couldn't update user permissions"
          stopLoadError error
          return false
        # Update UI
        if permission isnt "delete"
          $(".set-permission-block[data-user='#{user}'] paper-icon-button[data-permission='#{permission}']")
          .attr "disabled", "disabled"
          .attr "data-current", permission
          $(".set-permission-block[data-user='#{user}'] paper-icon-button:not([data-permission='#{permission}'])").removeAttr "disabled"
          useIcon = $(".set-permission-block[data-user='#{user}'] paper-icon-button[data-permission='#{permission}']").attr "icon"
          $(".user-permission-list-row[data-user='#{{user}}'] .user-current-permission iron-icon").attr "icon", useIcon
          toastStatusMessage "#{user} granted #{permission} permissions"
          # TODO Change internal permissions list
        else
          # Remove the row
          $(".set-permission-block[data-user='#{user}']").parent().remove()
          $(".user-permission-list-row[data-user='#{{user}}']").remove()
          toastStatusMessage "Removed #{user} from project ##{window.projectParams.pid}"
          objPrefix = if current is "read" then "viewers" else "editors"
          delete _adp.projectData.access_data.composite[userEmail]
          for k, userObj of _adp.projectData.access_data["#{objPrefix}_list"]
            try
              if typeof userObj isnt "object" then continue
              if userObj.user_id is user
                delete  _adp.projectData.access_data["#{objPrefix}_list"][k]
          for k, userObj of _adp.projectData.access_data[objPrefix]
            try
              if typeof userObj isnt "object" then continue
              if userObj.user_id is user
                delete  _adp.projectData.access_data[objPrefix][k]
        # Update _adp.projectData.access_data for the saving
        _adp.projectData.access_data.raw = result.new_access_saved
        stopLoad()
      .error (result, status) ->
        console.error "Server error", result, status
        stopLoadError "Problem changing permissions"
      false
    $(".add-user")
    .unbind()
    .click ->
      showAddUserDialog(project.access_data.total)
      false
    # Open the dialog
    safariDialogHelper "#user-setter-dialog"
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
    searchHelper = ->
      search = $("#search-user").val()
      if isNull search
        $("#user-search-result-container").prop "hidden", "hidden"
      else
        $.post "#{uri.urlString}/api.php", "action=search_users&q=#{search}", "json"
        .done (result) ->
          console.info result
          users = Object.toArray result.result
          if users.length > 0
            $("#user-search-result-container").removeAttr "hidden"
            html = ""
            for user in users
              # TODO check if user already has access
              if _adp.projectData.access_data.composite[user.email]?
                prefix = """
                <iron-icon icon="icons:done-all" class="materialgreen round"></iron-icon>
                """
                badge = """
                <paper-badge for="#{user.uid}-email" icon="icons:done-all" label="Already Added"> </paper-badge>
                """
                bonusClass = "noclick"
              else
                prefix = ""
                badge = ""
                bonusClass = ""
              html += """
              <div class="user-search-result #{bonusClass}" data-uid="#{user.uid}" id="#{user.uid}-result">
                <span class="email search-result-detail" id="#{user.uid}-email">#{prefix}#{user.email}</span>
                  |
                <span class="name search-result-detail" id="#{user.uid}-name">#{user.full_name}</span>
                  |
                <span class="user search-result-detail" id="#{user.uid}-handle">#{user.handle}</span></div>
              """
            $("#user-search-result-container").html html
            $(".user-search-result:not(.noclick)").click ->
              uid = $(this).attr "data-uid"
              console.info "Clicked on #{uid}"
              email = $(this).find(".email").text()
              unless _adp?.currentQueueUids?
                unless _adp?
                  window._adp = new Object()
                _adp.currentQueueUids = new Array()
              for user in $("#user-add-queue .list-add-users")
                _adp.currentQueueUids.push $(user).attr "data-uid"
              unless email in refAccessList
                unless uid in _adp.currentQueueUids
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
          else
            $("#user-search-result-container").prop "hidden", "hidden"
        .error (result, status) ->
          console.error result, status
    searchHelper.debounce()

  # bind add button
  $("#add-user").click ->
    startLoad()
    toAddUids = new Array()
    toAddEmails = new Array()
    for user in $("#user-add-queue .list-add-users")
      toAddUids.push $(user).attr "data-uid"
      toAddEmails.push user
    if toAddUids.length < 1
      toastStatusMessage "Please add at least one user to the access list."
      return false
    console.info "Saving list of #{toAddUids.length} UIDs to #{window.projectParams.pid}", toAddUids
    jsonUids =
      add: toAddUids
    uidArgs = jsonTo64 jsonUids
    args = "perform=editaccess&project=#{window.projectParams.pid}&deltas=#{uidArgs}"
    # Push needs to be server authenticated, to prevent API spoofs
    console.log "Would push args to", "#{adminParams.apiTarget}?#{args}"
    $.post adminParams.apiTarget, args, "json"
    .done (result) ->
      console.log "Server permissions said", result
      if result.status isnt true
        error = result.human_error ? result.error ? "We couldn't update user permissions"
        stopLoadError error
        return false
      stopLoad()
      tense = if toAddUids.length is 1 then "viewer" else "viewers"
      toastStatusMessage "Successfully added #{toAddUids.length} #{tense} to the project"
      # Update the UI with the new list
      $("#user-add-queue").empty()
      ## Add to manage users table
      icon = """
            <iron-icon icon="icons:visibility"></iron-icon>
      """
      i = 0
      for uid in toAddUids
        user = toAddEmails[i]
        ++i
        html = """
            <tr class="user-permission-list-row" data-user="#{uid}">
              <td colspan="5">#{user}</td>
              <td class="text-center user-current-permission">#{icon}</td>
            </tr>
        """
        $("#permissions-table").append html
        ## Update _adp.projectData.access_data
        userObj =
          email: user
          user_id: uid
          permission: "READ"
        _adp.projectData.access_data.total.push user
        _adp.projectData.access_data.viewers_list.push user
        _adp.projectData.access_data.viewers.push userObj
        _adp.projectData.access_data.raw = result.new_access_saved
        _adp.projectData.access_data.composite[user] = userObj
      # Dismiss the dialog
      p$("#add-new-user").close()
    .error (result, status) ->
      console.error "Server error", result, status
  false



getProjectCartoData = (cartoObj, mapOptions) ->
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
    try
      workingMap = geo.googleMapWebComponent.slice 0, truncateLength
    catch
      workingMap = "<google-map>"
    pointArr = new Array()
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      lat = geoJson.coordinates[0]
      lng = geoJson.coordinates[1]
      point = new Point lat, lng
      point.infoWindow = new Object()
      point.data = row
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
      infoWindow = """
        <p>
          <em>#{row.genus} #{row.specificepithet}</em> #{note}
          <br/>
          Tested <strong>#{row.diseasedetected}</strong> for #{row.diseasetested}
        </p>
      """
      point.infoWindow.html = infoWindow
      marker = """
      <google-map-marker latitude="#{lat}" longitude="#{lng}" data-disease-detected="#{row.diseasedetected}">
      #{infoWindow}
      </google-map-marker>
      """
      # $("#transect-viewport").append marker
      workingMap += marker
      pointArr.push point
    # p$("#transect-viewport").resize()
    unless cartoData?.bounding_polygon?.paths? and cartoData?.bounding_polygon?.fillColor?
      try
        _adp.canonicalHull = createConvexHull pointArr, true
        try
          cartoObj = new Object()
          unless cartoData?
            cartoData = new Object()
          unless cartoData.bounding_polygon?
            cartoData.bounding_polygon = new Object()
          cartoData.bounding_polygon.paths = _adp.canonicalHull.hull
          cartoData.bounding_polygon.fillOpacity ?= defaultFillOpacity
          cartoData.bounding_polygon.fillColor ?= defaultFillColor
          _adp.projectData.carto_id = JSON.stringify cartoData
          bsAlert "We've updated some of your data automatically. Please save the project before continuing.", "warning"
    totalRows = result.parsed_responses[0].total_rows ? 0
    if pointArr.length > 0 or mapOptions?.boundingBox?.length > 0
      mapOptions.skipHull = false
      if pointArr.length is 0
        center = geo.centerPoint ? [mapOptions.boundingBox[0].lat, mapOptions.boundingBox[0].lng] ? [window.locationData.lat, window.locationData.lng]
        pointArr.push center
      mapOptions.onClickCallback = ->
        console.log "No callback for data-provided maps."
      createMap2 pointArr, mapOptions, (map) ->
        after = """
        <p class="text-muted"><span class="glyphicon glyphicon-info-sign"></span> There are <span class='carto-row-count'>#{totalRows}</span> sample points in this dataset</p>
        """
        $(map.selector).after
        stopLoad()
    else
      console.info "Classic render.", mapOptions, pointArr.length
      workingMap += """
      </google-map>
      <p class="text-muted"><span class="glyphicon glyphicon-info-sign"></span> There are <span class='carto-row-count'>#{totalRows}</span> sample points in this dataset</p>
      """
      $("#transect-viewport").replaceWith workingMap
      stopLoad()
  .fail (result, status) ->
    console.error "Couldn't talk to back end server to ping carto!"
    stopLoadError "There was a problem communicating with the server. Please try again in a bit. (E-002)"
  window.dataFileparams = cartoData.raw_data
  if cartoData.raw_data.hasDataFile
    # We already have a data file
    filePath = cartoData.raw_data.filePath
    if filePath.search(helperDir) is -1
      filePath = "#{helperDir}#{filePath}"
    html = """
    <p>
      Your project already has data associated with it. <span id="last-modified-file"></span>
    </p>
    <button id="download-project-file" class="btn btn-primary center-block click download-file" data-href="#{filePath}"><iron-icon icon="icons:cloud-download"></iron-icon> Download File</button>
    <p>You can upload more data below, or replace this existing data.</p>
    """
    $("#data-card .card-content .variable-card-content").html html
    args = "do=get_last_mod&file=#{filePath}"
    console.info "Timestamp: ", "#{uri.urlString}meta.php?#{args}"
    $.get "meta.php", args, "json"
    .done (result) ->
      time = toInt(result.last_mod) * 1000 # Seconds -> Milliseconds
      console.log "Last modded", time, result
      if isNumber time
        t = new Date(time)
        iso = t.toISOString()
        #  Not good enough time resolution to use t.toTimeString().split(" ")[0]
        timeString = "#{iso.slice(0, iso.search("T"))}"
        $("#last-modified-file").text "Last uploaded on #{timeString}."
        bindClicks()
      else
        console.warn "Didn't get a number back to check last mod time for #{filePath}"
      false
    .fail (result, status) ->
      # We don't really care, actually.
      console.warn "Couldn't get last mod time for #{filePath}"
      false
  else
    # We don't already have a data file
    $("#data-card .card-content .variable-card-content").html "<p>You can upload data to your project here:</p>"
    $("#append-replace-data-toggle").attr "hidden", "hidden"
  bootstrapUploader("data-card-uploader", "")
  false


saveEditorData = (force = false, callback) ->
  ###
  # Actually do the file saving
  ###
  startLoad()
  $(".hanging-alert").remove()
  if force or not localStorage._adp?
    postData = _adp.projectData
    try
      postData.access_data = _adp.projectData.access_data.raw
    # Alter this based on inputs
    for el in $(".project-param:not([readonly])")
      key = $(el).attr "data-field"
      if isNull key then continue
      postData[key] = p$(el).value
    authorObj = new Object()
    for el in $(".author-param")
      key = $(el).attr "data-key"
      authorObj[key] = $(el).attr("data-value") ? p$(el).value
    postData.author_data = JSON.stringify authorObj
    _adp.postedSaveData = postData
    _adp.postedSaveTimestamp = Date.now()
  else
    postData = localStorage._adp.postedSaveData
    window._adp = localStorage._adp
  # Post it
  console.log "Sending to server", postData
  args = "perform=save&data=#{jsonTo64 postData}"
  $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
  .done (result) ->
    console.info "Save result: server said", result
    unless result.status is true
      error = result.human_error ? result.error ? "There was an error saving to the server"
      stopLoadError "There was an error saving to the server"
      localStorage._adp = _adp
      bsAlert "<strong>Save Error:</strong> #{error}. An offline backup has been made.", "danger"
      console.error result.error
      return false
    stopLoad()
    toastStatusMessage "Save successful"
    # Update the project data
    _adp.projectData = result.project
    delete localStorage._adp
  .error (result, status) ->
    stopLoadError "Sorry, there was an error communicating with the server"
    localStorage._adp = _adp
    bsAlert "<strong>Save Error</strong>: We had trouble communicating with the server and your data was NOT saved. Please try again in a bit. An offline backup has been made.", "danger"
    console.error result, status
  .always ->
    if typeof callback is "function"
      callback()
  false


$ ->
  if localStorage._adp?.postedSaveData?
    d = new Date localStorage._adp.postedSaveTimestamp
    alertHtml = """
    <strong>You have offline save information</strong> &#8212; did you want to save it?
    <br/><br/>
    Project ##{localStorage._adp.postedSaveData.project_id} on #{d.toLocaleDateString()} at #{d.toLocaleTimeString()}
    <br/><br/>
    <button class="btn btn-success" id="offline-save">
      Save Now &amp; Refresh Page
    </button>
    """
    bsAlert alertHtml, "info"
    $("#offline-save").click ->
      saveEditorData false,  ->
        document.location.reload(true)

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
  url = "#{uri.urlString}admin-page.html#action:show-viewable"
  state =
    do: "action"
    prop: "show-viewable"
  history.pushState state, "Viewing Personal Project List", url
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
      icon = if projectId in publicList then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
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
  # We'll ultimately have some slightly better integrated admin viewer
  # for projects, but for now we'll just run with the redirect
  goTo "#{uri.urlString}project.php?id=#{projectId}"
  false


loadSUProjectBrowser = ->
  url = "#{uri.urlString}admin-page.html#action:show-su-viewable"
  state =
    do: "action"
    prop: "show-su-viewable"
  history.pushState state, "Viewing Superuser Project List", url
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
  _adp.validationDataObject = dataObject
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



stopLoadBarsError = (currentTimeout, message) ->
  try
    clearTimeout currentTimeout
  $("#validator-progress-container paper-progress[indeterminate]")
  .addClass "error-progress"
  .removeAttr "indeterminate"
  others = $("#validator-progress-container paper-progress:not([indeterminate])")
  for el in others
    if p$(el).value isnt p$(el).max
      $(el).addClass "error-progress"
      $(el).find("#primaryProgress").css "background", "#F44336"
  if message?
    bsAlert "<strong>Data Validation Error</strong: #{message}", "danger"
    stopLoadError "There was a problem validating your data"
  false


delayFimsRecheck = (originalResponse, callback) ->
  cookies = encodeURIComponent originalResponse.responses.login_response.cookies
  args = "perform=validate&auth=#{cookies}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Server said", result
    if typeof callback is "function"
      callback()
    else
      console.warn "Warning: delayed recheck had no callback"
  .error (result, status) ->
    console.error "#{status}: Couldn't check status on FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadError "There was a problem validating your data, please try again later"
  false


validateFimsData = (dataObject, callback = null) ->
  ###
  #
  #
  # @param Object dataObject -> object with at least one key, "data",
  #  containing the parsed data to be validated by FIMS
  # @param function callback -> callback function
  ###
  unless typeof _adp?.fims?.expedition?.expeditionId is "number"
    if _adp.hasRunMintCallback is true
      console.error "Couldn't run validateFimsData(); called itself back recursively. There may be a problem with the server. "
      stopLoadError "Couldn't validate your data, please try again later"
      _adp.hasRunMintCallback = false
      return false
    _adp.hasRunMintCallback = false
    console.warn "Haven't minted expedition yet! Minting that first"
    mintExpedition _adp.projectId, p$("#project-title").value, ->
      _adp.hasRunMintCallback = true
      validateFimsData(dataObject, callback)
    return false
  console.info "FIMS Validating", dataObject.data
  $("#data-validation").removeAttr "indeterminate"
  rowCount = Object.size dataObject.data
  p$("#data-validation").max = rowCount * 2
  # Set an animation timer
  timerPerRow = 20
  validatorTimeout = null
  do animateProgress = ->
    val = p$("#data-validation").value
    if val >= rowCount
      # Stop the animation
      clearTimeout validatorTimeout
      return false
    ++val
    p$("#data-validation").value = val
    validatorTimeout = delay timerPerRow, ->
      animateProgress()
  # Format the JSON for FIMS
  data = jsonTo64 dataObject.data
  src = post64 dataObject.dataSrc
  args = "perform=validate&datasrc=#{src}&link=#{_adp.projectId}"
  # Post the object over to FIMS
  console.info "Posting ...", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
  $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
  .done (result) ->
    console.log "FIMS validate result", result
    unless result.status is true
      # Server crazieness
      stopLoadError "There was a problem talking to the server"
      error = result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
      bsAlert "<strong>Server Error:</strong> #{error}", "danger"
      stopLoadBarsError validatorTimeout
      return false
    statusTest = if result.validate_status?.status? then result.validate_status.status else result.validate_status
    if result.validate_status is "FIMS_SERVER_DOWN"
      toastStatusMessage "Validation server is down, proceeding ..."
      bsAlert "<strong>FIMS error</strong>: The validation server is down, we're trying to finish up anyway.", "warning"
    else if statusTest isnt true
      # Bad validation
      overrideShowErrors = false
      stopLoadError "There was a problem with your dataset"
      error = result.validate_status.error ? result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
      if error.length > 255
        overrideShowErrors = true
        error = error.substr(0, 255) + "[...] and more."
      bsAlert "<strong>FIMS reported an error validating your data:</strong> #{error}", "danger"
      stopLoadBarsError validatorTimeout
      # Show all other errors, if there
      errors = result.validate_status.errors
      if Object.size(errors) > 1 or overrideShowErrors
        html = """
        <div class="error-block" id="validation-error-block">
          <p><strong>Your dataset had errors</strong>. Here's a summary:</p>
          <table class="table-responsive table-striped table-condensed table table-bordered table-hover" >
            <thead>
              <tr>
                <th>Error Type</th>
                <th>Error Message</th>
              </tr>
            </thhead>
            <tbody>
        """
        for key, errorType of errors
          for errorClass, errorMessages of errorType
            errorList = "<ul>"
            for k, message of errorMessages
              # Format the message
              message = message.stripHtml(true)
              if /\[(?:((?:"(\w+)"((, )?))*?))\]/m.test(message)
                # Wrap the column names
                message = message.replace /"(\w+)"/mg, "<code>$1</code>"
              errorList += "<li>#{message}</li>"
            errorList += "</ul>"
            html += """
            <tr>
              <td><strong>#{errorClass.stripHtml(true)}</strong></td>
              <td>#{errorList}</td>
            </tr>
            """
        html += """
            </tbody>
          </table>
        </div>
        """
        $("#validator-progress-container").append html
        $("#validator-progress-container").get(0).scrollIntoView()
      return false
    p$("#data-validation").value = p$("#data-validation").max
    clearTimeout validatorTimeout
    # When we're successful, run the dependent callback
    if typeof callback is "function"
      callback(dataObject)
  .error (result, status) ->
    clearTimeout validatorTimeout
    console.error "#{status}: Couldn't upload to FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadError "There was a problem validating your data, please try again later"
    false
  false


mintBcid = (projectId, datasetUri = dataFileParams?.filePath, title, callback) ->
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
  addToExp = _adp?.fims?.expedition?.ark?

  args = "perform=mint&link=#{projectId}&title=#{post64(title)}&file=#{datasetUri}&expedition=#{addToExp}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadError result.human_error
      console.error result.error
      return false
    resultObj = result
  .error (result, status) ->
    resultObj =
      ark: null
      error: status
      human_error: result.responseText
      status: false
    false
  .always ->
    console.info "mintBcid is calling back", resultObj
    callback(resultObj)
  false


mintExpedition = (projectId = _adp.projectId, title = p$("#project-title").value, callback) ->
  ###
  #
  # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
  #
  # Resolve the ARK with
  # https://n2t.net/
  ###
  if typeof callback isnt "function"
    console.warn "mintExpedition() requires a callback function"
    return false
  resultObj = new Object()
  publicProject = p$("#data-encumbrance-toggle").checked
  unless typeof publicProject is "boolean"
    publicProject = false
  args = "perform=create_expedition&link=#{projectId}&title=#{post64(title)}&public=#{publicProject}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Expedition got", result
    unless result.status
      stopLoadError result.human_error
      console.error result.error
      return false
    resultObj = result
    unless _adp?.fims?
      unless _adp?
        window._adp = new Object()
      _adp.fims = new Object()
    _adp.fims.expedition =
      permalink: result.project_permalink
      ark: result.ark
      expeditionId: result.fims_expedition_id
      fimsRawResponse: result.responses.expedition_response
  .error (result, status) ->
    resultObj.ark = null
    false
  .always ->
    console.info "mintExpedition is calling back", resultObj
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
        stopLoadBarsError()
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
  .error (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false
