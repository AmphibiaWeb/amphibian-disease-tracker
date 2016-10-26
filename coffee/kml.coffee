###
# KML handling
#
#
# Test this code:
  loadJS("js/kml.js"); delay(500, function() { loadKML("geoxml3/KML_Samples.kml"); });
#
# @path ./coffee/kml.coffee
# @author Philip Kahn
###


loadKML = (filePath, callback) ->
  if isNull filePath
    console.error "No file provided"
    return false
  if isNull geo.kml.parser
    console.error "Parser has not been initiated. Please initiate the parser."
    return false
  isKmz = filePath.split(".").pop() is "kmz"
  unless isKmz
    geo.kml.parser.parse filePath
    if typeof callback is "function"
      callback()
  else
    console.info "Loading Zip handling"
    loadJS "js/ZipFile.complete.min.js", ->
      geo.kml.parser.parse filePath
      if typeof callback is "function"
        callback()


initializeParser = (mapSelector = "google-map", callback) ->
  loadJS "js/geoxml3.min.js", ->
    loadJS "js/ProjectedOverlay.min.js", ->
      m = p$(mapSelector).map
      p = new geoXML3.parser({map: m})      
      geo.kml =
        map: m
        parser: p
      if typeof callback is "function"
        callback()
      false
    false


$ ->
  unless geo.inhibitKMLInit is true
    initializeParser()
  false
