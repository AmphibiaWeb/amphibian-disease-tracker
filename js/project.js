
/*
 * Project-specific code
 */
var checkProjectAuthorization, postAuthorizeRender, renderEmail, showEmailField,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
      console.info("Non logged-in user");
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
  html = "<div class=\"row\">\n  <paper-input readonly class=\"col-xs-8 col-md-11\" label=\"Contact Email\" value=\"" + email + "\"></paper-input>\n  <div class=\"col-xs-4 col-md-1\">\n    <paper-fab icon=\"communication:email\" class=\"click materialblue\" id=\"contact-email-send\" data-href=\"mailto:" + email + "\"></paper-fab>\n  </div>\n</div>";
  $("#email-fill").replaceWith(html);
  bindClicks("#contact-email-send");
  return false;
};

postAuthorizeRender = function(projectData) {
  var apiPostSqlQuery, args, authorData, cartoData, cartoQuery, cartoTable, editButton, i, len, mapHtml, point, poly, ref, usedPoints;
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
  cartoTable = cartoData.table;
  poly = cartoData.bounding_polygon;
  mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
  usedPoints = new Array();
  ref = poly.paths;
  for (i = 0, len = ref.length; i < len; i++) {
    point = ref[i];
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
    var error, geoJson, googleMap, k, lat, lng, marker, note, ref1, row, rows, taxa, truncateLength, workingMap;
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
    truncateLength = 0 - "</google-map>".length;
    workingMap = geo.googleMapWebComponent.slice(0, truncateLength);
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
        console.warn(taxa + " was changed from " + row.originaltaxa);
        note = "(<em>" + row.originaltaxa + "</em>)";
      }
      marker = "<google-map-marker latitude=\"" + lat + "\" longitude=\"" + lng + "\">\n  <p>\n    <em>" + row.genus + " " + row.specificepithet + "</em> " + note + "\n    <br/>\n    Tested <strong>" + row.diseasedetected + "</strong> for " + row.diseasetested + "\n  </p>\n</google-map-marker>";
      mapHtml += marker;
    }
    googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + project.lat + "\" longitude=\"" + project.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui>\n  " + mapHtml + "\n</google-map>";
    $("#auth-block").append(googleMap);
    return stopLoad();
  }).error(function(result, status) {
    console.error(result, status);
    return stopLoadError("Couldn't render map");
  });
  return false;
};

$(function() {
  _adp.projectId = uri.o.param("id");
  return checkProjectAuthorization();
});

//# sourceMappingURL=maps/project.js.map
