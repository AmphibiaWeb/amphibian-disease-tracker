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
      for user in list
        if isNull user.full_name
          continue
        if user.has_verified_email
          verifiedHtml  """
<iron-icon id='restriction-badge' icon='icons:verified-user' class='material-green' data-toggle='tooltip' title='Unrestricted Account'></iron-icon>
          """
        else
          verifiedHtml = ""
        if user.is_admin
          adminHtml = """
          <span class="glyphicons glyphicons-user-key" data-toggle="tooltip" title="Adminstrator"></span>
          """
        else
          adminHtml = ""
        entry = """
        <span class="#{classPrefix}-user-details">
          #{user.full_name} / #{user.handle} / #{user.email} #{verifiedHtml} #{adminHtml}
        </span>
        <div>
          <button class="#{classPrefix}-view-projects btn btn-default" data-uid="#{user.uid}">
            <iron-icon icon="icons:find-in-page"></iron-icon>
            Find Projects
          </button>
          <button class="#{classPrefix}-reset btn btn-warning" data-uid="#{user.uid}">
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
      $(".#{classPrefix}-view-projects").click ->
        listElement = $(this).parents(".su-user-list")
        console.log "Got li of ", listElement, "testing removal"
        listElement.slideUp "slow", ->
          listElement.remove()
        foo()
        false
      $(".#{classPrefix}-reset").click ->
        foo()
        false
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
          uid = $(this).attr "data-uid"
          args = "perform=su_manipulate_user&user=#{uid}&change_type=delete"
          console.info "Posting to", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
          $.post adminParams.apiTarget, args, "json"
          .done (result) ->
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
            listElement = $(this).parents(".su-user-list")
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
          stopLoad()
          false
        false
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
