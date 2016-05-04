###
#
#
#
# See
# https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
###

profileAction = "update_profile"
apiTarget = "#{uri.urlString}/admin-api.php"

loadUserBadges = ->
  ###
  # 
  ###
  false


setupProfileImageUpload = ->
  ###
  # Bootstrap an uploader for images
  ###
  false


conditionalLoadAccountSettingsOptions = ->
  ###
  # Verify the account ownership, and if true, provide options for
  # various account settings.
  #
  # Largely acts as links back to admin-login.php
  ###
  false


constructProfileJson = (encodeForPosting = false)->
  ###
  # Read all the fields and return a JSON formatted for the database
  # field
  #
  # See Github Issue #48
  #
  # @param bool encodeForPosting -> when true, returns a URI-encoded
  #   base64 string, rather than an actual object.
  ###
  response = false
  # Build it
  tmp = new Object()
  inputs = $(".profile-data:not(.from-base-profile) .user-input")
  for el in inputs
    val = p$(el).value
    key = $(el).attr "data-source"
    parentKey = $(el).parents("[data-source]").attr "data-source"
    tmp[parentKey][key] = val
  response = tmp
  if encodeForPosting
    response = post64 response
  response

saveProfileChanges = ->
  ###
  # Post the appropriate JSON to the server and give user feedback
  # based on the response
  ###
  foo()
  return false
  startLoad()
  data = constructProfileJson(true)
  args = "perform=#{profileAction}&data=#{data}"
  $.post apiTarget, args, "json"
  .done (result) ->
    $("#save-profile").attr "disabled", "disabled"
    stopLoad()
    false
  .fail (result, status) ->
    stopLoadError()
    false
  false


$ ->
  # On load page events
  try
    loadUserBadges()
  try
    setupProfileImageUpload()
  try
    conditionalLoadAccountSettingsOptions()
  $("#save-profile").click ->
    saveProfileChanges()
    false
  $("#main-body input").keyup ->
    $("#save-profile").removeAttr "disabled"
    false
  false
