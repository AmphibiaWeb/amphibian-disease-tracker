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
  # We'll ultimately have some slightly better integrated admin viewer
  # for projects, but for now we'll just run with the redirect
  goTo "#{uri.urlString}project.php?id=#{projectId}"
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
