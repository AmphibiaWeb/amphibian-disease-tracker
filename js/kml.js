
/*
 * KML handling
 *
 *
 * Test this code:
  loadJS("js/kml.js"); delay(500, function() { loadKML("geoxml3/KML_Samples.kml"); });
 *
 * @path ./coffee/kml.coffee
 * @author Philip Kahn
 */
var initializeParser, loadKML;

loadKML = function(filePath, callback) {
  var isKmz, startTime;
  startTime = Date.now();
  if (isNull(filePath)) {
    console.error("No file provided");
    return false;
  }
  if (isNull(geo.kml.parser)) {
    console.error("Parser has not been initiated. Please initiate the parser.");
    return false;
  }
  isKmz = filePath.split(".").pop() === "kmz";
  if (!isKmz) {
    geo.kml.parser.parse(filePath, null, function() {
      var elapsed;
      elapsed = Date.now() - startTime;
      return console.debug("Test callback fired after " + elapsed + "ms");
    });
    return delay(500, function() {
      if (typeof callback === "function") {
        return callback();
      }
    });
  } else {
    console.info("Loading Zip handling");
    return loadJS("js/ZipFile.complete.min.js", function() {
      geo.kml.parser.parse(filePath, null, function() {
        var elapsed;
        elapsed = Date.now() - startTime;
        return console.debug("Test callback (kmz) fired after " + elapsed + "ms");
      });
      return delay(500, function() {
        if (typeof callback === "function") {
          return callback();
        }
      });
    });
  }
};

initializeParser = function(mapSelector, callback) {
  var modTime, ref;
  if (mapSelector == null) {
    mapSelector = "google-map";
  }
  modTime = !isNull(typeof _adp !== "undefined" && _adp !== null ? (ref = _adp.lastMod) != null ? ref.geoAll : void 0 : void 0) ? _adp.lastMod.geoAll : Date.now();
  return loadJS("js/geoxml3.min.js?t=" + modTime, function() {
    loadJS("js/ProjectedOverlay.min.js?t=" + modTime, function() {
      var m, p;
      m = p$(mapSelector).map;
      p = new geoXML3.parser({
        map: m
      });
      geo.kml = {
        map: m,
        parser: p
      };
      if (typeof callback === "function") {
        callback();
      }
      return false;
    });
    return false;
  });
};

$(function() {
  if (geo.inhibitKMLInit !== true) {
    initializeParser();
  }
  try {
    checkFileVersion(true, "js/geoxml3.min.js", function() {
      _adp.lastMod.geoAll = _adp.lastMod.geoxml3;
      return checkFileVersion(true, "js/ProjectedOverlay.min.js", function() {
        try {
          if (_adp.lastMod.ProjectedOverlay > _adp.lastMod.geoAll) {
            _adp.lastMod.geoAll = _adp.lastMod.ProjectedOverlay;
          }
        } catch (undefined) {}
        return checkFileVersion(true, "js/ZipFile.complete.min.js", function() {
          try {
            if (_adp.lastMod.ZipFile > _adp.lastMod.geoAll) {
              return _adp.lastMod.geoAll = _adp.lastMod.ZipFile;
            }
          } catch (undefined) {}
        });
      });
    });
  } catch (undefined) {}
  return false;
});

//# sourceMappingURL=maps/kml.js.map
