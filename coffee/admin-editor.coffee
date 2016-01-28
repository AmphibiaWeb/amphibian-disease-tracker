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
    toastStatusMessage "Would load editor for this."
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



