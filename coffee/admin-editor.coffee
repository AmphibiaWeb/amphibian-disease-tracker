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
