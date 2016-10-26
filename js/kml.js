
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
  var isKmz;
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
    geo.kml.parser.parse(filePath);
    return delay(500, function() {
      if (typeof callback === "function") {
        return callback();
      }
    });
  } else {
    console.info("Loading Zip handling");
    return loadJS("js/ZipFile.complete.min.js", function() {
      geo.kml.parser.parse(filePath);
      return delay(500, function() {
        if (typeof callback === "function") {
          return callback();
        }
      });
    });
  }
};

initializeParser = function(mapSelector, callback) {
  if (mapSelector == null) {
    mapSelector = "google-map";
  }
  return loadJS("js/geoxml3.min.js", function() {
    loadJS("js/ProjectedOverlay.min.js", function() {
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
  return false;
});

//# sourceMappingURL=maps/kml.js.map
