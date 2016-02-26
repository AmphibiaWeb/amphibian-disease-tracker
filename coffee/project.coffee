###
# Project-specific code
###

checkProjectAuthorization = (projectId = _adp.projectId, callback = postAuthorizeRender) ->
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
    showEmailField authorData.contact_email
    stopLoad()
  .error (result, status) ->
    stopLoadError "Sorry, there was a problem getting the contact email"
    false
  false


showEmailField = (email) ->
  html = """
  <div class="row">
    <paper-input readonly class="col-xs-8 col-md-11" label="Contact Email" value="#{email}"></paper-input>
    <div class="col-xs-4 col-md-1">
      <paper-fab icon="communication:email" class="click materialblue" id="contact-email-send" data-href="mailto:#{email}"></paper-fab>
    </div>
  </div>
  """
  $("#email-fill").replaceWith html
  bindClicks("#contact-email-send")
  false



postAuthorizeRender = (projectData) ->
  if projectData.public
    console.info "Project is already public, not rerendering"
    false
  startLoad()
  console.info "Should render stuff", projectData
  editButton = """
  <paper-icon-button icon="icons:create" class="authorized-action" data-href="admin-page.html?id=#{projectData.project_id}"></paper-icon-button>
  """
  $("#title").append editButton
  authorData = JSON.parse projectData.author_data
  showEmailField authorData.contact_email
  $(".needs-auth").html "<p>User is authorized, should repopulate</p>"
  bindClicks(".authorized-action")
  cartoData = JSON.parse deEscape projectData.carto_id
  cartoTable = cartoData.table
  try
    zoom = getMapZoom cartoData.bounding_polygon.paths, "#transect-viewport"
    console.info "Got zoom", zoom
  catch
    zoom = ""
  poly = cartoData.bounding_polygon
  mapHtml = """
  <google-map-poly closed fill-color="#{poly.fillColor}" fill-opacity="#{poly.fillOpacity}" stroke-weight="1">
  """
  usedPoints = new Array()
  for point in poly.paths
    unless point in usedPoints
      usedPoints.push point
      mapHtml += """
      <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
      """
  mapHtml += "    </google-map-poly>"

  cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM #{cartoTable};"
  console.info "Would ping cartodb with", cartoQuery
  apiPostSqlQuery = encodeURIComponent encode64 cartoQuery
  args = "action=fetch&sql_query=#{apiPostSqlQuery}"
  $.post "api.php", args, "json"
  .done (result) ->
    console.info "Carto query got result:", result
    unless result.status
      error = result.human_error ? result.error
      unless error?
        error = "Unknown error"
      stopLoadError "Sorry, we couldn't retrieve your information at the moment (#{error})"
      return false
    rows = result.parsed_responses[0].rows
    for k, row of rows
      geoJson = JSON.parse row.st_asgeojson
      lat = geoJson.coordinates[0]
      lng = geoJson.coordinates[1]
      # Fill the points as markers
      row.diseasedetected = switch row.diseasedetected.toString().toLowerCase()
        when "true"
          "positive"
        when "false"
          "negative"
        else
          row.diseasedetected.toString()
      taxa = "#{row.genus} #{row.specificepithet}"
      note = ""
      if taxa isnt row.originaltaxa
        note = "(<em>#{row.originaltaxa}</em>)"
      marker = """
      <google-map-marker latitude="#{lat}" longitude="#{lng}">
        <p>
          <em>#{row.genus} #{row.specificepithet}</em> #{note}
          <br/>
          Tested <strong>#{row.diseasedetected}</strong> for #{row.diseasetested}
        </p>
      </google-map-marker>
      """
      # $("#transect-viewport").append marker
      mapHtml += marker
    # Looped over all of them
    googleMap = """
          <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" fit-to-markers map-type="hybrid" disable-default-ui zoom="#{zoom}">
            #{mapHtml}
          </google-map>
    """
    $("#auth-block").append googleMap
    stopLoad()
  .error (result, status) ->
    console.error result, status
    stopLoadError "Couldn't render map"
  false


$ ->
  _adp.projectId = uri.o.param "id"
  checkProjectAuthorization()
