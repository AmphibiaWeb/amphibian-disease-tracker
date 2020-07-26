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

try
  domainHost = uri.o.attr("host").split(".")
  domainHost.pop()
  domainHost = domainHost.join(".").replace(/www\./g,"")


window.adminParams = new Object()
adminParams.domain = unless isNull domainHost then domainHost else "amphibiandisease"
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
    slowNet = delay 3000, ->
      html = """
      <div class='bs-callout bs-callout-warning'>
        <h4>Please be patient</h4>
        <p>
          The internet is a bit slow right now. We're still verifying your credentials.
        </p>
      </div>
      """
      $("main #main-body").html html
      false
  try
    verifyLoginCredentials (data) ->
      # Post verification
      clearTimeout slowNet
      badgeHtml = if data.unrestricted is true then "<iron-icon id='restriction-badge' icon='icons:verified-user' class='material-green' data-toggle='tooltip' title='Unrestricted Account'></iron-icon>" else "<iron-icon id='restriction-badge' icon='icons:verified-user' class='text-muted' data-toggle='tooltip' title='Restricted Account'></iron-icon>"
      articleHtml = """
      <h3>
        Welcome, #{$.cookie("#{adminParams.domain}_name")} #{badgeHtml}
      </h3>
      <section id='admin-actions-block' class="row center-block text-center">
        <div class='bs-callout bs-callout-info'>
          <p>Please be patient while the administrative interface loads.</p>
        </div>
      </section>
      """
      $("main #main-body").before(articleHtml)
      $(".fill-user-fullname").text $.cookie("#{adminParams.domain}_fullname")
      $("#restriction-badge").click ->
        showUnrestrictionCriteria()
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
  $(".hanging-alert").remove()
  createButton = """
        <paper-button id="new-project" class="admin-action col-md-3 col-sm-4 col-xs-12" raised>
          <iron-icon icon="icons:add"></iron-icon>
            Create New Project
        </paper-button>

  """
  createPlaceholder = """
  <paper-button id="create-placeholder" class="admin-action non-action col-md-3 col-sm-4 col-xs-12" raised data-toggle="tooltip" title="Your account is restricted. Click to verify account">
    <iron-icon icon="icons:star-border"></iron-icon>
    Verify &amp; Create Project
  </paper-button>
  """
  createHtml = if _adp.isUnrestricted then createButton else createPlaceholder
  adminActions = """
  #{createHtml}
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
  $("#create-placeholder").click -> showUnrestrictionCriteria()
  verifyLoginCredentials (result) ->
    rawSu = toInt result.detail.userdata.su_flag
    if rawSu.toBool()
      console.info "NOTICE: This is an SUPERUSER Admin"
      html = """
      <paper-button id="su-view-projects" class="admin-action su-action col-md-3 col-sm-4 col-xs-12">
        <iron-icon icon="icons:supervisor-account"></iron-icon>
         <iron-icon icon="icons:add"></iron-icon>
        (SU) Administrate All Projects
      </paper-button>
      <paper-button id="su-manage-users" class="admin-action su-action col-md-3 col-sm-4 col-xs-12">
        <iron-icon icon="icons:supervisor-account"></iron-icon>
         <iron-icon icon="icons:create"></iron-icon>
        (SU) Manage All Users
      </paper-button>
      """
      $("#admin-actions-block").append html
      try
        delay 500, ->
          setupDebugContext()
      $("#su-view-projects").click ->
        loadSUProjectBrowser()
      $("#su-manage-users").click ->
        loadSUProfileBrowser()
    _adp.isUnrestricted = result.unrestricted
    if result.unrestricted isnt true
      $("#new-project").remove()
      unless $("#create-placeholder").exists()
        $("#edit-project").before createPlaceholder
      $("#create-placeholder")
      .unbind()
      .click -> showUnrestrictionCriteria()
    if result.unrestricted is true and not $("#new-project").exists()
      # Add the create button
      $("#create-placeholder").remove()
      unless $("#new-project").exists()
        $("#edit-project").before createButton
      $("#new-project")
      .unbind()
      .click -> loadCreateNewProject()
    false
  false



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
        <paper-item data-href="https://amphibiandisease.org/dashboard.php" class="click">
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



showUnrestrictionCriteria = ->
  startLoad()
  verifyLoginCredentials (result) ->
    stopLoad()
    isUnrestricted = result.unrestricted.toBool()
    hasAlternate = result.has_alternate.toBool()
    verifiedEmail = result.detail.userdata.email_verified.toBool()
    emailAllowed = result.email_allowed.toBool()
    if hasAlternate
      verifiedAlternateEmail = result.detail.userdata.alternate_email_verified.toBool()
      alternateAllowed = result.alternate_allowed.toBool()
      hasAllowedEmail = alternateAllowed or emailAllowed
    else
      hasAllowedEmail = emailAllowed
    rawSu = toInt result.detail.userdata.su_flag
    rawAdmin = toInt result.detail.userdata.admin_flag
    hasOverride = rawSu.toBool() or rawAdmin.toBool()
    accountSettings = "https://#{adminParams.domain}.org/#{adminParams.loginDir.slice(0,-1)}"
    completeIcon = """
    <iron-icon icon="icons:verified-user" class="material-green" data-toggle="tooltip" title="Completed"></iron-icon>
    """
    incompleteIcon = """
    <iron-icon icon="icons:verified-user" class="text-muted" data-toggle="tooltip" title="Incomplete"></iron-icon>
    """
    allowedString = "<br/><small class='allowed-tld-domains'>Verifiable email addresses can be from #{result.restriction_criteria.domains} <span data-toggle='tooltip' title='e.g., your institution'>domains</span>, but must end in: #{result.restriction_criteria.tlds}</small>"
    if hasAllowedEmail
      allowedEmail = """
      #{completeIcon} Have an email in allowed TLDs / domains. #{allowedString}
      """
    else
      if hasAlternate
        allowedEmail = """
        #{incompleteIcon} Neither your primary email or alternate email is in an allowed TLD / domain. <strong>Fix:</strong> Change your alternative email in <a href='#{accountSettings}'>Account Settings</a>. #{allowedString}
        """
      else
        allowedEmail = """
        #{incompleteIcon} To create a new project, you must have a verifiable email address. <strong>Fix:</strong> Add  an alternative email address in <a href='#{accountSettings}'>Account Settings</a>. #{allowedString}
        """
    if verifiedEmail
      verifiedMain = """
      #{completeIcon} Have a verified username
      """
    else
      verifiedMain = """
      #{incompleteIcon} Your primary email isn't verified. <strong>Fix:</strong> Verify it in <a href='#{accountSettings}'>Account Settings</a>
      """
    if hasAlternate
      if verifiedAlternateEmail
        verifiedAlternate = """
        #{completeIcon} Your alternate email is verified
        """
      else
        if alternateAllowed
          verifiedAlternate = """
          #{incompleteIcon} Your alternate email isn't verified. <strong>Fix:</strong> Verify it in <a href='#{accountSettings}'>Account Settings</a>
          """
    verifiedAlternate =  if isNull(verifiedAlternate) then "" else "<li>#{verifiedAlternate}</li>"
    overrideHtml = ""
    if hasOverride
      phrase = if rawSu.toBool() then "a SuperUser" else "an administrator"
      overrideHtml = """
        #{completeIcon} You're #{phrase}. You're always unrestricted.
      """
    dialogContent = """
    <div>
      #{overrideHtml}
      <ul class="restriction-criteria">
        <li>#{allowedEmail}</li>
        <li>#{verifiedMain}</li>
        #{verifiedAlternate}
      </ul>
      <p>
        Restricted accounts can't create projects.
      </p>
    </div>
    """
    title = if isUnrestricted then "Your account is unrestricted" else "Your account is restricted"
    # Pop a dialog
    $("#restriction-summary").remove()
    dialogHtml = """
    <paper-dialog id="restriction-summary" modal>
      <h2>#{title}</h2>
      <paper-dialog-scrollable>
        #{dialogContent}
      </paper-dialog-scrollable>
      <div class="buttons">
        <paper-button dialog-dismiss>Close</paper-button>
      </div>
    </paper-dialog>
    """
    $("body").append dialogHtml
    safariDialogHelper "#restriction-summary", 0, ->
      console.info "Opened restriction summary dialog"
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
  $.post adminParams.loginApiTarget, args, "json"
  .done (result) ->
    if result.status is true
      unless _adp?
        window._adp = new Object()
      _adp.isUnrestricted = result.unrestricted
      callback(result)
    else
      console.error "Invalid login credentials, redirecting to login url"
      try
        localStorage.lastLogin = JSON.stringify result
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
  <paper-input label="Descriptive, unique project title" id="project-title" class="project-field col-md-6 col-xs-11" required auto-validate data-field="project_title"></paper-input>
  #{getInfoTooltip("A descriptive title is most useful. Tell us the main focus of the project and whether a monitoring effort or project that just occurred in the Spring of 2015.")}
  <h2 class="new-title col-xs-12">Project Parameters</h2>
  <section class="project-inputs clearfix col-xs-12">
    <div class="row">
      <paper-input label="Primary Pathogen" id="project-disease" class="project-field col-xs-6" required auto-validate data-field="disease"></paper-input>
        #{getInfoTooltip("Bd, Bsal, or other. If empty, we'll take it from your data.")}
        <button class="btn btn-default fill-pathogen col-xs-2" data-pathogen="Batrachochytrium dendrobatidis">Bd</button>
        <button class="btn btn-default fill-pathogen col-xs-2" data-pathogen="Batrachochytrium salamandrivorans">Bsal</button>
      <paper-input label="Pathogen Strain" id="project-disease-strain" class="project-field col-md-6 col-xs-11" data-field="disease_strain"></paper-input>#{getInfoTooltip("For example, specific Bd strains which have been sequenced JEL423, JAM81, if known")}
      <paper-input label="Project Reference" id="reference-id" class="project-field col-md-6 col-xs-11" data-field="reference_id"></paper-input>
      #{getInfoTooltip("E.g.  a DOI or other reference")}
      <paper-input label="Publication DOI" id="pub-doi" class="project-field col-md-6 col-xs-11" data-field="publication"></paper-input>
      #{getInfoTooltip("Publication DOI citing these datasets may be added here.")}
      <h2 class="new-title col-xs-12">Lab Parameters</h2>
      <paper-input label="Project PI" id="project-pi" class="project-field col-md-6 col-xs-12"  required auto-validate data-field="pi_lab"></paper-input>
      <paper-input label="Project Contact" id="project-author" class="project-field col-md-6 col-xs-12" value="#{userFullname}"  required auto-validate></paper-input>
      #{getInfoTooltip("This will be the identity used for the project citation")}
      <gold-email-input label="Contact Email" id="author-email" class="project-field col-md-6 col-xs-12" value="#{userEmail}"  required auto-validate></gold-email-input>
      <paper-input label="Technical/Data Contact" id="project-technical-contact" class="project-field col-md-6 col-xs-12" value="#{userFullname}"  required auto-validate></paper-input>
      #{getInfoTooltip("This will be the identity suggested for technical communications about the project")}
      <gold-email-input label="Technical/Data Contact Email" id="technical-contact-email" class="project-field col-md-6 col-xs-12" value="#{userEmail}"  required auto-validate></gold-email-input>
      <paper-input label="Diagnostic Lab" id="project-lab" class="project-field col-md-6 col-xs-11"  required auto-validate></paper-input>
      #{getInfoTooltip("Name or PI responsible for lab results")}
      <paper-input label="Affiliation" id="project-affiliation" class="project-field col-md-6 col-xs-11"  required auto-validate></paper-input> #{getInfoTooltip("Of project PI. e.g., UC Berkeley")}
      <h2 class="new-title col-xs-12">Project Notes</h2>
      <iron-autogrow-textarea id="project-notes" class="project-field col-md-6 col-xs-11 language-markdown" rows="3" data-field="sample_notes"></iron-autogrow-textarea>#{getInfoTooltip("Project notes or brief abstract; accepts Markdown ")}
      <marked-element class="project-param col-md-6 col-xs-12" id="note-preview">
        <div class="markdown-html"></div>
      </marked-element>
      <h2 class="new-title col-xs-12">Data Permissions</h2>
      <div class="col-xs-12">
        <span class="toggle-off-label iron-label">Private Dataset</span>
        <paper-toggle-button id="data-encumbrance-toggle" class="red">Public Dataset</paper-toggle-button>
        #{getInfoTooltip("this will be the setting for all data uploaded to this Project")}
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
      <div id="carto-rendered-map" class="col-md-6 col-xs-12">
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
  <section id="uploader-container-section" class="data-section col-xs-12 clearfix">
    <h2 class="new-title">Uploading your project data</h2>
    <p>Drag and drop as many files as you need below. </p>
    <p>
      Please note that the data <strong>must</strong> have a header row,
      and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, and <code>coordinateUncertaintyInMeters</code>. Your project must also be titled before uploading data.
    </p>
    <div class="alert alert-info" role="alert">
      We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href="http://www.biscicol.org/template" class="newwindow alert-link" data-newtab="true">biscicol.org <span class="glyphicon glyphicon-new-window"></span></a> <small>(Alternate link: <a href="https://berkeley.box.com/v/AmphibianDisease-template" class="newwindow alert-link" data-newtab="true">Berkeley Box <span class="glyphicon glyphicon-new-window"></span></a>)</small>. Check out the documentation for <a href="https://amphibian-disease-tracker.readthedocs.org/en/latest/Creating%20a%20New%20Project/#with-data" class="newwindow alert-link" data-newtab="true">more instructions <span class="glyphicon glyphicon-new-window"></span></a>
    </div>
    <div class="alert alert-warning" role="alert">
      <strong>If the data are in Excel</strong>, ensure that they are in the first sheet in the workbook, or in a worksheet titled <code>Samples</code>, as per FIMS.
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
      <p class="col-xs-12"><a id="download-server-parsed-data" class="btn btn-primary disabled">Download Parsed Data</a></p>
    </div>
  </section>
  <section id="submission-section" class="col-xs-12">
    <div class="pull-right">
      <button id="upload-data" class="btn btn-success click" data-function="finalizeData"><iron-icon icon="icons:lock"></iron-icon> <span class="label-with-data">Save Data &amp;</span> Create Private Project</button>
      <button id="reset-data" class="btn btn-danger click" data-function="resetForm">Reset Form</button>
    </div>
  </section>
  """
  $("main #main-body").append html
  try
    $("#project-title").blur ->
      testTitle = p$(this).value.toLowerCase()
      noDiseaseTitle = testTitle.replace(/ *b(sal|d\W) *|(19|20)[0-9]{2}|\s+\W|\s+(for|the|and|of|in|from|a|an)\s+/img, " ")
      cleanedTitle = noDiseaseTitle.replace(/  /mg, " ")
      titleArr = cleanedTitle.trim().split " "
      if titleArr.length <= 3
        bsAlert "Your title seems very short/generic. Read it again, and make sure it is both <strong>unique</strong> and <strong>descriptive</strong>."
      false
  catch e
    console.warn "Couldn't set up blur event - #{e.message}"
    console.warn e.stack
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
      console.debug "doMapBuilder callback initialized ..."
      html = """
      <p class="text-muted" id="computed-locality">
        Computed locality: <strong>#{map.locality}</strong>
      </p>
      """
      $("#computed-locality").remove()
      $("#using-computed-locality").remove()
      $("#transect-input-container").after html
      false
  $("#reset-map-builder").click ->
    delete window.mapBuilder
    #window.mapBuilder.points = new Array()
    $("#init-map-build").attr "disabled", "disabled"
    $("#init-map-build .points-count").text window.mapBuilder.points.length
    try
      p$("google-map").clear()
    # Remove the points
    $("google-map google-map-marker").remove()
    # Remove current polygons
    $("google-map google-map-poly").remove()
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
    try
      delay 500, ->
        setupDebugContext()
  bindClicks()
  false

finalizeData = (skipFields = false, callback) ->
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
    if dataFileParams?.hasDataFile
      if dataFileParams.filePath.search(helperDir) is -1
        dataFileParams.filePath = "#{helperDir}#{dataFileParams.filePath}"
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
        unless skipFields
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
        else
          postData = _adp.projectData
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
          sampleIds = new Array()
          dispositions = new Array()
          sampleMethods = new Array()
          rowNumber = 0
          for row in Object.toArray uploadedData
            ++rowNumber
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
            sampleIds.push row.sampleId
            # Prepare to calculate the radius
            rowLat = toFloat row.decimalLatitude
            rowLng = toFloat row.decimalLongitude
            try
              distanceFromCenter = geo.distance rowLat, rowLng, center.lat, center.lng
            catch e
              console.error "Couldn't calculate distanceFromCenter", rowLat, rowLng, center
              console.warn "Row: ##{rowNumber}", row
              throw e
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
          postData.sample_field_numbers = sampleIds.join(",")
          postData.sample_methods_used = sampleMethods.join(",")
        else
          # No data, check bounding box
          unless geo.canonicalHullObject?
            try
              createConvexHullFINISHME
          if geo.canonicalHullObject?
            hull = geo.canonicalHullObject.hull
            for point in hull
              distanceFromCenter = geo.distance point.lat, point.lng, center.lat, center.lng
              if distanceFromCenter > excursion then excursion = distanceFromCenter
        if dataFileParams?.hasDataFile
          if dataFileParams.filePath.search(helperDir) is -1
            dataFileParams.filePath = "#{helperDir}#{dataFileParams.filePath}"
          postData.sample_raw_data = "https://amphibiandisease.org/#{dataFileParams.filePath}"
        postData.lat = center.lat
        postData.lng = center.lng
        postData.radius = toInt excursion * 1000
        if _adp.data?.pushDataUpload?.samples?
          # Store the samples in postData
          s = _adp.data.pushDataUpload.samples
          postData.disease_morbidity = s.morbidity
          postData.disease_mortality = s.mortality
          postData.disease_negative = s.negative
          postData.disease_no_confidence = s.no_confidence
          postData.disease_positive = s.positive
          postData.disease_samples = toInt(s.positive) + toInt(s.negative) + toInt(s.no_confidence)
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
          try
            postData.technical_contact = p$("#project-technical-contact").value
            postData.technical_contact_email = p$("#project-technical-contact-email").value
          try
            if typeof kmlInfo is "object"
              try
                postData.transect_file = JSON.stringify kmlInfo
              catch e
                console.warn "Couldn't stringify data - #{e.message}", kmlInfo
                if kmlInfo.path?
                  postData.transect_file = kmlInfo.path
          unless _adp?.projectData?.author_data?
            authorData =
              name: p$("#project-author").value
              contact_email: p$("#author-email").value
              affiliation: p$("#project-affiliation").value
              lab: p$("#project-pi").value
              diagnostic_lab: p$("#project-lab").value
              entry_date: Date.now()
            postData.author_data = JSON.stringify authorData
          else
            postData.author_data = _adp.projectData.author_data
          cartoData =
            table: geo.dataTable
            raw_data: dataFileParams
            bounding_polygon: geo?.canonicalBoundingBox
            bounding_polygon_geojson: geo?.geoJsonBoundingBox
          postData.carto_id = JSON.stringify cartoData
          postData.project_id = _adp.projectId
          postData.modified = Date.now() / 1000
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
          postData.public = p$("#data-encumbrance-toggle")?.checked ? p$("#public")?.checked ? _adp?.projectData?.public ? true
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
          if skipFields
            if typeof callback is "function"
              callback postData
            stopLoad()
            return postData
          _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
          .done (result) ->
            try
              if result.status is true
                bsAlert("Project ID #<strong>#{postData.project_id}</strong> created","success")
                # Notify
                d = new Date()
                ds = d.toLocaleString()
                qargs =
                  action: "notify"
                  subject: "Project '#{postData.project_title}' Created"
                  body: "Project #{postData.project_id} ('#{postData.project_title}') created at #{ds} by <a href='https://amphibiandisease.org/profile.php?id=#{$.cookie('amphibiandisease_link')}'>#{$.cookie('amphibiandisease_fullname')}&lt;<code>#{$.cookie('amphibiandisease_user')}</code>&gt;</a>"
                $.get "#{uri.urlString}admin-api.php", buildArgs qargs, "json"
                # Ping the record migrator
                $.get "#{uri.urlString}recordMigrator.php"
                stopLoad()
                delay 1000, ->
                  loadEditor _adp.projectId
                toastStatusMessage "Data successfully saved to server"
              else
                console.error result.error.error
                console.log result
                stopLoadError result.human_error
                bsAlert result.human_error, "error"
            catch e
              stopLoadError "There was a verifying your save data"
              try
                jsonResponse = JSON.stringify result
              catch
                jsonResponse = "BAD_OBJECT"
              try
                bsAlert "There was a problem verifying your save data<br/><br/>Application said: <code>#{jsonResponse}</code><code>#{e.message}</code><code>#{e.stack}</code>", "error"
              console.error "JavaScript error in save data callback! FinalizeData said: #{e.message}"
              console.warn e.stack
            false
          .fail (result, status) ->
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
    try
      bsAlert "There was a problem with the application. Please try again later. (E-004)<br/><br/>Application said: <code>#{e.message}</code><code>#{e.stack}</code>", "error"
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


pointStringToLatLng = (pointString, reverseLatLngOrder = false) ->
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
  latKey = if Math.abs(pointArr[0]) > 90 or reverseLatLngOrder then 1 else 0
  lngKey = if latKey is 1 then 0 else 1
  pointObj =
    lat: pointArr[latKey]
    lng: pointArr[lngKey]
  pointObj

pointStringToPoint = (pointString, reverseLatLngOrder = false) ->
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
  pointObj = pointStringToLatLng pointString, reverseLatLngOrder
  point = canonicalizePoint pointObj
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
            <strong>Location Found</strong>: <span class="lookup-name">#{result[0].formatted_address}</span>
          </div>
          """
        infoHtml = """
        <p class="text-muted" id="computed-locality">
          Computed locality: <strong>#{result[0].formatted_address}</strong>
        </p>
        <div class="alert alert-info" id="using-computed-locality">
          <p>
            This is your currently active locality. Entering points below will take priority over this.
          </p>
        </div>
        """
        $("#computed-locality").remove()
        $("#using-computed-locality").remove()
        $("#transect-input-container").after infoHtml
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
    getCols = "SELECT * FROM #{table} WHERE FALSE"
    args = "action=fetch&sql_query=#{post64(getCols)}"
    _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
    .done (result) ->
      try
        r = JSON.parse(result.post_response[0])
      catch e
        console.error "getCanonicalDataCoords couldn't read carto data! Failed to get columns (#{e.message})", result
        console.warn "Table: '#{table}' for query", getCols
        console.warn e.stack
        error = result.human_error ? result.error ? "It should be safe, however."
        message = "There was a problem fetching your data back from CartoDB. "
        stopLoadError message
        bsAlert message, "danger"
        try
          if typeof callback is "function"
            callback [], options
        return false
      cols = new Object()
      for k, v of r.fields
        cols[k] = v
      _adp.activeCols = cols
      colsArr = new Array()
      colRemap = new Object()
      for col, type of cols
        if col isnt "id" and col isnt "the_geom"
          colsArr.push col
        colRemap[col.toLowerCase()] = col
      _adp.colsList = colsArr
      _adp.colRemap = colRemap
      sqlQuery = "SELECT ST_AsText(the_geom), #{colsArr.join(",")} FROM #{table}"
      apiPostSqlQuery = encodeURIComponent encode64 sqlQuery
      args = "action=fetch&sql_query=#{apiPostSqlQuery}"
      _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
      .done (result) ->
        cartoResponse = result.parsed_responses[0]
        coords = new Array()
        info = new Array()
        _adp.cartoRows = new Object()
        for i, row of cartoResponse.rows
          _adp.cartoRows[i] = new Object()
          for col, val of row
            realCol = colRemap[col] ? col
            _adp.cartoRows[i][realCol] = val
          textPoint = row.st_astext
          if isNull row.infraspecificepithet
            row.infraspecificepithet = ""
          # CartoDB returns these data reversed, as lng/lat
          point = pointStringToLatLng textPoint, true
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
        if typeof callback is "function"
          callback coords, options
        # callback coords, info
      .fail (result, status) ->
        # On error, return direct from file upload
        if dataAttrs?.coords?
          callback dataAttrs.coords, options
          # callback dataAttrs.coords, dataAttrs.markerInfo
        else
          stopLoadError "Couldn't get bounding coordinates from data"
          console.error "No valid coordinates accessible!"
    .fail (result, status) ->
      false
  false

getUploadIdentifier = ->
  if isNull _adp.uploadIdentifier
    if isNull _adp.projectId
      author = $.cookie("#{adminParams.domain}_link")
      if isNull _adp.projectIdentifierString
        try
          seed = if isNull p$("#project-title").value then randomString(16) else p$("#project-title").value
        catch
          seed = randomString(16)
        projectIdentifier = "t" + md5(seed + author)
        _adp.projectIdentifierString = projectIdentifier
      _adp.projectId = md5("#{projectIdentifier}#{author}#{Date.now()}")
    _adp.uploadIdentifier = md5 "#{user}#{_adp.projectId}"
  _adp.uploadIdentifier



bootstrapUploader = (uploadFormId = "file-uploader", bsColWidth = "col-md-4", callback) ->
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
              <div class="uploaded-media center-block" data-system-file="#{fileName}" data-link-path="#{linkPath}">
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
          checkPath = linkPath.slice 0
          cp2 = linkPath.slice 0
          extension = cp2.split(".").pop()
          switch mediaType
            when "application"
              # Another switch!
              console.info "Checking #{longType} in application"
              switch longType
                # Fuck you MS, and your terrible MIME types
                when "vnd.openxmlformats-officedocument.spreadsheetml.sheet", "vnd.ms-excel"
                  excelHandler(linkPath)
                when "vnd.ms-office"
                  switch extension
                    when "xls"
                      excelHandler linkPath
                    else
                      stopLoadError "Sorry, we didn't understand the upload type."
                      return false
                when "zip", "x-zip-compressed"
                  # Some servers won't read it as the crazy MS mime type
                  # But as a zip, instead. So, check the extension.
                  #
                  if file.type is "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or extension is "xlsx"
                    excelHandler(linkPath)
                  else if extension is "kmz"
                    kmlHandler(linkPath)
                  else
                    zipHandler(linkPath)
                when "x-7z-compressed"
                  _7zHandler(linkPath)
                when "vnd.google-earth.kml+xml", "vnd.google-earth.kmz", "xml"
                  if extension is "kml" or extension is "kmz"
                    kmlHandler(linkPath)
                  else
                    console.warn "Non-KML xml"
                    allError "Sorry, we can't processes files of type application/#{longType}"
                    return false
                else
                  console.warn "Unknown mime type application/#{longType}"
                  allError "Sorry, we can't processes files of type application/#{longType}"
                  return false
            when "text" then csvHandler(linkPath)
            when "image" then imageHandler(linkPath)
        catch e
          toastStatusMessage "Your file uploaded successfully, but there was a problem in the post-processing."
      # Callback if exists
      if typeof callback is "function"
        callback()
    false


singleDataFileHelper = (newFile, callback) ->
  if typeof callback isnt "function"
    console.error "Second argument must be a function"
    return false
  if dataFileParams.hasDataFile is true and newFile isnt dataFileParams.filePath
    # Clear out the bsAlert
    try
      $("#bs-alert").remove()
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


excelHandler = (path, hasHeaders = true, callbackSkipsGeoHandler) ->
  ###
  # Handle the upload for excel documents.
  # Handles both 97-2007 documents (xls), and 2007+ documents (xlsx)
  #
  # @param string path -> the path to the uploaded excel document.
  # @parm bool hasHeaders -> does the data file have headers? Default true
  # @param function callbackSkipsGeoHandler -> A callback function to
  #   run in the place of geoDataHandler()
  ###
  startLoad()
  $("#validator-progress-container").remove()
  renderValidateProgress()
  helperApi = "#{helperDir}excelHelper.php"
  correctedPath = path
  if path.search(helperDir) isnt -1
    # The helper file lives in /helpers/ so we want to remove that
    console.info "removing '#{helperDir}'"
    correctedPath = path.slice helperDir.length
  console.info "Pinging for #{correctedPath}"
  args = "action=parse&path=#{correctedPath}&sheets=Samples"
  hasInvalid = false
  try
    for input in $("paper-input[required]")
      if p$(input).invalid
        hasInvalid = true
        stopLoadError "Please fill out all required fields before uploading data"
        bsAlert "Please fill out all required fields before uploading data", "danger"
        try
          stopLoadBarsError()
        removeDataFile(correctedPath)
        return false
  if hasInvalid
    console.error "Exiting handler -- invalid inputs"
    return false
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
      # randomData = ""
      # if rows > 0
      #   randomRow = randomInt(1,rows) - 1
      #   randomData = "\n\nHere's a random row: " + JSON.stringify(result.data[randomRow])
      # html = """
      # <pre>
      # From upload, fetched #{rows} rows.#{randomData}
      # </pre>
      # """
      # $("#main-body").append html
      uploadedData = result.data
      _adp.parsedUploadedData = result.data
      try
        p$("#replace-data-toggle").disabled = false
      unless typeof callbackSkipsGeoHandler is "function"
        newGeoDataHandler(result.data)
      else
        console.warn "Skipping newGeoDataHandler() !"
        callbackSkipsGeoHandler(result.data)
      stopLoad()
  .fail (result, error) ->
    console.error "Couldn't POST"
    console.warn result, error
    stopLoadError()
  false

csvHandler = (path, hasHeaders = true, callbackSkipsGeoHandler) ->
  ###
  # Handle the upload for CSV datafiles
  # Treats them as per RFC4180
  # https://tools.ietf.org/html/rfc4180
  #
  # @param string path -> the upload path to the file
  # @parm bool hasHeaders -> does the data file have headers? Default true
  # @param function callbackSkipsGeoHandler -> A callback function to
  #   run in the place of geoDataHandler()
  ###
  if path.search(helperDir) isnt -1
    # The helper file lives in /helpers/ so we want to remove that
    console.info "removing '#{helperDir}'"
    correctedPath = path.slice helperDir.length
  singleDataFileHelper path, ->
    $("#upload-data").attr "disabled", "disabled"
    nameArr = path.split "/"
    dataFileParams.hasDataFile = true
    dataFileParams.fileName = nameArr.pop()
    dataFileParams.filePath = correctedPath
    # Parse out the CSV here
    geoDataHandler()
  false



kmlHandler = (path, callback) ->
  ###
  # Load a KML file
  ###
  try
    console.debug "Loading KML file"
  geo.inhibitKMLInit = true
  jsPath = if isNull(_adp?.lastMod?.kml) then "js/kml.min.js" else "js/kml.min.js?t=#{_adp.lastMod.kml}"
  startLoad()
  loadJS jsPath, ->
    initializeParser null, ->
      loadKML path, ->
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
          polygons = new Array()
          polygonFills = new Array()
          polygonOpacities = new Array()
          for polygon in parsedKmlData.gpolygons
            # Read out and parse the polys
            # https://developers.google.com/maps/documentation/javascript/3.exp/reference#Polygon
            polyBounds = new Array()
            polygonFills.push polygon.fillColor
            polygonOpacities.push polygon.fillOpacity
            for segment in polygon.getPaths().getArray()
              for segmentPoint in segment.getArray()
                # https://developers.google.com/maps/documentation/javascript/3.exp/reference#LatLng
                tmpPoint = canonicalizePoint segmentPoint
                polyBounds.push tmpPoint
            polygons.push polyBounds
          # We now have a multipart polygon
          window.kmlInfo = new Object()
          kmlInfo.path = path
          try
            simpleBCPoly = polygons[0]
            if polygons.length is 1
              polygons = polygons[0]
            # Save it normalish
            boundingPolygon =
              fillOpacity: polygonOpacities[0]
              fillColor: polygonFills[0]
              paths: simpleBCPoly
              multibounds: polygons
            kmlInfo.parameters = boundingPolygon
            kmlInfo.polys = polygons
            if isNull geo
              window.geo = new Object()
            if isNull geo.canonicalHullObject
              geo.canonicalHullObject = new Object()
            geo.canonicalHullObject.hull = simpleBCPoly
            geo.canonicalBoundingBox = boundingPolygon
            unless isNull _adp?.projectData
              try
                cartoObj = _adp.projectData.carto_id
                unless typeof cartoObj is "object"
                  try
                    cartoDataParsed = JSON.parse deEscape cartoObj
                  catch e
                    err1 = e.message
                    try
                      cartoDataParsed = JSON.parse cartoObj
                    catch e
                      if cartoObj.length > 511
                        cartoJson = fixTruncatedJson cartoObj
                        if typeof cartoJson is "object"
                          console.debug "The carto data object was truncated, but rebuilt."
                          cartoDataParsed = cartoJson
                      if isNull cartoDataParsed
                        console.error "cartoObj must be JSON string or obj, given", cartoObj
                        console.warn "Cleaned obj:", deEscape cartoObj
                        console.warn "Told '#{err1}' then", e.message
                        stopLoadError "Couldn't parse data"
                        return false
                else
                  cartoDataParsed = cartoObj
                cartoDataParsed.bounding_polygon = boundingPolygon
                _adp.projectData.carto_id = JSON.stringify cartoDataParsed
              catch e
                console.error e.message
                console.warn e.stack
                allError "Warning: there may have been a problem saving your carto data"

          catch e
            console.warn "WARNING: Couldn't write polygon data to globals"
          if typeof callback is "function"
            callback(kmlInfo)
          else
            console.info "kmlHandler wasn't given a callback function"
          stopLoad()
        catch e
          allError "There was an error importing the data from this KML file"
          console.warn e.message
          console.warn e.stack
        false # Ends loadKML callback
      false #
    false
  false



copyMarkdown = (selector, zeroClipEvent, html5 = true) ->
  # TODO FINISH ME
  unless _adp?.zcClient?
    zcConfig =
      swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
    ZeroClipboard.config zcConfig
    _adp.zcClient = new ZeroClipboard $(selector).get 0
    # client.on "copy", (e) =>
    #   copyLink(this, e)
    $("#copy-ark").click ->
      copyLink _adp.zcClient
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


imageHandler = (path) ->
  # Insert a link to put a copy link with MD path
  divEl = $("div[data-link-path='#{path}']")
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

newGeoDataHandler = (dataObject = new Object(), skipCarto = false, postCartoCallback) ->
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
  console.info "Starting geoDataHandler()"
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
    try
      p$("#samplecount").value = rows
    if isNull $("#project-disease").val()
      try
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
    try
      p$("#data-parsing").max = rows
    now = Date.now()
    uniqueFieldIds = new Array()
    duplicatedFieldIds = new Array()
    for n, row of dataObject
      prettyHumanRow = toInt(n) + 1
      tRow = new Object()
      uniqueColumn = new Array()
      for column, value of row
        column = column.trim()
        if column in uniqueColumn
          # Duplicate column
          console.error "There was a duplicate column '#{column}'", uniqueColumn
          stopLoadBarsError null, "You have at least one duplicate column '#{column}'. Ensure all your columns are unique."
          return false
        skipCol = false
        switch column
          # Change FIMS to internal structure:
          # http://www.biscicol.org/biocode-fims/template
          # Expects:
          #  id: "int"
          #  collectionID: "varchar"
          #  catalogNumber: "varchar"
          #  sampleId: "varchar"
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
            if typeof value is "string"
              try
                value = value.replace /;/mig, "&#59;"
                value = value.replace /'/mig, "&#39;"
                value = value.replace /"/mig, "&#34;"
              catch
                console.warn "Couldn't replace quotes for this:", value
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
            t = excelDateToUnixTime(value, true)
            if not isNumber t
              console.error "This row (##{prettyHumanRow}) has a non-date value ! (#{value} = #{t})"
              stopLoadBarsError null, "Detected an invalid date '#{value}' at row ##{prettyHumanRow}. Check your dates!"
              return false
            d = new Date(t)
            ucBerkeleyFounded = new Date("1868-03-23")
            if t < ucBerkeleyFounded.getTime()
              console.error "This row (##{prettyHumanRow}) has a date (#{value} = #{t}) too far in the past!"
              stopLoadBarsError null, "Detected an implausibly old date '#{value}' = <code>#{d.toDateString()}</code> at row ##{prettyHumanRow}. Check your dates!"
              return false
            if t > Date.now()
              console.error "This row (##{prettyHumanRow}) has a date (#{value} = #{t}) after today!"
              stopLoadBarsError null, "Detected a future date '#{value}' at row ##{prettyHumanRow}. Check your dates!"
              return false
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
              stopLoadBarsError null, "Detected an invalid number for #{column} at row #{prettyHumanRow} (<code>#{value}</code>)"
              return false
            if column is "decimalLatitude"
              if value < -90 or value > 90
                stopLoadBarsError null, "Detected an invalid latitude <code>#{value}</code> at row #{prettyHumanRow}<br/><br/>Valid latitudes are between <code>90</code> and <code>-90</code>."
                return false
            if column is "decimalLongitude"
              if value < -180 or value > 180
                stopLoadBarsError null, "Detected an invalid longitude <code>#{value}</code> at row #{prettyHumanRow}<br/><br/>Valid latitudes are between <code>180</code> and <code>-180</code>."
                return false
            if column is "coordinateUncertaintyInMeters" and value <= 0
              stopLoadBarsError null, "Coordinate uncertainty must be >= 0 at row #{prettyHumanRow}"
              return false
            cleanValue = toFloat value
          when "diseaseDetected"
            if isBool value
              cleanValue = value.toBool()
            else
              try
                if value.trim().toLowerCase() is "negative"
                  cleanValue = false
                else if value.trim().toLowerCase() is "positive"
                  cleanValue = true
                else
                  cleanValue = "NO_CONFIDENCE"
              catch
                cleanValue = "NO_CONFIDENCE"
          when "sex"
            try
              value = value.trim().toLowerCase()
              if value.slice(0,1) is "m"
                value = "male"
              else if value.slice(0,1) is "f"
                value = "female"
              else
                value = "not determined"
            catch
              value = "not determined"
          when "sampleId"
            # These are "validForUri" columns
            try
              trimmed = value.trim()
              if trimmed.toLowerCase() is "n/a"
                trimmed = ""
              # For field that are "PLC 123", remove the space
              trimmed = trimmed.replace /^([a-zA-Z]+) (\d+)$/mg, "$1$2"
              cleanValue = trimmed
            catch
              cleanValue = value
            unless cleanValue in uniqueFieldIds
              uniqueFieldIds.push cleanValue
            else
              unless cleanValue in duplicatedFieldIds
                duplicatedFieldIds.push cleanValue
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
        console.log "Processed #{n} rows ..."
      try
        p$("#data-parsing").value = n + 1
    try
      console.log "Basic validation passed"
      unless isNull duplicatedFieldIds
        bsAlert "<strong>Warning</strong>: the following field IDs all had duplicates:<br/><code>#{duplicatedFieldIds}</code></br>We <strong>strongly</strong> recommend unique IDs.", "warning"
    if isNull _adp.projectIdentifierString
      # Create a project identifier from the user hash and project title
      projectIdentifier = "t" + md5(p$("#project-title").value + author + Date.now())
      _adp.projectIdentifierString = projectIdentifier
    else
      projectIdentifier = _adp.projectIdentifierString
    try
      csvOptions =
        downloadFile: "cleaned-dataset-#{Date.now()}.csv"
        selector: "#download-server-parsed-data"
      downloadCSVFile parsedData, csvOptions
      window.parsedData = parsedData
      _adp.cleanedAndParsedData = parsedData
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
    try
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
        unless taxonString in taxonList
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
      try
        p$("#species-list").bindValue = taxonListString
      dataAttrs.dataObj = validatedData
      _adp.data.dataObj = validatedData
      _adp.data.taxa = new Object()
      _adp.data.taxa.list = taxonList
      _adp.data.taxa.clades = cladeList
      _adp.data.taxa.validated = validatedData.validated_taxa
      unless typeof skipCarto is "function" or skipCarto is true
        try
          csvOptions =
            downloadFile: "cleaned-dataset-#{Date.now()}.csv"
            selector: "#download-server-parsed-data"
          downloadCSVFile validatedData, csvOptions
        geo.requestCartoUpload validatedData, projectIdentifier, "create", (table, coords, options) ->
          #mapOverlayPolygon validatedData.transectRing
          createMap2 coords, options, ->
            # Reset the biulder
            window.mapBuilder.points = new Array()
            $("#init-map-build").attr "disabled", "disabled"
            $("#init-map-build .points-count").text window.mapBuilder.points.length
            if typeof postCartoCallback is "function"
              postCartoCallback(table, coords)
      else
        if typeof skipCarto is "function"
          skipCarto validatedData, projectIdentifier
        else
          console.warn "Carto upload was skipped, but no callback provided"
  catch e
    console.error "Error parsing data - #{e.message}"
    console.warn e.stack
    message = """There was a problem parsing your data. Please check <a href="http://biscicol.org/biocode-fims/template" class="newwindow alert-link" data-newtab="true">biscicol.org FIMS requirements<span class="glyphicon glyphicon-new-window"></span></a>"""
    stopLoadBarsError null, message

  false




excelDateToUnixTime = (excelTime, strict = false) ->
  ###
  #
  ###
  earliestPlausibleYear = 1863
  d = new Date()
  thisYear = d.getUTCFullYear()
  try
    if not isNumber excelTime
      # It might be a string of some readable date
      possibleDate = Date.parse excelTime
      # A bad date will have parsed as "NaN"
      if isNumber possibleDate
        return possibleDate
      throw "Bad date error"
    if earliestPlausibleYear <= excelTime <= thisYear
      ###
      # The Excel format isn't smart enough to mark a date as a date
      # We have to do some guessing
      #
      # This correction will generate bad values for samples collected
      # between February and July 1905, casting them into the years
      # 1863 through current.
      ###
      # Use the third to avoid time zone issues
      parseableDate = "#{excelTime}-01-03"
      t = Date.parse parseableDate
    else if 0 < excelTime < 10e5
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
      if not isNumber(t)
        console.warn "excelDateToUnixTime got bad number: #{excelTime} -> #{t}"
        throw "Bad Number Error"
    else
      # Standard date parsing
      t = Date.parse(excelTime)
  catch
    t = if strict then false else Date.now()
  t


renderValidateProgress = (placeAfterSelector = "#file-uploader-form", returnIt = false)->
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
    <br/><br/>
    <button class="btn btn-danger" id="cancel-new-upload"><iron-icon icon="icons:cancel"></iron-icon> Cancel</button>
  </div>
  """
  unless $("#validator-progress-container").exists()
    $(placeAfterSelector).after html
    $("#cancel-new-upload").click ->
      cancelAsyncOperation(this)
  if returnIt
    return html
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
            when "show-su-profiles"
              loadSUProfileBrowser()
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
  try
    checkFileVersion true, "js/kml.min.js"

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
        try
          kmlData = JSON.parse deEscape path
          path = kmlData.path
        catch
          if path.length > 511
            # Might be broken?
            pathJson = fixTruncatedJson path
            if typeof pathJson is "object"
              kmlData = pathJson
              path = kmlData.path
          if isNull kmlData
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
      _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
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
          _adp.originalProjectId = project.project_id
          _adp.fetchResult = result
          ## End Bindings
          ## Real DOM stuff
          # Userlist
          userHtml = ""
          hasDisplayedUser = new Array()
          for user in project.access_data.total
            try
              uid = project.access_data.composite[user]["user_id"]
              if uid in hasDisplayedUser
                continue
              hasDisplayedUser.push uid
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
                  <google-map id="transect-viewport" latitude="#{project.lat}" longitude="#{project.lng}" fit-to-markers map-type="hybrid" disable-default-ui  api-key="#{gMapsApiKey}">
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
            <li role="presentation" class="active" data-view="md"><a>Preview</a></li>
            <li role="presentation" data-view="edit"><a>Edit</a></li>
          </ul>
          <iron-autogrow-textarea id="project-notes" class="markdown-pair project-param language-markdown" rows="3" data-field="sample_notes" hidden #{conditionalReadonly}>#{project.sample_notes}</iron-autogrow-textarea>
          <marked-element class="markdown-pair" id="note-preview">
            <div class="markdown-html"></div>
            <script type="text/markdown">#{mdNotes}</script>
          </marked-element>
          """
          mdFunding = if isNull(project.extended_funding_reach_goals) then "*No funding reach goals*" else project.extended_funding_reach_goals.unescape()
          fundingHtml = """
          <ul class="nav nav-tabs" id="markdown-switcher-funding">
            <li role="presentation" class="active" data-view="md"><a>Preview</a></li>
            <li role="presentation" data-view="edit"><a>Edit</a></li>
          </ul>
          <iron-autogrow-textarea id="project-funding" class="markdown-pair project-param language-markdown" rows="3" data-field="extended_funding_reach_goals" hidden #{conditionalReadonly}>#{project.extended_funding_reach_goals}</iron-autogrow-textarea>
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
          if toInt(project.sampled_collection_start) isnt 0
            # Technically, there is 1ms that this would fail at, but
            # ... close enough is good enough
            d1 = new Date toInt project.sampled_collection_start
            d2 = new Date toInt project.sampled_collection_end
            collectionRangePretty = "#{dateMonthToString d1.getMonth()} #{d1.getFullYear()} &#8212; #{dateMonthToString d2.getMonth()} #{d2.getFullYear()}"
          else
            collectionRangePretty = "<em>(no data)</em>"
          if months.length is 0 or isNull monthPretty then monthPretty = "<em>(no data)</em>"
          if years.length is 0 or isNull yearPretty then yearPretty = "<em>(no data)</em>"
          toggleChecked = if cartoParsed?.raw_data?.filePath? then "" else "checked disabled"
          if isNull project.technical_contact
            project.technical_contact = authorData.name
          if isNull project.technical_contact_email
            project.technical_contact_email = authorData.contact_email
          html = """
          <h2 class="clearfix newtitle col-xs-12">#{project.project_title} #{icon} <paper-icon-button icon="icons:visibility" class="click" data-href="#{uri.urlString}project.php?id=#{opid}" data-toggle="tooltip" title="View in Project Viewer" data-newtab="true"></paper-icon-button><br/><small>Project ##{opid}</small></h2>
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
                <paper-button class="manage-users" id="manage-users-button">Manage Users</paper-button>
              </div>
            </paper-card>
          </section>
          <section id="project-basics" class="col-xs-12 col-md-8 clearfix">
            <h3>Project Basics</h3>
            <paper-input readonly label="Project Identifier" value="#{project.project_id}" id="project_id" class="project-param"></paper-input>
            <paper-input readonly label="Project Creation" value="#{creation.toLocaleString()}" id="project_creation" class="author-param" data-key="entry_date" data-value="#{authorData.entry_date}"></paper-input>
            <div class="row">
              <paper-input readonly label="Project ARK" value="#{project.project_obj_id}" id="project_creation" class="project-param col-xs-11"></paper-input>
              #{getInfoTooltip("ARK or Archival Resource Key identifier is a persistent, citable identifier for this project and maybe used to cite these data in a publication or report. We use the California Digital Library Name Assigning Authority")}
            </div>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Title" value="#{project.project_title}" id="project-title" data-field="project_title"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Primary Pathogen" value="#{project.disease}" data-field="disease"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="PI Lab" value="#{project.pi_lab}" id="project-title" data-field="pi_lab"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Reference" value="#{project.reference_id}" id="project-reference" data-field="reference_id"></paper-input>
            <div class="row">
              <paper-input #{conditionalReadonly} class="project-param col-xs-11" label="Publication DOI" value="#{project.publication}" id="doi" data-field="publication"></paper-input>
              #{getInfoTooltip("Publication DOI citing these datasets may be added here.")}
            </div>
            <paper-input #{conditionalReadonly} class="author-param" data-key="name" label="Project Contact" value="#{authorData.name}" id="project-contact"></paper-input>
            <gold-email-input #{conditionalReadonly} class="author-param" data-key="contact_email" label="Contact Email" value="#{authorData.contact_email}" id="contact-email"></gold-email-input>
            <paper-input #{conditionalReadonly} class="author-param" data-key="diagnostic_lab" label="Diagnostic Lab" value="#{authorData.diagnostic_lab}" id="project-lab"></paper-input>
            <paper-input #{conditionalReadonly} class="author-param" data-key="affiliation" label="Affiliation" value="#{authorData.affiliation}" id="project-affiliation"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Technical/Data Contact" value="#{project.technical_contact}" data-field="technical_contact" id="technical-contact"></paper-input>
            <gold-email-input #{conditionalReadonly} class="project-param" label="Technical/Data Contact_email" value="#{project.technical_contact_email}" data-field="technical_contact_email" id="technical-contact-email"></gold-email-input>
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
                  <span class="toggle-off-label iron-label">Append/Amend Data
                    <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip" title="If you upload a dataset, append all rows as additional data, and modify existing ones by sampleId"></span>
                  </span>
                  <paper-toggle-button id="replace-data-toggle" class="material-red" #{toggleChecked}>Replace Data</paper-toggle-button>
                  <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip" title="If you upload data, archive current data and only have new data parsed"></span>
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
                <paper-button id="reparse-project"><iron-icon icon="icons:cached" class="materialindigotext"></iron-icon> Re-parse Data, Save Project &amp; Reload</paper-button>
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
                <div class="row markdown-pair" id="preview-funding">
                  <span class="pull-left" style="margin-top:1.75em;vertical-align:bottom;padding-left:15px">$</span><paper-input #{conditionalReadonly} class="project-param col-xs-11" label="Additional Funding Request" value="#{project.more_analysis_funding_request}" id="more-analysis-funding" data-field="more_analysis_funding_request" type="number"></paper-input>
                </div>
          </section>
          """
          $("#main-body").html html
          $(".pull-right paper-card .header").click ->
            console.info "Clicked header, triggering collapse"
            $(this).parent().toggleClass "collapsed"
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
          unless isNull project.transect_file
            kmlLoader project.transect_file, ->
              console.debug "Editor loaded KML file"
          # Watch for changes and toggle save watcher state
          # Events
          ## Events for notes
          ta = p$("#project-notes").textarea
          $(ta).keyup ->
            p$("#note-preview").markdown = $(this).val()
          $("#markdown-switcher li").click ->
            $("#markdown-switcher li").removeClass "active"
            $("#markdown-switcher").parent().find(".markdown-pair").removeAttr "hidden"
            $(this).addClass "active"
            targetView = $(this).attr "data-view"
            console.info "Switching to target view", targetView
            switch targetView
              when "md"
                $("#project-notes").attr "hidden", "hidden"
              when "edit"
                $("#note-preview").attr "hidden", "hidden"
            false
          ## Events for funding
          ta = p$("#project-funding").textarea
          $(ta).keyup ->
            p$("#preview-funding").markdown = $(this).val()
          $("#markdown-switcher-funding li").click ->
            $("#markdown-switcher-funding li").removeClass "active"
            $("#markdown-switcher-funding").parent().find(".markdown-pair").removeAttr "hidden"
            $(this).addClass "active"
            targetView = $(this).attr "data-view"
            console.info "Switching to target view", targetView
            switch targetView
              when "md"
                $("#project-funding").attr "hidden", "hidden"
              when "edit"
                $("#preview-funding").attr "hidden", "hidden"
            false
          ##  Events for deletion
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
              _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
              .done (result) ->
                if result.status is true
                  stopLoad()
                  toastStatusMessage "Successfully deleted Project ##{project.project_id}"
                  delay 1000, ->
                    populateAdminActions()
                else
                  stopLoadError result.human_error
                  $(el).remove()
              .fail (result, status) ->
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
          $("#reparse-project").click ->
            try
              recalculateAndUpdateHull()
            revalidateAndUpdateData()
            false
          topPosition = $("#data-management").offset().top
          affixOptions =
            top: topPosition
            bottom: 0
            target: window
          # $("#data-management").affix affixOptions
          # console.info "Affixed at #{topPosition}px", affixOptions
          $("paper-button#manage-users-button").click ->
            popManageUserAccess(_adp.projectData)
          $(".danger-toggle").on "iron-change", ->
            if $(this).get(0).checked
              $(this).find("iron-icon").addClass("material-red")
            else
              $(this).find("iron-icon").removeClass("material-red")
          # Load more detailed data from CartoDB
          unless isNull project.carto_id
            console.info "Getting carto data with id #{project.carto_id} and options", createMapOptions
            getProjectCartoData project.carto_id, createMapOptions
          else
            console.warn "There is no carto data to load up for the editor"
            # Allow uploader anyway
            startEditorUploader()
        catch e
          stopLoadError "There was an error loading your project"
          console.error "Unhandled exception loading project! #{e.message}"
          console.warn e.stack
          loadEditor()
          return false
      .fail (result, status) ->
        console.error "AJAX failure: Error from server", result, status
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
        publicList = Object.toArray result.public_projects
        authoredList = Object.toArray result.authored_projects
        editableList = Object.toArray result.editable_projects
        viewOnlyList = new Array()
        hasEditableProjects = false
        for projectId, projectTitle of result.projects
          accessIcon = if projectId in publicList then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
          icon = if projectId in authoredList then """<iron-icon icon="social:person" data-toggle="tooltip" title="Author"></iron-icon>""" else """<iron-icon icon="social:group" data-toggle="tooltip" title="Collaborator"></iron-icon>"""
          if projectId in editableList
            html = """
            <li>
              <button class="btn btn-primary" data-project="#{projectId}">
                #{accessIcon} #{projectTitle} / ##{projectId.substring(0,8)}
              </button>
              #{icon}
            </li>
            """
            $("#project-list").append html
            hasEditableProjects = true
          else
            viewOnlyList.push projectId
        console.info "Didn't display read-only projects", viewOnlyList
        unless hasEditableProjects

          html = """
          <p class="text-muted col-xs-12" id="no-edits-available">
            Sorry, you have no projects you're eligible to edit.
          </p>
          """
          $("#project-list").before html
          try
            verifyLoginCredentials (result) ->
              rawSu = toInt result.detail.userdata.su_flag
              if rawSu.toBool()
                console.info "NOTICE: This is an SUPERUSER Admin"
                html = """
                <button class="btn btn-xs btn-primary" id="su-view-projects">
                  <iron-icon icon="icons:supervisor-account"></iron-icon>
                   <iron-icon icon="icons:add"></iron-icon>
                  (SU) Administrate All Projects
                </button>
                """
                $("#no-edits-available").append html
                $("#su-view-projects").click ->
                  loadSUProjectBrowser()
        $("#project-list button")
        .unbind()
        .click ->
          project = $(this).attr("data-project")
          editProject(project)
        stopLoad()
      .fail (result, status) ->
        stopLoadError "There was a problem loading viable projects"
  else
    # We have a requested project preload
    editProject(projectPreload)
  false




popManageUserAccess = (project = _adp.projectData, result = _adp.fetchResult) ->
  verifyLoginCredentials (credentialResult) ->
    # For each user in the access list, give some toggles
    console.info "Working with", result, credentialResult, project
    userHtml = ""
    hasDisplayedUser = new Array()
    for user in project.access_data.total
      uid = project.access_data.composite[user]["user_id"]
      if uid in hasDisplayedUser
        continue
      hasDisplayedUser.push uid
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
      if result.user.has_edit_permissions and not isAuthor and uid isnt result.user.user
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
      _adp.currentAsyncJqxhr = $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
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
      .fail (result, status) ->
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
        try
          $("#search-user").parent().removeClass "has-error"
          $("#search-user").parent().removeClass "has-success"
          $("#search-user").parent().find(".help-block").remove()
        _adp.currentAsyncJqxhr = $.post "#{uri.urlString}/api.php", "action=search_users&q=#{search}", "json"
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
            try
              $("#search-user").parent().removeClass "has-error"
              $("#search-user").parent().removeClass "has-success"
              $("#search-user").parent().find(".help-block").remove()
            # Email regex from
            # http://emailregex.com/
            button = if /^(?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$/im.test(search) then """<button class="btn btn-xs btn-primary add-listed-user"> Invite Them </button> """ else "Finish the email address and we can invite them."

            helperHtml = """
            <span class="help-block">
              We couldn't find a user matching "#{search}".
              #{button}
            </span>
            """
            $("#search-user").after helperHtml
            $("#search-user").parent().addClass "has-error"
            $(".add-listed-user").click ->
              ###
              # Perform the invitation
              # See
              #
              # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/181
              ###
              startLoad()
              args = "action=invite&invitee=#{search}"
              $.post "#{uri.urlString}/admin-api.php", args, "json"
              .done (result) ->
                if result.status isnt true
                  niceError = switch result.error
                    when "INVALID_EMAIL"
                      "#{result.target} isn't a valid email"
                    when "ALREADY_REGISTERED"
                      "#{result.target} already has an account"
                    else
                      console.error result
                      "There was a problem sending the email"
                  stopLoadError niceError
                toastStatusMessage "Invitation sent"
                try
                  $("#search-user").parent().removeClass "has-error"
                  $("#search-user").parent().addClass "has-success"
                  $("#search-user").parent().find(".help-block").text "Invitation Sent to #{result.invited}"
                  $("#search-user").val("")
                stopLoad()
              .fail ->
                stopLoadError "Failed to contact the server"
              false
        .fail (result, status) ->
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
    _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
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
        console.info "Adding", user
        try
            userName = user.text()
        catch
            userName = $(user).text()
        ++i
        html = """
            <tr class="user-permission-list-row" data-user="#{uid}">
              <td colspan="5">#{userName}</td>
              <td class="text-center user-current-permission">#{icon}</td>
            </tr>
        """
        $("#permissions-table").append html
        ## Update _adp.projectData.access_data
        userObj =
          email: user
          user_id: uid
          permission: "READ"
        try
          unless isArray _adp.projectData.access_data.total
            _adp.projectData.access_data.total = Object.toArray _adp.projectData.access_data.total
            _adp.projectData.access_data.viewers_list = Object.toArray _adp.projectData.access_data.viewers_list
            _adp.projectData.access_data.viewers = Object.toArray _adp.projectData.access_data.viewers
        _adp.projectData.access_data.total.push user
        _adp.projectData.access_data.viewers_list.push user
        _adp.projectData.access_data.viewers.push userObj
        _adp.projectData.access_data.raw = result.new_access_saved
        _adp.projectData.access_data.composite[user] = userObj
      # Dismiss the dialog
      p$("#add-new-user").close()
    .fail (result, status) ->
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
          console.warn "Told", err1, e.message
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
  if isNull cartoTable
    console.warn "There's no assigned table, not pulling carto data"
    stopLoad()
    startEditorUploader()
    return false
  # Ping Carto on this and get the data
  getCols = "SELECT * FROM #{cartoTable} WHERE FALSE"
  args = "action=fetch&sql_query=#{post64(getCols)}"
  _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
  .done (result) ->
    try
      r = JSON.parse(result.post_response[0])
    catch e
      console.error "Couldn't load carto data! (#{e.message})", result
      console.warn "post_response: (want key 0)", result.post_response
      console.warn "Base data source:", cartoData
      console.warn e.stack
      stopLoadError "There was a problem talking to CartoDB. Please try again later"
      startEditorUploader()
      return false
    cols = new Object()
    for k, v of r.fields
      cols[k] = v
    _adp.activeCols = cols
    colsArr = new Array()
    colRemap = new Object()
    for col, type of cols
      if col isnt "id" and col isnt "the_geom"
        colsArr.push col
      colRemap[col.toLowerCase()] = col
    _adp.colsList = colsArr
    _adp.colRemap = colRemap
    cartoQuery = "SELECT #{colsArr.join(",")}, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
    # cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
    console.info "Would ping cartodb with", cartoQuery
    apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
    args = "action=fetch&sql_query=#{apiPostSqlQuery}"
    _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
    .done (result) ->
      console.info "Carto query got result:", result
      unless result.status
        error = result.human_error ? result.error
        unless error?
          error = "Unknown error"
        stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
        return false
      rows = result.parsed_responses[0].rows
      _adp.cartoRows = new Object()
      for i, row of rows
        _adp.cartoRows[i] = new Object()
        for col, val of row
          realCol = colRemap[col] ? col
          _adp.cartoRows[i][realCol] = val
      truncateLength = 0 - "</google-map>".length
      try
        workingMap = geo.googleMapWebComponent.slice 0, truncateLength
      catch
        workingMap = "<google-map>"
      pointArr = new Array()
      for k, row of rows
        geoJson = JSON.parse row.st_asgeojson
        # # cartoDB stores as lng, lat
        # lat = geoJson.coordinates[1]
        # lng = geoJson.coordinates[0]
        lat = row.decimallatitude
        lng = row.decimallongitude
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
      _adp.workingProjectPoints = pointArr
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
            # bsAlert "We've updated some of your data automatically. Please save the project before continuing.", "warning"
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
      <p>You can upload more data below, or replace existing data of the same type.</p>
      <br/><br/>
      <p class="text-muted">
        Allowed types (single type of each): <code>*.kml</code>, <code>*.kmz</code>, <code>*.xls</code>, <code>*.xlsx</code>
        <br/>
        Allowed types (inifinite copies): <code>image/*</code>, <code>*.pdf</code>, <code>*.7z</code>, <code>*.zip</code>
      </p>
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
    startEditorUploader()
  .fail (result, status) ->
    false
  false



startEditorUploader = ->
  # We've finished the handler, reinitialize
  unless $("link[href='bower_components/neon-animation/animations/fade-out-animation.html']").exists()
    animations = """
    <link rel="import" href="bower_components/neon-animation/animations/fade-in-animation.html" />
    <link rel="import" href="bower_components/neon-animation/animations/fade-out-animation.html" />
    """
    $("head").append animations
  bootstrapUploader "data-card-uploader", "", ->
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
      try
        pathPrefix = "helpers/js-dragdrop/uploaded/#{getUploadIdentifier()}/"
        fileName = result.full_path.split("/").pop()
        thumbPath = result.wrote_thumb
        mediaType = result.mime_provided.split("/")[0]
        longType = result.mime_provided.split("/")[1]
        linkPath = if file.size < 5*1024*1024 or mediaType isnt "image" then "#{pathPrefix}#{result.wrote_file}" else "#{pathPrefix}#{thumbPath}"
        checkPath = linkPath.slice 0
        cp2 = linkPath.slice 0
        extension = cp2.split(".").pop()
      catch e
        console.warn "Warning - #{e.message}"
        console.warn e.stack
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
      checkKml = [
        "vnd.google-earth.kml+xml"
        "vnd.google-earth.kmz"
        "xml"
        ]
      if longType in checkKml
        if extension is "kml" or extension is "kmz"
          finKml = (kdata) ->
            transectFileObj =
              path: linkPath
              data: kdata
            try
              _adp.projectData.transect_file = JSON.stringify transectFileObj
            catch e
              try
                console.warn "Couldn't stringify json - #{e.message}", linkPath, kdata
              _adp.projectData.transect_file = linkPath
            bsAlert "Your KML will take over your current bounding polygon once you save and refresh this page"
          return kmlHandler(linkPath, finKml)
        else
          console.warn "Non-KML xml"
          allError "Sorry, we can't processes files of type application/#{longType}"
          return false
      try
        # Open up dialog
        html = renderValidateProgress("dont-exist", true)
        dialogHtml = """
        <paper-dialog modal id="upload-progress-dialog"
          entry-animation="fade-in-animation"
          exit-animation="fade-out-animation">
          <h2>Upload Progress</h2>
          <paper-dialog-scrollable>
            <div id="upload-progress-container" style="min-width:80vw; ">
            </div>
            #{html}
      <p class="col-xs-12">Species in dataset</p>
      <iron-autogrow-textarea id="species-list" class="project-field  col-xs-12" rows="3" placeholder="Taxon List" readonly></iron-autogrow-textarea>
          </paper-dialog-scrollable>
          <div class="buttons">
            <paper-button id="close-overlay">Close &amp; Cancel</paper-button>
            <paper-button id="save-now-upload" disabled>Save</paper-button>
          </div>
        </paper-dialog>
        """
        $("#upload-progress-dialog").remove()
        $("body").append dialogHtml
        p$("#upload-progress-dialog").open()
        $("#close-overlay").click ->
          cancelAsyncOperation(this)
          p$("#upload-progress-dialog").close()
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
                excelHandler2(linkPath)
              when "zip", "x-zip-compressed"
                # Some servers won't read it as the crazy MS mime type
                # But as a zip, instead. So, check the extension.
                #
                if file.type is "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or linkPath.split(".").pop() is "xlsx"
                  excelHandler2(linkPath)
                else
                  zipHandler(linkPath)
                  p$("#upload-progress-dialog").close()
              when "x-7z-compressed"
                _7zHandler(linkPath)
                p$("#upload-progress-dialog").close()
              when "vnd.google-earth.kml+xml", "vnd.google-earth.kmz", "xml"
                if extension is "kml" or extension is "kmz"
                  kmlHandler(linkPath)
                  p$("#upload-progress-dialog").close()
                else
                  console.warn "Non-KML xml"
                  allError "Sorry, we can't processes files of type application/#{longType}"
                  p$("#upload-progress-dialog").close()
                  return false
              else
                console.warn "Unknown mime type application/#{longType}"
                allError "Sorry, we can't processes files of type application/#{longType}"
                p$("#upload-progress-dialog").close()
                return false
          when "text"
            csvHandler()
            p$("#upload-progress-dialog").close()
          when "image"
            imageHandler()
            p$("#upload-progress-dialog").close()
      catch e
        toastStatusMessage "Your file uploaded successfully, but there was a problem in the post-processing."
      false
  false

excelHandler2 = (path, hasHeaders = true, callbackSkipsRevalidate) ->
  startLoad()
  $("#validator-progress-container").remove()
  helperApi = "#{helperDir}excelHelper.php"
  correctedPath = path
  if path.search(helperDir) isnt -1
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
    # We don't care about the single file here
    $("#upload-data").attr "disabled", "disabled"
    nameArr = path.split "/"
    dataFileParams.hasDataFile = true
    dataFileParams.fileName = nameArr.pop()
    dataFileParams.filePath = correctedPath
    rows = Object.size(result.data)
    uploadedData = result.data
    _adp.parsedUploadedData = result.data
    unless typeof callbackSkipsRevalidate is "function"
      if p$("#replace-data-toggle").checked
        # Replace
        # Show the dialog
        startLoad()
        revalidateAndUpdateData false, false, false, false, true
        console.info "Starting newGeoDataHandler to handle a replacement dataset"
        _adp.projectIdentifierString = "t" + md5(_adp.projectId + _adp.projectData.author + Date.now())
        html = """
        <div class="row">
        <div class="alert alert-info col-xs-12" id="still-processing">
          Please do not close this window until your upload has finished. As long as this message is showing, your processing is still incomplete.
        </div>
        </div>
        """
        $("#validator-progress-container").before html
        newGeoDataHandler result.data, false, (tableName, pointCoords) ->
          console.info "Upload and save complete", tableName
          startLoad()
          # console.log "Got coordinates", pointCoords
          # try
          #   cartoParsed = JSON.parse _adp.carto_id
          # else
          #   cartoParsed = new Object()
          # # Parse out the changed geo data
          # cartoParsed.table = tableName
          # cartoParsed.raw_data =
          #   hasDataFile: true
          #   fileName: dataFileParams.fileName
          #   filePath: dataFileParams.filePath
          # # Get new bounds
          # createConvexHull(geo.boundingBox)
          # simpleHull = new Array()
          # for p in geo.canonicalHullObject.hull
          #   simpleHull.push p.getObj()
          # cartoParsed.bounding_polygon = simpleHull
          # _adp.sample_raw_data = "https://amphibiandisease.org/#{dataFileParams.filePath}"
          # _adp.bounding_box_n = geo.computedBoundingRectangle.north
          # _adp.bounding_box_s = geo.computedBoundingRectangle.south
          # _adp.bounding_box_e = geo.computedBoundingRectangle.east
          # _adp.bounding_box_w = geo.computedBoundingRectangle.west
          # # Get new center
          # # New locality
          # _adp.locality = geo.computedLocality
          # # New dataset ark
          finalizeData true, (readyPostData) ->
            readyPostData.project_id = _adp.originalProjectId
            _adp.reassignedTrashProjectId = _adp.projectId
            _adp.projectId = _adp.originalProjectId
            console.info "Successfully finalized data", readyPostData
            $("#still-processing").remove()
            html = """
            <div class="row">
            <div class="alert alert-warning center-block text-center col-xs-8 force-center">
              <strong>IMPORTANT</strong>: Remember to save your project after closing this window!<br/><br/>
                If you don't, your new data <em>will not be saved</em>!
            </div>
            </div>
            """
            $("#validator-progress-container").before html
            # _adp.carto_id = JSON.stringify cartoParsed
            _adp.projectData = readyPostData
            $("#save-now-upload")
            .click ->
              saveEditorData true, ->
                document.location.reload
            .removeAttr "disabled"
            stopLoad()
      else
        # Update
        console.info "Starting revalidateAndUpdateData to handle an update"
        revalidateAndUpdateData(result)
    else
      console.warn "Skipping Revalidator() !"
      callbackSkipsRevalidate(result)
    stopLoad()
  .fail (result, error) ->
    console.error "Couldn't POST"
    console.warn result
    console.warn error
    errorMessage = "<code>#{result.status} #{result.statusText}</code>"
    stopLoadBarsError("There was a problem with the server handling your data. The server said: #{errorMessage}")
    delay 500, ->
      stopLoad()
  false


revalidateAndUpdateData = (newFilePath = false, skipCallback = false, testOnly = false, skipSave = false, onlyDialog = false) ->
  unless $("#upload-progress-dialog").exists()
    html = renderValidateProgress("dont-exist", true)
    dialogHtml = """
    <paper-dialog modal id="upload-progress-dialog"
      entry-animation="fade-in-animation"
      exit-animation="fade-out-animation">
      <h2>Upload Progress</h2>
      <paper-dialog-scrollable>
        <div id="upload-progress-container" style="min-width:80vw; ">
        </div>
        #{html}
  <p class="col-xs-12">Species in dataset</p>
  <iron-autogrow-textarea id="species-list" class="project-field  col-xs-12" rows="3" placeholder="Taxon List" readonly></iron-autogrow-textarea>
      </paper-dialog-scrollable>
      <div class="buttons">
        <paper-button id="close-overlay">Close &amp; Cancel</paper-button>
        <paper-button id="save-now-upload" disabled>Save</paper-button>
      </div>
    </paper-dialog>
    """
    $("#upload-progress-dialog").remove()
    $("body").append dialogHtml
    $("#close-overlay").click ->
      cancelAsyncOperation(this)
      p$("#upload-progress-dialog").close()
  safariDialogHelper "#upload-progress-dialog"
  if onlyDialog
    return false
  try
    cartoData = JSON.parse _adp.projectData.carto_id.unescape()
    _adp.cartoData = cartoData
  catch
    link = $.cookie "#{uri.domain}_link"
    cartoData =
      table: _adp.projectIdentifierString + "_#{link}"
      bounding_polygon: new Object()
  skipHandler = false
  if newFilePath isnt false
    if typeof newFilePath is "object"
      skipHandler = true
      passedData = newFilePath.data
      path = newFilePath.path.requested_path
    else
      path = newFilePath
  else
    path = _adp.projectData.sample_raw_data.slice uri.urlString.length
    unless path?
      if dataFileParams?.filePath?
        path = dataFileParams.filePath
      else
        path = cartoData.raw_data.filePath
  _adp.projectIdentifierString = cartoData.table.split("_")[0]
  _adp.projectId = _adp.projectData.project_id
  unless _adp.fims?.expedition?.expeditionId?
    _adp.fims =
      expedition:
        expeditionId: 26
        ark: _adp.projectData.project_obj_id

  dataCallback = (data) ->
    # Is this a legitimate operation?
    allowedOperations = [
      "edit"
      "create"
      ]
    operation = if p$("#replace-data-toggle").checked then "create" else "edit" # For now
    unless operation in allowedOperations
      console.error "#{operation} is not an allowed operation on a data set!"
      console.info "Allowed operations are ", allowedOperations
      toastStatusMessage "Sorry, '#{operation}' isn't an allowed operation."
      return false
    if operation is "create"
      newGeoDataHandler data, (validatedData, projectIdentifier) ->
        geo.requestCartoUpload validatedData, projectIdentifier, "create", (table, coords, options) ->
          bsAlert "Hang on for a moment while we reprocess this for saving", "info"
          cartoData.table = geo.dataTable
          # Call back and re-parse all this
          try
            if isArray points
              cartoData = recalculateAndUpdateHull()
          _adp.projectData.carto_id = JSON.stringify cartoData
          path = dataFileParams.filePath
          revalidateAndUpdateData(path)
          false
        false
      return false
    newGeoDataHandler data, (validatedData, projectIdentifier) ->
      console.info "Ready to update", validatedData
      dataTable = cartoData.table
      data = validatedData.data
      # Need carto update
      if typeof data isnt "object"
        console.info "This function requires the base data to be a JSON object."
        toastStatusMessage "Your data is malformed. Please double check your data and try again."
        return false


      if isNull dataTable
        console.error "Must use a defined table name!"
        toastStatusMessage "You must name your data table"
        return false

      # Is the user allowed and logged in?
      link = $.cookie "#{uri.domain}_link"
      hash = $.cookie "#{uri.domain}_auth"
      secret = $.cookie "#{uri.domain}_secret"
      unless link? and hash? and secret?
        console.error "You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret
        toastStatusMessage "Sorry, you're not logged in. Please log in and try again."
        return false
      args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
      ## NOTE THIS SHOULD ACTUALLY VERIFY THAT THE DATA COULD BE WRITTEN
      # TO THIS PROJECT BY THIS PERSON!!!
      #
      # Some of this could, in theory, be done via
      # http://docs.cartodb.com/cartodb-platform/cartodb-js/sql/
      unless adminParams?.apiTarget?
        console.warn "Administration file not loaded. Upload cannot continue"
        stopLoadError "Administration file not loaded. Upload cannot continue"
        return false
      _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
      .done (result) ->
        if result.status
          console.info "Validated data", validatedData
          sampleLatLngArray = new Array()
          # Before we begin parsing, throw up an overlay for the duration
          # Loop over the data and clean it up
          # Create a GeoJSON from the data
          lats = new Array()
          lngs = new Array()
          for n, row of data
            ll = new Array()
            for column, value of row
              switch column
                when "decimalLongitude"
                  ll[1] = value
                  lngs.push value
                when "decimalLatitude"
                  ll[0] = value
                  lats.push value
            sampleLatLngArray.push ll
          bb_north = lats.max() ? 0
          bb_south = lats.min() ? 0
          bb_east = lngs.max() ? 0
          bb_west = lngs.min() ? 0
          defaultPolygon = [
              [bb_north, bb_west]
              [bb_north, bb_east]
              [bb_south, bb_east]
              [bb_south, bb_west]
            ]
          # See if the user provided a good transect polygon
          try
            # See if the user provided a valid JSON string of coordinates
            if typeof data.transectRing is "string"
              userTransectRing = JSON.parse validatedData.transectRing
            else
              userTransectRing = validatedData.transectRing
            userTransectRing = Object.toArray userTransectRing
            i = 0
            for coordinatePair in userTransectRing
              if coordinatePair instanceof Point
                # Coerce it into simple coords
                coordinatePair = coordinatePair.toGeoJson()
                userTransectRing[i] = coordinatePair
              # Is it just two long?
              if coordinatePair.length isnt 2
                throw
                  message: "Bad coordinate length for '#{coordinatePair}'"
              for coordinate in coordinatePair
                unless isNumber coordinate
                  throw
                    message: "Bad coordinate number '#{coordinate}'"
              ++i
          catch e
            console.warn "Error parsing the user transect ring - #{e.message}"
            userTransectRing = undefined
          # Massive object row
          transectPolygon = userTransectRing ? defaultPolygon
          geoJson =
            type: "GeometryCollection"
            geometries: [
                  type: "MultiPoint"
                  coordinates: sampleLatLngArray # An array of all sample points
                ,
                  type: "Polygon"
                  coordinates: transectPolygon
              ]
          dataGeometry = "ST_AsBinary(#{JSON.stringify(geoJson)}, 4326)"
          # Rows per-sample ...
          # FIMS based
          # Uses DarwinCore terms
          # http://www.biscicol.org/biocode-fims/template#
          # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
          columnDatatype = getColumnObj()
          # Make a lookup sampleId -> obj map
          try
            lookupMap = new Object()
            for i, row of _adp.cartoRows
              sampleId = row.sampleId ? row.sampleid
              try
                trimmed = sampleId.trim()
              catch
                continue
              # For field that are "PLC 123", remove the space
              trimmed = trimmed.replace /^([a-zA-Z]+) (\d+)$/mg, "$1$2"
              sampleId = trimmed
              lookupMap[sampleId] = i
          catch
            console.warn "Couldn't make lookupMap"
          # Construct the SQL query
          sqlQuery = ""
          valuesList = new Array()
          columnNamesList = new Array()
          columnNamesList.push "id int"
          _adp.rowsCount = Object.size data
          _adp.lookupMap = lookupMap
          for i, row of data
            i = toInt(i)

            ##console.log "Iter ##{i}", i is 0, `i == 0`
            # Each row ...
            valuesArr = new Array()
            lat = 0
            lng = 0
            alt = 0
            err = 0
            geoJsonGeom =
              type: "Point"
              coordinates: new Array()
            iIndex = i + 1
            sampleId = row.sampleId
            try
              refRowNum = lookupMap[sampleId]
            refRow = null
            if refRowNum?
              refRow = _adp.cartoRows[refRowNum]
            #console.info "For row #{i}, fn #{sampleId} = refrownum #{refRowNum}", refRow
            colArr = new Array()
            for column, value of row
              # Loop data ....
              if i is 0
                columnNamesList.push "#{column} #{columnDatatype[column]}"
              try
                # Strings only!
                value = value.replace("'", "&#95;")
              switch column
                # Assign geoJSON values
                when "decimalLongitude"
                  geoJsonGeom.coordinates[1] = value
                when "decimalLatitude"
                  geoJsonGeom.coordinates[0] = value
                when "sampleId"
                  if refRow?
                    continue
              if refRow?
                refVal = refRow[column] ? refRow[column.toLowerCase()]
                if typeof refVal is "object"
                  if typeof value is "string"
                    try
                      v2 = JSON.parse value
                  else
                    v2 = value
                  roundCutoff = 10 # Should be more than good enough
                  for k, v of v2
                    if typeof v is "number"
                      v2[k] = roundNumber v, roundCutoff
                  for k, v of refVal
                    if typeof v is "number"
                      refVal[k] = roundNumber v, roundCutoff
                  cv = JSON.stringify v2
                  refVal = JSON.stringify refVal
                  if refVal is cv then continue
                  else
                    console.info "No Object Match:", refVal, cv
                if typeof value is "boolean"
                  altRefVal = refVal.toBool()
                else if typeof refVal is "boolean"
                  altRefVal = refVal.toString()
                else if typeof refVal is "number"
                  altRefVal = "#{refVal}"
                else if typeof value is "number"
                  altRefVal = toFloat refVal
                else if refVal is "null"
                  altRefVal = null
                else if refVal is null
                  altRefVal = "null"
                else
                  try
                    altRefVal = refVal.replace "T00:00:00Z", ""
                  catch
                    altRefVal = undefined
                if refVal is value or altRefVal is value
                  # Don't need to add it again
                    continue
                else
                  console.info "Not skipping for", refVal, altRefVal, "on #{row.sampleId} @ #{column} = ", value
              if typeof value is "string"
                if refRow?
                  valuesArr.push "#{column.toLowerCase()}='#{value}'"
                else
                  valuesArr.push "'#{value}'"
              else if isNull value
                if refRow?
                  valuesArr.push "#{column.toLowerCase()}=null"
                else
                  valuesArr.push "null"
              else
                if refRow?
                  valuesArr.push "#{column.toLowerCase()}=#{value}"
                else
                  valuesArr.push value
              colArr.push column
            # cartoDB stores as lng, lat
            geoJsonVal = "ST_SetSRID(ST_Point(#{geoJsonGeom.coordinates[1]},#{geoJsonGeom.coordinates[0]}),4326)"
            if refRow?
              # is it needed?
              gjString = JSON.stringify geoJsonGeom
              refGeom = refRow.the_geom ? refRow.st_asgeojson
              if refGeom isnt gjString
                console.info "Not skipping coords", refGeom, geoJsonGeom, gjString
                valuesArr.push "the_geom=#{geoJsonVal}"
            else
              colArr.push "the_geom"
              valuesArr.push geoJsonVal
            if valuesArr.length is 0
              continue
            if refRow?
              sqlWhere = " WHERE sampleid='#{sampleId}';"
              sqlQuery += "UPDATE #{dataTable} SET #{valuesArr.join(", ")} #{sqlWhere}"
            else
              # Add new row
              sqlQuery += "INSERT INTO #{dataTable} (#{colArr.join(",")}) VALUES (#{valuesArr.join(",")}); "
          # console.log sqlQuery
          statements = sqlQuery.split ";"
          statementCount = statements.length - 1
          console.log statements
          console.info "Running #{statementCount} statements"

          if testOnly is true
            console.warn "Exiting before carto post because testOnly is set true"
            return false
          geo.postToCarto sqlQuery, dataTable, (table, coords, options) ->
            console.info "Post carto callback fn"
            bsAlert "<strong>Please Wait</strong>: Re-Validating your total taxa data", "info"
            try
              p$("#taxa-validation").value = 0
              p$("#taxa-validation").indeterminate = true
            # Recalculate hull and update project data
            _adp.canonicalHull = createConvexHull coords, true
            cartoData.bounding_polygon.paths = _adp.canonicalHull.hull
            _adp.projectData.carto_id = JSON.stringify cartoData
            # Update project data with new taxa info
            # Recheck the integrated taxa

            cartoQuery = "SELECT #{_adp.colsList.join(",")}, ST_asGeoJSON(the_geom) FROM #{dataTable};"
            args = "action=fetch&sql_query=#{post64(cartoQuery)}"
            _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
            .done (result) ->
              console.info "Carto query got result:", result
              unless result.status
                error = result.human_error ? result.error
                unless error?
                  error = "Unknown error"
                stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
                return false
              rows = result.parsed_responses[0].rows
              _adp.cartoRows = new Object()
              for i, row of rows
                _adp.cartoRows[i] = new Object()
                for col, val of row
                  realCol = _adp.colRemap[col] ? col
                  _adp.cartoRows[i][realCol] = val
              faux =
                data: _adp.cartoRows
              try
                p$("#taxa-validation").indeterminate = false
              validateTaxonData faux, (taxa) ->
                validatedData.validated_taxa = taxa.validated_taxa
                _adp.projectData.includes_anura = false
                _adp.projectData.includes_caudata = false
                _adp.projectData.includes_gymnophiona = false
                for taxonObject in validatedData.validated_taxa
                  aweb = taxonObject.response.validated_taxon
                  console.info "Aweb taxon result:", aweb
                  clade = aweb.order.toLowerCase()
                  key = "includes_#{clade}"
                  _adp.projectData[key] = true
                  # If we have all three, stop checking
                  if _adp.projectData.includes_anura isnt false and _adp.projectData.includes_caudata isnt false and _adp.projectData.includes_gymnophiona isnt false then break
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
                  unless taxonString in taxonList
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
                try
                  p$("#species-list").bindValue = taxonListString
                dataAttrs.dataObj = validatedData
                _adp.data.dataObj = validatedData
                _adp.data.taxa = new Object()
                _adp.data.taxa.list = taxonList
                _adp.data.taxa.clades = cladeList
                _adp.data.taxa.validated = validatedData.validated_taxa
                _adp.projectData.sampled_species = taxonList.join ","
                _adp.projectData.sampled_clades = cladeList.join ","
                # Update project data with new sample data
                _adp.projectData.disease_morbidity = validatedData.samples.morbidity
                _adp.projectData.disease_mortality = validatedData.samples.mortality
                _adp.projectData.disease_positive = validatedData.samples.positive
                _adp.projectData.disease_negative = validatedData.samples.negative
                _adp.projectData.disease_no_confidence = validatedData.samples.no_confidence
                _adp.projectData.disease_samples = _adp.rowsCount
                # All the parsed month data, etc.
                center = getMapCenter(geo.boundingBox)
                # Have some fun times with uploadedData
                excursion = 0
                dates = new Array()
                months = new Array()
                years = new Array()
                methods = new Array()
                catalogNumbers = new Array()
                sampleIds = new Array()
                dispositions = new Array()
                sampleMethods = new Array()
                for row in Object.toArray _adp.cartoRows
                  # sanify the dates
                  date = row.dateidentified
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
                    catalogNumbers.push row.catalognumber
                  sampleIds.push row.sampleid
                  # Prepare to calculate the radius
                  rowLat = row.decimallatitude
                  rowLng = row.decimallongitude
                  distanceFromCenter = geo.distance rowLat, rowLng, center.lat, center.lng
                  if distanceFromCenter > excursion then excursion = distanceFromCenter
                  # Samples
                  if row.samplemethod?
                    unless row.samplemethod in sampleMethods
                      sampleMethods.push row.samplemethod
                  if row.specimendisposition?
                    unless row.specimendisposition in dispositions
                      dispositions.push row.sampledisposition
                console.info "Got date ranges", dates
                months.sort()
                years.sort()
                _adp.projectData.sampled_collection_start = dates.min()
                _adp.projectData.sampled_collection_end = dates.max()
                console.info "Collected from", dates.min(), dates.max()
                _adp.projectData.sampling_months = months.join(",")
                _adp.projectData.sampling_years = years.join(",")
                _adp.projectData.sample_catalog_numbers = catalogNumbers.join(",")
                _adp.projectData.sample_field_numbers = sampleIds.join(",")
                _adp.projectData.sample_methods_used = sampleMethods.join(",")
                try
                  recalculateAndUpdateHull()
                # Finalizing callback
                finalize = ->
                  # Save it
                  # Update the file downloader link
                  $("#download-project-file").attr("data-href", correctedPath)
                  console.info "Raw data download repointed to", correctedPath
                  _adp.skipRead = true
                  _adp.dataBu = _adp.projectData
                  if skipSave is true
                    console.warn "Save skipped on flag!"
                    console.info "Project data", _adp.projectData
                    return false
                  saveEditorData true, ->
                    if skipCallback is true
                      # Debugging
                      console.info "Saved", _adp.projectData, dataBu
                    unless localStorage._adp?
                      document.location.reload(true)
                  false
                # If the datasrc isn't the stored one, remint an ark and
                # append
                fullPath = "#{uri.urlString}#{validatedData.dataSrc}"
                if fullPath isnt _adp.projectData.sample_raw_data
                  # Mint it
                  arks = _adp.projectData.dataset_arks.split(",")
                  unless _adp.fims?.expedition?.ark?
                    unless _adp.fims?
                      _adp.fims = new Object()
                    unless _adp.fims.expedition?
                      _adp.fims.expedition = new Object()
                    _adp.fims.expedition.ark = _adp.projectData.project_obj_id
                  if _adp.originalProjectId?
                    if _adp.projectId isnt _adp.originalProjectId or _adp.projectData.project_id isnt _adp.originalProjectId
                      _adp.projectId = _adp.originalProjectId
                      _adp.projectData.project_id = _adp.originalProjectId
                  if _adp.projectData.project_id isnt _adp.projectId
                    _adp.projectId = _adp.projectData.project_id
                  mintBcid _adp.projectId, fullPath, _adp.projectData.project_title, (result) ->
                    if result.ark?
                      fileA = fullPath.split("/")
                      file = fileA.pop()
                      newArk = "#{result.ark}::#{file}"
                      arks.push newArk
                      _adp.projectData.dataset_arks = arks.join(",")
                    else
                      console.warn "Couldn't mint!"
                    _adp.previousRawData = _adp.projectData.sample_raw_data
                    _adp.projectData.sample_raw_data = fullPath
                    finalize()
                else
                  finalize()
                false # End validateTaxa callback
              false # End updated carto fetch callback
            .fail (result, status) ->
              stopLoadError "Error fetching updated table"
            false # End postToCarto callback
          false # End API validation check
        else
          stopLoadError "Invalid user"
      .fail (result, status) ->
        stopLoadError "Error updating Carto"
      false # End newGeoDataHandler callback
    false # End dataCallback
  unless skipHandler
    excelHandler2 path, true, (resultObj) ->
      data = resultObj.data
      dataCallback(data)
  else
    dataCallback(passedData)
  false



recalculateAndUpdateHull = (points = _adp.workingProjectPoints) ->
  unless points?
    console.error "Can't run without points!"
  _adp.projectPreModBackup = _adp.projectData
  try
    localStorage.projectPreModBackup = JSON.stringify _adp.projectData
  _adp.canonicalHull = createConvexHull points, true
  if isNull _adp.canonicalHull
    return false
  simpleHull = new Array()
  for point in _adp.canonicalHull.hull
    simpleHull.push point.getObj()
  try
    cartoData = JSON.parse _adp.projectData.carto_id
  catch
    cartoData = new Object()
  opacity = cartoData.bounding_polygon?.fillOpacity ? defaultFillOpacity
  color =   cartoData.bounding_polygon?.fillColor ? defaultFillColor
  consoleCopy = cartoData
  console.warn "Overwriting cartoData", consoleCopy
  cartoData.bounding_polygon =
    paths: _adp.canonicalHull.hull
    fillOpacity: opacity
    fillColor: color
  _adp.projectData.carto_id = JSON.stringify cartoData
  cartoData


remintArk = ->
  title = _adp.projectData.project_title.trim()
  mintExpedition _adp.projectData.project_id, title, (arkResult) ->
    if arkResult.status is true
      _adp.projectData.project_obj_id = arkResult.ark.identifier
      console.log "New ARK:", _adp.projectData.project_obj_id
      console.warn "The save may not update the ARK -- it may have to be manually changed in the database"
      saveEditorData(true)


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
    unless _adp.skipRead is true
      for el in $(".project-param:not([readonly])")
        key = $(el).attr "data-field"
        if isNull key then continue
        postData[key] = p$(el).value.unescape()
      authorObj = new Object()
      for el in $(".author-param")
        key = $(el).attr "data-key"
        authorObj[key] = $(el).attr("data-value") ? p$(el).value
      postData.author_data = JSON.stringify authorObj
    _adp.postedSaveData = postData
    _adp.postedSaveTimestamp = Date.now()
  else
    window._adp = JSON.parse localStorage._adp
    postData = _adp.postedSaveData
  # Clean up any double parsing
  for key, data of postData
    try
      postData[key] = deEscape data
  isChangingPublic = false
  if $("paper-toggle-button#public").exists()
    postData.public = p$("paper-toggle-button#public").checked
    if postData.public
      isChangingPublic = true
      try
        recalculateAndUpdateHull()
        postData.carto_id = _adp.projectData.carto_id
  # Post it
  if _adp.originalProjectId?
    if _adp.originalProjectId isnt _adp.projectId
      console.warn "Mismatched IDs!", _adp.originalProjectId, _adp.projectId
      postData.project_id = _adp.originalProjectId
  try
    ###
    # POST data craps out with too many points
    # Known failure at 4594*4
    ###
    maxPathCount = 4000
    try
      cd = JSON.parse postData.carto_id
      paths = cd.bounding_polygon.paths
    catch
      paths = []
    try
      tf = JSON.parse postData.transect_file
      tfPaths = tf.data.parameters.paths
    catch
      tfPaths = []
    bpPathCount = Object.size paths
    try
      for multi in cd.bounding_polygon.multibounds
        bpPathCount += Object.size multi
    tfPathCount = Object.size tfPaths
    try
      for multi in tf.data.polys
        tfPathCount += Object.size multi
    pointCount = bpPathCount + tfPathCount
    if pointCount > maxPathCount
      console.warn "Danger: Have #{pointCount} paths. The recommended max is #{maxPathCount}"
      if tfPathCount is bpPathCount
        tf.data.parameters.paths = "SEE_BOUNDING_POLY"
        try
          i = 0
          for pathSet in tf.data.polys
            tf.data.polys[i] = "SEE_BOUNDING_POLY"
            ++i
        postData.transect_file = JSON.stringify tf
        tfPathCount = tf.data.parameters.paths.length
      try
        cd.bounding_polygon.paths = false
        postData.carto_id = JSON.stringify cd
        bpPathCount = 0
      try
        for multi in cd.bounding_polygon.multibounds
          bpPathCount += Object.size multi
      try
        for multi in tf.data.polys
          tfPathCount += Object.size multi
      pointCount = bpPathCount + tfPathCount
      console.debug "Shrunk to reduced data size #{pointCount}. May have compatability errors."
  catch e
    console.error "Couldn't check path count -- #{e.message}. Faking it."
    pointCount = maxPathCount + 1
  postData.modified = Date.now() / 1000
  console.log "Sending to server", postData
  args = "perform=save&data=#{jsonTo64 postData}"
  debugInfoDelay = delay 10000, ->
    console.warn "POST may have hung after 10 seconds"
    console.warn "args length was '#{args.length}' = #{args.length * 8} bytes"
    false
  _adp.currentAsyncJqxhr = $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
  .done (result) ->
    console.info "Save result: server said", result
    unless result.status is true
      error = result.human_error ? result.error ? "There was an error saving to the server"
      stopLoadError "There was an error saving to the server"
      localStorage._adp = JSON.stringify _adp
      bsAlert "<strong>Save Error:</strong> #{error}. An offline backup has been made.", "danger"
      console.error result.error
      return false
    stopLoad()
    toastStatusMessage "Save successful"
    # Notify
    d = new Date()
    ds = d.toLocaleString()
    qargs =
      action: "notify"
      subject: "Project '#{result.project.project.project_title}' Updated"
      body: "Project #{result.project.project_id} ('#{result.project.project.project_title}') updated at #{ds} by <a href='https://amphibiandisease.org/profile.php?id=#{result.project.user.user}'>#{$.cookie('amphibiandisease_fullname')}&lt;<code>#{$.cookie('amphibiandisease_user')}</code>&gt;</a>"
    $.get "#{uri.urlString}admin-api.php", buildArgs qargs, "json"
    # Ping the record migrator
    $.get "#{uri.urlString}recordMigrator.php"
    # Update the project data
    _adp.projectData = result.project.project
    delete localStorage._adp
    if isChangingPublic
      if _adp.projectData.public
        $("paper-toggle-button#public").parent().remove()
        newStatus = """
        <iron-icon icon="social:public" class="material-green" data-toggle="tooltip" title="Public Project"></iron-icon>
        """
        $("iron-icon[icon='icons:lock'].material-red").replaceWith newStatus
      else
        console.warn "We sent a change to public, but it didn't update server-side."
  .fail (result, status) ->
    stopLoadError "Sorry, there was an error communicating with the server"
    try
      shadowAdp = _adp
      delete shadowAdp.currentAsyncJqxhr
      if pointCount > maxPathCount
        try
          tf = JSON.parse shadowAdp.projectData.transect_file
          tf.data.parameters.paths = "REMOVED_FOR_LOCAL_SAVE"
          tf.data.polys = "REMOVED_FOR_LOCAL_SAVE"
          shadowAdp.projectData.transect_file = JSON.stringify tf
      localStorage._adp = JSON.stringify shadowAdp
      console.debug "Local storage backup succeeded"
      backupMessage = "An offline backup has been made."
    catch e
      console.warn "Couldn't backup to local storage! #{e.message}"
      console.warn e.stack
      backupMessage = "Offline backup failed (said: <code>#{e.message}</code>)"
      delay 250, ->
        delete shadowAdp.currentAsyncJqxhr
        delete _adp.currentAsyncJqxhr
        try
          localStorage._adp = JSON.stringify _adp
          backupMessage = "An offline backup has been made."
          $("#offline-backup-status").replaceWith backupMessage
      $("#offline-backup-status").replaceWith backupMessage
    bsAlert "<strong>Save Error</strong>: We had trouble communicating with the server and your data was NOT saved. Please try again in a bit. <span id='offline-backup-status'>#{backupMessage}</span>", "danger"
    console.error result, status
    # console.error "Tried", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
    console.warn "Raw post data", postData
    console.warn "args length was '#{args.length}' = #{args.length * 8} bytes"
  .always ->
    clearTimeout debugInfoDelay
    if typeof callback is "function"
      callback()
  false




$ ->
  try
    _adp.originalProjectId = _adp.projectData.project_id
    bupid = _adp.projectData.project_id
  catch
    delay 1000, ->
      try
        _adp.originalProjectId = _adp.projectData.project_id
        bupid = _adp.projectData.project_id
      catch
        console.warn "Warning: COuldn't backup project id"
  if localStorage._adp?
    try
      window._adp = JSON.parse localStorage._adp
    catch
      window._adp ?= new Object()
    try
      _adp.originalProjectId = bupid
    try
      d = new Date _adp.postedSaveTimestamp
      alertHtml = """
      <strong>You have offline save information</strong> &#8212; did you want to save it?
      <br/><br/>
      Project ##{_adp.postedSaveData.project_id} on #{d.toLocaleDateString()} at #{d.toLocaleTimeString()}
      <br/><br/>
      <button class="btn btn-success" id="offline-save">
        Save Now &amp; Refresh Page
      </button>
      <button class="btn btn-danger" id="offline-trash">
        Remove Offline Backup
      </button>
      """
      bsAlert alertHtml, "info"
      $("#outdated-warning").remove()
      delay 300, ->
        $("#outdated-warning").remove()
      $("#offline-save").click ->
        saveEditorData false,  ->
          document.location.reload(true)
      $("#offline-trash").click ->
        delete localStorage._adp
        $(".hanging-alert").alert("close")
    catch e
      console.warn "Backup corrupted, removing -- #{e.message}"
      delete localStorage._adp

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
  .fail (result, status) ->
    stopLoadError "There was a problem loading viable projects"

  false


loadProject = (projectId, message = "") ->
  # We'll ultimately have some slightly better integrated admin viewer
  # for projects, but for now we'll just run with the redirect
  goTo "#{uri.urlString}project.php?id=#{projectId}"
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
  unless $("#validator-progress-container:visible").exists()
    ex = ->
      this.message = "Loading bars aren't visible!"
      this.name = "BadLoadState"
    throw new ex()
  if typeof currentTimeout is "string" and isNull message
    message = currentTimeout
  try
    clearTimeout currentTimeout
  $("#validator-progress-container paper-progress[indeterminate]")
  .addClass "error-progress"
  .removeAttr "indeterminate"
  others = $("#validator-progress-container paper-progress:not([indeterminate])")
  for el in others
    try
      if p$(el).value isnt p$(el).max
        $(el).addClass "error-progress"
        $(el).find("#primaryProgress").css "background", "#F44336"
  if message?
    bsAlert "<strong>Data Validation Error</strong>: #{message}", "danger"
    stopLoadError null, "There was a problem validating your data"
  try
    $("#cancel-new-upload").remove()
  false


delayFimsRecheck = (originalResponse, callback) ->
  cookies = encodeURIComponent originalResponse.responses.login_response.cookies
  args = "perform=validate&auth=#{cookies}"
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Server said", result
    if typeof callback is "function"
      callback()
    else
      console.warn "Warning: delayed recheck had no callback"
  .fail (result, status) ->
    console.error "#{status}: Couldn't check status on FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadBarsError null, "There was a problem validating your data, please try again later"
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
      stopLoadBarsError null, "Couldn't generate an ARK for your data, please try again later (couldn't communicate with the FIMS server)"
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
  try
    p$("#data-validation").max = rowCount * 2
  # Set an animation timer
  timerPerRow = 20
  validatorTimeout = null
  do animateProgress = ->
    try
      val = p$("#data-validation").value
    catch
      # Probably revalidating ...
      return false
    if val >= rowCount
      # Stop the animation
      clearTimeout validatorTimeout
      return false
    ++val
    try
      p$("#data-validation").value = val
    catch
      return false
    validatorTimeout = delay timerPerRow, ->
      animateProgress()
  # Format the JSON for FIMS
  data = jsonTo64 dataObject.data
  src = post64 dataObject.dataSrc
  args = "perform=validate&datasrc=#{src}&link=#{_adp.projectId}"
  # Post the object over to FIMS
  console.info "Posting ...", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
  _adp.currentAsyncJqxhr = $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
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
    fimsStatusProceedAnyway = [
      "FIMS_SERVER_DOWN"
      ]
    fimsErrorProceedAnyway = [
      "server error"
      ]
    permissibleError = false
    serverErrorMessageMain = ""
    try
      if Object.size(result.validate_status.errors) is 1
        for errorType, errorMessage of result.validate_status.errors[0]
          serverErrorMessageMain = errorMessage
          if typeof serverErrorMessageMain is "object"
            serverErrorMessageMain = errorMessage[0]
          break
        permissibleError = serverErrorMessageMain.toLowerCase() in fimsErrorProceedAnyway
    errorStatus =
      statusesOK: fimsStatusProceedAnyway
      errorsOK: fimsErrorProceedAnyway
      message: serverErrorMessageMain
      permissible: permissibleError
      errorSize: Object.size(result.validate_status.errors)

    if result.validate_status in fimsStatusProceedAnyway or permissibleError
      toastStatusMessage "Validation server is down, proceeding ..."
      bsAlert "<strong>FIMS error</strong>: The validation server is down, we're trying to finish up anyway.", "warning"
    else if statusTest isnt true
      # Bad validation
      overrideShowErrors = false
      console.error "Bad validation", errorStatus
      stopLoadError "There was a problem with your dataset"
      error = "<code>#{result.validate_status.error}</code>" ? result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
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
    try
      p$("#data-validation").value = p$("#data-validation").max
      clearTimeout validatorTimeout
    # When we're successful, run the dependent callback
    if typeof callback is "function"
      callback(dataObject)
  .fail (result, status) ->
    clearTimeout validatorTimeout
    console.error "#{status}: Couldn't upload to FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadBarsError null, "There was a problem validating your data, please try again later"
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
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadBarsError null, result.human_error
      console.error result.error
      return false
    resultObj = result
  .fail (result, status) ->
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


mintExpedition = (projectId = _adp.projectId, title = p$("#project-title").value, callback, fatal = false) ->
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
  try
    publicProject = p$("#data-encumbrance-toggle").checked
  catch
    try
      publicProject = p$("#public").checked
  unless typeof publicProject is "boolean"
    publicProject = false
  args = "perform=create_expedition&link=#{projectId}&title=#{post64(title)}&public=#{publicProject}"
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Expedition got", result
    unless result.status
      errorJsonEscaped = result.error.replace /^.*\[(.*)\]$/img, "$1"
      errorJson = errorJsonEscaped.unescape()
      try
        errorParsed = JSON.parse errorJson
        message = errorParsed.message.trim()
        lastError = message.replace /^([a-z_]+\(.*\):\s*)?((.*?(?::|!)\s*)*(.*))/img, "$4"
        wholeError = message.replace /^([a-z_]+\(.*\):\s*)?((.*?(?::|!)\s*)*(.*))/img, "$2"
        alertError = if isNull(lastError) then wholeError else lastError
      catch
        alertError = "UNREADABLE_FIMS_ERROR"
      result.human_error += """" Server said: <code>#{alertError}</code> """
      console.error result.error, "#{adminParams.apiTarget}?#{args}"
      if fatal
        try
            stopLoadBarsError null, result.human_error
        catch
            stopLoadError result.human_error
        return false
      else
        unless _adp?.fims?
          unless _adp?
            window._adp = new Object()
          _adp.fims = new Object()
        _adp.fims.expedition = {"expeditionId": -1}
    else
        resultObj = result
        unless _adp?.fims?
          unless _adp?
            window._adp = new Object()
          _adp.fims = new Object()
        _adp.fims.expedition =
            permalink: result.project_permalink
            ark: unless typeof result.ark is "object" then result.ark else result.ark.identifier
            expeditionId: result.fims_expedition_id
            fimsRawResponse: result.responses.expedition_response
  .fail (result, status) ->
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
    species = row.specificEpithet ? row.specificepithet
    ssp = row.infraspecificEpithet ? row.infraspecificepithet
    clade = row.cladeSampled ? row.cladesampled
    taxon =
      genus: row.genus
      species: species
      subspecies: ssp
      clade: clade
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
  length = Object.toArray(data).length
  toastStatusMessage "Validating #{taxa.length} unique #{grammar} from #{length} rows ..."
  console.info "Replacement tracker", taxaPerRow
  $("#taxa-validation").removeAttr "indeterminate"
  try
    p$("#taxa-validation").max = taxa.length
  do taxonValidatorLoop = (taxonArray = taxa, key = 0) ->
    taxaString = "#{taxonArray[key].genus} #{taxonArray[key].species}"
    unless isNull taxonArray[key].subspecies
      taxaString += " #{taxonArray[key].subspecies}"
    validateAWebTaxon taxonArray[key], (result) ->
      if result.invalid is true
        cleanupToasts()
        specificEpithetRegex = /^([a-zA-Z]+) +[a-zA-Z\. ]+$/im
        match = specificEpithetRegex.exec(taxonArray[key].species)
        sspMatch = specificEpithetRegex.exec(taxonArray[key].subspecies)
        if match? or sspMatch?
          which = if match? then "species" else "subspecies"
          extraMessage = """
          (We noticed your #{which} looks like the full species name. <a href="https://tdwg.github.io/dwc/terms/index.htm#specificEpithet" class="alert-link newwindow" data-newtab="true">Double check the definition <span class="glyphicon glyphicon-new-window"></span></a> and your entry &#8212; that may help!)
          """
        else
          extraMessage = "Please correct taxonomy issues and try uploading again. If you're confused by this message, please check <a href='https://amphibian-disease-tracker.readthedocs.io/en/latest/APIs/#validating-updating-taxa' data-newtab='true' class='newwindow alert-link'>our documentation  <span class='glyphicon glyphicon-new-window'></span></a>."
        message = result.response.human_error ? result.response.error ? "Unknown error."
        stopLoadError message
        message = result.response.human_error_html ? message
        console.error result.response.error
        taxaRow = taxaPerRow[taxaString].slice 0
        n = 0
        for row in taxaRow
          row++
          taxaRow[n] = row
          n++
        if taxaRow.length > 5
          taxaRow = taxaRow.slice 0, 5
          taxaRow = taxaRow.toString() + "..."
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. #{message} The error occured while we were checking taxon <span class='sciname'>\"#{taxaString}\"</span>, which occurs at rows #{taxaRow}. We stopped validation at that point. #{extraMessage}"
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
      try
        p$("#taxa-validation").value = key
      key++
      if key < taxonArray.length
        if key %% 50 is 0
          toastStatusMessage "Validating taxa #{key} of #{taxonArray.length} ..."
        taxonValidatorLoop(taxonArray, key)
      else
        try
          p$("#taxa-validation").value = key
        dataObject.validated_taxa  = taxonArray
        console.info "Calling back!", dataObject
        callback(dataObject)
  false

###
#
###


loadSUProfileBrowser = ->
  url = "#{uri.urlString}admin-page.html#action:show-su-profiles"
  state =
    do: "action"
    prop: "show-su-profiles"
  history.pushState state, "Viewing Superuser Profile List", url
  startAdminActionHelper()
  startLoad()
  verifyLoginCredentials (result) ->
    rawSu = toInt result.detail.userdata.su_flag
    unless rawSu.toBool()
      stopLoadError "Sorry, you must be an admin to do this"
      return false
    # Show list of users
    classPrefix = "su-admin-users"
    args = "action=search_users&q="
    dest = "#{uri.urlString}api.php"
    $.post dest, args
    .done (result) ->
      unless result.status is true
        message = result.human_error ? result.error ? "There was a problem loading the user list"
        stopLoadError message
        return false
      list = result.result
      list = Object.toArray list
      listElements = new Array()
      i = 0
      for user in list
        ++i
        if isNull user.full_name
          continue
        if user.has_verified_email
          verifiedHtml = """
<iron-icon id='restriction-badge-#{i}' icon='icons:verified-user' class='material-blue' data-toggle='tooltip' title='At least one verified email'></iron-icon>
          """
        else
          verifiedHtml = ""
        if user.unrestricted
          isUnrestricted = """
<iron-icon id='unrestriction-badge-#{i}' icon='icons:verified-user' class='material-green' data-toggle='tooltip' title='Meets restriction criteria'></iron-icon>
          """
        else
          isUnrestricted = "<iron-icon id='unrestriction-badge-#{i}' icon='icons:verified-user' class='material-red' data-toggle='tooltip' title='Fails restriction criteria'></iron-icon>"
        if user.is_admin
          adminHtml = """
          <span class="glyphicons glyphicons-user-key" data-toggle="tooltip" title="Adminstrator"></span>
          """
        else
          adminHtml = ""
        entry = """
        <span class="#{classPrefix}-user-details">
          #{user.full_name} / #{user.handle} / #{user.email} | <small>#{user.alternate_email ? "No Alternate Email"}</small> #{isUnrestricted} #{verifiedHtml} #{adminHtml}
        </span>
        <div>
          <button class="#{classPrefix}-view-projects btn btn-default" data-uid="#{user.uid}" data-email="#{user.email}">
            <iron-icon icon="icons:find-in-page"></iron-icon>
            Find Projects
          </button>
          <button class="#{classPrefix}-reset btn btn-warning" data-uid="#{user.uid}" data-email="#{user.email}">
            <iron-icon icon="av:replay"></iron-icon>
            Reset Password
          </button>
          <button class="#{classPrefix}-delete btn btn-danger" data-uid="#{user.uid}">
            <iron-icon icon="icons:delete"></iron-icon>
            Delete User
          </button>
        </div>
        """
        listElements.push entry
      listInterior = listElements.join "</li><li class='su-user-list'>"
      html = """
      <ul class='su-total-list col-xs-12' id="su-management-list">
        <li class='su-user-list'>#{listInterior}</li>
      </ul>
      """
      $("#main-body").html html
      # Events
      ## View links
      $(".#{classPrefix}-view-projects").click ->
        ###
        # Handler to search projects
        ###
        startLoad()
        uid = $(this).attr "data-uid"
        email = $(this).attr "data-email"
        search = uid
        cols = "access_data,author_data,author"
        console.info "Searching on #{search} ... in #{cols}"
        # POST a request to the server for projects matching this
        args = "action=search_project&q=#{search}&cols=#{cols}"
        $.post "#{uri.urlString}api.php", args, "json"
        .done (result) =>
          console.info result
          html = """
          <h3 class="col-xs-12">
            Projects with "#{email}" as a participant
          </h3>
          """
          showList = new Array()
          projects = Object.toArray result.result
          if projects.length > 0
            html += "<ul class='project-search-su col-xs-12'>"
            for project in projects
              if isNull project.project_id
                continue
              showList.push project.project_id
              publicState = project.public.toBool()
              isAuthor = search is project.author
              console.log search, project.author, isAuthor, project
              if isAuthor
                matchStatus = """
                <iron-icon icon="social:person" data-toggle="tooltip" title="Author">
                </iron-icon>
                """
              else
                matchStatus = """
                <iron-icon icon="social:group" data-toggle="tooltip" title="Collaborator">
                </iron-icon>
                """
              hasData = not isNull(project.dataset_arks)
              if hasData
                dataAttached = """
                <iron-icon icon="editor:insert-chart" data-toggle="tooltip" title="Data Attached">
                </iron-icon>
                """
              else
                dataAttached = ""
              icon = if publicState then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
              button = """
              <button class="btn btn-primary search-proj-link" data-href="#{uri.urlString}project.php?id=#{project.project_id}" data-toggle="tooltip" data-placement="right" title="Project ##{project.project_id.slice(0,8)}...">
                #{icon} #{project.project_title}
              </button> #{matchStatus} #{dataAttached}
              """
              html += "<li class='project-search-result'>#{button}</li>"
            html += "</ul>"
          else
            s = email ? $(this).attr("data-email") ? result.search ? search
            html = "<p class='col-xs-12'><em>No results found for user \"<strong>#{s}</strong>\""
          # Always provide a back button
          html += """
          <div class="col-xs-12">
            <button class="btn btn-default go-back-button">
              <iron-icon icon="icons:arrow-back"></iron-icon>
              Back to Profile Browser
            </button>
          </div>
          """
          $("#main-body").html html
          bindClicks(".search-proj-link")
          $(".go-back-button").click ->
            loadSUProfileBrowser()
            false
          false
        .fail (result, status) =>
          console.error "AJAX error trying to search on user projects", result, status
          message = "#{status} #{result.status}: #{result.statusText}"
          stopLoadError "Couldn't search projects (#{message})"
          false
        stopLoad()
        false
      ## Reset
      $(".#{classPrefix}-reset").click ->
        startLoad()
        email = $(this).attr "data-email"
        args = "action=startpasswordreset&username=#{email}&method=email"
        $(this).attr "disabled", "disabled"
        $.post "admin/async_login_handler.php", args, "json"
        .done (result) ->
          console.info "Reset prompt returned", result
          unless result.status
            message = result.human_error ? result.error ? "Couldn't initiate password reset for #{email}"
            if result.action is "GET_TOTP"
              message = "User has two-factor authentication. They have to reset themselves."
            else
              unless isNull result.action
                message += " (#{result.action})"
            stopLoadError message
            return false
          # It worked
          stopLoad()
          message = "Successfully prompted '#{email}' to reset their password (method: #{result.method})"
          toastStatusMessage message, "", 7000
          false
        .fail (result, status) =>
          console.error "AJAX error trying to initiate password reset", result, status
          message = "#{status} #{result.status}: #{result.statusText}"
          stopLoadError "Couldn't initiate password reset (#{message})"
          $(this).removeAttr "disabled"
          false
        false
      ## Delete
      $(".#{classPrefix}-delete").click ->
        # Change to a confirmation button
        html = """
        <iron-icon icon="icons:warning" class="">
        </iron-icon>
        Confirm Deletion
        """
        $(this)
        .addClass "danger-glow"
        .html html
        .unbind()
        .click ->
          # Post the deletion. Confirmation occurs server-side.
          # See
          # https://github.com/AmphibiaWeb/amphibian-disease-tracker/commit/4d9f060777290fb6d9a1b6ebbc54575da7ecdf89
          startLoad()
          listElement = $(this).parents(".su-user-list")
          uid = $(this).attr "data-uid"
          # Disable the button until the POST is done
          $(this).attr "disabled", "disabled"
          args = "perform=su_manipulate_user&user=#{uid}&change_type=delete"
          console.info "Posting to", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
          $.post adminParams.apiTarget, args, "json"
          .done (result) =>
            console.info "Click to delete returned", result
            unless result.status is true
              message = result.human_error ? result.error ? "There was an error executing the action"
              systemError = result.error
              switch systemError
                # Reserving a switch for future other actions
                when systemError.search("INVALID_TARGET") isnt -1
                  # This was in invalid action
                  $(this).attr "disabled", "disabled"
              stopLoadError message
              return false
            # The request succeeded
            console.log "Got li of ", listElement
            listElement.slideUp "slow", ->
              listElement.remove()
            delay 1000, ->
              if listElement.exists()
                console.warn "Trying to force removal of element"
                listElement.remove()
            false
          .fail (result, status) ->
            console.error "AJAX error", result, status
            message = "#{status} #{result.status}: #{result.statusText}"
            stopLoadError "Couldn't execute action (#{message})"
            false
          .always =>
            # Time out 300ms so someone doesn't accidentally delete a
            # user by double-clicking
            delay 300, =>
              $(this).removeAttr "disabled"
          stopLoad()
          false
        false
      stopLoad()
      false
    .fail (result, status) ->
      console.error "Couldn't load user list", result, status
      message = "#{status} #{result.status}: #{result.statusText}"
      stopLoadError "Sorry, can't load user list (#{message})"
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
    .fail (result, status) ->
      stopLoadError "There was a problem loading projects"
  false
