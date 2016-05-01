###
#
#
#
# See
# https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
###


loadUserBadges = ->
  false


setupProfileImageUpload = ->
  false


conditionalLoadAccountSettingsOptions = ->
  false


constructProfileJson = ->
  false

saveProfileChanges = ->
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
  false
