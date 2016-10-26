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
  startTime = Date.now()
  if isNull filePath
    console.error "No file provided"
    return false
  if isNull geo.kml.parser
    console.error "Parser has not been initiated. Please initiate the parser."
    return false
  isKmz = filePath.split(".").pop() is "kmz"
  unless isKmz
    geo.kml.parser.parse filePath, null, ->
      elapsed = Date.now() - startTime
      console.debug "Test callback fired after #{elapsed}ms"
    delay 500, ->
      if typeof callback is "function"
        callback()
  else
    console.info "Loading Zip handling"
    loadJS "js/ZipFile.complete.min.js", ->
      geo.kml.parser.parse filePath, null, ->
        elapsed = Date.now() - startTime
        console.debug "Test callback (kmz) fired after #{elapsed}ms"
      delay 500, ->
        if typeof callback is "function"
          callback()


initializeParser = (mapSelector = "google-map", callback) ->
  modTime = unless isNull(_adp?.lastMod?.geoAll) then _adp.lastMod.geoAll else Date.now()
  loadJS "js/geoxml3.min.js?t=#{modTime}", ->
    loadJS "js/ProjectedOverlay.min.js?t=#{modTime}", ->
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
  try
    checkFileVersion true, "js/geoxml3.min.js", ->
      _adp.lastMod.geoAll = _adp.lastMod.geoxml3
      checkFileVersion true, "js/ProjectedOverlay.min.js", ->
        try
          if _adp.lastMod.ProjectedOverlay > _adp.lastMod.geoAll
            _adp.lastMod.geoAll = _adp.lastMod.ProjectedOverlay
        checkFileVersion true, "js/ZipFile.complete.min.js", ->
          try
            if _adp.lastMod.ZipFile > _adp.lastMod.geoAll
              _adp.lastMod.geoAll = _adp.lastMod.ZipFile
  false
