###
# The main coffeescript file for administrative stuff
# Triggered from admin-page.html
###
window.adminParams = new Object()
adminParams.domain = "amphibiandisease"
adminParams.apiTarget = "admin_api.php"
adminParams.adminPageUrl = "https://#{adminParams.domain}.org/admin-page.html"
adminParams.loginDir = "admin/"
adminParams.loginApiTarget = "#{adminParams.loginDir}async_login_handler.php"

dataFileParams = new Object()
dataFileParams.hasDataFile = false
dataFileParams.fileName = null
dataFileParams.filePath = null

helperDir = "helpers/"
user =  $.cookie "#{adminParams.domain}_link"

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
            View All Projects
        </paper-button>
  """
  $("#admin-actions-block").html adminActions
  $("#show-actions").remove()
  # Remove the previous project progress or any placeholders
  $("main #main-body").empty()
  $("#new-project").click -> loadCreateNewProject()
  $("#edit-project").click -> loadEditor()
  $("#view-project").click -> loadProjectBrowser()



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



loadEditor = ->
  startAdminActionHelper()
  # Get the data ref
  adData.cartoRef = "38544c04-5e56-11e5-8515-0e4fddd5de28"
  geo.init()
  foo()
  false

loadCreateNewProject = ->
  startAdminActionHelper()
  html = """
  <h2 class="new-title">Project Title</h2>
  <paper-input label="Project Title" id="project-title" class="project-field col-md-6 col-xs-12" required autovalidate="true"></paper-input>
  <h2 class="new-title">Project Parameters</h2>
  <section class="project-inputs clearfix">
    <paper-input label="Primary Disease Studied" id="project-disease" class="project-field col-md-6 col-xs-12" required autovalidate="true"></paper-input>
    <paper-input label="Project Reference" id="reference-id" class="project-field col-md-6 col-xs-12"></paper-input>
    <h2 class="new-title">Lab Parameters</h2>
    <paper-input label="Project PI" id="project-pi" class="project-field col-md-6 col-xs-12"  required autovalidate="true"></paper-input>
    <paper-input label="Project Contact" id="project-author" class="project-field col-md-6 col-xs-12"  required autovalidate="true"></paper-input>
    <gold-email-input label="Contact Email" id="author-email" class="project-field col-md-6 col-xs-12"  required autovalidate="true"></gold-email-input>
    <paper-input label="Project Lab" id="project-lab" class="project-field col-md-6 col-xs-12"  required autovalidate="true"></paper-input>
    <h2 class="new-title">Project Notes</h2>

    <h2 class="new-title">Data Parameters</h2>
    <paper-input label="Samples Counted" placeholder="Please upload a data file to see sample count" class="project-field col-md-6 col-xs-12" id="samplecount" readonly type="number"></paper-input>
    <h2 class="new-title">Transects</h2>
    <div class="col-xs-12">
      <span class="toggle-off-label label">Locality Name</span>
      <paper-toggle-button id="transect-input" checked>Coordinate List</paper-toggle-button>
    </div>
    <p id="transect-instructions"></p>
    <div id="transect-input" class="col-md-6 col-xs-12">
    </div>
    <div id="carto-rendered-map" class="col-md-6">
    </div>
  </section>
  <p>Etc</p>
  <h2 class="new-title">Uploading your project data</h2>
  <p>Drag and drop as many files as you need below. </p>
  <p>
    To save your project, we need at least one file with structured data containing coordinates.
    Please note that the data <strong>must</strong> have a header row,
    and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>alt</code>, and <code>coordinateUncertaintyInMeters</code>.
  </p>
  """
  $("main #main-body").append html
  bootstrapUploader()
  bootstrapTransect()
  foo()
  false

loadProjectBrowser = ->
  startAdminActionHelper()
  html = """
  <div class='bs-callout bs-callout-warn center-block col-md-5'>
    <p>Function worked, there's just nothing to show yet.</p>
    <p>Imagine the beautiful and functional browser of all projects you have access to of your dreams, here.</p>
  </div>
  """
  $("#main-body").html html
  # Get a data ref
  adData.cartoRef = "38544c04-5e56-11e5-8515-0e4fddd5de28"
  geo.init()
  foo()
  false


bootstrapTransect = ->
  showCartoTransectMap = (coordList) ->
    foo()
    false
  do setupTransectUi() = ->
    if p$("#transect-input").checked
      # Coordinates
      instructions = """
      Please input a list of coordinates, in the form <code>lat, lng</code>, with one set on each line. <strong>Please press <kbd>enter</kbd> to insert a new line after your last coordinate</strong>.
      """
      transectInput = """
      <iron-autogrow-textarea id="coord-input" class="col-xs-10 col-md-5" required rows="3"></iron-autogrow-textarea>
      """
    else
      instructions = """
      Please enter a name of a locality
      """
      transectInput = """
      <paper-input id="locality-input" label="Locality" class="col-xs-10 col-md-5" required autovalidate></paper-input> <paper-icon-button class="col-xs-2 col-md-1" id="do-search-locality" icon="icons:search"></paper-icon-button>
      """
    $("#transect-instructions").html instructions
    $("#transect-input").html transectInput
    if p$("#transect-input").checked
      $(p$("#coord-input").textarea).keyup (e) =>
        kc = if e.keyCode then e.keyCode else e.which
        if kc is 13
          # New line
          lines = @split("\n").length
          if lines > 3
            # Count the new lines
            # if 3+, send the polygon to be drawn
            coords = new Array()
            coordsRaw = @split("\n")
            for coordPair in coordsRaw
              if coordPair.search "," > 0
                coordSplit = coordPair.split(",")
                tmp = [toFloat(coordSplit[0]), toFloat(coordSplit[1])]
                coords.push tmp
            if coords.length >= 3
              console.info "Coords:", coords
              showCartoTransectMap(coords)
            else
              console.warn "There is one or more invalid coordinates preventing the UI from being shown."
    false
  ## Events
  # Reverse geocode locality search
  $("body #do-search-locality").click ->
    # Do reverse geocode
    window.geocodeLookupCallback = ->
      startLoad()
      locality = p$("#do-search-locality").value
      # https://developers.google.com/maps/documentation/javascript/examples/geocoding-simple
      geocoder = new google.maps.Geocoder()
      request =
        address: locality
      geocoder.geocode request, (result, status) ->
        if status is google.maps.GeocoderStatus.OK
          unless $("#locality-lookup-result").exists()
            $("#carto-rendered-map").prepend """
            <div class="alert alert-info" id="locality-lookup-result">
              <h2>Location Found</h2>: <span class="lookup-name"></span>
            </div>
            """
          $("#locality-lookup-reult .lookup-name").text result[0].formatted_address
          # Render the carto map
          loc = result[0].geometry.location
          lat = loc.lat()
          lng = loc.lng()
          bounds = result[0].geometry.viewport
          bbEW = bounds.O
          bbNS = bounds.j
          boundingBox =
            nw: [bbEW.O, bbNS.O]
            ne: [bbEW.j, bbNS.O]
            sw: [bbEW.O, bbNS.j]
            se: [bbEW.j, bbNS.j]
          console.info "Got bounds: ", [lat, lng], boundingBox
          foo()
          stopLoad()
        else
          stopLoadError "Couldn't find location: #{status}"
    unless google.maps?
      # Load the JS
      loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=geocodeLookupCallback"
    else
      geocodeLookupCallback()
    coords = new Array()
    showCartoTransectMap(coords)
    false
  # Toggle switch
  $("#transect-input").on "iron-change", ->
    setupTransectUi()
  false


bootstrapUploader = (uploadFormId = "file-uploader") ->
  ###
  # Bootstrap the file uploader into existence
  ###
  # Check for the existence of the uploader form; if it's not there,
  # create it
  selector = "##{uploadFormId}"
  unless $(selector).exists()
    # Create it
    html = """
    <form id="#{uploadFormId}-form" class="col-md-4 clearfix">
      <p class="visible-xs-block">Tap the button to upload a file</p>
      <fieldset class="hidden-xs">
        <legend>Upload Files</legend>
        <div id="#{uploadFormId}" class="media-uploader outline media-upload-target">
        </div>
      </fieldset>
    </form>
    """
    $("main #main-body").append html
    $(selector).submit (e) ->
      e.preventDefault()
      e.stopPropagation()
      return false
  # Validate the user before guessing
  verifyLoginCredentials ->
    window.dropperParams ?= new Object()
    window.dropperParams.uploadPath = "uploaded/#{user}/"
    loadJS "helpers/js-dragdrop/client-upload.min.js", ->
      # Successfully uploaded the file
      console.info "Loaded drag drop helper"
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
      $("#main-body").append html
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
    if isNull p$("#project-disease")
      p$("#project-disease").value = sampleRow.diseaseTested
    # Clean up the data for CartoDB
    # FIMS it up
    parsedData = new Object()
    # Iterate over the data, coerce some data types
    for n, row of dataObject
      tRow = new Object()
      for column, value of row
        switch column
          when "dateIdentified"
            # Coerce to ISO8601
            try
              if 0 < value < 10e5
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
                t = ((value - daysFrom1900to1970) * secondsPerDay) * 1000 # Unix Milliseconds
              else
                # Standard date parsing
                t = Date.parse(value)
            catch
              t = Date.now()
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
      parsedData[n] = tRow
    try
      # http://marianoguerra.github.io/json.human.js/
      prettyHtml = JsonHuman.format parsedData
      $("#main-body").append prettyHtml
    catch e
      console.warn "Couldn't pretty set!"
      console.warn e.stack
      console.info parsedData
    # Create a project identifier from the user hash and project title
    projectIdentifier = "t" + md5(p$("#project-title").value + $.cookie "#{uri.domain}_link")
    totalData =
      transectRing: undefined # Read in, manually entered
      data: parsedData
    geo.requestCartoUpload(totalData, projectIdentifier, "create")
  catch e
    console.error e.message
    toastStatusMessage "There was a problem parsing your data"
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
