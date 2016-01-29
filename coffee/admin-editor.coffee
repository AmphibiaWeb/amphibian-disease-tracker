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
          # Check the result
          unless result.status is true
            error = result.human_error ? result.error
            unless error?
              error = "Unidentified Error"
            stopLoadError "There was a problem loading your project (#{error})"
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
          # Helper functions to bind to upcoming buttons
          popManageUserAccess = ->
            # For each user in the access list, give some toggles
            userHtml = ""
            for user in project.access_data.total
              isAuthor = user is project.access_data.author
              isEditor =  user in project.access_data.editors_list
              isViewer = not isEditor
              editDisabled = if isEditor or isAuthor then "disabled data-toggle='tooltip' title='Make Editor'" else ""
              viewerDisabled = if isViewer or isAuthor then "disabled data-toggle='tooltip' title='Make Read-Only'" else ""
              authorDisabled = if isAuthor then "disabled data-toggle='tooltip' title='Grant Ownership'" else ""
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
              <li>#{theirHtml}</li>
              """
            userHtml = """
            <ul class="simple-list">
              #{userHtml}
            </ul>
            """
            # Put it in a dialog
            dialogHtml = """
            <paper-dialog modal id="user-setter-dialog">
              <paper-dialog-scrollable>
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
              toastStatusMessage "Would grant #{user} permission '#{permission}'"
            # Open the dialog
            safariDialogHelper "#user-setter-dialog"
            false
          # Userlist
          userHtml = ""
          for user in project.access_data.total
            icon = ""
            if user in project.access_data.editors_list
              icon = """
              <icon-icon icon="image:edit"></iron-icon>
              """
            else if user in project.access_data.viewers_list
              icon = """
              <icon-icon icon="image:remove-red-eye"></iron-icon>
              """
            userHtml += """
            <tr>
              <td colspan="5">#{user}</td>
              <td>#{icon}</td>
            </tr>
            """
          # The actual HTML
          html = """
          <section id="manage-users" class="col-xs-12 col-md-4">
            <div class="alert alert-info">
              <h3>Project Collaborators</h3>
              <table class="table table-striped table-collapsed" cols="6">
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
          </section>
          <section id="project-basics" class="col-xs-12 col-md-8">
          </section>
          <section id="project-data" class="col-xs-12 clearfix">
          </section>
          """
          $("#main-body").html html
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
