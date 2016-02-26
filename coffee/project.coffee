###
# Project-specific code
###

checkProjectAuthorization = (projectId = _adp.projectId, callback) ->
  console.info "Checking authorization for #{projectId}"
  checkLoggedIn (result) ->
    unless result.status
      console.info "Non logged-in user"
      return false
    else
      # Check if the user is authorized
      dest = "#{uri.urlString}/admin-api.php"
      args = "perfom=check_access&project=#{projectId}"
      $.post dest, args, "json"
      .done (result) ->
        if result.status
          console.info "User is authorized"
          if typeof callback is "function"
            callback(result)
        else
          console.info "User is unauthorized"
      .error (result, status) ->
        console.log "Error checking server", result, status
  false



$ ->
  _adp.projectId = uri.o.param "id"
  checkProjectAuthorization()
