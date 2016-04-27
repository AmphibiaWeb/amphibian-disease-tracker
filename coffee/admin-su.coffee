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
      for user in list
        entry = """
        #{user.full_name} / #{user.handle} / #{user.email}
        """
        listElements.push entry
      listInterior = listElements.join "</li><li class='su-user-list'>"
      html = """
      <ul class='su-total-list' id="su-management-list">
        <li class='su-user-list'>#{listInterior}</li>
      </ul>
      """
      $("#main-body").html html
      foo()
      stopLoad()
      false
    .fail (result, status) ->
      console.error "Couldn't load user list", result, status
      stopLoadError "Sorry, can't load user list"
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
