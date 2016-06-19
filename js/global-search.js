
/*
 * Do global searches, display global points.
 */
var checkCoordinateSanity, doDeepSearch, doSearch, generateColorByRecency, generateColorByRecency2, getSearchObject, namedMapSource, resetMap, showAllTables,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

namedMapSource = "adp_generic_heatmap-v8";

checkCoordinateSanity = function() {
  var bounds, isGood;
  isGood = true;
  bounds = {
    n: toFloat($("#north-coordinate").val()),
    w: toFloat($("#west-coordinate").val()),
    s: toFloat($("#south-coordinate").val()),
    e: toFloat($("#east-coordinate").val())
  };
  console.log("User Bounds", bounds);
  if (!(bounds.n > bounds.s)) {
    isGood = false;
    $(".lat-input").parent().addClass("has-error");
  }
  if (!(bounds.e > bounds.w)) {
    isGood = false;
    $(".lng-input").parent().addClass("has-error");
  }
  if (!isGood) {
    $(".do-search").attr("disabled", "disabled");
    return false;
  }
  $(".coord-input").parent().removeClass("has-error");
  $(".do-search").removeAttr("disabled");
  return true;
};

getSearchObject = function() {
  var bounds, diseaseStatus, morbidityStatus, search;
  bounds = {
    n: $("#north-coordinate").val(),
    w: $("#west-coordinate").val(),
    s: $("#south-coordinate").val(),
    e: $("#east-coordinate").val()
  };
  search = {
    sampled_species: {
      data: $("#taxa-input").val()
    },
    bounding_box_n: {
      data: bounds.n,
      search_type: "<="
    },
    bounding_box_e: {
      data: bounds.e,
      search_type: "<="
    },
    bounding_box_w: {
      data: bounds.w,
      search_type: ">="
    },
    bounding_box_s: {
      data: bounds.s,
      search_type: ">="
    }
  };
  diseaseStatus = $(p$("#disease-status").selectedItem).attr("data-search");
  if (diseaseStatus !== "*") {
    search.disease_positive = {
      data: 0,
      search_type: diseaseStatus.toBool() ? ">" : "="
    };
  }
  morbidityStatus = $(p$("#morbidity-status").selectedItem).attr("data-search");
  if (morbidityStatus !== "*") {
    search.disease_morbidity = {
      data: 0,
      search_type: morbidityStatus.toBool() ? ">" : "="
    };
  }
  return search;
};

doSearch = function(search, goDeep) {
  var args, data;
  if (search == null) {
    search = getSearchObject();
  }
  if (goDeep == null) {
    goDeep = false;
  }

  /*
   *
   */
  startLoad();
  data = jsonTo64(search);
  args = "perform=advanced_project_search&q=" + data;
  $.post(uri.urlString + "admin-api.php", args, "json").done(function(result) {
    var boundingBox, boundingBoxArray, cartoParsed, cartoPreParsed, cleanKey, cleanVal, e, error, error1, error2, error3, i, j, k, key, l, layer, layerSourceObj, layers, len, len1, len2, mapCenter, posSamples, project, ref, results, spArr, species, speciesCount, table, totalSamples, totalSpecies, val, zoom;
    console.info("Adv. search result", result);
    if (result.status !== true) {
      console.error(result.error);
      stopLoadError("There was a problem fetching the results");
      return false;
    }
    results = Object.toArray(result.result);
    if (results.length === 0) {
      console.warn("No results");
      stopLoadError("No results");
      return false;
    }
    totalSamples = 0;
    posSamples = 0;
    totalSpecies = new Array();
    layers = new Array();
    boundingBox = {
      n: -90,
      s: 90,
      e: -180,
      w: 180
    };
    i = 0;
    console.info("Using named map " + namedMapSource);
    for (j = 0, len = results.length; j < len; j++) {
      project = results[j];
      if (project.bounding_box_n > boundingBox.n) {
        boundingBox.n = project.bounding_box_n;
      }
      if (project.bounding_box_e > boundingBox.e) {
        boundingBox.e = project.bounding_box_e;
      }
      if (project.bounding_box_s < boundingBox.s) {
        boundingBox.s = project.bounding_box_s;
      }
      if (project.bounding_box_w < boundingBox.w) {
        boundingBox.w = project.bounding_box_w;
      }
      totalSamples += project.disease_samples;
      posSamples += project.disease_positive;
      spArr = project.sampled_species.split(",");
      for (k = 0, len1 = spArr.length; k < len1; k++) {
        species = spArr[k];
        species = species.trim();
        if (indexOf.call(totalSpecies, species) < 0) {
          totalSpecies.push(species);
        }
      }
      if (((ref = project.carto_id) != null ? ref.table : void 0) == null) {
        try {
          cartoPreParsed = JSON.parse(project.carto_id);
          cartoParsed = new Object();
          for (key in cartoPreParsed) {
            val = cartoPreParsed[key];
            cleanKey = key.replace("&#95;", "_");
            try {
              cleanVal = val.replace("&#95;", "_");
            } catch (error) {
              cleanVal = val;
            }
            cartoParsed[cleanKey] = cleanVal;
          }
          project.carto_id = cartoParsed;
        } catch (undefined) {}
      }
      try {
        table = project.carto_id.table.slice(0, 63);
      } catch (undefined) {}
      if (!isNull(table)) {
        layer = {
          name: namedMapSource,
          type: "namedmap",
          layers: [
            {
              layer_name: "layer-" + layers.length,
              interactivity: "id, diseasedetected, genus, specificepithet"
            }
          ],
          params: {
            table_name: table,
            color: "#FF6600"
          }
        };
        layers.push(layer);
      } else {
        console.warn("Unable to get a table id from this carto data:", project.carto_id);
      }
      results[i] = project;
      ++i;
    }
    try {
      boundingBoxArray = [[boundingBox.n, boundingBox.w], [boundingBox.n, boundingBox.e], [boundingBox.s, boundingBox.e], [boundingBox.s, boundingBox.w]];
      mapCenter = getMapCenter(boundingBoxArray);
      try {
        p$("#global-data-map").latitude = mapCenter.lat;
        p$("#global-data-map").longitude = mapCenter.lng;
      } catch (error1) {
        try {
          geo.lMap.panTo([mapCenter.lat, mapCenter.lng]);
        } catch (undefined) {}
      }
      zoom = getMapZoom(boundingBoxArray, ".map-container");
      if (geo.lMap != null) {
        geo.lMap.setZoom(zoom);
      }
    } catch (error2) {
      e = error2;
      console.warn("Failed to rezoom/recenter map - " + e.message, boundingBoxArray);
      console.warn(e.stack);
    }
    if (goDeep) {
      doDeepSearch(results);
      return false;
    }
    speciesCount = totalSpecies.length;
    console.info("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species", boundingBox);
    $("#post-map-subtitle").text("Viewing projects containing " + totalSamples + " samples (" + posSamples + " positive) among " + speciesCount + " species");
    try {
      for (l = 0, len2 = layers.length; l < len2; l++) {
        layer = layers[l];
        layerSourceObj = {
          user_name: cartoAccount,
          type: "namedmap",
          named_map: layer
        };
        createRawCartoMap(layerSourceObj);
      }
    } catch (error3) {
      e = error3;
      console.error("Couldn't create map! " + e.message);
      console.warn(e.stack);
    }
    stopLoad();
    return false;
  }).fail(function(result, status) {
    console.error(result, status);
    console.warn("Attempted to do", uri.urlString + "admin-api.php?" + args);
    return stopLoadError("Server error, couldn't perform search");
  });
  return false;
};

doDeepSearch = function(shallowResults) {

  /*
   * Follows up on doSearch() to then look at the shallow matches and
   * do a Carto query
   */
  toastStatusMessage("Deep search not yet implemented");
  stopLoad();
  return false;
};

showAllTables = function() {

  /*
   * Looks up all table names with permissions and shows
   * their data on the map
   */
  var args, url;
  console.log("Starting table list");
  url = uri.urlString + "admin-api.php";
  args = "perform=list";
  $.post(url, args, "json").done(function(result) {
    var cartoTables, data, e, error, i, j, layer, layerSourceObj, layers, len, pid, table, validTables;
    if (result.status === false) {
      console.error("Got bad result", result);
      return false;
    }
    console.info("Good result", result);
    cartoTables = result.carto_table_map;
    layers = new Array();
    validTables = new Array();
    i = 0;
    for (pid in cartoTables) {
      data = cartoTables[pid];
      table = data.table;
      console.log("Colors", data.creation, generateColorByRecency(data.creation), generateColorByRecency2(data.creation));
      if (!isNull(table)) {
        table = table.slice(0, 63);
        validTables.push(table);
        layer = {
          name: namedMapSource,
          type: "namedmap",
          layers: [
            {
              layer_name: "layer-" + layers.length,
              interactivity: "id, diseasedetected, genus, specificepithet"
            }
          ],
          params: {
            table_name: table,
            color: generateColorByRecency2(data.creation)
          }
        };
        layers.push(layer);
      } else {
        console.warn("Bad table #" + i, table);
      }
      ++i;
    }
    console.info("Got tables", validTables);
    console.info("Got layers", layers);
    try {
      for (j = 0, len = layers.length; j < len; j++) {
        layer = layers[j];
        layerSourceObj = {
          user_name: cartoAccount,
          type: "namedmap",
          named_map: layer
        };
        console.log("Creating raw map from", layerSourceObj);
        createRawCartoMap(layerSourceObj);
      }
    } catch (error) {
      e = error;
      console.error("Couldn't create map! " + e.message);
      console.warn(e.stack);
    }
    return false;
  }).error(function(result, status) {
    return console.error("AJAX failure showing tables", result, status);
  });
  return false;
};

resetMap = function(map) {
  var j, len, ref, sublayer;
  if (map == null) {
    map = geo.lMap;
  }
  if (geo.mapSublayers == null) {
    console.error("geo.mapSublayers is not defined.");
    return false;
  }
  ref = geo.mapSublayers;
  for (j = 0, len = ref.length; j < len; j++) {
    sublayer = ref[j];
    sublayer.remove();
  }
  foo();
  return false;
};

generateColorByRecency = function(timestamp, oldCutoff) {
  var age, b, color, cv, g, hexArray, i, j, len, maxAge, r, stepCount, stepSize, temp;
  if (oldCutoff == null) {
    oldCutoff = 1420070400;
  }

  /*
   * Start with white, then lose one color channel at a time to get
   * color recency
   *
   * @param int oldCutoff -> Linux Epoch "old" cutoff. 2015-01-01
   */
  if (!isNumber(timestamp)) {
    temp = new Date(timestamp);
    timestamp = temp.getTime() / 1000;
  }
  if (timestamp > Date.now() / 1000) {
    timestamp = timestamp / 1000;
  }
  age = (Date.now() / 1000) - timestamp;
  maxAge = timestamp - oldCutoff;
  if (age > maxAge) {
    color = "#000";
  } else {
    stepSize = maxAge / (255 * 3);
    stepCount = age / stepSize;
    b = 255;
    g = 255;
    r = 255 - stepCount;
    r = r < 0 ? 0 : toInt(r);
    if (stepCount > 255) {
      g = 255 + 255 - stepCount;
      g = g < 0 ? 0 : toInt(g);
      if (stepCount > 255 * 2) {
        b = 255 + 255 + 255 - stepCount;
        b = b < 0 ? 0 : toInt(b);
      }
    }
    console.log("Base channels", r, g, b);
    hexArray = [r.toString(16), g.toString(16), b.toString(16)];
    i = 0;
    for (j = 0, len = hexArray.length; j < len; j++) {
      cv = hexArray[j];
      if (cv.length === 1) {
        hexArray[i] = "0" + cv;
      }
      ++i;
    }
    color = "#" + (hexArray.join(""));
  }
  return color;
};

generateColorByRecency2 = function(timestamp, oldCutoff) {
  var age, b, color, cv, g, hexArray, i, j, len, maxAge, r, stepCount, stepSize, temp;
  if (oldCutoff == null) {
    oldCutoff = 1420070400;
  }

  /*
   * Start with white, then lose one color channel at a time to get
   * color recency
   *
   * @param int oldCutoff -> Linux Epoch "old" cutoff. 2015-01-01
   */
  if (!isNumber(timestamp)) {
    temp = new Date(timestamp);
    timestamp = temp.getTime() / 1000;
  }
  if (timestamp > Date.now() / 1000) {
    timestamp = timestamp / 1000;
  }
  age = (Date.now() / 1000) - timestamp;
  maxAge = timestamp - oldCutoff;
  if (age > maxAge) {
    color = "#000";
  } else {
    stepSize = maxAge / (255 * 3);
    stepCount = age / stepSize;
    r = 255 - stepCount;
    g = r < 0 ? 0 - r : 255 - r;
    r = r < 0 ? 0 : toInt(r);
    b = g > 255 ? toInt(g - 255) : 0;
    g = g > 255 ? 255 - (g - 255) : toInt(g);
    b = b < 0 ? 0 : toInt(b);
    console.log("Base channels", r, g, b);
    hexArray = [r.toString(16), g.toString(16), b.toString(16)];
    i = 0;
    for (j = 0, len = hexArray.length; j < len; j++) {
      cv = hexArray[j];
      if (cv.length === 1) {
        hexArray[i] = "0" + cv;
      }
      ++i;
    }
    color = "#" + (hexArray.join(""));
  }
  return color;
};

$(function() {
  var initProjectSearch, lMap, lTopoOptions, leafletOptions;
  geo.initLocation();
  leafletOptions = {
    center: [17.811456088564483, -37.265625],
    zoom: 2
  };
  lMap = new L.Map("global-map-container", leafletOptions);
  lTopoOptions = {
    attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
  };
  L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions).addTo(lMap);
  geo.lMap = lMap;
  $(".coord-input").keyup(function() {
    return checkCoordinateSanity();
  });
  initProjectSearch = function(clickedElement) {
    var deep, error, ok;
    ok = checkCoordinateSanity();
    if (!ok) {
      toastStatusMessage("Please check your coordinates");
      return false;
    }
    try {
      deep = $(clickedElement).attr("data-deep").toBool();
    } catch (error) {
      deep = false;
    }
    doSearch(getSearchObject(), deep);
    return false;
  };
  $("input.submit-project-search").keyup(function(e) {
    var kc;
    kc = e.keyCode ? e.keyCode : e.which;
    if (kc === 13) {
      return initProjectSearch();
    } else {
      return false;
    }
  });
  $(".do-search").click(function() {
    return initProjectSearch(this);
  });
  $("#reset-global-map").click(function() {
    resetMap();
    return false;
  });
  showAllTables();
  return false;
});

//# sourceMappingURL=maps/global-search.js.map
