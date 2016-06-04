
/*
 *
 */
var checkCoordinateSanity, doDeepSearch, doSearch, getSearchObject,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

checkCoordinateSanity = function() {
  var bounds, isGood;
  isGood = true;
  bounds = {
    n: $("#north-coordinate").val(),
    w: $("#west-coordinate").val(),
    s: $("#south-coordinate").val(),
    e: $("#east-coordinate").val()
  };
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
    var boundingBox, boundingBoxArray, cartoParsed, cartoPreParsed, cleanKey, e, error, error1, i, j, k, key, layer, layers, len, len1, mapCenter, posSamples, project, ref, results, spArr, species, speciesCount, table, totalSamples, totalSpecies, val, zoom;
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
      n: 0,
      s: 0,
      e: 0,
      w: 0
    };
    i = 0;
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
            cartoParsed[cleanKey] = val.replace("&#95;", "_");
          }
          project.carto_id = cartoParsed;
        } catch (undefined) {}
      }
      table = project.carto_id.table;
      if (!isNull(table)) {
        layer = {
          sql: "SELECT * FROM " + table,
          cartocss: '##{table} {marker-fill: #F0F0F0;}'
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
      p$("#global-data-map").latitude = mapCenter.lat;
      p$("#global-data-map").longitude = mapCenter.lng;
      zoom = getMapZoom(boundingBoxArray, "#global-data-map");
    } catch (error) {
      e = error;
      console.warn("Failed to rezoom/recenter map - " + e.message);
      console.warn(e.stack);
    }
    if (goDeep) {
      doDeepSearch(results);
      return false;
    }
    speciesCount = totalSpecies.length;
    console.info("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species");
    $("#post-map-subtitle").text("Viewing projects containing " + totalSamples + " samples (" + posSamples + " positive) among " + speciesCount + " species");
    try {
      createRawCartoMap(layers);
    } catch (error1) {
      e = error1;
      console.error("Couldn't create map! " + e.message);
      console.warn(e.stack);
    }
    stopLoad();
    return false;
  }).fail(function(result, status) {
    console.error(result, status);
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

$(function() {
  geo.initLocation();
  $(".coord-input").keyup(function() {
    return checkCoordinateSanity();
  });
  return $(".do-search").click(function() {
    var deep, ok;
    ok = checkCoordinateSanity();
    if (!ok) {
      toastStatusMessage("Please check your coordinates");
      return false;
    }
    deep = $(this).attr("data-deep").toBool();
    doSearch(getSearchObject(), deep);
    return false;
  });
});

//# sourceMappingURL=maps/global-search.js.map
