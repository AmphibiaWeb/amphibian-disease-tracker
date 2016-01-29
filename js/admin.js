
/*
 * The main coffeescript file for administrative stuff
 * Bootstraps some of the other loads, sets up parameters, and contains
 * code for the main creator/uploader.
 *
 * Triggered from admin-page.html
 *
 * Compiles into ./js/admin.js via ./Gruntfile.coffee
 *
 * For administrative editor code, look at ./coffee/admin-editor.coffee
 * For adminstrative viewer code, look at ./coffee/admin-viewer.coffee
 *
 * @path ./coffee/admin.coffee
 * @author Philip Kahn
 */
var _7zHandler, alertBadProject, bootstrapTransect, bootstrapUploader, csvHandler, dataAttrs, dataFileParams, excelHandler, finalizeData, getCanonicalDataCoords, getInfoTooltip, getTableCoordinates, helperDir, imageHandler, loadCreateNewProject, loadEditor, loadProject, loadProjectBrowser, mapAddPoints, mapOverlayPolygon, newGeoDataHandler, pointStringToLatLng, pointStringToPoint, populateAdminActions, removeDataFile, resetForm, singleDataFileHelper, startAdminActionHelper, user, verifyLoginCredentials, zipHandler,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.adminParams = new Object();

adminParams.domain = "amphibiandisease";

adminParams.apiTarget = "admin-api.php";

adminParams.adminPageUrl = "https://" + adminParams.domain + ".org/admin-page.html";

adminParams.loginDir = "admin/";

adminParams.loginApiTarget = adminParams.loginDir + "async_login_handler.php";

dataFileParams = new Object();

dataFileParams.hasDataFile = false;

dataFileParams.fileName = null;

dataFileParams.filePath = null;

dataAttrs = new Object();

helperDir = "helpers/";

user = $.cookie(adminParams.domain + "_link");

window.loadAdminUi = function() {

  /*
   * Main wrapper function. Checks for a valid login state, then
   * fetches/draws the page contents if it's OK. Otherwise, boots the
   * user back to the login page.
   */
  var e;
  try {
    verifyLoginCredentials(function(data) {
      var articleHtml;
      articleHtml = "<h3>\n  Welcome, " + ($.cookie(adminParams.domain + "_name")) + "\n  <span id=\"pib-wrapper-settings\" class=\"pib-wrapper\" data-toggle=\"tooltip\" title=\"User Settings\" data-placement=\"bottom\">\n    <paper-icon-button icon='icons:settings-applications' class='click' data-href='" + data.login_url + "'></paper-icon-button>\n  </span>\n\n</h3>\n<section id='admin-actions-block' class=\"row center-block text-center\">\n  <div class='bs-callout bs-callout-info'>\n    <p>Please be patient while the administrative interface loads.</p>\n  </div>\n</section>";
      $("main #main-body").before(articleHtml);
      populateAdminActions();
      bindClicks();
      return false;
    });
  } catch (_error) {
    e = _error;
    $("main #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>");
  }
  return false;
};

populateAdminActions = function() {
  var adminActions;
  adminActions = "<paper-button id=\"new-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:add\"></iron-icon>\n    Create New Project\n</paper-button>\n<paper-button id=\"edit-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:create\"></iron-icon>\n    Edit Existing Project\n</paper-button>\n<paper-button id=\"view-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:visibility\"></iron-icon>\n    View All My Projects\n</paper-button>";
  $("#admin-actions-block").html(adminActions);
  $("#show-actions").remove();
  $("main #main-body").empty();
  $("#new-project").click(function() {
    return loadCreateNewProject();
  });
  $("#edit-project").click(function() {
    return loadEditor();
  });
  return $("#view-project").click(function() {
    return loadProjectBrowser();
  });
};

verifyLoginCredentials = function(callback) {

  /*
   * Checks the login credentials against the server.
   * This should not be used in place of sending authentication
   * information alongside a restricted action, as a malicious party
   * could force the local JS check to succeed.
   * SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
   */
  var args, hash, link, secret;
  hash = $.cookie(adminParams.domain + "_auth");
  secret = $.cookie(adminParams.domain + "_secret");
  link = $.cookie(adminParams.domain + "_link");
  args = "hash=" + hash + "&secret=" + secret + "&dblink=" + link;
  $.post(adminParams.loginApiTarget, args, "json").done(function(result) {
    if (result.status === true) {
      return callback(result);
    } else {
      return goTo(result.login_url);
    }
  }).fail(function(result, status) {
    $("main #main-body").html("<div class='bs-callout-danger bs-callout'><h4>Couldn't verify login</h4><p>There's currently a server problem. Try back again soon.</p></div>");
    console.log(result, status);
    return false;
  });
  return false;
};

startAdminActionHelper = function() {
  var showActionsHtml;
  $("#admin-actions-block").empty();
  showActionsHtml = "<span id=\"pib-wrapper-dashboard\" class=\"pib-wrapper\" data-toggle=\"tooltip\" title=\"Administration Home\" data-placement=\"bottom\">\n  <paper-icon-button icon=\"icons:dashboard\" class=\"admin-action\" id=\"show-actions\">\n  </paper-icon-button>\n</span>";
  $("#pib-wrapper-settings").after(showActionsHtml);
  return $("#show-actions").click(function() {
    $(this).tooltip("hide");
    $(".tooltip").tooltip("hide");
    return populateAdminActions();
  });
};

getInfoTooltip = function(message) {
  var html;
  if (message == null) {
    message = "No Message Provided";
  }
  html = "<div class=\"col-xs-1 adjacent-info\">\n  <span class=\"glyphicon glyphicon-info-sign\" data-toggle=\"tooltip\" title=\"" + message + "\"></span>\n</div>";
  return html;
};

alertBadProject = function(projectId) {
  projectId = projectId != null ? "project " + projectId : "this project";
  stopLoadError("Sorry, " + projectId + " doesn't exist");
  return false;
};

loadCreateNewProject = function() {
  var html;
  startAdminActionHelper();
  html = "<h2 class=\"new-title col-xs-12\">Project Title</h2>\n<paper-input label=\"Project Title\" id=\"project-title\" class=\"project-field col-md-6 col-xs-12\" required auto-validate data-field=\"project_title\"></paper-input>\n<h2 class=\"new-title col-xs-12\">Project Parameters</h2>\n<section class=\"project-inputs clearfix col-xs-12\">\n  <div class=\"row\">\n    <paper-input label=\"Primary Pathogen Studied\" id=\"project-disease\" class=\"project-field col-md-6 col-xs-11\" required auto-validate data-field=\"disease\"></paper-input>" + (getInfoTooltip("Bd, Bsal, or other")) + "\n    <paper-input label=\"Pathogen Strain\" id=\"project-disease-strain\" class=\"project-field col-md-6 col-xs-11\" data-field=\"disease_strain\"></paper-input>" + (getInfoTooltip("For example, Hepatitus A, B, C would enter the appropriate letter here")) + "\n    <paper-input label=\"Project Reference\" id=\"reference-id\" class=\"project-field col-md-6 col-xs-11\" data-field=\"reference_id\"></paper-input>\n    " + (getInfoTooltip("E.g.  a DOI or other reference")) + "\n    <paper-input label=\"Publication DOI\" id=\"pub-doi\" class=\"project-field col-md-6 col-xs-11\" data-field=\"publication\"></paper-input>\n    <h2 class=\"new-title col-xs-12\">Lab Parameters</h2>\n    <paper-input label=\"Project PI\" id=\"project-pi\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate data-field=\"pi_lab\"></paper-input>\n    <paper-input label=\"Project Contact\" id=\"project-author\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate></paper-input>\n    <gold-email-input label=\"Contact Email\" id=\"author-email\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate></gold-email-input>\n    <paper-input label=\"Diagnostic Lab\" id=\"project-lab\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate></paper-input>\n    <h2 class=\"new-title col-xs-12\">Project Notes</h2>\n    <iron-autogrow-textarea id=\"project-notes\" class=\"project-field col-md-6 col-xs-11\" rows=\"3\"></iron-autogrow-textarea data-field=\"sample_notes\">" + (getInfoTooltip("Project notes or brief abstract")) + "\n    <h2 class=\"new-title col-xs-12\">Data Permissions</h2>\n    <div class=\"col-xs-12\">\n      <span class=\"toggle-off-label iron-label\">Private Dataset</span>\n      <paper-toggle-button id=\"data-encumbrance-toggle\" class=\"red\">Public Dataset</paper-toggle-button>\n      <p><strong>Smart selector here for registered users</strong>, only show when \"private\" toggle set</p>\n    </div>\n    <h2 class=\"new-title col-xs-12\">Project Area of Interest</h2>\n    <div class=\"col-xs-12\">\n      <p>\n        This represents the approximate collection region for your samples.\n        <strong>\n          Leave blank for a bounding box to be calculated from your sample sites\n        </strong>.\n      </p>\n      <span class=\"toggle-off-label iron-label\">Locality Name</span>\n      <paper-toggle-button id=\"transect-input-toggle\">Coordinate List</paper-toggle-button>\n    </div>\n    <p id=\"transect-instructions\" class=\"col-xs-12\"></p>\n    <div id=\"transect-input\" class=\"col-md-6 col-xs-12\">\n    </div>\n    <div id=\"carto-rendered-map\" class=\"col-md-6\">\n      <div id=\"carto-map-container\" class=\"carto-map map\">\n      </div>\n    </div>\n    <div class=\"col-xs-12\">\n      <br/>\n      <paper-checkbox checked id=\"has-data\">My project already has data</paper-checkbox>\n      <br/>\n    </div>\n  </div>\n</section>\n<section id=\"uploader-container-section\" class=\"data-section col-xs-12\">\n  <h2 class=\"new-title\">Uploading your project data</h2>\n  <p>Drag and drop as many files as you need below. </p>\n  <p>\n    To save your project, we need at least one file with structured data containing coordinates.\n    Please note that the data <strong>must</strong> have a header row,\n    and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>elevation</code>, and <code>coordinateUncertaintyInMeters</code>.\n  </p>\n  <div class=\"alert alert-info\" role=\"alert\">\n    We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href=\"http://biscicol.org/biocode-fims/templates.jsp\" class=\"newwindow alert-link\">biscicol.org <span class=\"glyphicon glyphicon-new-window\"></span></a>. Your data will be validated with the same service.\n  </div>\n  <div class=\"alert alert-warning\" role=\"alert\">\n    <strong>If the data is in Excel</strong>, ensure that it is in a single-sheet workbook. Data across multiple sheets in one workbook may be improperly processed.\n  </div>\n</section>\n<section class=\"project-inputs clearfix data-section col-xs-12\">\n  <div class=\"row\">\n    <h2 class=\"new-title col-xs-12\">Project Data Summary</h2>\n    <h3 class=\"new-title col-xs-12\">Calculated Data Parameters</h3>\n    <paper-input label=\"Samples Counted\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"samplecount\" readonly type=\"number\" data-field=\"disease_samples\"></paper-input>\n    <paper-input label=\"Positive Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"positive-samples\" readonly type=\"number\" data-field=\"disease_positive\"></paper-input>\n    <paper-input label=\"Negative Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"negative-samples\" readonly type=\"number\" data-field=\"disease_negative\"></paper-input>\n    <paper-input label=\"No Confidence Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"no_confidence-samples\" readonly type=\"number\" data-field=\"disease_no_confidence\"></paper-input>\n    <paper-input label=\"Disease Morbidity\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"morbidity-count\" readonly type=\"number\" data-field=\"disease_morbidity\"></paper-input>\n    <paper-input label=\"Disease Mortality\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"mortality-count\" readonly type=\"number\" data-field=\"disease_mortality\"></paper-input>\n    <p class=\"col-xs-12\">Etc</p>\n  </div>\n</section>\n<section id=\"submission-section col-xs-12\">\n  <div class=\"pull-right\">\n    <button id=\"upload-data\" class=\"btn btn-success click\" data-function=\"finalizeData\"><iron-icon icon=\"icons:lock-open\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Private Project</button>\n    <button id=\"reset-data\" class=\"btn btn-danger click\" data-function=\"resetForm\">Reset Form</button>\n  </div>\n</section>";
  $("main #main-body").append(html);
  bootstrapUploader();
  bootstrapTransect();
  $("#has-data").on("iron-change", function() {
    if (!$(this).get(0).checked) {
      $(".data-section").attr("hidden", "hidden");
      return $(".label-with-data").attr("hidden", "hidden");
    } else {
      $(".data-section").removeAttr("hidden");
      return $(".label-with-data").removeAttr("hidden");
    }
  });
  $("#data-encumbrance-toggle").on("iron-change", function() {
    var buttonLabel;
    buttonLabel = p$("#data-encumbrance-toggle").checked ? "<iron-icon icon=\"social:public\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Public Project" : "<iron-icon icon=\"icons:lock-open\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Private Project";
    return $("#upload-data").html(buttonLabel);
  });
  bindClicks();
  return false;
};

finalizeData = function() {

  /*
   * Make sure everythign is uploaded, validate, and POST to the server
   */
  var args, authorData, cartoData, center, dataCheck, el, input, key, l, len, postData, ref, uniqueId;
  startLoad();
  dataCheck = true;
  $("[required]").each(function() {
    var val;
    try {
      val = $(this).val();
      if (isNull(val)) {
        $(this).get(0).focus();
        dataCheck = false;
        return false;
      }
    } catch (_error) {}
  });
  if (!dataCheck) {
    stopLoadError("Please fill out all required fields");
    return false;
  }
  postData = new Object();
  ref = $(".project-field");
  for (l = 0, len = ref.length; l < len; l++) {
    el = ref[l];
    if ($(el).hasClass("iron-autogrow-textarea-0")) {
      input = $($(el).get(0).textarea).val();
    } else {
      input = $(el).val();
    }
    key = $(el).attr("data-field");
    if (!isNull(key)) {
      if ($(el).attr("type") === "number") {
        postData[key] = toInt(input);
      } else {
        postData[key] = input;
      }
    }
  }
  center = getMapCenter(geo.boundingBox);
  postData.lat = center.lat;
  postData.lng = center.lng;
  postData.author = $.cookie(adminParams.domain + "_link");
  authorData = {
    name: "",
    affiliation: "",
    lab: "",
    entry_date: ""
  };
  postData.author_data = JSON.stringify(authorData);
  cartoData = {
    table: geo.dataTable
  };
  postData.carto_id = JSON.stringify(cartoData);
  uniqueId = md5("" + geo.dataTable + postData.author + (Date.now()));
  postData.project_id = uniqueId;
  postData["public"] = p$("#data-encumbrance-toggle").checked;
  args = "perform=new&data=" + (jsonTo64(postData));
  console.info("Data object constructed:", postData);
  return $.post(adminParams.apiTarget, args, "json").done(function(result) {
    if (result.status === true) {
      toastStatusMessage("Data successfully saved to server (Warning: Parsing incomplete! Test Mode!)");
      bsAlert("Project ID #<strong>" + postData.project_id + "</strong> created", "success");
      stopLoad();
    } else {
      console.error(result.error.error);
      console.log(result);
      stopLoadError(result.human_error);
    }
    return false;
  }).error(function(result, status) {
    stopLoadError("There was a problem saving your data. Please try again");
    return false;
  });
};

resetForm = function() {

  /*
   * Kill it dead
   */
  return foo();
};

getTableCoordinates = function(table) {
  if (table == null) {
    table = "tdf0f1bc730325de59d48a5c80df45931_6d6d454828c05e8ceea03c99cc5f547e52fcb5fb";
  }

  /*
   *
   *
   * Sample:
   * https://tigerhawkvok.cartodb.com/api/v2/sql?q=SELECT+ST_AsText(the_geom)+FROM+t62b61b0091e633029be9332b5f20bf74_6d6d454828c05e8ceea03c99cc5f547e52fcb5fb&api_key=4837dd9b4df48f6f7ca584bd1c0e205d618bd723
   */
  return false;
};

pointStringToLatLng = function(pointString) {

  /*
   * Take point of form
   *
   * "POINT(37.878086 37.878086)"
   *
   * and return a json obj
   */
  var pointArr, pointObj, pointSSV;
  if (!pointString.search("POINT" === 0)) {
    console.warn("Invalid point string");
    return false;
  }
  pointSSV = pointString.slice(6, -1);
  pointArr = pointSSV.split(" ");
  pointObj = {
    lat: pointArr[0],
    lng: pointArr[1]
  };
  return pointObj;
};

pointStringToPoint = function(pointString) {

  /*
   * Take point of form
   *
   * "POINT(37.878086 37.878086)"
   *
   * and return a json obj
   */
  var point, pointArr, pointSSV;
  if (!pointString.search("POINT" === 0)) {
    console.warn("Invalid point string");
    return false;
  }
  pointSSV = pointString.slice(6, -1);
  pointArr = pointSSV.split(" ");
  point = new Point(pointArr[0], pointArr[1]);
  return point;
};

bootstrapTransect = function() {

  /*
   * Load up the region of interest UI into the DOM, and bind all the
   * events, and set up helper functions.
   */
  var geocodeEvent, setupTransectUi;
  window.geocodeLookupCallback = function() {

    /*
     * Reverse geocode locality search
     *
     */
    var geocoder, locality, request;
    startLoad();
    locality = p$("#locality-input").value;
    geocoder = new google.maps.Geocoder();
    request = {
      address: locality
    };
    return geocoder.geocode(request, function(result, status) {
      var bbEW, bbNS, boundingBox, bounds, doCallback, e, lat, lng, loc;
      if (status === google.maps.GeocoderStatus.OK) {
        console.info("Google said:", result);
        if (!$("#locality-lookup-result").exists()) {
          $("#carto-rendered-map").prepend("<div class=\"alert alert-info alert-dismissable\" role=\"alert\" id=\"locality-lookup-result\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>Location Found</strong>: <span class=\"lookup-name\"></span>\n</div>");
        }
        $("#locality-lookup-result .lookup-name").text(result[0].formatted_address);
        loc = result[0].geometry.location;
        lat = loc.lat();
        lng = loc.lng();
        bounds = result[0].geometry.viewport;
        try {
          bbEW = bounds.N;
          bbNS = bounds.j;
          boundingBox = {
            nw: [bbEW.j, bbNS.N],
            ne: [bbEW.j, bbNS.j],
            se: [bbEW.N, bbNS.N],
            sw: [bbEW.N, bbNS.j]
          };
        } catch (_error) {
          e = _error;
          console.warn("Danger: There was an error calculating the bounding box (" + e.message + ")");
          console.warn(e.stack);
          console.info("Got bounds", bounds);
          console.info("Got geometry", result[0].geometry);
        }
        console.info("Got bounds: ", [lat, lng], boundingBox);
        geo.boundingBox = boundingBox;
        doCallback = function() {
          return geo.renderMapHelper(boundingBox, lat, lng);
        };
        return loadJS("https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false);
      } else {
        return stopLoadError("Couldn't find location: " + status);
      }
    });
  };
  geo.renderMapHelper = function(overlayBoundingBox, centerLat, centerLng) {
    var coords, e, i, k, options, totalLat, totalLng;
    if (overlayBoundingBox == null) {
      overlayBoundingBox = geo.boundingBox;
    }

    /*
     * Helper function to consistently render the map
     *
     * @param Object overlayBoundingBox -> an object with values of
     * [lat,lng] arrays
     * @param float centerLat -> the centering for the latitude
     * @param float centerLng -> the centering for the longitude
     */
    startLoad();
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
      window.recallMapHelper = function() {
        return geo.renderMapHelper(overlayBoundingBox, centerLat, centerLng);
      };
      loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=recallMapHelper");
      return false;
    }
    try {
      geo.boundingBox = overlayBoundingBox;
      if (typeof centerLat !== "number") {
        i = 0;
        totalLat = 0.0;
        for (k in overlayBoundingBox) {
          coords = overlayBoundingBox[k];
          ++i;
          totalLat += coords[0];
          console.info(coords, i, totalLat);
        }
        centerLat = toFloat(totalLat) / toFloat(i);
      }
      if (typeof centerLng !== "number") {
        i = 0;
        totalLng = 0.0;
        for (k in overlayBoundingBox) {
          coords = overlayBoundingBox[k];
          ++i;
          totalLng += coords[1];
        }
        centerLng = toFloat(totalLng) / toFloat(i);
      }
      centerLat = toFloat(centerLat);
      centerLng = toFloat(centerLng);
      options = {
        cartodb_logo: false,
        https: true,
        mobile_layout: true,
        gmaps_base_type: "hybrid",
        center_lat: centerLat,
        center_lon: centerLng,
        zoom: getMapZoom(overlayBoundingBox)
      };
      geo.mapParams = options;
      $("#carto-map-container").empty();
      return createMap(null, "carto-map-container", options, function(layer, map) {
        var e;
        try {
          mapOverlayPolygon(overlayBoundingBox);
          stopLoad();
        } catch (_error) {
          e = _error;
          console.error("There was an error drawing your bounding box - " + e.emssage);
          stopLoadError("There was an error drawing your bounding box - " + e.emssage);
        }
        return false;
      });
    } catch (_error) {
      e = _error;
      console.error("There was an error rendering the map - " + e.message);
      return stopLoadError("There was an error rendering the map - " + e.message);
    }
  };
  geocodeEvent = function() {

    /*
     * Event handler for the geocoder
     */
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
      loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=geocodeLookupCallback");
    } else {
      geocodeLookupCallback();
    }
    return false;
  };
  (setupTransectUi = function() {

    /*
     * Create the toggles and instructions, then place them into the DOM
     */
    var instructions, transectInput;
    if (p$("#transect-input-toggle").checked) {
      instructions = "Please input a list of coordinates, in the form <code>lat, lng</code>, with one set on each line. <strong>Please press <kbd>enter</kbd> to insert a new line after your last coordinate</strong>.";
      transectInput = "<iron-autogrow-textarea id=\"coord-input\" class=\"\" rows=\"3\"></iron-autogrow-textarea>";
    } else {
      instructions = "Please enter a name of a locality";
      transectInput = "<paper-input id=\"locality-input\" label=\"Locality\" class=\"pull-left\"></paper-input> <paper-icon-button class=\"pull-left\" id=\"do-search-locality\" icon=\"icons:search\"></paper-icon-button>";
    }
    $("#transect-instructions").html(instructions);
    $("#transect-input").html(transectInput);
    if (p$("#transect-input-toggle").checked) {
      $(p$("#coord-input").textarea).keyup((function(_this) {
        return function(e) {
          var bbox, coord, coordPair, coordSplit, coords, coordsRaw, doCallback, i, kc, l, len, len1, lines, m, tmp, val;
          kc = e.keyCode ? e.keyCode : e.which;
          if (kc === 13) {
            val = $(p$("#coord-input").textarea).val();
            lines = val.split("\n").length;
            if (lines > 3) {
              coords = new Array();
              coordsRaw = val.split("\n");
              console.info("Raw coordinate info:", coordsRaw);
              for (l = 0, len = coordsRaw.length; l < len; l++) {
                coordPair = coordsRaw[l];
                if (coordPair.search(",") > 0 && !isNull(coordPair)) {
                  coordSplit = coordPair.split(",");
                  if (coordSplit.length === 2) {
                    tmp = [toFloat(coordSplit[0]), toFloat(coordSplit[1])];
                    coords.push(tmp);
                  }
                }
              }
              if (coords.length >= 3) {
                console.info("Coords:", coords);
                i = 0;
                bbox = new Object();
                for (m = 0, len1 = coords.length; m < len1; m++) {
                  coord = coords[m];
                  ++i;
                  bbox[i] = coord;
                }
                doCallback = function() {
                  return geo.renderMapHelper(bbox);
                };
                geo.boundingBox = bbox;
                return loadJS("https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false);
              } else {
                return console.warn("There is one or more invalid coordinates preventing the UI from being shown.");
              }
            }
          }
        };
      })(this));
    } else {
      $("#locality-input").keyup(function(e) {
        var kc;
        kc = e.keyCode ? e.keyCode : e.which;
        if (kc === 13) {
          return geocodeEvent();
        }
      });
      $("#do-search-locality").click(function() {
        return geocodeEvent();
      });
    }
    return false;
  })();
  $("#transect-input-toggle").on("iron-change", function() {
    return setupTransectUi();
  });
  return false;
};

mapOverlayPolygon = function(polygonObjectParams, regionProperties, overlayOptions, map) {
  var chAltPoints, chPoints, chSortedPoints, coordinateArray, cpHull, e, eastCoord, gMapPaths, gMapPathsAlt, gMapPoly, gPolygon, geoJSON, geoMultiPoly, k, mpArr, northCoord, points, southCoord, temp, westCoord;
  if (regionProperties == null) {
    regionProperties = null;
  }
  if (overlayOptions == null) {
    overlayOptions = new Object();
  }
  if (map == null) {
    map = geo.googleMap;
  }

  /*
   *
   *
   * @param polygonObjectParams ->
   *  an array of point arrays: http://geojson.org/geojson-spec.html#multipolygon
   */
  gMapPoly = new Object();
  if (typeof polygonObjectParams !== "object") {
    console.warn("mapOverlayPolygon() got an invalid data type to overlay!");
    return false;
  }
  if (typeof overlayOptions !== "object") {
    overlayOptions = new Object();
  }
  if (overlayOptions.fillColor == null) {
    overlayOptions.fillColor = "#ff7800";
  }
  gMapPoly.fillColor = overlayOptions.fillColor;
  gMapPoly.fillOpacity = 0.35;
  if (typeof regionProperties !== "object") {
    regionProperties = null;
  }
  console.info("Should overlay polygon from bounds here");
  if ($("#carto-map-container").exists() && (geo.cartoMap != null)) {
    mpArr = new Array();
    chPoints = new Array();
    chAltPoints = new Array();
    gMapPaths = new Array();
    gMapPathsAlt = new Array();
    northCoord = -90;
    southCoord = 90;
    eastCoord = -180;
    westCoord = 180;
    for (k in polygonObjectParams) {
      points = polygonObjectParams[k];
      mpArr.push(points);
      temp = new Object();
      temp.lat = points[0];
      temp.lng = points[1];
      chAltPoints.push(new fPoint(temp.lat, temp.lng));
      gMapPathsAlt.push(new Point(temp.lat, temp.lng));
    }
    gMapPaths = sortPoints(gMapPathsAlt);
    chPoints = sortPoints(gMapPathsAlt, false);
    chSortedPoints = chAltPoints;
    chSortedPoints.sort(sortPointY);
    chSortedPoints.sort(sortPointX);
    coordinateArray = new Array();
    coordinateArray.push(mpArr);
    try {
      cpHull = getConvexHullPoints(chSortedPoints);
    } catch (_error) {
      e = _error;
      console.error("Convex hull points CHP failed! - " + e.message);
      console.warn(e.stack);
      console.info(chSortedPoints);
    }
    console.info("Got hulls", cpHull);
    console.info("Sources", chPoints, chAltPoints, chSortedPoints);
    gMapPoly.paths = cpHull;
    geoMultiPoly = {
      type: "Polygon",
      coordinates: coordinateArray
    };
    geoJSON = {
      type: "Feature",
      properties: regionProperties,
      geometry: geoMultiPoly
    };
    console.info("Rendering GeoJSON MultiPolygon", geoMultiPoly);
    geo.geoJsonBoundingBox = geoJSON;
    geo.overlayOptions = overlayOptions;
    console.info("Rendering Google Maps polygon", gMapPoly);
    geo.canonicalBoundingBox = gMapPoly;
    gPolygon = new google.maps.Polygon(gMapPoly);
    if (geo.googlePolygon != null) {
      geo.googlePolygon.setMap(null);
    }
    geo.googlePolygon = gPolygon;
    gPolygon.setMap(map);
    if (!isNull(dataAttrs.coords || isNull(geo.dataTable))) {
      getCanonicalDataCoords(geo.dataTable);
    }
  } else {
    console.warn("There's no map yet! Can't overlay polygon");
  }
  return false;
};

mapAddPoints = function(pointArray, pointInfoArray, map) {
  var gmLatLng, i, infoWindow, infoWindows, iwConstructor, k, l, len, len1, m, marker, markerConstructor, markerContainer, markers, point, pointLatLng, ref, title;
  if (map == null) {
    map = geo.googleMap;
  }

  /*
   *
   *
   * @param array pointArray -> an array of geo.Point instances
   * @param array pointInfoArray -> An array of objects of type
   *   {"title":"Point Title","html":"Point infoWindow HTML"}
   *   If this is empty, no such popup will be added.
   * @param google.maps.Map map -> A google Map object
   */
  for (l = 0, len = pointArray.length; l < len; l++) {
    point = pointArray[l];
    if (!(point instanceof geo.Point)) {
      console.warn("Invalid datatype in array -- array must be constructed of Point objects");
      return false;
    }
  }
  markers = new Object();
  infoWindows = new Array();
  i = 0;
  for (m = 0, len1 = pointArray.length; m < len1; m++) {
    point = pointArray[m];
    title = pointInfoArray != null ? (ref = pointInfoArray[i]) != null ? ref.title : void 0 : "";
    pointLatLng = point.getObj();
    gmLatLng = new google.maps.LatLng(pointLatLng.lat, pointLatLng.lng);
    markerConstructor = {
      position: gmLatLng,
      map: map,
      title: title
    };
    marker = new google.maps.Marker(markerConstructor);
    markers[i] = {
      marker: marker
    };
    if (!isNull(title)) {
      iwConstructor = {
        content: pointInfoArray[i].html
      };
      infoWindow = new google.maps.InfoWindow(iwConstructor);
      markers[i].infoWindow = infoWindow;
      infoWindows.push(infoWindow);
    } else {
      console.info("Key " + i + " has no title in pointInfoArray", pointInfoArray[i]);
    }
    ++i;
  }
  if (!isNull(infoWindows)) {
    dataAttrs.coordInfoWindows = infoWindows;
    for (k in markers) {
      markerContainer = markers[k];
      marker = markerContainer.marker;
      marker.unbind("click");
      marker.self = marker;
      marker.iw = markerContainer.infoWindow;
      marker.iwk = k;
      marker.addListener("click", function() {
        var e;
        try {
          this.iw.open(map, this);
          return console.info("Opening infoWindow #" + this.iwk);
        } catch (_error) {
          e = _error;
          return console.error("Invalid infowindow @ " + this.iwk + "!", infoWindows, markerContainer, this.iw);
        }
      });
    }
    geo.markers = markers;
  }
  return markers;
};

getCanonicalDataCoords = function(table, callback) {
  if (callback == null) {
    callback = mapAddPoints;
  }

  /*
   * Fetch data coordinate points
   */
  if (isNull(table)) {
    console.error("A table must be specified!");
    return false;
  }
  if (typeof callback !== "function") {
    console.error("This function needs a callback function as the second argument");
    return false;
  }
  verifyLoginCredentials(function(data) {
    var apiPostSqlQuery, args, sqlQuery;
    sqlQuery = "SELECT ST_AsText(the_geom), genus, specificEpithet, infraspecificEpithet, dateIdentified, sampleMethod, diseaseDetected, diseaseTested, catalogNumber FROM " + table;
    apiPostSqlQuery = encodeURIComponent(encode64(sqlQuery));
    args = "action=fetch&sql_query=" + apiPostSqlQuery;
    return $.post("api.php", args, "json").done(function(result) {
      var cartoResponse, coords, i, info, point, ref, row, textPoint;
      cartoResponse = result.parsed_responses[0];
      coords = new Array();
      info = new Array();
      ref = cartoResponse.rows;
      for (i in ref) {
        row = ref[i];
        textPoint = row.st_astext;
        if (isNull(row.infraspecificepithet)) {
          row.infraspecificepithet = "";
        }
        point = pointStringToPoint(textPoint);
        data = {
          title: row.catalognumber + ": " + row.genus + " " + row.specificepithet + " " + row.infraspecificepithet,
          html: "<p>\n  <span class=\"sciname italic\">" + row.genus + " " + row.specificepithet + " " + row.infraspecificepithet + "</span> collected on " + row.dateidentified + "\n</p>\n<p>\n  <strong>Status:</strong>\n  Sampled by " + row.samplemethod + ", disease status " + row.diseasedetected + " for " + row.diseasetested + "\n</p>"
        };
        coords.push(point);
        info.push(data);
      }
      dataAttrs.coords = coords;
      dataAttrs.markerInfo = info;
      return callback(coords, info);
    }).error(function(result, status) {
      if ((dataAttrs != null ? dataAttrs.coords : void 0) != null) {
        return callback(dataAttrs.coords, dataAttrs.markerInfo);
      } else {
        stopLoadError("Couldn't get bounding coordinates from data");
        return console.error("No valid coordinates accessible!");
      }
    });
  });
  return false;
};

bootstrapUploader = function(uploadFormId) {
  var html, selector;
  if (uploadFormId == null) {
    uploadFormId = "file-uploader";
  }

  /*
   * Bootstrap the file uploader into existence
   */
  selector = "#" + uploadFormId;
  if (!$(selector).exists()) {
    html = "<form id=\"" + uploadFormId + "-form\" class=\"col-md-4 clearfix\">\n  <p class=\"visible-xs-block\">Tap the button to upload a file</p>\n  <fieldset class=\"hidden-xs\">\n    <legend>Upload Files</legend>\n    <div id=\"" + uploadFormId + "\" class=\"media-uploader outline media-upload-target\">\n    </div>\n  </fieldset>\n</form>";
    $("main #uploader-container-section").append(html);
    $(selector).submit(function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
  }
  return verifyLoginCredentials(function() {
    if (window.dropperParams == null) {
      window.dropperParams = new Object();
    }
    window.dropperParams.uploadPath = "uploaded/" + user + "/";
    loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
      console.info("Loaded drag drop helper");
      return window.dropperParams.postUploadHandler = function(file, result) {

        /*
         * The callback function for handleDragDropImage
         *
         * The "file" object contains information about the uploaded file,
         * such as name, height, width, size, type, and more. Check the
         * console logs in the demo for a full output.
         *
         * The result object contains the results of the upload. The "status"
         * key is true or false depending on the status of the upload, and
         * the other most useful keys will be "full_path" and "thumb_path".
         *
         * When invoked, it calls the "self" helper methods to actually do
         * the file sending.
         */
        var e, linkPath, longType, mediaType, pathPrefix, previewHtml;
        window.dropperParams.dropzone.removeAllFiles();
        if (typeof result !== "object") {
          console.error("Dropzone returned an error - " + result);
          toastStatusMessage("There was a problem with the server handling your image. Please try again.");
          return false;
        }
        if (result.status !== true) {
          if (result.human_error == null) {
            result.human_error = "There was a problem uploading your image.";
          }
          toastStatusMessage("" + result.human_error);
          console.error("Error uploading!", result);
          return false;
        }
        try {
          console.info("Server returned the following result:", result);
          console.info("The script returned the following file information:", file);
          pathPrefix = "helpers/js-dragdrop/uploaded/" + user + "/";
          result.full_path = result.wrote_file;
          result.thumb_path = result.wrote_thumb;
          mediaType = result.mime_provided.split("/")[0];
          longType = result.mime_provided.split("/")[1];
          linkPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.full_path : "" + pathPrefix + result.thumb_path;
          previewHtml = (function() {
            switch (mediaType) {
              case "image":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + result.full_path + "\">\n  <img src=\"" + linkPath + "\" alt='Uploaded Image' class=\"img-circle thumb-img img-responsive\"/>\n    <p class=\"text-muted\">\n      " + file.name + " -> " + result.full_path + "\n  (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n    Original Image\n  </a>)\n    </p>\n</div>";
              case "audio":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + result.full_path + "\">\n  <audio src=\"" + linkPath + "\" controls preload=\"auto\">\n    <span class=\"glyphicon glyphicon-music\"></span>\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + result.full_path + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              case "video":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + result.full_path + "\">\n  <video src=\"" + linkPath + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + result.thumb_path + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + result.full_path + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              default:
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + result.full_path + "\">\n  <span class=\"glyphicon glyphicon-file\"></span>\n  <p class=\"text-muted\">" + file.name + " -> " + result.full_path + "</p>\n</div>";
            }
          })();
          $(window.dropperParams.dropTargetSelector).before(previewHtml);
          switch (mediaType) {
            case "application":
              console.info("Checking " + longType + " in application");
              switch (longType) {
                case "vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                case "vnd.ms-excel":
                  return excelHandler(linkPath);
                case "zip":
                case "x-zip-compressed":
                  if (file.type === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || linkPath.split(".").pop() === "xlsx") {
                    return excelHandler(linkPath);
                  } else {
                    return zipHandler(linkPath);
                  }
                  break;
                case "x-7z-compressed":
                  return _7zHandler(linkPath);
              }
              break;
            case "text":
              return csvHandler();
            case "image":
              return imageHandler();
          }
        } catch (_error) {
          e = _error;
          return toastStatusMessage("Your file uploaded successfully, but there was a problem in the post-processing.");
        }
      };
    });
    return false;
  });
};

singleDataFileHelper = function(newFile, callback) {
  var html;
  if (typeof callback !== "function") {
    console.error("Second argument must be a function");
    return false;
  }
  if (dataFileParams.hasDataFile === true) {
    if ($("#single-data-file-modal").exists()) {
      $("#single-data-file-modal").remove();
    }
    html = "<paper-dialog modal id=\"single-data-file-modal\">\n  <h2>You can only have one primary data file</h2>\n  <div>\n    Continuing will remove your previous one\n  </div>\n  <div class=\"buttons\">\n    <paper-button id=\"cancel-parse\">Cancel Upload</paper-button>\n    <paper-button id=\"overwrite\">Replace Previous</paper-button>\n  </div>\n</paper-dialog>";
    $("body").append(html);
    $("#cancel-parse").click(function() {
      removeDataFile(newFile, false);
      p$("#single-data-file-modal").close();
      return false;
    });
    $("#overwrite").click(function() {
      removeDataFile();
      p$("#single-data-file-modal").close();
      return callback();
    });
    return safariDialogHelper("#single-data-file-modal");
  } else {
    return callback();
  }
};

excelHandler = function(path, hasHeaders) {
  var args, correctedPath, helperApi;
  if (hasHeaders == null) {
    hasHeaders = true;
  }
  startLoad();
  toastStatusMessage("Processing ...");
  helperApi = helperDir + "excelHelper.php";
  correctedPath = path;
  if (path.search(helperDir !== -1)) {
    correctedPath = path.slice(helperDir.length);
  }
  console.info("Pinging for " + correctedPath);
  args = "action=parse&path=" + correctedPath;
  $.get(helperApi, args, "json").done(function(result) {
    console.info("Got result", result);
    return singleDataFileHelper(path, function() {
      var html, randomData, randomRow, rows;
      dataFileParams.hasDataFile = true;
      dataFileParams.fileName = path;
      dataFileParams.filePath = correctedPath;
      rows = Object.size(result.data);
      randomData = "";
      if (rows > 0) {
        randomRow = randomInt(1, rows) - 1;
        randomData = "\n\nHere's a random row: " + JSON.stringify(result.data[randomRow]);
      }
      html = "<pre>\nFrom upload, fetched " + rows + " rows." + randomData + "\n</pre>";
      newGeoDataHandler(result.data);
      return stopLoad();
    });
  }).fail(function(result, error) {
    console.error("Couldn't POST");
    console.warn(result, error);
    return stopLoadError();
  });
  return false;
};

csvHandler = function(path) {
  dataFileParams.hasDataFile = true;
  dataFileParams.fileName = path;
  dataFileParams.filePath = correctedPath;
  geoDataHandler();
  return false;
};

imageHandler = function(path) {
  foo();
  return false;
};

zipHandler = function(path) {
  foo();
  return false;
};

_7zHandler = function(path) {
  foo();
  return false;
};

removeDataFile = function(removeFile, unsetHDF) {
  var args, serverPath;
  if (removeFile == null) {
    removeFile = dataFileParams.fileName;
  }
  if (unsetHDF == null) {
    unsetHDF = true;
  }
  removeFile = removeFile.split("/").pop();
  if (unsetHDF) {
    dataFileParams.hasDataFile = false;
  }
  $(".uploaded-media[data-system-file='" + removeFile + "']").remove();
  serverPath = helperDir + "/js-dragdrop/uploaded/" + user + "/" + removeFile;
  args = "action=removefile&path=" + (encode64(removeFile)) + "&user=" + user;
  return false;
};

newGeoDataHandler = function(dataObject) {
  var cleanValue, column, coords, coordsPoint, d, data, date, daysFrom1900to1970, daysFrom1904to1970, e, fimsExtra, getCoordsFromData, k, month, n, parsedData, prettyHtml, projectIdentifier, row, rows, sampleRow, samplesMeta, secondsPerDay, t, tRow, totalData, value;
  if (dataObject == null) {
    dataObject = new Object();
  }

  /*
   * Data expected in form
   *
   * Obj {ROW_INDEX: {"col1":"data", "col2":"data"}}
   *
   * FIMS data format:
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
   *
   * Requires columns "decimalLatitude", "decimalLongitude", "coordinateUncertaintyInMeters", "alt"
   */
  try {
    try {
      sampleRow = dataObject[0];
    } catch (_error) {
      toastStatusMessage("Your data file was malformed, and could not be parsed. Please try again.");
      removeDataFile();
      return false;
    }
    if (!((sampleRow.decimalLatitude != null) && (sampleRow.decimalLongitude != null) && (sampleRow.coordinateUncertaintyInMeters != null) && (sampleRow.alt != null))) {
      toastStatusMessage("Data are missing required geo columns. Please reformat and try again.");
      console.info("Missing: ", sampleRow.decimalLatitude != null, sampleRow.decimalLongitude != null, sampleRow.coordinateUncertaintyInMeters != null, sampleRow.alt != null);
      removeDataFile();
      return false;
    }
    if (!(isNumber(sampleRow.decimalLatitude) && isNumber(sampleRow.decimalLongitude) && isNumber(sampleRow.coordinateUncertaintyInMeters) && isNumber(sampleRow.alt))) {
      toastStatusMessage("Data has invalid entries for geo columns. Please be sure they're all numeric and try again.");
      removeDataFile();
      return false;
    }
    rows = Object.size(dataObject);
    p$("#samplecount").value = rows;
    if (isNull($("#project-disease").val())) {
      p$("#project-disease").value = sampleRow.diseaseTested;
    }
    parsedData = new Object();
    dataAttrs.coords = new Array();
    dataAttrs.coordsFull = new Array();
    dataAttrs.fimsData = new Array();
    fimsExtra = new Object();
    for (n in dataObject) {
      row = dataObject[n];
      tRow = new Object();
      for (column in row) {
        value = row[column];
        switch (column) {
          case "ContactName":
          case "basisOfRecord":
          case "occurrenceID":
          case "institutionCode":
          case "collectionCode":
          case "labNumber":
          case "originalsource":
          case "datum":
          case "georeferenceSource":
          case "depth":
          case "Collector2":
          case "Collector3":
          case "verbatimLocality":
          case "Habitat":
          case "Test_Method":
          case "eventRemarks":
          case "quantityDetected":
          case "dilutionFactor":
          case "cycleTimeFirstDetection":
            fimsExtra[column] = value;
            break;
          case "specimenDisposition":
            column = "sampleDisposition";
            break;
          case "elevation":
            column = "alt";
            break;
          case "dateIdentified":
            try {
              if ((0 < value && value < 10e5)) {

                /*
                 * Excel is INSANE, and marks time as DAYS since 1900-01-01
                 * on Windows, and 1904-01-01 on OSX. Because reasons.
                 *
                 * Therefore, 2015-11-07 is "42315"
                 *
                 * The bounds of this check represent true Unix dates
                 * of
                 * Wed Dec 31 1969 16:16:40 GMT-0800 (Pacific Standard Time)
                 * to
                 * Wed Dec 31 1969 16:00:00 GMT-0800 (Pacific Standard Time)
                 *
                 * I hope you weren't collecting between 4 & 4:17 PM
                 * New Years Eve in 1969.
                 *
                 *
                 * This check will correct Excel dates until
                 * Sat Nov 25 4637 16:00:00 GMT-0800 (Pacific Standard Time)
                 *
                 * TODO: Fix before Thanksgiving 4637. Devs, you have
                 * 2,622 years. Don't say I didn't warn you.
                 */
                daysFrom1900to1970 = 25569;
                daysFrom1904to1970 = 24107;
                secondsPerDay = 86400;
                t = ((value - daysFrom1900to1970) * secondsPerDay) * 1000;
              } else {
                t = Date.parse(value);
              }
            } catch (_error) {
              t = Date.now();
            }
            d = new Date(t);
            date = d.getUTCDate();
            if (date < 10) {
              date = "0" + date;
            }
            month = d.getUTCMonth() + 1;
            if (month < 10) {
              month = "0" + month;
            }
            cleanValue = (d.getUTCFullYear()) + "-" + month + "-" + date;
            break;
          case "fatal":
            cleanValue = value.toBool();
            break;
          case "decimalLatitude":
          case "decimalLongitude":
          case "alt":
          case "coordinateUncertaintyInMeters":
            cleanValue = toFloat(value);
            break;
          case "diseaseDetected":
            if (isBool(value)) {
              cleanValue = value.toBool();
            } else {
              cleanValue = "NO_CONFIDENCE";
            }
            break;
          default:
            try {
              cleanValue = value.trim();
            } catch (_error) {
              cleanValue = value;
            }
        }
        tRow[column] = cleanValue;
      }
      coords = {
        lat: tRow.decimalLatitude,
        lng: tRow.decimalLongitude,
        alt: tRow.alt,
        uncertainty: tRow.coordinateUncertaintyMeters
      };
      coordsPoint = new Point(coords.lat, coords.lng);
      dataAttrs.coords.push(coordsPoint);
      dataAttrs.coordsFull.push(coords);
      dataAttrs.fimsData.push(fimsExtra);
      try {
        tRow.fimsExtra = JSON.stringify(fimsExtra);
      } catch (_error) {
        console.warn("Couldn't store FIMS extra data", fimsExtra);
      }
      parsedData[n] = tRow;
    }
    try {
      prettyHtml = JsonHuman.format(parsedData);
    } catch (_error) {
      e = _error;
      console.warn("Couldn't pretty set!");
      console.warn(e.stack);
      console.info(parsedData);
    }
    projectIdentifier = "t" + md5(p$("#project-title").value + $.cookie(uri.domain + "_link"));
    getCoordsFromData = function() {

      /*
       * We need to do some smart trimming in here for total inclusion
       * points ...
       */
      var coordsObj, i, j, l, len, sorted, textEntry;
      i = 0;
      j = new Object();
      sorted = sortPoints(dataAttrs.coords);
      textEntry = "";
      for (l = 0, len = sorted.length; l < len; l++) {
        coordsObj = sorted[l];
        j[i] = [coordsObj.lat, coordsObj.lng];
        textEntry += coordsObj.lat + "," + coordsObj.lng + "\n";
        ++i;
      }
      try {
        p$("#transect-input-toggle").checked = true;
        textEntry += "\n";
        $(p$("#coord-input").textarea).val(textEntry);
      } catch (_error) {}
      return j;
    };
    if (geo.boundingBox == null) {
      geo.boundingBox = getCoordsFromData();
    }
    samplesMeta = {
      mortality: 0,
      morbidity: 0,
      positive: 0,
      negative: 0,
      no_confidence: 0
    };
    for (k in parsedData) {
      data = parsedData[k];
      switch (data.diseaseDetected) {
        case true:
          samplesMeta.morbidity++;
          samplesMeta.positive++;
          break;
        case false:
          samplesMeta.negative++;
          break;
        case "NO_CONFIDENCE":
          samplesMeta.no_confidence++;
      }
      if (data.fatal) {
        samplesMeta.mortality++;
      }
    }
    p$("#positive-samples").value = samplesMeta.positive;
    p$("#negative-samples").value = samplesMeta.negative;
    p$("#no_confidence-samples").value = samplesMeta.no_confidence;
    p$("#morbidity-count").value = samplesMeta.morbidity;
    p$("#mortality-count").value = samplesMeta.mortality;
    totalData = {
      transectRing: geo.boundingBox,
      data: parsedData,
      samples: samplesMeta
    };
    dataAttrs.dataObj = totalData;
    geo.requestCartoUpload(totalData, projectIdentifier, "create", function(table) {
      return mapOverlayPolygon(totalData.transectRing);
    });
  } catch (_error) {
    e = _error;
    console.error(e.message);
    toastStatusMessage("There was a problem parsing your data");
  }
  return false;
};

$(function() {
  if ($("#next").exists()) {
    $("#next").unbind().click(function() {
      return openTab(adminParams.adminPageUrl);
    });
  }
  return loadJS("bower_components/bootstrap/dist/js/bootstrap.min.js", function() {
    return $("body").tooltip({
      selector: "[data-toggle='tooltip']"
    });
  });
});


/*
 * Split-out coffeescript file for adminstrative editor.
 *
 * This is included in ./js/admin.js via ./Gruntfile.coffee
 *
 * For adminstrative viewer code, look at ./coffee/admin-viewer.coffee
 *
 * @path ./coffee/admin-editor.coffee
 * @author Philip Kahn
 */

loadEditor = function() {

  /*
   * Load up the editor interface for projects with access
   */
  var editProject, showEditList;
  startAdminActionHelper();
  editProject = function(projectId) {

    /*
     * Load the edit interface for a specific project
     */
    startAdminActionHelper();
    startLoad();
    verifyLoginCredentials(function(credentialResult) {
      var args, opid, userDetail;
      userDetail = credentialResult.detail;
      user = userDetail.uid;
      opid = projectId;
      projectId = encodeURIComponent(projectId);
      args = "perform=get&project=" + projectId;
      return $.post(adminParams.apiTarget, args, "json").done(function(result) {
        var e, error, html, icon, l, len, popManageUserAccess, project, ref, ref1, userHtml;
        try {
          if (result.status !== true) {
            error = (ref = result.human_error) != null ? ref : result.error;
            if (error == null) {
              error = "Unidentified Error";
            }
            stopLoadError("There was a problem loading your project (" + error + ")");
            return false;
          }
          if (result.user.has_edit_permissions !== true) {
            if (result.user.has_view_permissions || result.project["public"] === true) {
              loadProject(opid, "Ineligible to edit " + opid + ", loading as read-only");
              return false;
            }
            alertBadProject(opid);
            return false;
          }
          toastStatusMessage("Good user, would load editor for project");
          project = result.project;
          popManageUserAccess = function() {
            return verifyLoginCredentials(function(credentialResult) {
              var authorDisabled, dialogHtml, editDisabled, isAuthor, isEditor, isViewer, l, len, ref1, uid, userHtml, viewerDisabled;
              userHtml = "";
              ref1 = project.access_data.total;
              for (l = 0, len = ref1.length; l < len; l++) {
                user = ref1[l];
                isAuthor = user === project.access_data.author;
                isEditor = indexOf.call(project.access_data.editors_list, user) >= 0;
                isViewer = !isEditor;
                editDisabled = isEditor || isAuthor ? "disabled" : "data-toggle='tooltip' title='Make Editor'";
                viewerDisabled = isViewer || isAuthor ? "disabled" : "data-toggle='tooltip' title='Make Read-Only'";
                authorDisabled = isAuthor ? "disabled" : "data-toggle='tooltip' title='Grant Ownership'";
                uid = project.access_data.composite[user]["user_id"];
                theirHtml += "<paper-icon-button icon=\"image:edit\" " + editDisabled + " class=\"set-permission\" data-permission=\"edit\" data-user=\"" + uid + "\"> </paper-icon-button>\n<paper-icon-button icon=\"image:remove-red-eye\" " + viewerDisabled + " class=\"set-permission\" data-permission=\"read\" data-user=\"" + uid + "\"> </paper-icon-button>";
                if (result.user.is_author) {
                  theirHtml += "<paper-icon-button icon=\"social:person\" " + authorDisabled + " class=\"set-permission\" data-permission=\"author\" data-user=\"" + uid + "\"> </paper-icon-button>";
                }
                userHtml += "<li>" + theirHtml + "</li>";
              }
              userHtml = "<ul class=\"simple-list\">\n  " + userHtml + "\n</ul>";
              dialogHtml = "<paper-dialog modal id=\"user-setter-dialog\">\n  <paper-dialog-scrollable>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button class=\"add-user\"><iron-icon icon=\"social:person-add\"></iron-icon> Add User</paper-button>\n    <paper-button class=\"close-dialog\" dialog-dismiss>Done</paper-button>\n  </div>\n</paper-dialog>";
              $("#user-setter-dialog").remove();
              $("body").append(dialogHtml);
              $(".set-permission").unbind().click(function() {
                var permission;
                user = $(this).attr("data-user");
                permission = $(this).attr("data-permission");
                return toastStatusMessage("Would grant " + user + " permission '" + permission + "'");
              });
              safariDialogHelper("#user-setter-dialog");
              return false;
            });
          };
          userHtml = "";
          ref1 = project.access_data.total;
          for (l = 0, len = ref1.length; l < len; l++) {
            user = ref1[l];
            icon = "";
            if (user === project.access_data.author) {
              icon = "<icon-icon icon=\"social:person\"></iron-icon>";
            } else if (indexOf.call(project.access_data.editors_list, user) >= 0) {
              icon = "<icon-icon icon=\"image:edit\"></iron-icon>";
            } else if (indexOf.call(project.access_data.viewers_list, user) >= 0) {
              icon = "<icon-icon icon=\"image:remove-red-eye\"></iron-icon>";
            }
            userHtml += "<tr>\n  <td colspan=\"5\">" + user + "</td>\n  <td>" + icon + "</td>\n</tr>";
          }
          html = "<section id=\"manage-users\" class=\"col-xs-12 col-md-4\">\n  <div class=\"alert alert-info\">\n    <h3>Project Collaborators</h3>\n    <table class=\"table table-striped table-collapsed\" cols=\"6\">\n      <thead>\n        <tr>\n          <td colspan=\"5\">User</td>\n          <td>Permissions</td>\n        </tr>\n      </thead>\n      <tbody>\n        " + userHtml + "\n      </tbody>\n    </table>\n  </div>\n</section>\n<section id=\"project-basics\" class=\"col-xs-12 col-md-8\">\n</section>\n<section id=\"project-data\" class=\"col-xs-12 clearfix\">\n</section>";
          $("#main-body").html(html);
          return stopLoad();
        } catch (_error) {
          e = _error;
          stopLoadError("There was an error loading your project");
          console.error("Unhandled exception loading project! " + e.message);
          console.warn(e.stack);
          return false;
        }
      }).error(function(result, status) {
        return stopLoadError("We couldn't load your project. Please try again.");
      });
    });
    return false;
  };
  (showEditList = function() {

    /*
     * Show a list of icons for editable projects. Blocked on #22, it's
     * just based on authorship right now.
     */
    var args;
    startLoad();
    args = "perform=list";
    return $.get(adminParams.apiTarget, args, "json").done(function(result) {
      var authoredList, html, icon, k, projectId, projectTitle, ref, ref1;
      html = "<h2 class=\"new-title col-xs-12\">Editable Projects</h2>\n<ul id=\"project-list\" class=\"col-xs-12 col-md-6\">\n</ul>";
      $("#main-body").html(html);
      authoredList = new Array();
      ref = result.authored_projects;
      for (k in ref) {
        projectId = ref[k];
        authoredList.push(projectId);
      }
      ref1 = result.projects;
      for (projectId in ref1) {
        projectTitle = ref1[projectId];
        icon = indexOf.call(authoredList, projectId) >= 0 ? "<iron-icon icon=\"social:person\" data-toggle=\"tooltip\" title=\"Author\"></iron-icon>" : "<iron-icon icon=\"social:group\" data-toggle=\"tooltip\" title=\"Collaborator\"></iron-icon>";
        if (indexOf.call(authoredList, projectId) >= 0) {
          html = "<li>\n  <button class=\"btn btn-primary\" data-project=\"" + projectId + "\">\n    " + projectTitle + " / #" + (projectId.substring(0, 8)) + "\n  </button>\n  " + icon + "\n</li>";
          $("#project-list").append(html);
        }
      }
      $("#project-list button").unbind().click(function() {
        var project;
        project = $(this).attr("data-project");
        return editProject(project);
      });
      return stopLoad();
    }).error(function(result, status) {
      return stopLoadError("There was a problem loading viable projects");
    });
  })();
  return false;
};


/*
 *
 *
 * This is included in ./js/admin.js via ./Gruntfile.coffee
 *
 * For administrative editor code, look at ./coffee/admin-editor.coffee
 *
 * @path ./coffee/admin-viewer.coffee
 * @author Philip Kahn
 */

loadProjectBrowser = function() {
  var args;
  startAdminActionHelper();
  startLoad();
  args = "perform=list";
  $.get(adminParams.apiTarget, args, "json").done(function(result) {
    var html, icon, k, projectId, projectTitle, publicList, ref, ref1;
    html = "<h2 class=\"new-title col-xs-12\">Available Projects</h2>\n<ul id=\"project-list\" class=\"col-xs-12 col-md-6\">\n</ul>";
    $("#main-body").html(html);
    publicList = new Array();
    ref = result.public_projects;
    for (k in ref) {
      projectId = ref[k];
      publicList.push(projectId);
    }
    ref1 = result.projects;
    for (projectId in ref1) {
      projectTitle = ref1[projectId];
      icon = indexOf.call(publicList, projectId) >= 0 ? "<iron-icon icon=\"social:public\"></iron-icon>" : "<iron-icon icon=\"icons:lock-open\"></iron-icon>";
      html = "<li>\n  <button class=\"btn btn-primary\" data-project=\"" + projectId + "\" data-toggle=\"tooltip\" title=\"Project #" + (projectId.substring(0, 8)) + "...\">\n    " + icon + " " + projectTitle + "\n  </button>\n</li>";
      $("#project-list").append(html);
    }
    $("#project-list button").unbind().click(function() {
      var project;
      project = $(this).attr("data-project");
      return loadProject(project);
    });
    return stopLoad();
  }).error(function(result, status) {
    return stopLoadError("There was a problem loading viable projects");
  });
  return false;
};

loadProject = function(projectId, message) {
  if (message == null) {
    message = "";
  }
  toastStatusMessage("Would load project " + projectId + " to view");
  return false;
};

//# sourceMappingURL=maps/admin.js.map
