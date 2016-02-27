renderPublicMap = (projectData) ->
  if projectData.public.toBool()
    # We're going to already be rendered more fully
    return false
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
  nw =
    lat: projectData.bounding_box_n
    lng: projectData.bounding_box_w
  ne =
    lat: projectData.bounding_box_n
    lng: projectData.bounding_box_e
  se =
    lat: projectData.bounding_box_s
    lng: projectData.bounding_box_e
  sw =
    lat: projectData.bounding_box_s
    lng: projectData.bounding_box_w
  paths = [
    nw
    ne
    se
    sw
    ]
  for point in paths
    unless point in usedPoints
      usedPoints.push point
      mapHtml += """
      <google-map-point latitude="#{point.lat}" longitude="#{point.lng}"> </google-map-point>
      """
  mapHtml += "    </google-map-poly>"
  googleMap = """
        <google-map id="transect-viewport" latitude="#{projectData.lat}" longitude="#{projectData.lng}" fit-to-markers map-type="hybrid" disable-default-ui zoom="#{zoom}" class="col-xs-12 col-md-9 col-lg-6">
          #{mapHtml}
        </google-map>
  """
  $("#auth-block").append googleMap
