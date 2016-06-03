
/*
 *
 */
var checkCoordinateSanity, doSearch, getSearchObject;

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
    return false;
  }
  $(".coord-input").parent().removeClass("has-error");
  return false;
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

doSearch = function(search) {
  var args, data;
  if (search == null) {
    search = getSearchObject();
  }

  /*
   *
   */
  data = jsonTo64(search);
  args = "action=advanced_project_search&q=" + data;
  $.post(uri.urlString + "api.php", args, "json").done(function(result) {
    console.info("Adv. search result", result);
    stopLoad();
    return false;
  }).fail(function(result, status) {
    console.error(result, status);
    return stopLoadError("Server error, couldn't perform search");
  });
  return false;
};

$(function() {
  return $(".coord-input").keyup(function() {
    return checkCoordinateSanity();
  });
});

//# sourceMappingURL=maps/global-search.js.map
