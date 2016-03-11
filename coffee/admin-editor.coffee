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
                if result.user.has_edit_permissions and user isnt isAuthor and user isnt result.user
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
          mdNotes = if isNull(project.sample_notes) then "*No notes for this project*" else deEscape project.sample_notes
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
          <h2 class="clearfix newtitle col-xs-12">Managing #{project.project_title} #{icon} <paper-icon-button icon="icons:visibility" class="click" data-href="#{uri.urlString}/project.php?id=#{opid}"></paper-icon-button><br/><small>Project ##{opid}</small></h2>
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
            <paper-input readonly label="Project ARK" value="#{project.project_obj_id}" id="project_creation" class="project-param"></paper-input>
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

          p$("#project-notes").bindValue = deEscape project.sample_notes
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
              startLoad()
              el = this
              args = "perform=delete&id=#{project.id}"
              $.post adminParams.apiTarget, args, "json"
              .done (result) ->
                if result.status is true
                  stopLoad
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
          console.info "Getting carto data with id #{project.carto_id} and options", createMapOptions
          getProjectCartoData project.carto_id, createMapOptions
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
            for user in users
              # TODO check if user already has access
              html = """
              <div class="user-search-result" data-uid="#{user.uid}">
                <span class="email">#{user.email}</span>
                  |
                <span class="name">#{user.full_name}</span>
                  |
                <span class="user">#{user.handle}</span></div>
              """
            $("#user-search-result-container").html html
            $(".user-search-result").click ->
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
    totalRows = result.parsed_responses[0].total_rows ? 0
    if pointArr.length > 0 or mapOptions?.boundingBox?.length > 0
      mapOptions.skipHull = false
      if pointArr.length is 0
        center = geo.centerPoint ? [mapOptions.boundingBox[0].lat, mapOptions.boundingBox[0].lng] ? [window.locationData.lat, window.locationData.lng]
        pointArr.push center
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
    if filePath.search helperDir is -1
      filePath = "#{helperDir}#{filePath}"
    html = """
    <p>
      Your project already has data associated with it. <span id="last-modified-file"></span>
    </p>
    <button id="download-project-file" class="btn btn-primary center-block click download-file" data-href="#{filePath}"><iron-icon icon="icons:cloud-download"></iron-icon> Download File</button>
    <p>You can upload more data below, or replace this existing data.</p>
    """
    $("#data-card .card-content .variable-card-content").html html
    $.get "meta.php", "do=get_last_mod&file=#{filePath}", "json"
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
