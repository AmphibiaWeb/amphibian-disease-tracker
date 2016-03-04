
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
    var adminButton, args, dest;
    if (projectId == null) {
      if (result.status) {
        console.info("Logged in user, no project");
        adminButton = "<paper-icon-button icon=\"icons:dashboard\" class=\"authorized-action\" id=\"show-actions\" data-href=\"" + uri.urlString + "admin-page.html\" data-toggle=\"tooltip\" title=\"Administration Dashboard\"> </paper-icon-button>";
      } else {
        console.info("Not logged in");
      }
      stopLoad();
      return false;
    }
    if (!result.status) {
      console.info("Non logged-in user or unauthorized user");
      renderPublicMap();
      stopLoad();
      return false;
    } else {
      dest = uri.urlString + "admin-api.php";
      args = "perform=check_access&project=" + projectId;
      return $.post(dest, args, "json").done(function(result) {
        var project;
        if (result.status) {
          console.info("User is authorized");
          project = result.detail.project;
          if (typeof callback === "function") {
            return callback(project, result.detailed_authorization);
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
  dest = uri.urlString + "api.php";
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
  html = "<div class=\"row\">\n  <paper-input readonly class=\"col-xs-8 col-md-11\" label=\"Contact Email\" value=\"" + email + "\"></paper-input>\n  <paper-fab icon=\"communication:email\" class=\"click materialblue\" id=\"contact-email-send\" data-href=\"mailto:" + email + "\" data-toggle=\"tooltip\" title=\"Send Email\"></paper-fab>\n</div>";
  $("#email-fill").replaceWith(html);
  bindClicks("#contact-email-send");
  return false;
};

renderMapWithData = function(projectData, force) {
  var apiPostSqlQuery, args, cartoData, cartoQuery, cartoTable, downloadButton, error1, j, len, mapHtml, point, poly, raw, ref, usedPoints, zoom;
  if (force == null) {
    force = false;
  }
  if (_adp.mapRendered === true && force !== true) {
    console.warn("The map was asked to be rendered again, but it has already been rendered!");
    return false;
  }
  cartoData = JSON.parse(deEscape(projectData.carto_id));
  raw = cartoData.raw_data;
  if (raw.hasDataFile) {
    downloadButton = "<button class=\"btn btn-primary click\" data-href=\"" + raw.filePath + "\" data-newtab=\"true\">\n  <iron-icon icon=\"editor:insert-chart\"></iron-icon>\n  Download Data File\n</button>";
  }
  if (downloadButton == null) {
    downloadButton = "";
  }
  cartoTable = cartoData.table;
  try {
    zoom = getMapZoom(cartoData.bounding_polygon.paths, "#transect-viewport");
    console.info("Got zoom", zoom);
  } catch (error1) {
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
    var collectionRangePretty, d, d1, d2, error, geoJson, googleMap, i, k, l, lat, len1, len2, lng, m, mapData, marker, month, monthPretty, months, note, options, ref1, row, rows, taxa, year, yearPretty, years;
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
    mapData = "<div class=\"row\">\n  <h2 class=\"col-xs-12\">Mapping Data</h2>\n  " + googleMap + "\n  <div class=\"col-xs-12 col-md-3 col-lg-6\">\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken from " + collectionRangePretty + "</p>\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken in " + monthPretty + "</p>\n    <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were sampled in " + yearPretty + "</p>\n    <p class=\"text-muted\"><iron-icon icon=\"icons:language\"></iron-icon> The effective project center is at (" + (roundNumberSigfig(projectData.lat, 6)) + ", " + (roundNumberSigfig(projectData.lng, 6)) + ") with a sample radius of " + projectData.radius + "m and a resulting locality <strong class='locality'>" + projectData.locality + "</strong></p>\n    <p class=\"text-muted\"><iron-icon icon=\"editor:insert-chart\"></iron-icon> The dataset contains " + projectData.disease_positive + " positive samples (" + (roundNumber(projectData.disease_positive * 100 / projectData.disease_samples)) + "%), " + projectData.disease_negative + " negative samples (" + (roundNumber(projectData.disease_negative * 100 / projectData.disease_samples)) + "%), and " + projectData.disease_no_confidence + " inconclusive samples (" + (roundNumber(projectData.disease_no_confidence * 100 / projectData.disease_samples)) + "%)</p>\n    <div class=\"download-buttons\" id=\"data-download-buttons\">\n      " + downloadButton + "\n    </div>\n  </div>\n</div>";
    if (_adp.mapRendered !== true) {
      $("#auth-block").append(mapData);
      setupMapMarkerToggles();
      _adp.mapRendered = true;
      if (!isNull(_adp.pageSpeciesList)) {
        console.log("Creating CSV downloader for species list");
        d = new Date();
        options = {
          create: true,
          downloadFile: "species-list-" + projectData.project_id + "-" + (d.toISOString()) + ".csv",
          selector: ".download-buttons",
          buttonText: "Download Species List",
          splitValues: " "
        };
        downloadCSVFile(_adp.pageSpeciesList, options);
      }
    }
    return stopLoad();
  }).error(function(result, status) {
    console.error(result, status);
    return stopLoadError("Couldn't render map");
  });
  return false;
};

postAuthorizeRender = function(projectData, authorizationDetails) {

  /*
   * Takes in project data, then renders the appropriate bits
   */
  var adminButton, authorData, cartoData, editButton;
  if (projectData["public"]) {
    console.info("Project is already public, not rerendering");
    false;
  }
  startLoad();
  console.info("Should render stuff", projectData);
  editButton = adminButton = "";
  if (authorizationDetails.can_edit) {
    editButton = "<paper-icon-button icon=\"icons:create\" class=\"authorized-action\" data-href=\"" + uri.urlString + "admin-page.html?id=" + projectData.project_id + "\" data-toggle=\"tooltip\" title=\"Edit Project\"></paper-icon-button>";
  }
  adminButton = "<paper-icon-button icon=\"icons:dashboard\" class=\"authorized-action\" id=\"show-actions\" data-href=\"" + uri.urlString + "admin-page.html\" data-toggle=\"tooltip\" title=\"Administration Dashboard\"> </paper-icon-button>";
  $("#title").append(editButton);
  authorData = JSON.parse(projectData.author_data);
  showEmailField(authorData.contact_email);
  bindClicks(".authorized-action");
  cartoData = JSON.parse(deEscape(projectData.carto_id));
  renderMapWithData(projectData);
  return false;
};

copyLink = function(zeroClipObj, zeroClipEvent, html5) {
  var ark, clip, clipboardData, e, error1, url;
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
      toastStatusMessage("ARK resolver path copied to clipboard");
      return false;
    } catch (error1) {
      e = error1;
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
        _adp.zcClient = new ZeroClipboard($("#copy-ark").get(0));
      }
      if (e.name === "flash-disabled") {
        console.info("No flash on this system");
        ZeroClipboard.destroy();
        $("#copy-ark").tooltip("destroy").remove();
        $(".ark-identifier").removeClass("col-xs-9 col-md-11").addClass("col-xs-12");
        return toastStatusMessage("Clipboard copying isn't available on your system");
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
        button = "<button class=\"btn btn-primary search-proj-link\" data-href=\"" + uri.urlString + "project.php?id=" + project.project_id + "\" data-toggle=\"tooltip\" data-placement=\"right\" title=\"Project #" + (project.project_id.slice(0, 8)) + "...\">\n  " + icon + " " + project.project_title + "\n</button>";
        html += "<li class='project-search-result'>" + button + "</li>";
      }
    } else {
      s = (ref = result.search) != null ? ref : search;
      html = "<p><em>No results found for \"<strong>" + s + "</strong>\"";
    }
    $("#project-result-container").html(html);
    return bindClicks(".search-proj-link");
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
  var cartoData, e, error1, error2, error3, googleMap, j, len, mapHtml, ne, nw, paths, point, poly, se, sw, usedPoints, zoom;
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
  } catch (error1) {
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
    } catch (error2) {
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
    googleMap = "<div class=\"row\" id=\"public-map\">\n  <h2 class=\"col-xs-12\">Approximate Mapping Data</h2>\n  <google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map\"  apiKey=\"" + gMapsApiKey + "\">\n        " + mapHtml + "\n  </google-map>\n</div>";
    return $("#auth-block").append(googleMap);
  } catch (error3) {
    e = error3;
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
  $("#copy-ark").click(function() {
    return copyLink(_adp.zcClient);
  });
  checkFileVersion(true, "js/project.js");
  return $("#toggle-project-viewport").click(function() {
    $(".project-list-page").toggleClass("hidden-xs");
    if ($(".project-search").hasClass("hidden-xs")) {
      return $(this).text("Show Project Search");
    } else {
      return $(this).text("Show Project List");
    }
  });
});

//# sourceMappingURL=maps/project.js.map
