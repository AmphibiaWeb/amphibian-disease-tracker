
/*
 * Project-specific code
 */
var checkProjectAuthorization, copyLink, postAuthorizeRender, renderEmail, renderMapWithData, showEmailField,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_adp.mapRendered = false;

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
    $("#auth-block").append(mapData);
    setupMapMarkerToggles();
    _adp.mapRendered = true;
    return stopLoad();
  }).error(function(result, status) {
    console.error(result, status);
    return stopLoadError("Couldn't render map");
  });
  return false;
};

postAuthorizeRender = function(projectData) {
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

copyLink = function(html5) {
  var ark, clip;
  if (html5 == null) {
    html5 = true;
  }
  toastStatusMessage("Would copy full ark link to clipboard");
  ark = p$(".ark-identifier").value;
  if (html5) {
    try {
      clip = new ClipboardEvent("copy");
      clip.clipboardData.setData("text/plain", "https://n2t.net/" + ark);
      document.dispatchEvent(clip);
      return false;
    } catch (_error) {}
    console.warn("Can't use HTML5");
  }
  return false;
};

$(function() {
  _adp.projectId = uri.o.param("id");
  checkProjectAuthorization();
  return $("#project-list button").unbind().click(function() {
    var project;
    project = $(this).attr("data-project");
    return goTo(uri.urlString + "project.php?id=" + project);
  });
});

//# sourceMappingURL=maps/project.js.map
