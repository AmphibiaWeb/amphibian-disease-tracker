
/*
 * Do global searches, display global points.
 */
var checkCoordinateSanity, createTemplateByProject, doDeepSearch, doSearch, generateColorByRecency, generateColorByRecency2, getSearchContainsObject, getSearchObject, namedMapAdvSource, namedMapSource, resetMap, setViewerBounds, showAllTables,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

namedMapSource = "adp_generic_heatmap-v16";

namedMapAdvSource = "adp_specific_heatmap-v11";

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

createTemplateByProject = function(table) {
  var args, query, start, templateId;
  if (table == null) {
    table = "t2627cbcbb4d7597f444903b2e7a5ce5c_6d6d454828c05e8ceea03c99cc5f5";
  }
  start = Date.now();
  table = table.slice(0, 63);
  templateId = "infowindow_template_" + table;
  if ($("#" + templateId).exists()) {
    return false;
  }
  query = "SELECT cartodb_id FROM " + table;
  args = "action=fetch&sql_query=" + (post64(query));
  $.post(uri.urlString + "api.php", args, "json").done(function(result) {
    var elapsed, html;
    if (!isNull(result.project_id)) {
      html = "<script type=\"infowindow/html\" id=\"" + templateId + "\">\n  <div class=\"cartodb-popup v2\">\n    <a href=\"#close\" class=\"cartodb-popup-close-button close\">x</a>\n    <div class=\"cartodb-popup-content-wrapper\">\n      <div class=\"cartodb-popup-header\">\n        <img style=\"width: 100%\" src=\"https://cartodb.com/assets/logos/logos_full_cartodb_light.png\"/>\n      </div>\n      <div class=\"cartodb-popup-content\">\n        <!-- content.data contains the field info -->\n        <h4>Species: </h4>\n        <p>{{content.data.genus}} {{content.data.specificepithet}}</p>\n        <p>Tested {{content.data.diseasetested}} as {{content.data.diseasedetected}} (Fatal: {{content.data.fatal}})</p>\n        <p><a href=\"https://amphibiandisease.org/project.php?id=" + result.project_id + "\">View Project</a></p>\n      </div>\n    </div>\n    <div class=\"cartodb-popup-tip-container\"></div>\n  </div>\n</script>";
      $("body").append(html);
      elapsed = Date.now() - start;
      return console.info("Template set for #" + templateId + " (took " + elapsed + "ms)");
    } else {
      return console.warn("Couldn't find project ID for table " + table, result);
    }
  });
  return false;
};

setViewerBounds = function(map) {
  var bounds, ne, sw;
  if (map == null) {
    map = geo.lMap;
  }
  bounds = map.getBounds();
  sw = bounds._southWest;
  ne = bounds._northEast;
  if (ne.lng - sw.lng > 360) {
    sw.lng = -180;
    ne.lng = 180;
  }
  $("#north-coordinate").val(ne.lat);
  $("#west-coordinate").val(sw.lng);
  $("#south-coordinate").val(sw.lat);
  $("#east-coordinate").val(ne.lng);
  return false;
};

getSearchObject = function() {
  var bounds, diseaseStatus, morbidityStatus, pathogen, search;
  try {
    if (p$("#use-viewport-bounds").checked) {
      setViewerBounds();
    }
  } catch (undefined) {}
  bounds = {
    n: $("#north-coordinate").val(),
    w: $("#west-coordinate").val(),
    s: $("#south-coordinate").val(),
    e: $("#east-coordinate").val()
  };
  search = {
    sampled_species: {
      data: $("#taxa-input").val().toLowerCase()
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
  pathogen = $(p$("#pathogen-choice").selectedItem).attr("data-search");
  if (pathogen !== "*") {
    search.disease = {
      data: pathogen
    };
  }
  return search;
};

getSearchContainsObject = function() {
  var bounds, diseaseStatus, genus, morbidityStatus, pathogen, search, sp, ssp, taxaSearch, taxaSplit;
  try {
    if (p$("#use-viewport-bounds").checked) {
      setViewerBounds();
    }
  } catch (undefined) {}
  bounds = {
    n: $("#north-coordinate").val(),
    w: $("#west-coordinate").val(),
    s: $("#south-coordinate").val(),
    e: $("#east-coordinate").val()
  };
  taxaSearch = $("#taxa-input").val().toLowerCase();
  taxaSplit = taxaSearch.split(" ");
  ssp = taxaSplit.length === 3 ? taxaSplit.pop() : "";
  sp = taxaSplit.length === 2 ? taxaSplit.pop() : "";
  genus = taxaSplit.length === 1 ? taxaSplit.pop() : "";
  search = {
    sampled_species: {
      data: taxaSearch,
      genus: genus,
      species: sp,
      subspecies: ssp
    },
    bounding_box_n: {
      data: bounds.s,
      search_type: ">"
    },
    bounding_box_e: {
      data: bounds.w,
      search_type: ">"
    },
    bounding_box_w: {
      data: bounds.e,
      search_type: "<"
    },
    bounding_box_s: {
      data: bounds.n,
      search_type: "<"
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
  pathogen = $(p$("#pathogen-choice").selectedItem).attr("data-search");
  if (pathogen !== "*") {
    search.disease = {
      data: pathogen
    };
  }
  return search;
};

doSearch = function(search, goDeep) {
  var action, args, data, namedMap;
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
  action = "advanced_project_search";
  namedMap = goDeep ? namedMapAdvSource : namedMapSource;
  args = "perform=" + action + "&q=" + data;
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
    if (goDeep) {
      doDeepSearch(results, namedMap);
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
    console.info("Using standard named map " + namedMap);
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
        try {
          createTemplateByProject(table);
        } catch (undefined) {}
        layer = {
          name: namedMap,
          type: "namedmap",
          layers: [
            {
              layer_name: "layer-" + layers.length
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
      zoom = getMapZoom(boundingBoxArray, ".map-container");
      console.info("Found @ zoom = " + zoom + " center", mapCenter, "for bounding box", boundingBoxArray);
      if (geo.lMap != null) {
        geo.lMap.setZoom(zoom);
      }
      try {
        p$("#global-data-map").latitude = mapCenter.lat;
        p$("#global-data-map").longitude = mapCenter.lng;
      } catch (error1) {
        try {
          geo.lMap.panTo([mapCenter.lat, mapCenter.lng]);
        } catch (undefined) {}
      }
    } catch (error2) {
      e = error2;
      console.warn("Failed to rezoom/recenter map - " + e.message, boundingBoxArray);
      console.warn(e.stack);
    }
    speciesCount = totalSpecies.length;
    console.info("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species", boundingBox);
    try {
      resetMap(geo.lMap, false, false);
      for (l = 0, len2 = layers.length; l < len2; l++) {
        layer = layers[l];
        layerSourceObj = {
          user_name: cartoAccount,
          type: "namedmap",
          named_map: layer
        };
        createRawCartoMap(layerSourceObj);
        $("#post-map-subtitle").text("Viewing projects containing " + totalSamples + " samples (" + posSamples + " positive) among " + speciesCount + " species");
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

doDeepSearch = function(results, namedMap) {
  var boundingBox, boundingBoxArray, cartoParsed, cartoPreParsed, cleanKey, cleanVal, detected, diseaseWord, e, error, error1, error2, error3, error4, fatal, fatalSimple, i, j, k, key, l, layer, layerSourceObj, layers, len, len1, len2, mapCenter, pathogen, posSamples, project, ref, ref1, ref2, ref3, ref4, search, spArr, spText, species, speciesCount, subText, table, totalSamples, totalSpecies, val, zoom;
  if (namedMap == null) {
    namedMap = namedMapAdvSource;
  }

  /*
   * Follows up on doSearch() to then look at the shallow matches and
   * do a Carto query
   */
  try {
    search = getSearchContainsObject();
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
    console.info("Using deep named map " + namedMap);
    detected = "";
    if (((ref = search.disease_positive) != null ? ref.data : void 0) != null) {
      if (search.disease_positive.search_type === ">") {
        detected = "true";
      } else {
        detected = "false";
      }
    }
    fatal = "";
    if (((ref1 = search.disease_morbidity) != null ? ref1.data : void 0) != null) {
      if (search.disease_morbidity.search_type === ">") {
        fatal = "and fatal = true";
        fatalSimple = true;
      } else {
        fatal = "and fatal = false";
        fatalSimple = false;
      }
    }
    pathogen = "";
    if (((ref2 = search.disease) != null ? ref2.data : void 0) != null) {
      pathogen = (function() {
        switch (search.disease.data) {
          case "Batrachochytrium dendrobatidis":
            return "bd";
          case "Batrachochytrium salamandrivorans":
            return "bsal";
          default:
            return "";
        }
      })();
    }
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
      if (((ref3 = project.carto_id) != null ? ref3.table : void 0) == null) {
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
          name: namedMap,
          type: "namedmap",
          layers: [
            {
              layer_name: "layer-" + layers.length
            }
          ],
          params: {
            table_name: table,
            color: "#FF6600",
            genus: search.sampled_species.genus,
            specific_epithet: search.sampled_species.species,
            disease_detected: detected,
            morbidity: fatal,
            pathogen: pathogen
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
      zoom = getMapZoom(boundingBoxArray, ".map-container");
      console.info("Found @ zoom = " + zoom + " center", mapCenter, "for bounding box", boundingBoxArray);
      if (geo.lMap != null) {
        geo.lMap.setZoom(zoom);
      }
      try {
        p$("#global-data-map").latitude = mapCenter.lat;
        p$("#global-data-map").longitude = mapCenter.lng;
      } catch (error1) {
        try {
          geo.lMap.panTo([mapCenter.lat, mapCenter.lng]);
        } catch (undefined) {}
      }
    } catch (error2) {
      e = error2;
      console.warn("Failed to rezoom/recenter map - " + e.message, boundingBoxArray);
      console.warn(e.stack);
    }
    speciesCount = totalSpecies.length;
    console.info("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species", boundingBox);
    subText = "Viewing data points";
    if (!isNull((ref4 = search.sampled_species) != null ? ref4.genus : void 0)) {
      spText = " of '" + search.sampled_species.genus + " " + search.sampled_species.species + " " + search.sampled_species.subspecies + "'";
      subText += spText.replace(/( \*)/img, "");
    }
    diseaseWord = search.pathogen != null ? search.pathogen.data : "disease";
    if (search.disease != null) {
      subText += " for " + search.disease.data;
    }
    if (search.disease_positive != null) {
      subText += " with disease status '" + detected + "'";
    }
    if (search.disease_morbidity != null) {
      subText += " with morbidity status '" + fatalSimple + "'";
    }
    subText += " in bounds defined by [{lat: " + search.bounding_box_n.data + ",lng: " + search.bounding_box_w.data + "},{lat: " + search.bounding_box_s.data + ",lng: " + search.bounding_box_e.data + "}]";
    try {
      resetMap(geo.lMap, false, false);
      for (l = 0, len2 = layers.length; l < len2; l++) {
        layer = layers[l];
        layerSourceObj = {
          user_name: cartoAccount,
          type: "namedmap",
          named_map: layer
        };
        createRawCartoMap(layerSourceObj);
        $("#post-map-subtitle").text(subText);
      }
    } catch (error3) {
      e = error3;
      console.error("Couldn't create map! " + e.message);
      console.warn(e.stack);
    }
    stopLoad();
  } catch (error4) {
    e = error4;
    stopLoadError("There was a problem performing a sample search");
    console.error("Problem performing sample search! " + e.message);
    console.warn(e.stack);
  }
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
              interactivity: "cartodb_id, id, diseasedetected, genus, specificepithet"
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

resetMap = function(map, showTables, resetZoom) {
  var error, error1, id, j, layer, len, p, ref, ref1, sublayer;
  if (map == null) {
    map = geo.lMap;
  }
  if (showTables == null) {
    showTables = true;
  }
  if (resetZoom == null) {
    resetZoom = true;
  }
  if (geo.mapSublayers == null) {
    console.error("geo.mapSublayers is not defined.");
    return false;
  }
  try {
    ref = geo.mapSublayers;
    for (j = 0, len = ref.length; j < len; j++) {
      sublayer = ref[j];
      sublayer.remove();
    }
  } catch (error) {
    ref1 = map._layers;
    for (id in ref1) {
      layer = ref1[id];
      try {
        p = layer._url.search("arcgisonline");
        if (p === -1) {
          try {
            layer.removeLayer();
          } catch (error1) {
            layer.remove();
          }
        }
      } catch (undefined) {}
    }
  }
  $("#post-map-subtitle").text("");
  if (resetZoom) {
    geo.lMap.setZoom(geo.defaultLeafletOptions.zoom);
    geo.lMap.panTo(geo.defaultLeafletOptions.center);
  }
  if (showTables) {
    showAllTables();
    $("#post-map-subtitle").text("All Projects");
  }
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
    color = "#000000";
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
   * @param int timestamp -> Javascript linux epoch (ms)
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
    color = "#000000";
  } else {
    stepSize = maxAge / (255 * 3);
    stepCount = age / stepSize;
    r = 255 - stepCount;
    g = r < 0 ? 0 - r : 255 - r;
    r = r < 0 ? 0 : toInt(r);
    b = g > 255 ? toInt(g - 255) : 255;
    g = g > 255 ? 255 - (g - 255) : toInt(g);
    b = b < 0 ? 0 : toInt(b);
    console.log("Base channels 2", r, g, b);
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
  console.log("Recency2 generated", hexArray, color);
  return color;
};

$(function() {
  var initProjectSearch, lMap, lTopoOptions, leafletOptions, updateViewportBounds;
  geo.initLocation();
  leafletOptions = {
    center: [17.811456088564483, -37.265625],
    zoom: 2
  };
  geo.defaultLeafletOptions = leafletOptions;
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
    var deep, error, ok, search;
    ok = checkCoordinateSanity();
    if (!ok) {
      toastStatusMessage("Please check your coordinates");
      return false;
    }
    search = getSearchObject();
    try {
      deep = $(clickedElement).attr("data-deep").toBool();
      if (deep) {
        search = getSearchContainsObject();
      }
    } catch (error) {
      deep = false;
    }
    doSearch(search, deep);
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
  $("#toggle-global-search-filters").click(function() {
    var actionWord, isOpened;
    isOpened = p$("#global-search-filters").opened;
    p$("#global-search-filters").toggle();
    actionWord = !isOpened ? "Hide" : "Show";
    $(this).find(".action-word").text(actionWord);
    return false;
  });
  updateViewportBounds = function() {
    if (p$("#use-viewport-bounds").checked) {
      console.info("Setting viewer bounds, checkbox is checked");
      return setViewerBounds();
    } else {
      return console.info("Not using viewport bounds");
    }
  };
  geo.lMap.on("moveend", function() {
    return updateViewportBounds();
  }).on("zoomend", function() {
    return updateViewportBounds();
  });
  showAllTables();
  checkFileVersion(false, "js/global-search.min.js");
  return false;
});

//# sourceMappingURL=maps/global-search.js.map
