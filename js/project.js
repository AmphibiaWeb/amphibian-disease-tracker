
/*
 * Project-specific code
 */
var checkArkDataset, checkProjectAuthorization, copyLink, createOverflowMenu, disableMapViewFilter, fillSorterWithDropdown, kmlLoader, postAuthorizeRender, prepParsedDataDownload, publicData, renderEmail, renderMapWithData, renderPublicMap, restrictProjectsToMapView, searchProjects, setPublicData, showCitation, showEmailField, sqlQueryBox,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_adp.mapRendered = false;

_adp.zcClient = null;

publicData = null;

try {
  (createOverflowMenu = function() {

    /*
     * Create the overflow menu lazily
     */
    checkLoggedIn(function(result) {
      var accountSettings, menu;
      accountSettings = result.status ? "    <paper-item data-href=\"https://amphibiandisease.org/admin\" class=\"click\">\n  <iron-icon icon=\"icons:settings-applications\"></iron-icon>\n  Account Settings\n</paper-item>\n<paper-item data-href=\"https://amphibiandisease.org/admin-login.php?q=logout\" class=\"click\">\n  <span class=\"glyphicon glyphicon-log-out\"></span>\n  Log Out\n</paper-item>" : "";
      menu = "<paper-menu-button id=\"header-overflow-menu\" vertical-align=\"bottom\" horizontal-offset=\"-15\" horizontal-align=\"right\" vertical-offset=\"30\">\n  <paper-icon-button icon=\"icons:more-vert\" class=\"dropdown-trigger\"></paper-icon-button>\n  <paper-menu class=\"dropdown-content\">\n    " + accountSettings + "\n    <paper-item data-href=\"" + uri.urlString + "/dashboard.php\" class=\"click\">\n      Summary Dashboard\n    </paper-item>\n    <paper-item data-href=\"https://amphibian-disease-tracker.readthedocs.org\" class=\"click\">\n      <iron-icon icon=\"icons:chrome-reader-mode\"></iron-icon>\n      Documentation\n    </paper-item>\n    <paper-item data-href=\"https://github.com/AmphibiaWeb/amphibian-disease-tracker\" class=\"click\">\n      <iron-icon icon=\"glyphicon-social:github\"></iron-icon>\n      Github\n    </paper-item>\n    <paper-item data-href=\"https://amphibiandisease.org/about.php\" class=\"click\">\n      About / Legal\n    </paper-item>\n  </paper-menu>\n</paper-menu-button>";
      $("#header-overflow-menu").remove();
      $("header#header-bar .logo-container + p").append(menu);
      if (!isNull(accountSettings)) {
        $("header#header-bar paper-icon-button[icon='icons:settings-applications']").remove();
      }
      return bindClicks();
    });
    return false;
  })();
} catch (undefined) {}

fillSorterWithDropdown = function(selector) {
  var data, dropdownHtml, html, i, k, matchKey, selectCounter, selectedIndex, sortOptions;
  if (selector == null) {
    selector = ".sort-by-placeholder-text";
  }

  /*
   * Replace .sort-by-placeholder-text with a dropdown for the various
   * sort options.
   *
   * This should also have a corresponding list in ../project.php
   */
  sortOptions = {
    date: {
      title: "sampling date",
      key: "date"
    },
    affiliation: {
      title: "affiliation",
      key: "affiliation"
    },
    lab: {
      title: "PI lab",
      key: "lab"
    },
    contact: {
      title: "PI contact",
      key: "contact"
    }
  };
  matchKey = $(selector).attr("data-order-key");
  dropdownHtml = "";
  i = 0;
  selectedIndex = 0;
  for (k in sortOptions) {
    data = sortOptions[k];
    if (data.key === matchKey) {
      selectedIndex = i;
    }
    ++i;
    dropdownHtml += "<paper-item data-sort-key=\"" + data.key + "\">" + data.title + "</paper-item>";
  }
  html = "<paper-dropdown-menu label=\"Sort Options\" id=\"sort-options\">\n  <paper-listbox class=\"dropdown-content\" selected=\"" + selectedIndex + "\">\n    " + dropdownHtml + "\n  </paper-listbox>\n</paper-dropdown-menu>";
  $(selector).replaceWith(html);
  selectCounter = 0;
  $("#sort-options").on("iron-select", function() {
    var selected, sortKey;
    selected = p$(this).selectedItem;
    sortKey = $(selected).attr("data-sort-key");
    console.debug("Selected '" + sortKey + "'");
    if (selectCounter > 0) {
      goTo("https://" + uri.domain + ".org/project.php?sort=" + sortKey);
    }
    return ++selectCounter;
  });
  return false;
};

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
      }).fail(function(result, status) {
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
  animateLoad();
  dest = uri.urlString + "api.php";
  args = "action=is_human&recaptcha_response=" + response + "&project=" + _adp.projectId;
  $.post(dest, args, "json").done(function(result) {
    var authorData, label, ref, ref1;
    console.info("Checked response");
    console.log(result);
    authorData = result.author_data;
    showEmailField(authorData.contact_email);
    if (!isNull((ref = result.technical) != null ? ref.name : void 0) && !isNull((ref1 = result.technical) != null ? ref1.email : void 0)) {
      label = "Technical Contact " + result.technical.name;
      showEmailField(result.technical.email, label, "technical-email-send");
    }
    return stopLoad();
  }).fail(function(result, status) {
    stopLoadError("Sorry, there was a problem getting the contact email");
    return false;
  });
  return false;
};

showEmailField = function(email, fieldLabel, fieldId) {
  var fields, html, i, lastField;
  if (fieldLabel == null) {
    fieldLabel = "Contact Email";
  }
  if (fieldId == null) {
    fieldId = "contact-email-send";
  }
  html = "<div class=\"row appended-email-field\">\n  <paper-input readonly class=\"col-xs-8 col-md-11\" label=\"" + fieldLabel + "\" value=\"" + email + "\"></paper-input>\n  <paper-fab icon=\"communication:email\" class=\"click materialblue\" id=\"" + fieldId + "\" data-href=\"mailto:" + email + "\" data-toggle=\"tooltip\" title=\"Send Email\"></paper-fab>\n</div>";
  if ($("#email-fill").exists()) {
    $("#email-fill").replaceWith(html);
  } else {
    fields = $(".appended-email-field");
    i = fields.length - 1;
    lastField = $(".appended-email-field").get(i);
    $(lastField).after(html);
  }
  bindClicks("#" + fieldId);
  return false;
};

renderMapWithData = function(projectData, force) {
  var apiPostSqlQuery, args, ark, arkId, arkIdentifiers, baseFilePath, cartoData, cartoJson, cartoObj, cartoQuery, cartoTable, data, downloadButton, e, err1, error1, error2, error3, extraClasses, filePath, helperDir, html, i, j, l, len, len1, mapHtml, paths, point, poly, raw, ref, ref1, showKml, title, tmp, usedPoints, zoom, zoomPaths;
  if (force == null) {
    force = false;
  }
  showKml = function() {
    try {
      if (!isNull(projectData.transect_file)) {
        return kmlLoader(projectData.transect_file, function() {
          return console.debug("Loaded KML file successfully");
        });
      }
    } catch (undefined) {}
  };
  if (_adp.mapRendered === true && force !== true) {
    console.warn("Carto: The map was asked to be rendered again, but it has already been rendered!");
    showKml();
    return false;
  }
  cartoObj = projectData.carto_id;
  if (typeof cartoObj !== "object") {
    try {
      cartoData = JSON.parse(deEscape(cartoObj));
    } catch (error1) {
      e = error1;
      err1 = e.message;
      try {
        cartoData = JSON.parse(cartoObj);
      } catch (error2) {
        e = error2;
        if (cartoObj.length > 511) {
          cartoJson = fixTruncatedJson(cartoObj);
          if (typeof cartoJson === "object") {
            console.debug("The carto data object was truncated, but rebuilt.");
            cartoData = cartoJson;
          }
        }
        if (isNull(cartoData)) {
          console.error("cartoObj must be JSON string or obj, given", cartoObj);
          console.warn("Cleaned obj:", deEscape(cartoObj));
          console.warn("Told '" + err1 + "' then", e.message);
          stopLoadError("Couldn't parse data");
          return false;
        }
      }
    }
  } else {
    cartoData = cartoObj;
  }
  _adp.cartoDataParsed = cartoData;
  raw = cartoData.raw_data;
  if (isNull(raw)) {
    console.warn("No raw data to render");
    showKml();
    return false;
  }
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
  if (isNull(cartoTable)) {
    console.warn("WARNING: This project has no data associated with it. Not doing map render.");
    showKml();
    return false;
  }
  try {
    try {
      if (cartoData.bounding_polygon.paths.toBool() === false && !isNull(cartoData.bounding_polygon.multibounds)) {
        cartoData.bounding_polygon.paths = cartoData.bounding_polygon.multibounds[0];
      }
    } catch (undefined) {}
    zoomPaths = (ref = cartoData.bounding_polygon.paths) != null ? ref : cartoData.bounding_polygon;
    zoom = getMapZoom(zoomPaths, "#transect-viewport");
    console.info("Got zoom", zoom);
  } catch (error3) {
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
  ref1 = poly.paths;
  for (l = 0, len1 = ref1.length; l < len1; l++) {
    point = ref1[l];
    if (indexOf.call(usedPoints, point) < 0) {
      usedPoints.push(point);
      mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
    }
  }
  mapHtml += "    </google-map-poly>";
  cartoQuery = "SELECT genus, specificepithet, diseasetested, diseasedetected, originaltaxa, ST_asGeoJSON(the_geom) FROM " + cartoTable + ";";
  console.info("Would ping cartodb with", cartoQuery);
  apiPostSqlQuery = encodeURIComponent(encode64(cartoQuery));
  args = "action=fetch&sql_query=" + apiPostSqlQuery;
  console.debug("Hitting endpoint for carto lookup", uri.urlString + "api.php?" + args);
  $.post("api.php", args, "json").done(function(result) {
    var adjustedList, collectionRangePretty, d, d1, d2, el, error, geoJson, googleMap, isPositive, k, lat, len2, len3, len4, len5, lng, m, mapData, marker, month, monthPretty, months, note, o, options, perTaxaStatus, pointPoints, points, q, ref2, ref3, ref4, row, rows, speciesItem, t, taxa, year, yearPretty, years;
    if (_adp.mapRendered === true) {
      console.warn("Duplicate map render! Skipping thread");
      showKml();
      return false;
    }
    console.info("Carto query got result:", result);
    if (!result.status) {
      error = (ref2 = result.human_error) != null ? ref2 : result.error;
      if (error == null) {
        error = "Unknown error";
      }
      stopLoadError("Sorry, we couldn't retrieve your information at the moment (" + error + ")");
      showKml();
      return false;
    }
    rows = result.parsed_responses[0].rows;
    points = new Array();
    pointPoints = new Array();
    console.log("Running swapped cartoDB order (lng, lat)");
    perTaxaStatus = new Object();
    for (k in rows) {
      row = rows[k];
      geoJson = JSON.parse(row.st_asgeojson);
      lat = geoJson.coordinates[1];
      lng = geoJson.coordinates[0];
      points.push([lat, lng]);
      try {
        pointPoints.push(canonicalizePoint([lat, lng]));
      } catch (undefined) {}
      taxa = row.genus + " " + row.specificepithet;
      if (perTaxaStatus[taxa] == null) {
        perTaxaStatus[taxa] = {
          positive: false,
          negative: false,
          no_confidence: false,
          counts: {
            total: 0,
            positive: 0,
            negative: 0,
            no_confidence: 0
          }
        };
      }
      row.diseasedetected = (function() {
        switch (row.diseasedetected.toString().toLowerCase()) {
          case "true":
            perTaxaStatus[taxa].positive = true;
            perTaxaStatus[taxa].counts.positive++;
            return "positive";
          case "false":
            perTaxaStatus[taxa].negative = true;
            perTaxaStatus[taxa].counts.negative++;
            return "negative";
          default:
            perTaxaStatus[taxa].no_confidence = true;
            perTaxaStatus[taxa].counts.no_confidence++;
            return row.diseasedetected.toString();
        }
      })();
      perTaxaStatus[taxa].counts.total++;
      note = "";
      if (taxa !== row.originaltaxa) {
        note = "(<em>" + row.originaltaxa + "</em>)";
      }
      marker = "<google-map-marker latitude=\"" + lat + "\" longitude=\"" + lng + "\" data-disease-detected=\"" + row.diseasedetected + "\">\n  <p>\n    <em>" + row.genus + " " + row.specificepithet + "</em> " + note + "\n    <br/>\n    Tested <strong>" + row.diseasedetected + "</strong> for " + row.diseasetested + "\n  </p>\n</google-map-marker>";
      if (row.diseasedetected !== "positive" && row.diseasedetected !== "negative") {
        row.diseasedetected = "inconclusive";
      }
      $(".aweb-link-species[data-species='" + row.genus + " " + row.specificepithet + "']").attr("data-" + row.diseasedetected, "true");
      mapHtml += marker;
    }
    if ((poly != null ? poly.paths : void 0) == null) {
      try {
        _adp.canonicalHull = createConvexHull(points, true);
      } catch (undefined) {}
    }
    googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + projectData.lat + "\" longitude=\"" + projectData.lng + "\" map-type=\"hybrid\" zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6\" api-key=\"" + gMapsApiKey + "\">\n  " + mapHtml + "\n</google-map>";
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
    for (o = 0, len3 = years.length; o < len3; o++) {
      year = years[o];
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
    mapData = mapData.replace(/NaN/mg, "0");
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
          buttonText: "Download Species Stats",
          splitValues: " ",
          header: ["Genus", "Species", "Subspecies", "Positive Samples?", "Negative Samples?", "Inconclusive Samples?", "Positive Count", "Negative Count", "Inconclusive Count", "Totals"]
        };
        adjustedList = new Array();
        ref3 = _adp.pageSpeciesList;
        for (q = 0, len4 = ref3.length; q < len4; q++) {
          speciesItem = ref3[q];
          tmp = speciesItem.split(options.splitValues);
          if (tmp.length < 3) {
            while (tmp.length < 3) {
              tmp.push("");
            }
          }
          if (perTaxaStatus[speciesItem] != null) {
            tmp.push(perTaxaStatus[speciesItem].positive.toString());
            tmp.push(perTaxaStatus[speciesItem].negative.toString());
            tmp.push(perTaxaStatus[speciesItem].no_confidence.toString());
            tmp.push(perTaxaStatus[speciesItem].counts.positive.toString());
            tmp.push(perTaxaStatus[speciesItem].counts.negative.toString());
            tmp.push(perTaxaStatus[speciesItem].counts.no_confidence.toString());
            tmp.push(perTaxaStatus[speciesItem].counts.total.toString());
          } else {
            console.warn("CSV downloader couldn't find " + speciesItem + " in perTaxaStatus");
            window.perTaxaStatus = perTaxaStatus;
          }
          adjustedList.push(tmp.join(options.splitValues));
        }
        downloadCSVFile(adjustedList, options);
      }
    }
    bindClicks(".download-file");
    sqlQueryBox();
    $(".download-data-file").contextmenu(function(event) {
      var caller, clipboardData, copyFn, elPos, inFn, outFn, url, zcClientInitial;
      event.preventDefault();
      console.log("Event details", event);
      elPos = $(this).offset();
      html = "<paper-material class=\"ark-context-wrapper\" style=\"top:" + event.pageY + "px;left:" + event.pageX + "px;position:absolute\">\n  <paper-menu class=context-menu\">\n    <paper-item class=\"copy-ark-context\">\n      Copy ARK to clipboard\n    </paper-item>\n  </paper-menu>\n</paper-material>";
      $(".ark-context-wrapper").remove();
      $("body").append(html);
      getMapZoom(pointPoints, "#transect-viewport");
      ZeroClipboard.config(_adp.zcConfig);
      zcClientInitial = new ZeroClipboard($(".copy-ark-context").get(0));
      ark = $(this).attr("data-ark");
      url = "http://biscicol.org/id/" + ark;
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
        var clip, error4;
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
        } catch (error4) {
          e = error4;
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
    ref4 = $(".aweb-link-species");
    for (t = 0, len5 = ref4.length; t < len5; t++) {
      el = ref4[t];
      isPositive = $(el).attr("data-positive").toBool();
      if (isPositive) {
        $(el).attr("data-negative", "false").attr("data-inconclusive", "false");
      }
    }
    console.info("Carto lookup complete");
    showKml();
    return stopLoad();
  }).fail(function(result, status) {
    console.error("Couldn't render map and carto data");
    console.error(result, status);
    showKml();
    return stopLoadError("Couldn't render map");
  });
  return false;
};

postAuthorizeRender = function(projectData, authorizationDetails) {

  /*
   * Takes in project data, then renders the appropriate bits
   *
   * @param object projectData -> the full projectData array from an
   *   authorized lookup
   * @param object authorizationDetails -> the permissions object
   */
  var adminButton, authorData, cartoData, cartoJson, cartoObj, e, editButton, err1, error1, error2, label;
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
  try {
    if (!isNull(projectData.technical_contact) && !isNull(projectData.technical_contact_email)) {
      label = "Technical Contact " + projectData.technical_contact;
      showEmailField(projectData.technical_contact_email, label, "technical-email-send");
    }
  } catch (undefined) {}
  bindClicks(".authorized-action");
  cartoObj = projectData.carto_id;
  if (typeof cartoObj !== "object") {
    try {
      cartoData = JSON.parse(deEscape(cartoObj));
    } catch (error1) {
      e = error1;
      err1 = e.message;
      try {
        cartoData = JSON.parse(cartoObj);
      } catch (error2) {
        e = error2;
        if (cartoObj.length > 511) {
          cartoJson = fixTruncatedJson(cartoObj);
          if (typeof cartoJson === "object") {
            console.debug("The carto data object was truncated, but rebuilt.");
            cartoData = cartoJson;
          }
        }
        if (isNull(cartoData)) {
          console.error("cartoObj must be JSON string or obj, given", cartoObj);
          console.warn("Cleaned obj:", deEscape(cartoObj));
          console.warn("Told '" + err1 + "' then", e.message);
          stopLoadError("Couldn't parse data");
          return false;
        }
      }
    }
  } else {
    cartoData = cartoObj;
  }
  renderMapWithData(projectData);
  try {
    prepParsedDataDownload(projectData);
  } catch (undefined) {}
  return false;
};

kmlLoader = function(path, callback) {

  /*
   * Load a KML file. The parser handles displaying it on any
   * google-map compatible objects.
   *
   * @param string path -> the  relative path to the file
   * @param function callback -> Callback function to execute
   */
  var error1, googleMap, jsPath, kmlData, mapData, ref;
  try {
    if (typeof path === "object") {
      kmlData = path;
      path = kmlData.path;
    } else {
      try {
        kmlData = JSON.parse(path);
        path = kmlData.path;
      } catch (error1) {
        kmlData = {
          path: path
        };
      }
    }
    console.debug("Loading KML file", path);
  } catch (undefined) {}
  geo.inhibitKMLInit = true;
  jsPath = isNull(typeof _adp !== "undefined" && _adp !== null ? (ref = _adp.lastMod) != null ? ref.kml : void 0 : void 0) ? "js/kml.min.js" : "js/kml.min.js?t=" + _adp.lastMod.kml;
  startLoad();
  if (!$("google-map").exists()) {
    googleMap = "<google-map id=\"transect-viewport\" class=\"col-xs-12 col-md-9 col-lg-6 kml-lazy-map\" api-key=\"" + gMapsApiKey + "\" map-type=\"hybrid\">\n</google-map>";
    mapData = "<div class=\"row\">\n  <h2 class=\"col-xs-12\">Mapping Data</h2>\n  " + googleMap + "\n</div>";
    if ($("#auth-block").exists()) {
      $("#auth-block").append(mapData);
    } else {
      console.warn("Couldn't find an authorization block to render the KML map in!");
      return false;
    }
    _adp.mapRendered = true;
  }
  loadJS(jsPath, function() {
    initializeParser(null, function() {
      loadKML(path, function() {
        var e, error2, parsedKmlData;
        try {
          parsedKmlData = geo.kml.parser.docsByUrl[path];
          if (isNull(parsedKmlData)) {
            path = "/" + path;
            parsedKmlData = geo.kml.parser.docsByUrl[path];
            if (isNull(parsedKmlData)) {
              console.warn("Could not resolve KML by url, using first doc");
              parsedKmlData = geo.kml.parser.docs[0];
            }
          }
          if (isNull(parsedKmlData)) {
            allError("Bad KML provided");
            return false;
          }
          console.debug("Using parsed data from path '" + path + "'", parsedKmlData);
          if (typeof callback === "function") {
            callback(parsedKmlData);
          } else {
            console.info("kmlHandler wasn't given a callback function");
          }
          stopLoad();
        } catch (error2) {
          e = error2;
          allError("There was a importing the data from this KML file");
          console.warn(e.message);
          console.warn(e.stack);
        }
        return false;
      });
      return false;
    });
    return false;
  });
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
      url = "http://biscicol.org/id/" + ark;
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
   * Handler to search projects on the top-level project page
   *
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
        button = "<button class=\"btn btn-info search-proj-link\" data-href=\"" + uri.urlString + "project.php?id=" + project.project_id + "\" data-toggle=\"tooltip\" data-placement=\"right\" title=\"Project #" + (project.project_id.slice(0, 8)) + "...\">\n  " + icon + " " + project.project_title + "\n</button>";
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
  }).fail(function(result, status) {
    return console.error(result, status);
  });
  return false;
};

setPublicData = function(projectData) {
  publicData = projectData;
  return false;
};

renderPublicMap = function(projectData) {
  var cartoData, coordArr, e, error, error1, error2, error3, error4, googleMap, j, len, mapCenter, mapHtml, ne, nw, paths, point, poly, se, sw, usedPoints, zoom;
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
    coordArr = getPointsFromBoundingBox(projectData);
    if (coordArr[0].lat == null) {
      coordArr = getCorners(coordArr);
    }
    nw = {
      lat: coordArr[0].lat,
      lng: coordArr[0].lng
    };
    ne = {
      lat: coordArr[1].lat,
      lng: coordArr[1].lng
    };
    se = {
      lat: coordArr[2].lat,
      lng: coordArr[2].lng
    };
    sw = {
      lat: coordArr[3].lat,
      lng: coordArr[3].lng
    };
    paths = [nw, ne, se, sw];
    try {
      zoom = getMapZoom(coordArr, "#transect-viewport");
      console.info("Got public zoom", zoom);
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
    mapCenter = getMapCenter(coordArr);
    googleMap = "<div class=\"row\" id=\"public-map\">\n  <h2 class=\"col-xs-12\">Project Area of Interest</h2>\n  <google-map id=\"transect-viewport\" latitude=\"" + mapCenter.lat + "\" longitude=\"" + mapCenter.lng + "\" map-type=\"hybrid\" zoom=\"" + zoom + "\" class=\"col-xs-12 col-md-9 col-lg-6 center-block clearfix public-fuzzy-map\"  api-key=\"" + gMapsApiKey + "\">\n        " + mapHtml + "\n  </google-map>\n</div>";
    $("#auth-block").append(googleMap);
    try {
      zoom = getMapZoom(paths, "#transect-viewport");
      return p$("#transect-viewport").zoom = zoom;
    } catch (error3) {
      error = error3;
      try {
        zoom = getMapZoom(coordArr, "#transect-viewport");
        return p$("#transect-viewport").zoom = zoom;
      } catch (undefined) {}
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
    $(selector).get(0).scrollIntoView(false);
  }
  return selector;
};

prepParsedDataDownload = function(projectData) {
  var apiPostSqlQuery, args, cartoData, cartoJson, cartoObj, cartoQuery, cartoTable, d, e, err1, error1, error2, options, parseableData;
  d = new Date();
  options = {
    selector: "#data-download-buttons",
    create: true,
    objectAsValues: true,
    buttonText: "Download Parsed Dataset",
    downloadFile: "datalist-" + projectData.project_id + "-" + (d.toISOString()) + ".csv"
  };
  parseableData = new Object();
  cartoObj = projectData.carto_id;
  if (typeof cartoObj !== "object") {
    try {
      cartoData = JSON.parse(deEscape(cartoObj));
    } catch (error1) {
      e = error1;
      err1 = e.message;
      try {
        cartoData = JSON.parse(cartoObj);
      } catch (error2) {
        e = error2;
        if (cartoObj.length > 511) {
          cartoJson = fixTruncatedJson(cartoObj);
          if (typeof cartoJson === "object") {
            console.debug("The carto data object was truncated, but rebuilt.");
            cartoData = cartoJson;
          }
        }
        if (isNull(cartoData)) {
          console.error("cartoObj must be JSON string or obj, given", cartoObj);
          console.warn("Cleaned obj:", deEscape(cartoObj));
          console.warn("Told '" + err1 + "' then", e.message);
          stopLoadError("Couldn't parse data");
          return false;
        }
      }
    }
  } else {
    cartoData = cartoObj;
  }
  cartoTable = cartoData.table;
  if (isNull(cartoTable)) {
    console.warn("WARNING: This project has no data associated with it. Not creating download.");
    return false;
  }
  cartoQuery = "SELECT *, ST_asGeoJSON(the_geom) FROM " + cartoTable + ";";
  console.info("Would ping cartodb with", cartoQuery);
  apiPostSqlQuery = encodeURIComponent(encode64(cartoQuery));
  args = "action=fetch&sql_query=" + apiPostSqlQuery;
  _adp.dataPoints = new Array();
  $.post("api.php", args, "json").done(function(result) {
    var col, coordObj, data, dataObj, error, error3, fims, geoJson, k, lat, lng, pTmp, ref, row, rows;
    if (!result.status) {
      error = (ref = result.human_error) != null ? ref : result.error;
      if (error == null) {
        error = "Unknown error";
      }
      stopLoadError("Sorry, we couldn't retrieve your information at the moment (" + error + ")");
      return false;
    }
    rows = result.parsed_responses[0].rows;
    dataObj = new Array();
    for (k in rows) {
      row = rows[k];
      geoJson = JSON.parse(row.st_asgeojson);
      lat = geoJson.coordinates[1];
      lng = geoJson.coordinates[0];
      coordObj = {
        lat: lat,
        lng: lng
      };
      pTmp = canonicalizePoint(coordObj);
      _adp.dataPoints.push(pTmp);
      row.decimalLatitude = lat;
      row.decimalLongitude = lng;
      delete row.st_asgeojson;
      try {
        try {
          fims = JSON.parse(row.fimsextra);
        } catch (error3) {
          fims = row.fimsextra;
        }
        if (typeof fims === "object") {
          for (col in fims) {
            data = fims[col];
            row[col] = data;
          }
          delete row.fimsextra;
        }
      } catch (undefined) {}
      delete row.cartodb_id;
      delete row.id;
      delete row.the_geom;
      delete row.the_geom_webmercator;
      dataObj.push(row);
    }
    return downloadCSVFile(dataObj, options);
  }).fail(function(result, status) {
    console.error("Couldn't create");
    return console.error(result, status);
  });
  return false;
};

sqlQueryBox = function() {

  /*
   * Render and bind events for a box to directly execute queries on a
   * project.
   */
  var formatQuery, html, queryCarto, queryResultDialog, queryResultSummaryHistory, startQuery;
  if (_adp.cartoDataParsed == null) {
    console.error("CartoDB data not available. Are you logged in?");
    return false;
  }
  queryCarto = function(query) {
    var args;
    animateLoad();
    console.info("Querying with");
    console.log(query);
    args = "action=fetch&sql_query=" + (post64(query));
    _adp.currentAsyncJqxhr = $.post("api.php", args, "json").done(function(result) {
      var e, err, error1, error2, ex, extended, json, n, nHuman, output, r, ref, ref1, ref2, sqlQuery;
      console.log(result);
      if (result.status !== true) {
        err = (ref = (ref1 = result.human_error) != null ? ref1 : result.error) != null ? ref : "Unknown error";
        console.error(err);
        extended = (function() {
          switch (err) {
            case "UNAUTHORIZED_QUERY_TYPE":
              return result.query_type;
            default:
              return ex = "(no details for error " + result.error + ")";
          }
        })();
        $("#query-immediate-result").text(err + ": " + extended);
        $(".do-sql-query").removeAttr("disabled");
        stopLoad();
        return false;
      }
      try {
        r = JSON.parse(result.post_response[0]);
      } catch (error1) {
        e = error1;
        console.error("Error parsing result");
        $("#query-immediate-result").text("Error parsing result from CartoDB");
        $(".do-sql-query").removeAttr("disabled");
        stopLoad();
        return false;
      }
      if (r.error != null) {
        console.error("Error in result: " + r.error);
        $("#query-immediate-result").text(r.error);
        $(".do-sql-query").removeAttr("disabled");
        stopLoad();
        return false;
      }
      console.log("Using responses", result.parsed_responses);
      output = "";
      ref2 = result.parsed_responses;
      for (n in ref2) {
        sqlQuery = ref2[n];
        nHuman = toInt(n) + 1;
        output += "#" + nHuman + ": ";
        try {
          json = JSON.stringify(sqlQuery.rows);
          output += "<code class=\"language-json\">" + json + "</code>";
        } catch (error2) {
          output += "BAD QUERY";
        }
        output += "\n\n";
      }
      $("#query-immediate-result").html(output);
      try {
        Prism.highlightAll(true);
      } catch (undefined) {}
      $(".do-sql-query").removeAttr("disabled");
      stopLoad();
      return false;
    }).error(function() {
      $("#query-immediate-result").text("Error executing query");
      $(".do-sql-query").removeAttr("disabled");
      return stopLoadError();
    });
    return false;
  };
  formatQuery = function(rawQuery, dontReplace) {
    var lowQuery, query;
    if (dontReplace == null) {
      dontReplace = false;
    }
    lowQuery = rawQuery.trim();
    query = lowQuery.replace(/@@/mig, _adp.cartoDataParsed.table);
    query = query.replace(/!@/mig, "SELECT * FROM " + _adp.cartoDataParsed.table);
    if (!dontReplace) {
      $("#query-input").val(query);
    }
    return query;
  };
  queryResultDialog = function() {
    return false;
  };
  queryResultSummaryHistory = function() {
    return false;
  };
  if (!$("#project-sql-query-box").exists()) {
    html = "<div id=\"project-sql-query-box\" class=\"row\">\n  <h2 class=\"col-xs-12\">Raw Project Queries</h2>\n  <textarea class=\"form-control code col-xs-10 col-xs-offset-1\" rows=\"3\" id=\"query-input\" placeholder=\"SQL Query\" aria-describedby=\"query-cheats\"></textarea>\n  <div class=\"col-xs-12\">\n    <label class=\"text-muted col-xs-2 col-md-1\" for=\"interpreted-query\">Real Query:</label>\n    <code class=\"language-sql col-xs-10 col-md-11\" id=\"interpreted-query\">\n    </code>\n  </div>\n  <div class=\"col-xs-12 col-sm-9\">\n    <span class=\"text-muted\" id=\"query-cheats\">Tips: <ol><li>You're querying PostgreSQL</li><li>Type <kbd>@@</kbd> as a placeholder for the table name</li><li>Type <kbd>!@</kbd> as a placeholder for <code>SELECT * FROM @@</code></li><li>Multiple queries at once is just fine. They're broken at <kbd>);</kbd>, so enclosing your <code>WHERE</code> in parentheses is good enough.</li></ol></span>\n  </div>\n  <div class=\"col-xs-12 col-sm-3\">\n    <button class=\"btn btn-default do-sql-query pull-right\">Execute Query</button>\n  </div>\n  <h3 class=\"col-xs-12\">Result:</h3>\n  <pre class=\"code col-xs-12\" id=\"query-immediate-result\"></pre>\n</div>";
    if ($("h2.project-identifier").exists()) {
      $("h2.project-identifier").before(html);
    } else {
      $("main").append(html);
    }
  }
  startQuery = function() {
    var input, query;
    console.info("Executing query ...");
    input = $("#query-input").val();
    query = formatQuery(input);
    if (query.search(_adp.cartoDataParsed.table) === -1) {
      console.error("Query didn't specify a table!");
      toastStatusMessage("You forgot to include the table identifier in your query.");
      return false;
    }
    $(".do-sql-query").attr("disabled", "disabled");
    return queryCarto(query);
  };
  $("#query-input").keyup(function(e) {
    var kc, query;
    kc = e.keyCode ? e.keyCode : e.which;
    if (kc === 13) {
      try {
        e.preventDefault();
      } catch (undefined) {}
      startQuery();
    } else {
      query = formatQuery($(this).val(), true);
      $("code#interpreted-query").text(query);
      Prism.highlightElement($("code#interpreted-query")[0], true);
    }
    return false;
  });
  $(".do-sql-query").click(function() {
    return startQuery();
  });
  return false;
};

showCitation = function() {
  var doi;
  doi = p$("paper-input[label='DOI']").value;
  if (!$("#citation-pop").exists()) {
    animateLoad();
    fetchCitation(doi, function(citation, url) {
      var e, error1, error2, error3, html, pdfButton;
      try {
        pdfButton = isNull(url) ? "" : "<paper-button class=\"click\" data-newtab=\"true\" data-href=\"" + url + "\">\n  <iron-icon icon=\"icons:open-in-new\"></iron-icon>\n  Open\n</paper-button>";
        html = "<paper-dialog id=\"citation-pop\" modal>\n  <h2>Citation</h2>\n  <paper-dialog-scrollable>\n    <div class=\"pop-contents\">\n      <paper-textarea label=\"Citation\" id=\"popped-citation\" readonly>\n        " + citation + "\n      </paper-textarea>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button id=\"copy-citation\" class=\"click-copy\" data-copy-selector=\"#popped-citation\">\n      <iron-icon icon=\"icons:content-copy\"></iron-icon>\n      Copy Citation\n    </paper-button>\n    <paper-button id=\"copy-doi\" class=\"click-copy\" data-copy-selector=\"#doi-input\">\n      <iron-icon icon=\"icons:content-copy\"></iron-icon>\n      Copy DOI\n    </paper-button>\n    " + pdfButton + "\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
        $("body").append(html);
        try {
          p$("#popped-citation").value = citation;
        } catch (error1) {
          delay(500, function() {
            try {
              return p$("#popped-citation").value = citation;
            } catch (undefined) {}
          });
        }
        bindClicks();
        bindCopyEvents();
        safariDialogHelper("#citation-pop");
        return stopLoad();
      } catch (error2) {
        e = error2;
        console.error("Couldn't show citation - " + e.message);
        try {
          return p$("#citation-pop").open();
        } catch (error3) {
          return stopLoadError("Failed to display citation");
        }
      }
    });
  } else {
    p$("#citation-pop").open();
  }
  return false;
};

window.showCitation = showCitation;

disableMapViewFilter = function() {
  $("google-map#community-map").unbind("google-map-idle");
  _adp.hasBoundMapEvent = false;
  return true;
};

restrictProjectsToMapView = function(edges) {
  var button, callback, corners, e, error1, includeProject, j, l, len, len1, len2, len3, m, map, mapBounds, o, point, poly, projectId, ref, ref1, ref10, ref11, ref12, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, test, updateWidthAttr, validProjects;
  if (edges == null) {
    edges = false;
  }

  /*
   * When we're on the top-level project page, we should only see
   * projects in the list that are visible in the map.
   *
   * See:
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/208
   */
  if (!$("google-map#community-map").exists()) {
    return false;
  }
  if (!_adp.hasBoundMapEvent) {
    _adp.hasBoundMapEvent = true;
    callback = null;
    (updateWidthAttr = function(callback) {
      $("google-map#community-map").removeAttr("width");
      delay(25, function() {
        var width;
        try {
          width = $("google-map#community-map").width();
          $("google-map#community-map").attr("width", width + "px");
        } catch (undefined) {}
        try {
          if (typeof callback === "function") {
            return callback();
          }
        } catch (undefined) {}
      });
      return false;
    })(callback);
    $("window").on("resize", function() {
      updateWidthAttr(function() {
        return restrictProjectsToMapView.debounce(50, null, null, edges);
      });
      return false;
    });
    $("google-map#community-map").on("google-map-idle", function() {
      updateWidthAttr(function() {
        return restrictProjectsToMapView.debounce(50, null, null, edges);
      });
      return false;
    });
    $("#projects-by-map-view").on("iron-change", function() {
      var control, j, len, ref;
      ref = $(".map-view-control:not(.map-view-master)");
      for (j = 0, len = ref.length; j < len; j++) {
        control = ref[j];
        p$(control).disabled = !p$(this).checked;
      }
      return false;
    });
    $(".map-view-control").on("iron-change", function() {
      restrictProjectsToMapView.debounce(50, null, null, edges);
      return false;
    });
    console.log("Bound events for RPTMV");
  }
  if (!p$("#projects-by-map-view").checked) {
    $("#project-list li").removeAttr("hidden");
    $("h2.status-notice.project-list").removeAttr("hidden");
    $("button.js-lazy-project").remove();
    $("#map-view-title").remove();
    return false;
  }
  $("h2.status-notice.project-list").attr("hidden", "hidden");
  map = p$("google-map#community-map").map;
  mapBounds = map.getBounds();
  corners = {
    north: mapBounds.getNorthEast().lat(),
    east: mapBounds.getNorthEast().lng(),
    south: mapBounds.getSouthWest().lat(),
    west: mapBounds.getSouthWest().lng()
  };
  if (corners.west > corners.east) {
    corners.west = -180;
    corners.east = 180;
  }
  validProjects = new Array();
  if (p$("#show-dataless-projects").checked) {
    ref = $("#project-list button");
    for (j = 0, len = ref.length; j < len; j++) {
      button = ref[j];
      try {
        projectId = $(button).attr("data-project");
        if (!$(button).attr("data-has-locale").toBool()) {
          validProjects.push(projectId);
        } else {
          console.debug(projectId + " has a locale, handling normally");
        }
      } catch (error1) {
        e = error1;
        console.warn("Error checking button -- " + e.message);
        console.warn(e.stack);
      }
    }
  }
  ref1 = $("google-map#community-map").find("google-map-poly");
  for (l = 0, len1 = ref1.length; l < len1; l++) {
    poly = ref1[l];
    projectId = $(poly).attr("data-project");
    if (indexOf.call(validProjects, projectId) >= 0) {
      continue;
    }
    test = {
      north: -90,
      south: 90,
      east: -180,
      west: 180
    };
    ref2 = $(poly).find("google-map-point");
    for (m = 0, len2 = ref2.length; m < len2; m++) {
      point = ref2[m];
      if (p$(point).latitude > test.north) {
        test.north = p$(point).latitude;
      }
      if (p$(point).longitude > test.east) {
        test.east = p$(point).longitude;
      }
      if (p$(point).longitude < test.west) {
        test.west = p$(point).longitude;
      }
      if (p$(point).latitude < test.south) {
        test.south = p$(point).latitude;
      }
    }
    includeProject = false;
    if (edges === true) {
      console.log("Checking edges of", projectId);
      if ((corners.south < (ref3 = test.north) && ref3 < corners.north)) {
        includeProject = true;
      }
      if ((corners.south < (ref4 = test.south) && ref4 < corners.north)) {
        includeProject = true;
      }
      if ((corners.west < (ref5 = test.east) && ref5 < corners.east)) {
        includeProject = true;
      }
      if ((corners.west < (ref6 = test.west) && ref6 < corners.east)) {
        includeProject = true;
      }
    } else {
      console.log("Checking containement of", projectId);
      if (test.south > corners.south && test.north < corners.north) {
        if ((corners.west < (ref7 = test.east) && ref7 < corners.east) || (corners.west < (ref8 = test.west) && ref8 < corners.east)) {
          console.log("Project is wholly NS contained");
          includeProject = true;
        }
      }
      if (test.west > corners.west && test.east < corners.east) {
        if ((corners.south < (ref9 = test.north) && ref9 < corners.north) || (corners.south < (ref10 = test.south) && ref10 < corners.north)) {
          console.log("Project is wholly EW contained");
          includeProject = true;
        }
      }
    }
    if (includeProject) {
      validProjects.push(projectId);
    }
  }
  $("#project-list li").attr("hidden", "hidden");
  ref11 = $("#project-list button");
  for (o = 0, len3 = ref11.length; o < len3; o++) {
    button = ref11[o];
    if (ref12 = $(button).attr("data-project"), indexOf.call(validProjects, ref12) >= 0) {
      $(button).parent("li").removeAttr("hidden");
    }
  }
  $.get(uri.urlString + "admin-api.php", "action=list", "json").done(function(result) {
    var html, icon, project, publicProjects, ref13, results, shortTitle, title;
    console.log("Got project list", result);
    $("button.js-lazy-project").remove();
    publicProjects = Object.toArray(result.public_projects);
    ref13 = result.projects;
    results = [];
    for (project in ref13) {
      title = ref13[project];
      if (indexOf.call(validProjects, project) >= 0) {
        if (!$("button[data-project='" + project + "']").exists()) {
          console.log("Should add visible project '" + title + "'", project);
          shortTitle = title.slice(0, 40);
          if (shortTitle !== title) {
            shortTitle += "...";
          }
          icon = indexOf.call(publicProjects, project) >= 0 ? "social:public" : "icons:lock";
          html = "<li>\n<button class=\"js-lazy-project btn btn-primary\" data-href=\"" + uri.urlString + "project.php?id=" + project + "\" data-project=\"" + project + "\" data-toggle=\"tooltip\">\n  <iron-icon icon=\"" + icon + "\"></iron-icon>\n  " + shortTitle + "\n</button>\n</li>";
          results.push($("#project-list").append(html));
        } else {
          results.push(console.log("Not re-adding button for", project));
        }
      } else {
        results.push(console.log("Not adding invalid project", project));
      }
    }
    return results;
  }).fail(function(result, status) {
    return console.warn("Failed to get project list", result, status);
  }).always(function() {
    var count, html;
    count = $("#project-list button:visible").length;
    html = "<h2 class=\"col-xs-12 status-notice hidden-xs project-list project-list-page map-view-title\" id=\"map-view-title\">\n  Showing " + count + " projects in view\n</h2>";
    $("#map-view-title").remove();
    return $("h2.status-notice.project-list").before(html);
  });
  console.log("Showing projects", validProjects, "within", corners);
  return validProjects;
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
  $("#community-map").on("google-map-ready", function() {
    var badLat, badLng, boundaryPoints, center, hull, hulls, j, l, len, len1, map, p, point, points, zoom;
    try {
      fillSorterWithDropdown();
    } catch (undefined) {}
    map = p$("#community-map");
    if (_adp.aggregateHulls != null) {
      boundaryPoints = new Array();
      hulls = Object.toArray(_adp.aggregateHulls);
      for (j = 0, len = hulls.length; j < len; j++) {
        hull = hulls[j];
        points = Object.toArray(hull);
        for (l = 0, len1 = points.length; l < len1; l++) {
          point = points[l];
          badLat = isNull(point.lat) || Math.abs(point.lat) === 90;
          badLng = isNull(point.lng) || Math.abs(point.lng) === 180;
          if (badLat || badLng) {
            continue;
          }
          p = new Point(point.lat, point.lng);
          boundaryPoints.push(p);
        }
      }
      console.info("Adjusting zoom from " + map.zoom);
      zoom = getMapZoom(boundaryPoints, "#community-map");
      console.info("Calculated new zoom " + zoom);
      try {
        center = getMapCenter(boundaryPoints);
        map.latitude = center.lat;
        map.longitude = center.lng;
        console.info("Recentered map");
      } catch (undefined) {}
      map.zoom = zoom;
    }
    return false;
  });
  try {
    $(".self-citation").click(function() {
      $(this).selectText();
      return false;
    });
  } catch (undefined) {}
  return restrictProjectsToMapView();
});

//# sourceMappingURL=maps/project.js.map
