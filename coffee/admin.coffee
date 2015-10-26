###
# The main coffeescript file for administrative stuff
# Triggered from admin-page.html
###
adminParams = new Object()
adminParams.apiTarget = "admin_api.php"
adminParams.adminPageUrl = "https://ssarherps.org/cndb/admin-page.html"
adminParams.loginDir = "admin/"
adminParams.loginApiTarget = "#{adminParams.loginDir}async_login_handler.php"

loadAdminUi = ->
  ###
  # Main wrapper function. Checks for a valid login state, then
  # fetches/draws the page contents if it's OK. Otherwise, boots the
  # user back to the login page.
  ###
  try
    verifyLoginCredentials (data) ->
      # Post verification
      articleHtml = """
      <h3>
        Welcome, #{$.cookie("ssarherps_name")}
        <span id="pib-wrapper-settings" class="pib-wrapper" data-toggle="tooltip" title="User Settings" data-placement="bottom">
          <paper-icon-button icon='settings-applications' class='click' data-url='#{data.login_url}'></paper-icon-button>
        </span>
        <span id="pib-wrapper-exit-to-app" class="pib-wrapper" data-toggle="tooltip" title="Go to CNDB app" data-placement="bottom">
          <paper-icon-button icon='exit-to-app' class='click' data-url='#{uri.urlString}' id="app-linkout"></paper-icon-button>
        </span>
      </h3>
      <div id='admin-actions-block'>
        <div class='bs-callout bs-callout-info'>
          <p>Please be patient while the administrative interface loads.</p>
        </div>
      </div>
      """
      $("article #main-body").html(articleHtml)
      # $(".pib-wrapper").tooltip()
      bindClicks()
      ###
      # Render out the admin UI
      # We want a search box that we pipe through the API
      # and display the table out for editing
      ###
      searchForm = """
      <form id="admin-search-form" onsubmit="event.preventDefault()" class="row">
        <div>
          <paper-input label="Search for species" id="admin-search" name="admin-search" required autofocus floatingLabel class="col-xs-7 col-sm-8"></paper-input>
          <paper-fab id="do-admin-search" icon="search" raisedButton class="materialblue"></paper-fab>
          <paper-fab id="do-admin-add" icon="add" raisedButton class="materialblue"></paper-fab>
        </div>
      </form>
      <div id='search-results' class="row"></div>
      """
      $("#admin-actions-block").html(searchForm)
      $("#admin-search-form").submit (e) ->
        e.preventDefault()
      $("#admin-search").keypress (e) ->
        if e.which is 13 then renderAdminSearchResults()
      $("#do-admin-search").click ->
        renderAdminSearchResults()
      $("#do-admin-add").click ->
        createNewTaxon()
      bindClickTargets()
      false
  catch e
    $("article #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>")
  false


verifyLoginCredentials = (callback) ->
  ###
  # Checks the login credentials against the server.
  # This should not be used in place of sending authentication
  # information alongside a restricted action, as a malicious party
  # could force the local JS check to succeed.
  # SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
  ###
  hash = $.cookie("ssarherps_auth")
  secret = $.cookie("ssarherps_secret")
  link = $.cookie("ssarherps_link")
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  $.post(adminParams.loginApiTarget,args,"json")
  .done (result) ->
    if result.status is true
      callback(result)
    else
      goTo(result.login_url)
  .fail (result,status) ->
    # Throw up some warning here
    $("article #main-body").html("<div class='bs-callout-danger bs-callout'><h4>Couldn't verify login</h4><p>There's currently a server problem. Try back again soon.</p>'</div>")
    console.log(result,status)
    false
  false



$ ->
  if $("#next").exists()
    $("#next")
    .unbind()
    .click ->
      openTab(adminParams.adminPageUrl)
  loadJS "https://ssarherps.org/cndb/bower_components/bootstrap/dist/js/bootstrap.min.js", ->
    $("[data-toggle='tooltip']").tooltip()
  # The rest of the onload for the admin has been moved to the core.coffee file.
