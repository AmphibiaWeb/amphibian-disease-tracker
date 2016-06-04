
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
    var boundingBox, e, error, error1, i, j, layer, layers, len, len1, mapCenter, posSamples, project, results, spArr, species, speciesCount, table, totalSamples, totalSpecies, zoom;
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
    try {
      boundingBox = [[search.bounding_box_n.data, search.bounding_box_w.data], [search.bounding_box_n.data, search.bounding_box_e.data], [search.bounding_box_s.data, search.bounding_box_e.data], [search.bounding_box_s.data, search.bounding_box_w.data]];
      mapCenter = getMapCenter(boundingBox);
      p$("#global-data-map").latitude = mapCenter.lat;
      p$("#global-data-map").longitude = mapCenter.lng;
      zoom = getMapZoom(boundingBox, "#global-data-map");
    } catch (error) {
      e = error;
      console.warn("Failed to rezoom/recenter map - " + e.message);
      console.warn(e.stack);
    }
    if (goDeep) {
      doDeepSearch(results);
      return false;
    }
    totalSamples = 0;
    posSamples = 0;
    totalSpecies = new Array();
    layers = new Array();
    for (i = 0, len = results.length; i < len; i++) {
      project = results[i];
      totalSamples += project.disease_samples;
      posSamples += project.disease_positive;
      spArr = project.sampled_species.split(",");
      for (j = 0, len1 = spArr.length; j < len1; j++) {
        species = spArr[j];
        species = species.trim();
        if (indexOf.call(totalSpecies, species) < 0) {
          totalSpecies.push(species);
        }
      }
      table = project.carto_id.table;
      if (!isNull(table)) {
        layer = {
          sql: "SELECT * FROM " + table
        };
        layers.push(layer);
      }
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
