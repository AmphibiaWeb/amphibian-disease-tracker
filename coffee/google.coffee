###
# Handling Google OAuth
###

unless oa?
  window.oa = new Object()



oa.googleOAuthCallback = (googleClient) ->
  ###
  # Sample:
  {
  "status": {
    "method": "AUTO",
    "signed_in": true,
    "google_logged_in": true
  },
  "_aa": "0",
  "expires_at": "1448075227",
  "issued_at": "1448071627",
  "response_type": "code token id_token gsession",
  "cookie_policy": "single_host_origin",
  "g_user_cookie_policy": "single_host_origin",
  "client_id": "680725378779.apps.googleusercontent.com",
  "prompt": "none",
  "session_state": "2135f83652337d54fa78c0505055673fb0a575c3..df84",
  "authuser": "0",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjM4OWRkNWU1OGYxYzUyN2QzMTQ0ODY5NzQ3ZDVkN2YzM2Q3MGFlMTcifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXRfaGFzaCI6IjlyZGg4T0hZaWhUR05kY2FkeHY4WUEiLCJhdWQiOiI2ODA3MjUzNzg3NzkuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJjX2hhc2giOiI4RlU1X090dXdTSXVsRl9aZzhlb0ZBIiwic3ViIjoiMTExNTE3ODg5NTc5MzM3NDIyNjYyIiwiYXpwIjoiNjgwNzI1Mzc4Nzc5LmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiaWF0IjoxNDQ4MDcxNjI2LCJleHAiOjE0NDgwNzUyMjZ9.bn7N_j35vnlN1NU5ODKjXvmZe3HgTdio71eaw4ybbu_DJNvPL-w8vHJKFkJp_4Bpqq0AWowTbak9p4qD_dumVJTCoiwTnrPrmSebKvOOg4tkwErPLJEUqf5DtYOM22xWISTNoLPHCdTdNroVtvj0tjblr7qFwiWhbHhXkqCWLLKivqQGcsXBsms__9vR8pFfigE5PYPq8EVQkJ958bw0GBX2TilyeOzKaFLfIkeNi-QR45cum40JKxg-M2rvYDwb14cXzXIlXfks9Pf5Dd0uoY6nWo2_qd6_njxdDiRPndZgigbn6CqXxOzqC5gTSXzUyBOYOLYQg7yvcdPcr1Tajw",
  "scope": "https:\/\/www.googleapis.com\/auth\/plus.login https:\/\/www.googleapis.com\/auth\/plus.moments.write https:\/\/www.googleapis.com\/auth\/plus.me https:\/\/www.googleapis.com\/auth\/plus.profile.agerange.read https:\/\/www.googleapis.com\/auth\/plus.profile.language.read https:\/\/www.googleapis.com\/auth\/plus.circles.members.read",
  "code": "4\/xwl-MpYfnSk_-WdqD_xk9qBleRfg8eTvuI9QUF6mKyc",
  "expires_in": "3600",
  "token_type": "Bearer",
  "access_token": "ya29.MwJSoCnRPFcB_Pr7vGTnDmOHST15fKNfNV5SWfngLMEon4rqsIHVJP2HFbUrUOvX9Zeg",
  "state": ""
}
  ###
  if not googleClient?
    console.warn "A bad Google client was returned from the server!"
    return false
  window.googleClient = googleClient
  console.info "Google said", googleClient
  try
    profile =  googleClient?.getBasicProfile()
  unless profile?
    console.info "Profile", profile
    name = profile.getName()
    email = profile.getEmail()
    id = profile.getId()
    image = profile.getImageUrl()
  # Authenticate to the back - end
  # https://developers.google.com/identity/sign-in/web/backend-auth
  authtokens = googleClient.getAuthResponse()
  atj = jsonTo64 authtokens
  idtoken = googleClient.getAuthResponse().id_token
  accesstoken = googleClient.getAuthResponse().access_token
  # Post it over, where it'll validate the token then log in the user
  # and return credentials
  url = "oauth_login_handler.php"
  args = "provider=google&token=#{idtoken}&access=#{accesstoken}&tokens=#{atj}"
  $.post url, args, "json"
  .done (result) ->
    ###
    # Should get back something like
    {
  "locale": "en",
  "family_name": "Kahn",
  "given_name": "Philip",
  "picture": "https:\/\/lh6.googleusercontent.com\/-3NU8bfRpuG8\/AAAAAAAAAAI\/AAAAAAAAiSY\/ABIlYyYUn4E\/s96-c\/photo.jpg",
  "name": "Philip Kahn",
  "exp": 1448092406.0,
  "iat": 1448088806.0,
  "email": "tigerhawkvok@gmail.com",
  "azp": "680725378779.apps.googleusercontent.com",
  "email_verified": true,
  "sub": "111517889579337422662",
  "aud": "680725378779.apps.googleusercontent.com",
  "at_hash": "6iCYFYkh2tq6SonCCA1iKg",
  "iss": "accounts.google.com"
    }
    ###
    console.info "POST got back the following result:", result
    unless result.status is true
      # Bad stuff
      console.error "Couldn't validate with Google - #{result.error}"
      return false
    email = result.identifier
    password = result.validator
    oneTimeHash = result.token_data.at_hash
    subscriber = result.token_data.sub
    # The calculated password for the user is the sha256 hash of their
    # personal server secret and their subscriber number ...
    testHtml = """
    <p>Will use credentials:</p>
    <p>Username: <code>#{email}</code></p>
    <p>Derived Password: <code>#{password}</code></p>
    """
    false

oa.googleBadCallback = (result) ->
  console.error result

window.onSignInCallback = oa.googleOAuthCallback

window.onFailureCallback = oa.googleBadCallback

insertGoogleOAuth = (clientId, containerSelector = ".oauth-container") ->
  # Insert DOM elements, if not present
  if clientId?
    clientId = "data-clientid='#{clientId}'"
  else
    clientId = ""
  html = """"
    <div id='gConnect'>
    <div class='g-signin2'
      data-onload='false'
      #{clientId}
      data-onsuccess='onSignInCallback'
      data-onfailure='onFailureCallback'>
    </div>
  </div>
  """
  if $(containerSelector).exists()
    $(containerSelector)
    .append(html)
  loadJS "https://apis.google.com/js/platform.js"

replaceLoginPrompt = ->
  false
