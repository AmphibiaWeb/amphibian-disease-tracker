
/*
 * Project-specific code
 */
var checkArkDataset, checkProjectAuthorization, copyLink, postAuthorizeRender, publicData, renderEmail, renderMapWithData, renderPublicMap, searchProjects, setPublicData, showEmailField,
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
  var apiPostSqlQuery, args, ark, arkId, arkIdentifiers, baseFilePath, cartoData, cartoQuery, cartoTable, data, downloadButton, error1, extraClasses, filePath, helperDir, html, i, j, l, len, len1, mapHtml, paths, point, poly, raw, ref, title, tmp, usedPoints, zoom;
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
    helperDir = "helpers/";
    filePath = raw.filePath;
    if (filePath.search(helperDir) === -1) {
      filePath = "" + helperDir + filePath;
    }
    downloadButton = "";
    arkIdentifiers = projectData.dataset_arks.split(",");
    if (arkIdentifiers.length > 0) {
      baseFilePath = filePath.split("/");
      baseFilePath.pop();
      baseFilePath = baseFilePath.join("/");
      i = 0;
      for (j = 0, len = arkIdentifiers.length; j < len; j++) {
        ark = arkIdentifiers[j];
        data = ark.split("::");
        arkId = data[0];
        filePath = baseFilePath + "/" + data[1];
        extraClasses = i === 0 ? "" : "btn-xs download-alt-datafile";
        title = i === 0 ? "Download Newest Datafile" : arkId + " dataset";
        html = "<button class=\"btn btn-primary click download-file download-data-file " + extraClasses + "\" data-href=\"" + filePath + "\" data-newtab=\"true\" data-toggle=\"tooltip\" title=\"" + arkId + " (right-click to copy)\" data-ark=\"" + arkId + "\">\n  <iron-icon icon=\"editor:insert-chart\"></iron-icon>\n  " + title + "\n</button>";
        downloadButton += html;
        ++i;
      }
    }
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
  if (isArray(poly) || ((poly != null ? poly.paths : void 0) == null)) {
    paths = poly;
    tmp = toObject(poly);
    if (typeof tmp !== "object") {
      tmp = new Object();
    }
    tmp.paths = poly;
    if (!isArray(tmp.paths)) {
      tmp.paths = new Array();
    }
    poly = tmp;
  }
  if (poly.fillColor == null) {
    poly.fillColor = defaultFillColor;
  }
  if (poly.fillOpacity == null) {
    poly.fillOpacity = defaultFillOpacity;
  }
  mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
  usedPoints = new Array();
  ref = poly.paths;
  for (l = 0, len1 = ref.length; l < len1; l++) {
    point = ref[l];
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
    var collectionRangePretty, d, d1, d2, error, geoJson, googleMap, k, lat, len2, len3, lng, m, mapData, marker, month, monthPretty, months, n, note, options, points, ref1, row, rows, taxa, year, yearPretty, years;
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
    points = new Array();
    for (k in rows) {
      row = rows[k];
      geoJson = JSON.parse(row.st_asgeojson);
      lat = geoJson.coordinates[0];
      lng = geoJson.coordinates[1];
      points.push([lat, lng]);
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
    if ((poly != null ? poly.paths : void 0) == null) {
      try {
        _adp.canonicalHull = createConvexHull(points, true);
      } catch (undefined) {}
    }
    googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6\">\n  " + mapHtml + "\n</google-map>";
    monthPretty = "";
    months = projectData.sampling_months.split(",");
    i = 0;
    for (m = 0, len2 = months.length; m < len2; m++) {
      month = months[m];
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
    for (n = 0, len3 = years.length; n < len3; n++) {
      year = years[n];
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
          splitValues: " ",
          header: ["Genus", "Species", "Subspecies"]
        };
        downloadCSVFile(_adp.pageSpeciesList, options);
      }
    }
    bindClicks(".download-file");
    $(".download-data-file").contextmenu(function(event) {
      var caller, clipboardData, copyFn, elPos, inFn, outFn, url, zcClientInitial;
      event.preventDefault();
      console.log("Event details", event);
      elPos = $(this).offset();
      html = "<paper-material class=\"ark-context-wrapper\" style=\"top:" + event.pageY + "px;left:" + event.pageX + "px;position:absolute\">\n  <paper-menu class=context-menu\">\n    <paper-item class=\"copy-ark-context\">\n      Copy ARK to clipboard\n    </paper-item>\n  </paper-menu>\n</paper-material>";
      $(".ark-context-wrapper").remove();
      $("body").append(html);
      ZeroClipboard.config(_adp.zcConfig);
      zcClientInitial = new ZeroClipboard($(".copy-ark-context").get(0));
      ark = $(this).attr("data-ark");
      url = "https://n2t.net/" + ark;
      clipboardData = {
        dataType: "text/plain",
        data: url,
        "text/plain": url
      };
      zcClientInitial.setData(clipboardData);
      zcClientInitial.on("aftercopy", function(e) {
        if (e.data["text/plain"]) {
          return toastStatusMessage("ARK resolver path copied to clipboard");
        } else {
          console.error("ZeroClipboard had an error - ", e);
          console.warn(clipboardData);
          return toastStatusMessage("Error copying to clipboard");
        }
      });
      zcClientInitial.on("error", function(e) {
        var zcClient;
        console.error("Initial error");
        zcClient = new ZeroClipboard($(".copy-ark-context").get(0));
        return copyFn(zcClient);
      });
      copyFn = function(zcClient, zcEvent) {
        var clip, e, error2;
        if (zcClient == null) {
          zcClient = zcClientInitial;
        }
        if (zcEvent == null) {
          zcEvent = null;
        }
        try {
          clip = new ClipboardEvent("copy", clipboardData);
          document.dispatchEvent(clip);
          toastStatusMessage("ARK resolver path copied to clipboard");
          return false;
        } catch (error2) {
          e = error2;
          console.error("Error creating copy: " + e.message);
          console.warn(e.stack);
          console.warn("Can't use HTML5");
        }
        zcClient.setData(clipboardData);
        if (!isNull(zcEvent)) {
          zcEvent.setData(clipboardData);
        }
        zcClient.on("aftercopy", function(e) {
          if (e.data["text/plain"]) {
            return toastStatusMessage("ARK resolver path copied to clipboard");
          } else {
            console.error("ZeroClipboard had an error - ", e);
            console.warn(clipboardData);
            return toastStatusMessage("Error copying to clipboard");
          }
        });
        return zcClient.on("error", function(e) {
          console.error("Error copying to clipboard");
          console.warn("Got", e);
          if (e.name === "flash-overdue") {
            if (_adp.resetClipboard === true) {
              console.error("Resetting ZeroClipboard didn't work!");
              return false;
            }
            ZeroClipboard.on("ready", function() {
              _adp.resetClipboard = true;
              zcClient = new ZeroClipboard($(".copy-ark-context").get(0));
              return copyFn(zcClient);
            });
          }
          if (e.name === "flash-disabled") {
            console.info("No flash on this system");
            ZeroClipboard.destroy();
            return toastStatusMessage("Clipboard copying isn't available on your system");
          }
        });
      };
      inFn = function(el) {
        $(this).addClass("iron-selected");
        return false;
      };
      outFn = function(el) {
        $(this).removeClass("iron-selected");
        return false;
      };
      caller = this;
      $(".ark-context-wrapper paper-item").hover(inFn, outFn).click(function() {
        _adp.resetClipboard = false;
        $(".ark-context-wrapper").remove();
        return false;
      }).contextmenu(function() {
        $(".ark-context-wrapper").remove();
        return false;
      });
      return false;
    });
    checkArkDataset(projectData);
    setPublicData(projectData);
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
    $("google-map-poly").removeAttr("hidden");
    return false;
  }
  item = p$("#search-filter").selectedItem;
  cols = $(item).attr("data-cols");
  console.info("Searching on " + search + " ... in " + cols);
  args = "action=search_project&q=" + search + "&cols=" + cols;
  $.post(uri.urlString + "api.php", args, "json").done(function(result) {
    var button, html, icon, j, l, len, len1, project, projectId, projects, publicState, ref, results, s, showList;
    console.info(result);
    html = "";
    showList = new Array();
    projects = Object.toArray(result.result);
    if (projects.length > 0) {
      for (j = 0, len = projects.length; j < len; j++) {
        project = projects[j];
        showList.push(project.project_id);
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
    bindClicks(".search-proj-link");
    $("google-map-poly").attr("hidden", "hidden");
    results = [];
    for (l = 0, len1 = showList.length; l < len1; l++) {
      projectId = showList[l];
      results.push($("google-map-poly[data-project='" + projectId + "']").removeAttr("hidden"));
    }
    return results;
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
  var cartoData, e, error, error1, error2, error3, error4, googleMap, j, len, mapHtml, ne, nw, paths, point, poly, se, sw, usedPoints, zoom;
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
    if (poly.fillColor == null) {
      poly.fillColor = "#ff7800";
    }
    if (poly.fillOpacity == null) {
      poly.fillOpacity = 0.35;
    }
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
    googleMap = "<div class=\"row\" id=\"public-map\">\n  <h2 class=\"col-xs-12\">Project Area of Interest</h2>\n  <google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" map-type=\"hybrid\" disable-default-ui zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map\"  apiKey=\"" + gMapsApiKey + "\">\n        " + mapHtml + "\n  </google-map>\n</div>";
    $("#auth-block").append(googleMap);
    try {
      zoom = getMapZoom(paths, "#transect-viewport");
      return p$("#transect-viewport").zoom = zoom;
    } catch (error3) {
      error = error3;
    }
  } catch (error4) {
    e = error4;
    stopLoadError("Couldn't render map");
    console.error("Map rendering error - " + e.message);
    return console.warn(e.stack);
  }
};

checkArkDataset = function(projectData, forceDownload, forceReparse) {
  var arg, ark, arkIdentifiers, canonical, data, dataId, dataset, fragList, fragment, j, l, len, len1, match, options, params, ref, selector, url;
  if (forceDownload == null) {
    forceDownload = false;
  }
  if (forceReparse == null) {
    forceReparse = false;
  }

  /*
   * See if the URL tag "#dataset:" exists. If so, take the user there
   * and "notice" it.
   *
   * @param projectData -> required so that an unauthorized user can't
   *  invoke this to get data.
   */
  if (typeof _adp === "undefined" || _adp === null) {
    window._adp = new Object();
  }
  fragment = uri.o.attr("fragment");
  fragList = fragment.split(",");
  if (forceReparse || (_adp.fragmentData == null)) {
    console.info("Examining fragment list");
    data = new Object();
    for (j = 0, len = fragList.length; j < len; j++) {
      arg = fragList[j];
      params = arg.split(":");
      data[params[0]] = params[1];
    }
    _adp.fragmentData = data;
  }
  dataset = (ref = _adp.fragmentData) != null ? ref.dataset : void 0;
  if (dataset == null) {
    return false;
  }
  console.info("Checking  ARK identifiers for dataset " + dataset + " ...");
  arkIdentifiers = projectData.dataset_arks.split(",");
  canonical = "";
  match = false;
  for (l = 0, len1 = arkIdentifiers.length; l < len1; l++) {
    ark = arkIdentifiers[l];
    if (ark.search(dataset) !== -1) {
      canonical = ark;
      match = true;
      break;
    }
  }
  if (match !== true) {
    console.warn("Could not find matching dataset in", arkIdentifiers);
    return false;
  }
  data = canonical.split("::");
  dataId = data[1];
  console.info("Got matching identifier " + canonical + " -> " + dataId);
  selector = ".download-file[data-href*='" + dataId + "']";
  selector = $(selector).get(0);
  if (forceDownload) {
    url = $(selector).attr("data-href");
    openTab(url);
  } else {
    $(selector).removeClass("btn-xs btn-primary").addClass("btn-success success-glow").click(function() {
      return $(this).removeClass("success-glow");
    });
    options = {
      behavior: "smooth",
      block: "start"
    };
    $(selector).get(0).scrollIntoView(true);
  }
  return selector;
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
  _adp.zcConfig = zcConfig;
  ZeroClipboard.config(zcConfig);
  _adp.zcClient = new ZeroClipboard($("#copy-ark").get(0));
  $("#copy-ark").click(function() {
    return copyLink(_adp.zcClient);
  });
  checkFileVersion(false, "js/project.js");
  $("#toggle-project-viewport").click(function() {
    $(".project-list-page").toggleClass("hidden-xs");
    if ($(".project-search").hasClass("hidden-xs")) {
      return $(this).text("Show Project Search");
    } else {
      return $(this).text("Show Project List");
    }
  });
  $("#community-map google-map-poly").on("google-map-poly-click", function(e) {
    var dest, proj;
    proj = $(this).attr("data-project");
    dest = uri.urlString + "project.php?id=" + proj;
    goTo(dest);
    return false;
  });
  return $("#community-map").on("google-map-ready", function() {
    var boundaryPoints, hull, hulls, j, l, len, len1, map, p, point, points, zoom;
    map = p$("#community-map");
    if (_adp.aggregateHulls != null) {
      boundaryPoints = new Array();
      hulls = Object.toArray(_adp.aggregateHulls);
      for (j = 0, len = hulls.length; j < len; j++) {
        hull = hulls[j];
        points = Object.toArray(hull);
        for (l = 0, len1 = points.length; l < len1; l++) {
          point = points[l];
          p = new Point(point.lat, point.lng);
          boundaryPoints.push(p);
        }
      }
      console.info("Adjusting zoom from " + map.zoom);
      zoom = getMapZoom(boundaryPoints, "#community-map");
      console.info("Calculated new zoom " + zoom);
      map.zoom = zoom;
    }
    return false;
  });
});

//# sourceMappingURL=maps/project.js.map
