###
# Project-specific code
###

checkProjectAuthorization = (projectId = _adp.projectId) ->
  console.info "Checking authorization for #{projectId}"
  checkLoggedIn (result) ->
    unless result.status
      console.info "Non logged-in user"
      return false
    else
      # Check if the user is authorized
  false



$ ->
  _adp.projectId = uri.o.param "id"
  checkProjectAuthorization()
