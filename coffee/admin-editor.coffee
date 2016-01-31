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


loadEditor = ->
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
            if result.user.has_view_permissions or result.project.public is true
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
                  <paper-button class="add-user"><iron-icon icon="social:person-add"></iron-icon> Add User</paper-button>
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
                toastStatusMessage "Would grant #{user} permission '#{permission}'"
              $(".add-user")
              .unbind()
              .click ->
                showAddUserDialog()
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
          icon = if project.public.toBool() then """<iron-icon icon="social:public" class="material-green"></iron-icon>""" else """<iron-icon icon="icons:lock" class="material-red"></iron-icon>"""
          conditionalReadonly = if result.user.has_edit_permissions then "" else "readonly"
          anuraState = if project.includes_anura.toBool() then "checked disabled" else "disabled"
          caudataState = if project.includes_caudata.toBool() then "checked disabled" else "disabled"
          gymnophionaState = if project.includes_gymnophiona.toBool() then "checked disabled" else "disabled"
          try
            cartoParsed = JSON.parse project.carto_id
          catch
            console.error "Couldn't parase the carto JSON!", project.carto_id
            toastStatusMessage "We couldn't parse your data. Please try again later."
            cartoParsed = new Object()
          # The actual HTML
          html = """
          <h2 class="clearfix newtitle col-xs-12">Managing #{project.project_title}<br/><small>Project ##{opid}</small></h2>
          <section id="manage-users" class="col-xs-12 col-md-4 pull-right">
            <div class="alert alert-info clearfix">
              <h4>Project Collaborators</h4>
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
              <paper-button class="manage-users pull-right" id="manage-users">Manage Users</paper-button>
            </div>
          </section>
          <section id="project-basics" class="col-xs-12 col-md-8 clearfix">
            <h3>Project Basics</h3>
            <paper-input readonly label="Project Identifier" value="#{project.project_id}" id="project_id" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Project Title" value="#{project.project_title}" id="project_title" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="Primary Disease" value="#{project.disease}"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="PI Lab" value="#{project.pi_lab}" id="project_title" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
            <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
          </section>
          <section id="data-management" class="col-xs-12 col-md-4 pull-right" data-spy="affix">
            <div class="alert alert-info clearfix">
              <h4>Project Data</h4>
              Your project does/does not have data associated with it. (Does should note overwrite, and link to cartoParsed.raw_data.filePath for current)
              <br/><br/>
              Uploader here
            </div>
          </section>
          <section id="project-data" class="col-xs-12 col-md-8 clearfix">
            <h3>Project Data Overview</h3>
              <h4>Project Studies:</h4>
                <paper-checkbox #{anuraState}>Anura</paper-checkbox>
                <paper-checkbox #{caudataState}>Caudata</paper-checkbox>
                <paper-checkbox #{gymnophionaState}>Gymnophiona</paper-checkbox>
              <h4>Sample Metrics</h4>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
              <h4>Locality &amp; Transect Data</h4>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
            <h3>Project Meta Parameters</h3>
              <h4>Project funding status</h4>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
                <paper-input #{conditionalReadonly} class="project-param" label="" value="" id="" class="project-param"></paper-input>
          </section>
          """
          $("#main-body").html html
          # Events
          topPosition = $("#data-management").position().top
          affixOptions =
            top: topPosition
          $("#data-management").affix affixOptions
          console.info "Affixed at #{topPosition}px"
          $("#manage-users").click ->
            popManageUserAccess()
          stopLoad()
        catch e
          stopLoadError "There was an error loading your project"
          console.error "Unhandled exception loading project! #{e.message}"
          console.warn e.stack
          return false
      .error (result, status) ->
        stopLoadError "We couldn't load your project. Please try again."
    false

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
  false


showAddUserDialog = ->
  toastStatusMessage "Would replace dialog with a new one to add a new user to project"
  dialogHtml = """
  """
  false
