
loadKML = (filePath) ->
  if isNull filePath
    console.error "No file provided"
    return false
  if isNull geo.kml.parser
    console.error "Parser has not been initiated. Please initiate the parser."
    return false
  isKmz = filePath.split(".").pop() is "kmz"
  unless isKmz
    geo.kml.parser.parse filePath
  else
    console.info "Loading Zip handling"
    loadJS "js/ZipFile.complete.min.js", ->
      geo.kml.parser.parse filePath


initializeParser = (mapSelector = "google-map") ->
  loadJS "js/geoxml3.min.js", ->
    loadJS "js/ProjectedOverlay.min.js", ->
      m = p$(mapSelector).map
      p = new geoXML3.parser({map: m})      
      geo.kml =
        map: m
        parser: p
      false
    false


$ ->
  initializeParser()
  false
