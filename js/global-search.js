
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
    $("#do-global-search").attr("disabled", "disabled");
    return false;
  }
  $(".coord-input").parent().removeClass("has-error");
  $("#do-global-search").removeAttr("disabled");
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
  args = "action=advanced_project_search&q=" + data;
  $.post(uri.urlString + "admin-api.php", args, "json").done(function(result) {
    var i, j, len, len1, posSamples, project, results, spArr, species, speciesCount, totalSamples, totalSpecies;
    console.info("Adv. search result", result);
    results = result.result;
    if (goDeep) {
      doDeepSearch(results);
      return false;
    }
    totalSamples = 0;
    posSamples = 0;
    totalSpecies = new Array();
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
    }
    speciesCount = totalSpecies.length;
    console.info("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species");
    toastStatusMessage("Projects containing your search returned " + totalSamples + " (" + posSamples + " positive) among " + speciesCount + " species");
    foo();
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
  return $("#do-global-search").click(function() {
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
