
/*
 * Do global searches, display global points.
 */
var checkCoordinateSanity, createTemplateByProject, doDeepSearch, doSearch, generateColorByRecency, generateColorByRecency2, getProjectResultDialog, getSampleSummaryDialog, getSearchContainsObject, getSearchObject, namedMapAdvSource, namedMapSource, resetMap, setViewerBounds, showAllTables,
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

doSearch = function(search, goDeep, hasRunValidated) {
  var action, args, data, namedMap;
  if (search == null) {
    search = getSearchObject();
  }
  if (goDeep == null) {
    goDeep = false;
  }
  if (hasRunValidated == null) {
    hasRunValidated = false;
  }

  /*
   * Main search bootstrapper.
   *
   * Looks up a taxon, and gets a list of projects to search within.
   */
  startLoad();
  $("#post-map-subtitle").removeClass("bg-success");
  data = jsonTo64(search);
  action = "advanced_project_search";
  namedMap = goDeep ? namedMapAdvSource : namedMapSource;
  args = "perform=" + action + "&q=" + data;
  $.post(uri.urlString + "admin-api.php", args, "json").done(function(result) {
    var boundingBox, boundingBoxArray, cartoParsed, cartoPreParsed, cleanKey, cleanVal, e, ensureCenter, error, error1, error2, i, j, k, key, l, layer, layerSourceObj, layers, len, len1, len2, mapCenter, posSamples, project, ref, ref1, ref2, ref3, ref4, results, rlButton, searchFailed, spArr, species, speciesCount, table, taxon, taxonArray, taxonRaw, totalSamples, totalSpecies, val, zoom;
    console.info("Adv. search result", result);
    if (result.status !== true) {
      console.error(result.error);
      stopLoadError("There was a problem fetching the results");
      return false;
    }
    results = Object.toArray(result.result);
    if (results.length === 0) {
      searchFailed = function() {
        var inputErrorHtml, ref;
        console.warn("The search failed!");
        if (!isNull((ref = search.sampled_species) != null ? ref.data : void 0)) {
          inputErrorHtml = "<span id=\"taxa-input-error\" class=\"help-block\">\n  Invalid species: Please check your spelling. <a href=\"http://amphibiaweb.org/search/index.html\" data-newtab=\"true\">Check AmphibiaWeb for valid species</a>\n</span>";
          $("#taxa-input-container").addClass("has-error");
          $("#taxa-input").attr("aria-describedby", "taxa-input-error").after(inputErrorHtml).keyup(function() {
            try {
              $("#taxa-input-container").removeClass("has-error");
              return $("#taxa-input-error").remove();
            } catch (undefined) {}
          });
          bindClicks();
        }
        console.warn("No results");
        stopLoadError("No results");
        return false;
      };
      if (!isNull((ref = search.sampled_species) != null ? ref.data : void 0) && !hasRunValidated) {
        console.warn("The initial search failed, we're going to validate the taxon and re-check");
        taxonRaw = search.sampled_species.data;
        taxonArray = taxonRaw.split(" ");
        taxon = {
          genus: (ref1 = taxonArray[0]) != null ? ref1 : "",
          species: (ref2 = taxonArray[1]) != null ? ref2 : ""
        };
        validateAWebTaxon(taxon, function(validatedTaxon) {
          var taxonString;
          if (validatedTaxon.invalid === true) {
            console.error("This taxon is invalid!", validatedTaxon);
            searchFailed();
            return false;
          }
          taxonString = validatedTaxon.genus + " " + validatedTaxon.species + " " + validatedTaxon.subspecies;
          taxonString = taxonString.trim();
          $("#taxa-input").val(taxonString);
          doSearch(getSearchObject(), goDeep, true);
          return false;
        });
      } else {
        console.warn("No need to validate", isNull((ref3 = search.sampled_species) != null ? ref3.data : void 0), hasRunValidated);
        searchFailed();
      }
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
      if (((ref4 = project.carto_id) != null ? ref4.table : void 0) == null) {
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
        table = project.carto_id.table;
        table = table.unescape();
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
        geo.lMap.once("zoomend", (function(_this) {
          return function() {
            console.info("ZoomEnd is ensuring centering");
            return ensureCenter(0);
          };
        })(this));
        geo.lMap.setZoom(zoom);
      }
      try {
        p$("#global-data-map").latitude = mapCenter.lat;
        p$("#global-data-map").longitude = mapCenter.lng;
        p$("#global-data-map").zoom = zoom;
      } catch (undefined) {}
      try {
        geo.lMap.setView(mapCenter.getObj());
      } catch (undefined) {}
    } catch (error1) {
      e = error1;
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
      }
      $("#post-map-subtitle").text("Viewing projects containing " + totalSamples + " samples (" + posSamples + " positive) among " + speciesCount + " species");
      $("#post-map-subtitle").addClass("bg-success");
      $(".show-result-list").remove();
      rlButton = "<paper-icon-button class=\"show-result-list\" icon=\"icons:subject\" data-toggle=\"tooltip\" title=\"Show Project list\" raised></paper-icon-button>";
      $("#post-map-subtitle").append(rlButton);
      getProjectResultDialog(results);
      (ensureCenter = function(count, maxCount, timeout) {

        /*
         * Make sure the center is right
         */
        var center, lat, lng, pctOffLat, pctOffLng, rndLat, rndLng, waited;
        rndLat = roundNumber(mapCenter.lat, 3);
        rndLng = roundNumber(mapCenter.lng, 3);
        try {
          lat = roundNumber(p$("#global-data-map").latitude, 3);
          lng = roundNumber(p$("#global-data-map").longitude, 3);
          center = {
            type: "google-map-element",
            lat: lat,
            lng: lng
          };
        } catch (undefined) {}
        try {
          center = geo.lMap.getCenter();
          lat = roundNumber(center.lat, 3);
          lng = roundNumber(center.lng, 3);
        } catch (undefined) {}
        pctOffLat = Math.abs((lat - rndLat) / rndLat) * 100;
        pctOffLng = Math.abs((lng - rndLng) / rndLng) * 100;
        if (pctOffLat < 2 && pctOffLng < 2 && count > 5) {
          console.info("Correctly centered", mapCenter, center, [pctOffLat, pctOffLng]);
          if (geo.lMap.getZoom() !== zoom) {
            console.warn("The map was centered before the zoom finished -- this may need to fire again");
          }
          clearTimeout(_adp.centerTimeout);
          return false;
        } else {
          if (!(count <= 15)) {
            console.warn("Centering too deviant", pctOffLat < 2, pctOffLng < 2, pctOffLat < 2 && pctOffLng < 2, lat, lng, rndLat, rndLng);
          }
        }
        if (!isNumber(maxCount)) {
          maxCount = 100;
        }
        if (count > maxCount) {
          waited = timeout * maxCount;
          console.info("Map could not be correctly centered in " + waited + "ms");
          clearTimeout(_adp.centerTimeout);
          return false;
        }
        ++count;
        return _adp.centerTimeout = delay(timeout, function() {
          var error2;
          if (!isNumber(maxCount)) {
            maxCount = 100;
          }
          try {
            p$("#global-data-map").latitude = mapCenter.lat;
            p$("#global-data-map").longitude = mapCenter.lng;
          } catch (undefined) {}
          try {
            console.log("#" + count + "/" + maxCount + " General setting view to", mapCenter.getObj(), [pctOffLat, pctOffLng]);
            geo.lMap.setView(mapCenter.getObj());
          } catch (error2) {
            e = error2;
            console.warn("Error setting view - " + e.message);
          }
          if (count < maxCount) {
            return ensureCenter(count);
          }
        });
      })(0, 100, 100);
    } catch (error2) {
      e = error2;
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
  var args, boundingBox, boundingBoxArray, cartoParsed, cartoPreParsed, cleanKey, cleanVal, detected, diseaseWord, e, ensureCenter, error, error1, error2, error3, fatal, fatalSimple, i, j, k, key, l, layer, layerSourceObj, layers, len, len1, len2, mapCenter, pathogen, posSamples, project, projectTableMap, ref, ref1, ref2, ref3, ref4, resultQueryPile, search, spArr, spText, species, speciesCount, subText, table, tempQuery, totalSamples, totalSpecies, val, zoom;
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
    projectTableMap = new Object();
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
        table = project.carto_id.table;
        table = table.unescape();
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
        projectTableMap[table] = {
          id: project.project_id,
          name: project.project_title
        };
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
        geo.lMap.once("zoomend", (function(_this) {
          return function() {
            console.info("ZoomEnd is ensuring centering");
            return ensureCenter(0);
          };
        })(this));
        geo.lMap.setZoom(zoom);
      }
      try {
        p$("#global-data-map").latitude = mapCenter.lat;
        p$("#global-data-map").longitude = mapCenter.lng;
        p$("#global-data-map").zoom = zoom;
      } catch (undefined) {}
      try {
        geo.lMap.setView(mapCenter.getObj());
      } catch (undefined) {}
    } catch (error1) {
      e = error1;
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
      resultQueryPile = "";
      for (l = 0, len2 = layers.length; l < len2; l++) {
        layer = layers[l];
        layerSourceObj = {
          user_name: cartoAccount,
          type: "namedmap",
          named_map: layer
        };
        createRawCartoMap(layerSourceObj);
        tempQuery = "select * from " + layer.params.table_name + " where (genus ilike '%" + layer.params.genus + "%' and specificepithet ilike '%" + layer.params.specific_epithet + "%' and diseasedetected ilike '%" + layer.params.disease_detected + "%' " + layer.params.morbidity + " and diseasetested ilike '%" + layer.params.pathogen + "%');";
        resultQueryPile += tempQuery;
      }
      $("#post-map-subtitle").text(subText);
      $("#post-map-subtitle").addClass("bg-success");
      args = "action=fetch&sql_query=" + (post64(resultQueryPile));
      $.post(uri.urlString + "api.php", args, "json").done(function(result) {
        var error2;
        console.info("Detailed results: ", result);
        try {
          results = Object.toArray(result.parsed_responses);
          getSampleSummaryDialog(results, projectTableMap);
        } catch (error2) {
          console.warn("Couldn't parse responses from server");
        }
        return false;
      }).fail(function(result, status) {
        return console.error("Couldn't fetch detailed results");
      });
      (ensureCenter = function(count, maxCount, timeout) {

        /*
         * Make sure the center is right
         */
        var center, lat, lng, pctOffLat, pctOffLng, rndLat, rndLng, waited;
        rndLat = roundNumber(mapCenter.lat, 3);
        rndLng = roundNumber(mapCenter.lng, 3);
        try {
          lat = roundNumber(p$("#global-data-map").latitude, 3);
          lng = roundNumber(p$("#global-data-map").longitude, 3);
          center = {
            type: "google-map-element",
            lat: lat,
            lng: lng
          };
        } catch (undefined) {}
        try {
          center = geo.lMap.getCenter();
          lat = roundNumber(center.lat, 3);
          lng = roundNumber(center.lng, 3);
        } catch (undefined) {}
        pctOffLat = Math.abs((lat - rndLat) / rndLat) * 100;
        pctOffLng = Math.abs((lng - rndLng) / rndLng) * 100;
        if (pctOffLat < 2 && pctOffLng < 2 && count > 5) {
          console.info("Correctly centered", mapCenter, center, [pctOffLat, pctOffLng]);
          if (geo.lMap.getZoom() !== zoom) {
            console.warn("The map was centered before the zoom finished -- this may need to fire again");
          }
          clearTimeout(_adp.centerTimeout);
          return false;
        } else {
          if (!(count <= 15)) {
            console.warn("Centering too deviant", pctOffLat < 2, pctOffLng < 2, pctOffLat < 2 && pctOffLng < 2, lat, lng, rndLat, rndLng);
          }
        }
        if (!isNumber(maxCount)) {
          maxCount = 100;
        }
        if (count > maxCount) {
          waited = timeout * maxCount;
          console.info("Map could not be correctly centered in " + waited + "ms");
          clearTimeout(_adp.centerTimeout);
          return false;
        }
        ++count;
        return _adp.centerTimeout = delay(timeout, function() {
          var error2;
          if (!isNumber(maxCount)) {
            maxCount = 100;
          }
          try {
            p$("#global-data-map").latitude = mapCenter.lat;
            p$("#global-data-map").longitude = mapCenter.lng;
          } catch (undefined) {}
          try {
            console.log("#" + count + "/" + maxCount + " Deep setting view to", mapCenter.getObj(), [pctOffLat, pctOffLng]);
            geo.lMap.setView(mapCenter.getObj());
          } catch (error2) {
            e = error2;
            console.warn("Error setting view - " + e.message);
          }
          if (count < maxCount) {
            return ensureCenter(count);
          }
        });
      })(0, 100, 100);
    } catch (error2) {
      e = error2;
      console.error("Couldn't create map! " + e.message);
      console.warn(e.stack);
    }
    stopLoad();
  } catch (error3) {
    e = error3;
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
      console.log("Colors", data.creation, generateColorByRecency2(data.creation));
      if (!isNull(table)) {
        table = table.unescape();
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
  color = "#ff0000";
  return color;
};

generateColorByRecency2 = function(timestamp, oldCutoff) {
  var age, b, color, cv, g, hexArray, i, j, len, maxAge, r, stepCount, stepSize, temp;
  if (oldCutoff == null) {
    oldCutoff = 1420070400;
  }

  /*
   * Mix and match color channels based on age. Newest is fully red,
   * then green is added in and red removed till fully green, then blue
   * is added in and green removed until fully blue, then blue removed
   * until fully black.
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
    b = g > 255 ? toInt(g - 255) : 0;
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
  color = "#ff0000";
  return color;
};

getProjectResultDialog = function(projectList) {

  /*
   * From a list of projects, show a modal dialog with some basic
   * metadata for that list
   */
  var anuraIcon, caudataIcon, gymnophionaIcon, html, j, len, project, projectTableRows, row;
  if (!isArray(projectList)) {
    projectList = Object.toArray(projectList);
  }
  if (projectList.length === 0) {
    console.warn("There were no projects in the result list");
    return false;
  }
  projectTableRows = new Array();
  for (j = 0, len = projectList.length; j < len; j++) {
    project = projectList[j];
    anuraIcon = project.includes_anura ? "<iron-icon icon='icons:check-circle'></iron-icon>" : "<iron-icon icon='icons:clear'></iron-icon>";
    caudataIcon = project.includes_caudata ? "<iron-icon icon='icons:check-circle'></iron-icon>" : "<iron-icon icon='icons:clear'></iron-icon>";
    gymnophionaIcon = project.includes_gymnophiona ? "<iron-icon icon='icons:check-circle'></iron-icon>" : "<iron-icon icon='icons:clear'></iron-icon>";
    row = "<tr>\n  <td>" + project.project_title + "</td>\n  <td class=\"text-center\">" + anuraIcon + "</td>\n  <td class=\"text-center\">" + caudataIcon + "</td>\n  <td class=\"text-center\">" + gymnophionaIcon + "</td>\n  <td class=\"text-center\"><paper-icon-button data-toggle=\"tooltip\" title=\"Visit Project\" raised class=\"click\" data-href=\"https://amphibiandisease.org/project.php?id=" + project.project_id + "\" icon=\"icons:arrow-forward\"></paper-icon-button></td>\n</tr>";
    projectTableRows.push(row);
  }
  html = "<paper-dialog id=\"modal-project-list\" modal always-on-top auto-fit-on-attach>\n  <h2>Project Result List</h2>\n  <paper-dialog-scrollable>\n    <div>\n      <table class=\"table table-striped\">\n        <tr>\n          <th>Project Name</th>\n          <th>Caudata</th>\n          <th>Anura</th>\n          <th>Gymnophiona</th>\n          <th>Visit</th>\n        </tr>\n        " + (projectTableRows.join("\n")) + "\n      </table>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  $("#modal-project-list").remove();
  $("body").append(html);
  $("#modal-project-list").on("iron-overlay-closed", function() {
    $(".leaflet-control-attribution").removeAttr("hidden");
    return $(".leaflet-control").removeAttr("hidden");
  });
  $(".show-result-list").unbind().click(function() {
    console.log("Calling dialog helper");
    return safariDialogHelper("#modal-project-list", 0, function() {
      console.info("Successfully opened dialog");
      $(".leaflet-control-attribution").attr("hidden", "hidden");
      return $(".leaflet-control").attr("hidden", "hidden");
    });
  });
  bindClicks();
  console.info("Generated project result list");
  return false;
};

getSampleSummaryDialog = function(resultsList, tableToProjectMap) {

  /*
   * Show a SQL-query like dataset in a modal dialog
   *
   * TODO migrate this to a Web Worker
   * http://www.html5rocks.com/en/tutorials/workers/basics/
   *
   * See
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/146
   *
   * @param array resultList -> array of Carto responses. Data expected
   *   in "rows" field
   * @param object tableToProjectMap -> Map the table name onto project id
   */
  var altRows, col, data, dataWidthMax, dataWidthMin, el, elapsed, error, error1, html, i, j, k, l, len, len1, len2, n, outputData, project, projectResults, projectTableRows, ref, ref1, ref2, rlButton, row, rowSet, startRenderTime, table, unhelpfulCols;
  startRenderTime = Date.now();
  if (!isArray(resultsList)) {
    resultsList = Object.toArray(resultsList);
  }
  if (resultsList.length === 0) {
    console.warn("There were no results in the result list");
    return false;
  }
  console.log("Generating dialog from", resultsList);
  projectTableRows = new Array();
  outputData = new Array();
  i = 0;
  unhelpfulCols = ["cartodb_id", "the_geom", "the_geom_webmercator", "id"];
  for (j = 0, len = resultsList.length; j < len; j++) {
    projectResults = resultsList[j];
    ++i;
    dataWidthMax = $(window).width() * .5;
    dataWidthMin = $(window).width() * .3;
    try {
      rowSet = projectResults.rows;
      try {
        altRows = new Object();
        ref = projectResults.rows;
        for (n in ref) {
          row = ref[n];
          for (k = 0, len1 = unhelpfulCols.length; k < len1; k++) {
            col = unhelpfulCols[k];
            delete row[col];
          }
          altRows[n] = row;
          row.carto_table = projectResults.table;
          row.project_id = projectResults.project_id;
          outputData.push(row);
        }
        rowSet = altRows;
      } catch (error) {
        ref1 = projectResults.rows;
        for (n in ref1) {
          row = ref1[n];
          row.carto_table = projectResults.table;
          row.project_id = projectResults.project_id;
          outputData.push(row);
        }
      }
      data = JSON.stringify(rowSet);
      if (isNull(data)) {
        console.warn("Got bad data for row #" + i + "!", projectResults, projectResults.rows, data);
        continue;
      }
      data = "" + data;
    } catch (error1) {
      data = "Invalid data from server";
    }
    table = project = tableToProjectMap[projectResults.table];
    row = "<tr>\n  <td colspan=\"4\" class=\"code-box-container\"><pre readonly class=\"code-box language-json\" style=\"max-width:" + dataWidthMax + "px;min-width:" + dataWidthMin + "px\">" + data + "</pre></td>\n  <td class=\"text-center\"><paper-icon-button data-toggle=\"tooltip\" raised class=\"click\" data-href=\"https://amphibiandisease.org/project.php?id=" + project.id + "\" icon=\"icons:arrow-forward\" title=\"" + project.name + "\"></paper-icon-button></td>\n</tr>";
    projectTableRows.push(row);
  }
  html = "<paper-dialog id=\"modal-sql-details-list\" modal always-on-top auto-fit-on-attach>\n  <h2>Project Result List</h2>\n  <paper-dialog-scrollable>\n    <div class=\"row\">\n      <div class=\"col-xs-12\">\n        <table class=\"table table-striped\">\n          <tr>\n            <th colspan=\"4\">Query Data</th>\n            <th>Visit Project</th>\n          </tr>\n          " + (projectTableRows.join("\n")) + "\n        </table>\n      </div>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button id=\"generate-download\">Create Download</paper-button>\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  $("#modal-sql-details-list").remove();
  $("body").append(html);
  $("#generate-download").click(function() {
    return generateCSVFromResults(outputData, this);
  });
  ref2 = $(".code-box");
  for (l = 0, len2 = ref2.length; l < len2; l++) {
    el = ref2[l];
    try {
      Prism.highlightElement(el, true);
    } catch (undefined) {}
  }
  $("#modal-sql-details-list").on("iron-overlay-closed", function() {
    $(".leaflet-control-attribution").removeAttr("hidden");
    return $(".leaflet-control").removeAttr("hidden");
  });
  $(".show-result-list").remove();
  rlButton = "<paper-icon-button class=\"show-result-list\" icon=\"editor:insert-chart\" data-toggle=\"tooltip\" title=\"Show Sample Details\" raised></paper-icon-button>";
  $("#post-map-subtitle").append(rlButton);
  $(".show-result-list").unbind().click(function() {
    var startTime;
    animateLoad();
    startTime = Date.now();
    console.log("Calling dialog helper");
    return safariDialogHelper("#modal-sql-details-list", 0, function() {
      var checkIsVisible, elapsed, maxTime, timeout;
      elapsed = Date.now() - startTime;
      console.info("Successfully opened dialog in " + elapsed + "ms via safariDialogHelper");
      $(".leaflet-control-attribution").attr("hidden", "hidden");
      $(".leaflet-control").attr("hidden", "hidden");
      i = 0;
      timeout = 100;
      maxTime = 30000;
      return (checkIsVisible = function() {
        return delay(timeout, function() {
          var appxTime;
          ++i;
          if ((i * timeout) < maxTime && !$("#modal-sql-details-list").isVisible()) {
            return checkIsVisible();
          } else {
            stopLoad();
            appxTime = (timeout * i) - (timeout / 2) + elapsed;
            if (appxTime > 500) {
              return console.warn("It took about " + appxTime + "ms to render the dialog visible!");
            } else {
              return console.info("Dialog ready in about " + appxTime + "ms");
            }
          }
        });
      })();
    });
  });
  bindClicks();
  elapsed = Date.now() - startRenderTime;
  console.info("Generated project result list in " + elapsed + "ms");
  return false;
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
  initProjectSearch = function(clickedElement, forceDeep) {
    var deep, error, error1, ok, search;
    if (forceDeep == null) {
      forceDeep = false;
    }
    ok = checkCoordinateSanity();
    if (!ok) {
      toastStatusMessage("Please check your coordinates");
      return false;
    }
    search = getSearchObject();
    try {
      try {
        deep = $(clickedElement).attr("data-deep").toBool();
      } catch (error) {
        deep = false;
      }
      if (forceDeep) {
        deep = true;
      }
      if (deep) {
        search = getSearchContainsObject();
      }
    } catch (error1) {
      deep = false;
    }
    doSearch(search, deep);
    return false;
  };
  $("input.submit-project-search").keyup(function(e) {
    var kc;
    kc = e.keyCode ? e.keyCode : e.which;
    if (kc === 13) {
      return initProjectSearch(null, true);
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
