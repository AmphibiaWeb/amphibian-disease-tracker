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
          verifiedHtml = """
<iron-icon id='restriction-badge' icon='icons:verified-user' class='material-green' data-toggle='tooltip' title='At least one verified email'></iron-icon>
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
          html = ""
          showList = new Array()
          projects = Object.toArray result.result
          if projects.length > 0
            html = "<ul class='project-search-su col-xs-12'>"
            for project in projects
              if isNull project.project_id
                continue
              showList.push project.project_id
              publicState = project.public.toBool()
              icon = if publicState then """<iron-icon icon="social:public"></iron-icon>""" else """<iron-icon icon="icons:lock"></iron-icon>"""
              button = """
              <button class="btn btn-primary search-proj-link" data-href="#{uri.urlString}project.php?id=#{project.project_id}" data-toggle="tooltip" data-placement="right" title="Project ##{project.project_id.slice(0,8)}...">
                #{icon} #{project.project_title}
              </button>
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
      foo()
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
