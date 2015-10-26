###
# The main coffeescript file for administrative stuff
# Triggered from admin-page.html
###
window.adminParams = new Object()
adminParams.domain = "amphibiandisease"
adminParams.apiTarget = "admin_api.php"
adminParams.adminPageUrl = "http://#{adminParams.domain}.org/admin-page.html"
adminParams.loginDir = "admin/"
adminParams.loginApiTarget = "#{adminParams.loginDir}async_login_handler.php"

window.loadAdminUi = ->
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
        Welcome, #{$.cookie("#{adminParams.domain}_name")}
        <span id="pib-wrapper-settings" class="pib-wrapper" data-toggle="tooltip" title="User Settings" data-placement="bottom">
          <paper-icon-button icon='settings-applications' class='click' data-url='#{data.login_url}'></paper-icon-button>
        </span>
        <span id="pib-wrapper-exit-to-app" class="pib-wrapper" data-toggle="tooltip" title="Go to CNDB app" data-placement="bottom">
        </span>
      </h3>
      <div id='admin-actions-block'>
        <div class='bs-callout bs-callout-info'>
          <p>Please be patient while the administrative interface loads. TODO MAKE ADMIN UI</p>
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

      bindClicks()
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
  hash = $.cookie("#{adminParams.domain}_auth")
  secret = $.cookie("#{adminParams.domain}_secret")
  link = $.cookie("#{adminParams.domain}_link")
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
  loadJS "bower_components/bootstrap/dist/js/bootstrap.min.js", ->
    $("[data-toggle='tooltip']").tooltip()
  # The rest of the onload for the admin has been moved to the core.coffee file.
