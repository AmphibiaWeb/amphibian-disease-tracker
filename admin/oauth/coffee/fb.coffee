###
# Handling the Facebook signin
# https://developers.facebook.com/docs/reference/javascript/FB.getLoginStatus/
###

if FB?
  ###
  # Here we subscribe to the auth.authResponseChange JavaScript
  # event. This event is fired
  # for any authentication related change, such as login, logout or
  # session refresh. This means that
  # whenever someone who was previously logged out tries to log in
  # again, the correct case below
  # will be handled.
  ###
  FB.Event.subscribe "auth.authResponseChange", (response) ->
    # Here we specify what we do with the response anytime this event occurs.
    if response.status is 'connected'
      # The response object is returned with a status field that lets
      # the app know the current login status of the person. In this
      # case, we're handling the situation where they have logged in
      # to the app.
      loggedIn()
    else if response.status is 'not_authorized'
      # In this case, the person is logged into Facebook, but not into
      # the app, so we call FB.login() to prompt them to do so.  In
      # real-life usage, you wouldn't want to immediately prompt
      # someone to login like this, for two reasons: (1) JavaScript
      # created popup windows are blocked by most browsers unless they
      # result from direct interaction from people using the app (such
      # as a mouse click) (2) it is a bad experience to be continually
      # prompted to login upon page load.
      # FB.login();
      removeSimpleLogin();
    else
      # In this case, the person is not logged into Facebook, so we
      # call the login() function to prompt them to do so. Note that
      # at this stage there is no indication of whether they are
      # logged into the app. If they aren't then they'll see the
      # Login dialog right after they log in to Facebook.  The same
      # caveats as above apply to the FB.login() call here.
      # FB.login();
      removeSimpleLogin();



  FB.getLoginStatus (response) ->
    ###
    # This function will only rarely be called, and instead the 
    # subscribed event notifier will be called. This is being  left here 
    # for completion.
    ###
    if response.status is "connected"
      # the user is logged in and has authenticated your
      # app, and response.authResponse supplies
      # the user's ID, a valid access token, a signed
      # request, and the time the access token
      # and signed request each expire
      uid = response.authResponse.userID
      accessToken = response.authResponse.accessToken
    else if response.status is 'not_authorized'
      # the user is logged in to Facebook,
      # but has not authenticated your app
      removeSimpleLogin()
    else
      # the user isn't logged in to Facebook.
      removeSimpleLogin()

  # Here we run a very simple test of the Graph API after login is
  # successful.  This testAPI() function is only called in those
  # cases.
  testAPI = ->
    console.log 'Welcome!  Fetching your information.... '
    FB.api '/me', (response) ->
      console.log 'Good to see you, #{response.name}.'

  loggedIn = ->
    auth = FB.getAuthResponse()
    # Post back important stuff
    FB.api "/me", (response) ->
      console.log response.email

  removeSimpleLogin = ->
    # Replace the simple text link with a a fancy, FB-JS-SDK version
    $("#basic_fb_login").remove()

# End if FB statement
