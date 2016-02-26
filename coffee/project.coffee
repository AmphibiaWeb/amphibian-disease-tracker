###
# Project-specific code
###

checkProjectAuthorization = (projectId = _adp.projectId, callback) ->
  startLoad()
  console.info "Checking authorization for #{projectId}"
  checkLoggedIn (result) ->
    unless result.status
      console.info "Non logged-in user"
      return false
    else
      # Check if the user is authorized
      dest = "#{uri.urlString}/admin-api.php"
      args = "perform=check_access&project=#{projectId}"
      $.post dest, args, "json"
      .done (result) ->
        if result.status
          console.info "User is authorized"
          project = result.detail.project
          if typeof callback is "function"
            callback project
          else
            console.warn "No callback specified!"
            console.info "Got project data", project
        else
          console.info "User is unauthorized"
      .error (result, status) ->
        console.log "Error checking server", result, status
      .always ->
        stopLoad()
  false

renderEmail = (response) ->
  stopLoad()
  dest = "#{uri.urlString}/api.php"
  args = "action=is_human&recaptcha_response=#{response}&project=#{_adp.projectId}"
  $.post dest, args, "json"
  .done (result) ->
    console.info "Checked response"
    console.log result
    authorData = result.author_data
    html = """
    <div class="row">
      <paper-input readonly class="col-xs-8 col-md-11" label="Contact Email" value="#{authorData.contact_email}"></paper-input>
      <div class="col-xs-4 col-md-1">
        <paper-fab icon="communication:email" class="click materialblue" id="contact-email-send" data-href="mailto:#{authorData.contact_email}"></paper-fab>
      </div>
    </div>
    """
    $("#email-fill").replaceWith html
    bindClicks("#contact-email-send")
    stopLoad()
  .error (result, status) ->
    stopLoadError "Sorry, there was a problem getting the contact email"
    false    
  false

$ ->
  _adp.projectId = uri.o.param "id"
  checkProjectAuthorization()
