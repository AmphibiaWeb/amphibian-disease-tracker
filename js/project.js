
/*
 * Project-specific code
 */
var checkProjectAuthorization, copyLink, postAuthorizeRender, publicData, renderEmail, renderMapWithData, renderPublicMap, searchProjects, setPublicData, showEmailField,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_adp.mapRendered = false;

_adp.zcClient = null;

publicData = null;

checkProjectAuthorization = function(projectId, callback) {
  if (projectId == null) {
    projectId = _adp.projectId;
  }
  if (callback == null) {
    callback = postAuthorizeRender;
  }
  startLoad();
  console.info("Checking authorization for " + projectId);
  checkLoggedIn(function(result) {
    var args, dest;
    if (!result.status) {
      console.info("Non logged-in user or unauthorized user");
      renderPublicMap();
      stopLoad();
      return false;
    } else {
      dest = uri.urlString + "/admin-api.php";
      args = "perform=check_access&project=" + projectId;
      return $.post(dest, args, "json").done(function(result) {
        var project;
        if (result.status) {
          console.info("User is authorized");
          project = result.detail.project;
          if (typeof callback === "function") {
            return callback(project);
          } else {
            console.warn("No callback specified!");
            return console.info("Got project data", project);
          }
        } else {
          return console.info("User is unauthorized");
        }
      }).error(function(result, status) {
        return console.log("Error checking server", result, status);
      }).always(function() {
        return stopLoad();
      });
    }
  });
  return false;
};

renderEmail = function(response) {
  var args, dest;
  stopLoad();
  dest = uri.urlString + "/api.php";
  args = "action=is_human&recaptcha_response=" + response + "&project=" + _adp.projectId;
  $.post(dest, args, "json").done(function(result) {
    var authorData;
    console.info("Checked response");
    console.log(result);
    authorData = result.author_data;
    showEmailField(authorData.contact_email);
    return stopLoad();
  }).error(function(result, status) {
    stopLoadError("Sorry, there was a problem getting the contact email");
    return false;
  });
  return false;
};

showEmailField = function(email) {
  var html;
  html = "<div class=\"row\">\n  <paper-input readonly class=\"col-xs-8 col-md-11\" label=\"Contact Email\" value=\"" + email + "\"></paper-input>\n  <div class=\"col-xs-4 col-md-1\">\n    <paper-fab icon=\"communication:email\" class=\"click materialblue\" id=\"contact-email-send\" data-href=\"mailto:" + email + "\" data-toggle=\"tooltip\" title=\"Send Email\"></paper-fab>\n  </div>\n</div>";
  $("#email-fill").replaceWith(html);
  bindClicks("#contact-email-send");
  return false;
};

renderMapWithData = function(projectData, force) {
  var apiPostSqlQuery, args, cartoData, cartoQuery, cartoTable, j, len, mapHtml, point, poly, ref, usedPoints, zoom;
  if (force == null) {
    force = false;
  }
  if (_adp.mapRendered === true && force !== true) {
    console.warn("The map was asked to be rendered again, but it has already been rendered!");
    return false;
  }
  cartoData = JSON.parse(deEscape(projectData.carto_id));
  cartoTable = cartoData.table;
  try {
    zoom = getMapZoom(cartoData.bounding_polygon.paths, "#transect-viewport");
    console.info("Got zoom", zoom);
  } catch (_error) {
    zoom = "";
  }
  poly = cartoData.bounding_polygon;
  mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
  usedPoints = new Array();
  ref = poly.paths;
  for (j = 0, len = ref.length; j < len; j++) {
    point = ref[j];
    if (indexOf.call(usedPoints, point) < 0) {
      usedPoints.push(point);
      mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
    }
  }
  mapHtml += "    </google-map-poly>";
  cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM " + cartoTable + ";";
  console.info("Would ping cartodb with", cartoQuery);
  apiPostSqlQuery = encodeURIComponent(encode64(cartoQuery));
  args = "action=fetch&sql_query=" + apiPostSqlQuery;
  $.post("api.php", args, "json").done(function(result) {
    var collectionRangePretty, d1, d2, error, geoJson, googleMap, i, k, l, lat, len1, len2, lng, m, mapData, marker, month, monthPretty, months, note, ref1, row, rows, taxa, year, yearPretty, years;
    if (_adp.mapRendered === true) {
      console.warn("Duplicate map render! Skipping thread");
      return false;
    }
    console.info("Carto query got result:", result);
    if (!result.status) {
      error = (ref1 = result.human_error) != null ? ref1 : result.error;
      if (error == null) {
        error = "Unknown error";
      }
      stopLoadError("Sorry, we couldn't retrieve your information at the moment (" + error + ")");
      return false;
    }
    rows = result.parsed_responses[0].rows;
    for (k in rows) {
      row = rows[k];
      geoJson = JSON.parse(row.st_asgeojson);
      lat = geoJson.coordinates[0];
      lng = geoJson.coordinates[1];
      row.diseasedetected = (function() {
        switch (row.diseasedetected.toString().toLowerCase()) {
          case "true":
            return "positive";
          case "false":
            return "negative";
          default:
            return row.diseasedetected.toString();
        }
      })();
      taxa = row.genus + " " + row.specificepithet;
      note = "";
      if (taxa !== row.originaltaxa) {
        note = "(<em>" + row.originaltaxa + "</em>)";
      }
      marker = "<google-map-marker latitude=\"" + lat + "\" longitude=\"" + lng + "\" data-disease-detected=\"" + row.diseasedetected + "\">\n  <p>\n    <em>" + row.genus + " " + row.specificepithet + "</em> " + note + "\n    <br/>\n    Tested <strong>" + row.diseasedetected + "</strong> for " + row.diseasetested + "\n  </p>\n</google-map-marker>";
      mapHtml += marker;
    }
    googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6\">\n  " + mapHtml + "\n</google-map>";
    monthPretty = "";
    months = projectData.sampling_months.split(",");
    i = 0;
    for (l = 0, len1 = months.length; l < len1; l++) {
      month = months[l];
      ++i;
      if (i > 1 && i === months.length) {
        if (months.length > 2) {
          monthPretty += ",";
        }
        monthPretty += " and ";
      } else if (i > 1) {
        monthPretty += ", ";
      }
      if (isNumber(month)) {
        month = dateMonthToString(month);
      }
      monthPretty += month;
    }
    i = 0;
    yearPretty = "";
    years = projectData.sampling_years.split(",");
    i = 0;
    for (m = 0, len2 = years.length; m < len2; m++) {
      year = years[m];
      ++i;
      if (i > 1 && i === years.length) {
        if (years.length > 2) {
          yearPretty += ",";
        }
        yearPretty += " and ";
      } else if (i > 1) {
        yearPretty += ", ";
      }
      yearPretty += year;
    }
    if (years.length === 1) {
      yearPretty = "the year " + yearPretty;
    } else {
      yearPretty = "the years " + yearPretty;
    }
    d1 = new Date(toInt(projectData.sampled_collection_start));
    d2 = new Date(toInt(projectData.sampled_collection_end));
    collectionRangePretty = (dateMonthToString(d1.getMonth())) + " " + (d1.getFullYear()) + " &#8212; " + (dateMonthToString(d2.getMonth())) + " " + (d2.getFullYear());
    mapData = "<div class=\"row\">\n  " + googleMap + "\n  <div class=\"col-xs-12 col-md-3 col-lg-6\">\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken from " + collectionRangePretty + "</p>\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken in " + monthPretty + "</p>\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were sampled in " + yearPretty + "</p>\n    <p class=\"text-muted\"><iron-icon icon=\"icons:language\"></iron-icon> The effective project center is at (" + (roundNumberSigfig(projectData.lat, 6)) + ", " + (roundNumberSigfig(projectData.lng, 6)) + ") with a sample radius of " + projectData.radius + "m and a resulting locality <strong class='locality'>" + projectData.locality + "</strong></p>\n    <p class=\"text-muted\"><iron-icon icon=\"editor:insert-chart\"></iron-icon> The dataset contains " + projectData.disease_positive + " positive samples (" + (roundNumber(projectData.disease_positive * 100 / projectData.disease_samples)) + "%), " + projectData.disease_negative + " negative samples (" + (roundNumber(projectData.disease_negative * 100 / projectData.disease_samples)) + "%), and " + projectData.disease_no_confidence + " inconclusive samples (" + (roundNumber(projectData.disease_no_confidence * 100 / projectData.disease_samples)) + "%)</p>\n  </div>\n</div>";
    if (_adp.mapRendered !== true) {
      $("#auth-block").append(mapData);
      setupMapMarkerToggles();
      _adp.mapRendered = true;
    }
    return stopLoad();
  }).error(function(result, status) {
    console.error(result, status);
    return stopLoadError("Couldn't render map");
  });
  return false;
};

postAuthorizeRender = function(projectData) {

  /*
   * Takes in project data, then renders the appropriate bits
   */
  var authorData, cartoData, editButton;
  if (projectData["public"]) {
    console.info("Project is already public, not rerendering");
    false;
  }
  startLoad();
  console.info("Should render stuff", projectData);
  editButton = "<paper-icon-button icon=\"icons:create\" class=\"authorized-action\" data-href=\"admin-page.html?id=" + projectData.project_id + "\"></paper-icon-button>";
  $("#title").append(editButton);
  authorData = JSON.parse(projectData.author_data);
  showEmailField(authorData.contact_email);
  $(".needs-auth").html("<p>User is authorized, should repopulate</p>");
  bindClicks(".authorized-action");
  cartoData = JSON.parse(deEscape(projectData.carto_id));
  renderMapWithData(projectData);
  return false;
};

copyLink = function(zeroClipObj, zeroClipEvent, html5) {
  var ark, clip, clipboardData, e, url;
  if (zeroClipObj == null) {
    zeroClipObj = _adp.zcClient;
  }
  if (html5 == null) {
    html5 = true;
  }
  ark = p$(".ark-identifier").value;
  if (html5) {
    try {
      url = "https://n2t.net/" + ark;
      clipboardData = {
        dataType: "text/plain",
        data: url,
        "text/plain": url
      };
      clip = new ClipboardEvent("copy", clipboardData);
      document.dispatchEvent(clip);
      return false;
    } catch (_error) {
      e = _error;
      console.error("Error creating copy: " + e.message);
      console.warn(e.stack);
    }
  }
  console.warn("Can't use HTML5");
  if (zeroClipObj != null) {
    zeroClipObj.setData(clipboardData);
    if (zeroClipEvent != null) {
      zeroClipEvent.setData(clipboardData);
    }
    zeroClipObj.on("aftercopy", function(e) {
      if (e.data["text/plain"]) {
        return toastStatusMessage("ARK resolver path copied to clipboard");
      } else {
        return toastStatusMessage("Error copying to clipboard");
      }
    });
    zeroClipObj.on("error", function(e) {
      console.error("Error copying to clipboard");
      console.warn("Got", e);
      if (e.name === "flash-overdue") {
        if (_adp.resetClipboard === true) {
          console.error("Resetting ZeroClipboard didn't work!");
          return false;
        }
        ZeroClipboard.on("ready", function() {
          _adp.resetClipboard = true;
          return copyLink();
        });
        return _adp.zcClient = new ZeroClipboard($("#copy-ark").get(0));
      }
    });
  } else {
    console.error("Can't use HTML, and ZeroClipboard wasn't passed");
  }
  return false;
};

searchProjects = function() {

  /*
   * Handler to search projects
   */
  var args, cols, item, search;
  search = $("#project-search").val();
  if (isNull(search)) {
    return false;
  }
  item = p$("#search-filter").selectedItem;
  cols = $(item).attr("data-cols");
  console.info("Searching on " + search + " ... in " + cols);
  args = "action=search_project&q=" + search + "&cols=" + cols;
  $.post(uri.urlString + "api.php", args, "json").done(function(result) {
    var button, html, icon, j, len, project, projects, publicState, ref, s;
    console.info(result);
    html = "";
    projects = Object.toArray(result.result);
    if (projects.length > 0) {
      for (j = 0, len = projects.length; j < len; j++) {
        project = projects[j];
        publicState = project["public"].toBool();
        icon = publicState ? "<iron-icon icon=\"social:public\"></iron-icon>" : "<iron-icon icon=\"icons:lock\"></iron-icon>";
        button = "<button class=\"btn btn-primary search-proj-link\" data-href=\"" + uri.urlString + "/project.php?id=" + project.project_id + "\" data-toggle=\"tooltip\" title=\"Project #" + (project.project_id.slice(0, 8)) + "...\">\n  " + icon + " " + project.project_title + "\n</button>";
        html += "<li class='project-search-result'>" + button + "</li>";
      }
      bindClicks(".search-proj-link");
    } else {
      s = (ref = result.search) != null ? ref : search;
      html = "<p><em>No results found for \"<strong>" + s + "</strong>\"";
    }
    return $("#project-result-container").html(html);
  }).error(function(result, status) {
    return console.error(result, status);
  });
  return false;
};

setPublicData = function(projectData) {
  publicData = projectData;
  return false;
};

renderPublicMap = function(projectData) {
  var cartoData, e, googleMap, j, len, mapHtml, ne, nw, paths, point, poly, se, sw, usedPoints, zoom;
  if (projectData == null) {
    projectData = publicData;
  }

  /*
   *
   */
  try {
    if (projectData["public"].toBool()) {
      console.info("Not rendering low-data public map for public project");
      return false;
    }
  } catch (_error) {
    console.error("Invalid project data passed!");
    console.warn(projectData);
    return false;
  }
  try {
    console.info("Working with limited data", projectData);
    cartoData = projectData.carto_id;
    poly = cartoData.bounding_polygon;
    mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
    usedPoints = new Array();
    nw = {
      lat: projectData.bounding_box_n,
      lng: projectData.bounding_box_w
    };
    ne = {
      lat: projectData.bounding_box_n,
      lng: projectData.bounding_box_e
    };
    se = {
      lat: projectData.bounding_box_s,
      lng: projectData.bounding_box_e
    };
    sw = {
      lat: projectData.bounding_box_s,
      lng: projectData.bounding_box_w
    };
    paths = [nw, ne, se, sw];
    try {
      zoom = getMapZoom(paths, "#transect-viewport");
      console.info("Got zoom", zoom);
    } catch (_error) {
      zoom = "";
    }
    for (j = 0, len = paths.length; j < len; j++) {
      point = paths[j];
      if (indexOf.call(usedPoints, point) < 0) {
        usedPoints.push(point);
        mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
      }
    }
    mapHtml += "    </google-map-poly>";
    googleMap = "<div class=\"row\" id=\"public-map\">\n  <h2 class=\"col-xs-12\">Approximate Mapping Data</h2>\n  <google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map\">\n        " + mapHtml + "\n  </google-map>\n</div>";
    return $("#auth-block").append(googleMap);
  } catch (_error) {
    e = _error;
    stopLoadError("Couldn't render map");
    console.error("Map rendering error - " + e.message);
    return console.warn(e.stack);
  }
};

$(function() {
  var zcConfig;
  _adp.projectId = uri.o.param("id");
  checkProjectAuthorization();
  $("#project-list button").unbind().click(function() {
    var project;
    project = $(this).attr("data-project");
    return goTo(uri.urlString + "project.php?id=" + project);
  });
  $("#project-search").unbind().keyup(function() {
    return searchProjects.debounce();
  });
  $("paper-radio-button").click(function() {
    var cue;
    cue = $(this).attr("data-cue");
    $("#project-search").attr("placeholder", cue);
    return searchProjects.debounce();
  });
  zcConfig = {
    swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
  };
  ZeroClipboard.config(zcConfig);
  _adp.zcClient = new ZeroClipboard($("#copy-ark").get(0));
  return $("#copy-ark").click(function() {
    return copyLink(_adp.zcClient);
  });
});

//# sourceMappingURL=maps/project.js.map
