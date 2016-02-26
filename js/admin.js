
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
var _7zHandler, alertBadProject, bootstrapTransect, bootstrapUploader, csvHandler, dataAttrs, dataFileParams, dateMonthToString, excelDateToUnixTime, excelHandler, finalizeData, getCanonicalDataCoords, getInfoTooltip, getProjectCartoData, getTableCoordinates, helperDir, imageHandler, loadCreateNewProject, loadEditor, loadProject, loadProjectBrowser, loadSUProjectBrowser, mapAddPoints, mapOverlayPolygon, mintBcid, newGeoDataHandler, pointStringToLatLng, pointStringToPoint, populateAdminActions, removeDataFile, renderValidateProgress, resetForm, showAddUserDialog, singleDataFileHelper, startAdminActionHelper, uploadedData, user, userEmail, userFullname, validateAWebTaxon, validateData, validateFimsData, validateTaxonData, verifyLoginCredentials, zipHandler,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

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

uploadedData = null;

helperDir = "helpers/";

user = $.cookie(adminParams.domain + "_link");

userEmail = $.cookie(adminParams.domain + "_user");

userFullname = $.cookie(adminParams.domain + "_fullname");

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
  $("#view-project").click(function() {
    return loadProjectBrowser();
  });
  verifyLoginCredentials(function(result) {
    var html, rawSu;
    rawSu = toInt(result.detail.userdata.su_flag);
    if (rawSu.toBool()) {
      console.info("NOTICE: This is an SUPERUSER Admin");
      html = "<paper-button id=\"su-view-projects\" class=\"admin-action su-action col-md-3 col-sm-4 col-xs-12\">\n  <iron-icon icon=\"icons:supervisor-account\"></iron-icon>\n   <iron-icon icon=\"icons:create\"></iron-icon>\n  (SU) Administrate All Projects\n</paper-button>";
      $("#admin-actions-block").append(html);
      $("#su-view-projects").click(function() {
        return loadSUProjectBrowser();
      });
    }
    return false;
  });
  return false;
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
  $("#pib-wrapper-dashboard").remove();
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
  var html, ta;
  startAdminActionHelper();
  html = "<h2 class=\"new-title col-xs-12\">Project Title</h2>\n<paper-input label=\"Project Title\" id=\"project-title\" class=\"project-field col-md-6 col-xs-12\" required auto-validate data-field=\"project_title\"></paper-input>\n<h2 class=\"new-title col-xs-12\">Project Parameters</h2>\n<section class=\"project-inputs clearfix col-xs-12\">\n  <div class=\"row\">\n    <paper-input label=\"Primary Pathogen Studied\" id=\"project-disease\" class=\"project-field col-md-6 col-xs-11\" required auto-validate data-field=\"disease\"></paper-input>" + (getInfoTooltip("Bd, Bsal, or other")) + "\n    <paper-input label=\"Pathogen Strain\" id=\"project-disease-strain\" class=\"project-field col-md-6 col-xs-11\" data-field=\"disease_strain\"></paper-input>" + (getInfoTooltip("For example, Hepatitus A, B, C would enter the appropriate letter here")) + "\n    <paper-input label=\"Project Reference\" id=\"reference-id\" class=\"project-field col-md-6 col-xs-11\" data-field=\"reference_id\"></paper-input>\n    " + (getInfoTooltip("E.g.  a DOI or other reference")) + "\n    <paper-input label=\"Publication DOI\" id=\"pub-doi\" class=\"project-field col-md-6 col-xs-11\" data-field=\"publication\"></paper-input>\n    <h2 class=\"new-title col-xs-12\">Lab Parameters</h2>\n    <paper-input label=\"Project PI\" id=\"project-pi\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate data-field=\"pi_lab\"></paper-input>\n    <paper-input label=\"Project Contact\" id=\"project-author\" class=\"project-field col-md-6 col-xs-12\" value=\"" + userFullname + "\"  required auto-validate></paper-input>\n    <gold-email-input label=\"Contact Email\" id=\"author-email\" class=\"project-field col-md-6 col-xs-12\" value=\"" + userEmail + "\"  required auto-validate></gold-email-input>\n    <paper-input label=\"Diagnostic Lab\" id=\"project-lab\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate></paper-input>\n    <paper-input label=\"Affiliation\" id=\"project-affiliation\" class=\"project-field col-md-6 col-xs-11\"  required auto-validate></paper-input> " + (getInfoTooltip("e.g., UC Berkeley")) + "\n    <h2 class=\"new-title col-xs-12\">Project Notes</h2>\n    <iron-autogrow-textarea id=\"project-notes\" class=\"project-field col-md-6 col-xs-11\" rows=\"3\" data-field=\"sample_notes\"></iron-autogrow-textarea>" + (getInfoTooltip("Project notes or brief abstract; accepts Markdown ")) + "\n    <marked-element class=\"project-param col-md-6 col-xs-12\" id=\"note-preview\">\n      <div class=\"markdown-html\"></div>\n    </marked-element>\n    <h2 class=\"new-title col-xs-12\">Data Permissions</h2>\n    <div class=\"col-xs-12\">\n      <span class=\"toggle-off-label iron-label\">Private Dataset</span>\n      <paper-toggle-button id=\"data-encumbrance-toggle\" class=\"red\">Public Dataset</paper-toggle-button>\n      <p><strong>Smart selector here for registered users</strong>, only show when \"private\" toggle set</p>\n    </div>\n    <h2 class=\"new-title col-xs-12\">Project Area of Interest</h2>\n    <div class=\"col-xs-12\">\n      <p>\n        This represents the approximate collection region for your samples.\n        <strong>\n          Leave blank for a bounding box to be calculated from your sample sites\n        </strong>.\n      </p>\n      <span class=\"toggle-off-label iron-label\">Locality Name</span>\n      <paper-toggle-button id=\"transect-input-toggle\">Coordinate List</paper-toggle-button>\n    </div>\n    <p id=\"transect-instructions\" class=\"col-xs-12\"></p>\n    <div id=\"transect-input\" class=\"col-md-6 col-xs-12\">\n    </div>\n    <div id=\"carto-rendered-map\" class=\"col-md-6\">\n      <div id=\"carto-map-container\" class=\"carto-map map\">\n      </div>\n    </div>\n    <div class=\"col-xs-12\">\n      <br/>\n      <paper-checkbox checked id=\"has-data\">My project already has data</paper-checkbox>\n      <br/>\n    </div>\n  </div>\n</section>\n<section id=\"uploader-container-section\" class=\"data-section col-xs-12\">\n  <h2 class=\"new-title\">Uploading your project data</h2>\n  <p>Drag and drop as many files as you need below. </p>\n  <p>\n    To save your project, we need at least one file with structured data containing coordinates.\n    Please note that the data <strong>must</strong> have a header row,\n    and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>elevation</code>, and <code>coordinateUncertaintyInMeters</code>.\n  </p>\n  <div class=\"alert alert-info\" role=\"alert\">\n    We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href=\"http://biscicol.org/biocode-fims/templates.jsp\" class=\"newwindow alert-link\">biscicol.org <span class=\"glyphicon glyphicon-new-window\"></span></a>. Your data will be validated with the same service.\n  </div>\n  <div class=\"alert alert-warning\" role=\"alert\">\n    <strong>If the data is in Excel</strong>, ensure that it is in a single-sheet workbook. Data across multiple sheets in one workbook may be improperly processed.\n  </div>\n</section>\n<section class=\"project-inputs clearfix data-section col-xs-12\">\n  <div class=\"row\">\n    <h2 class=\"new-title col-xs-12\">Project Data Summary</h2>\n    <h3 class=\"new-title col-xs-12\">Calculated Data Parameters</h3>\n    <paper-input label=\"Samples Counted\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"samplecount\" readonly type=\"number\" data-field=\"disease_samples\"></paper-input>\n    <paper-input label=\"Positive Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"positive-samples\" readonly type=\"number\" data-field=\"disease_positive\"></paper-input>\n    <paper-input label=\"Negative Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"negative-samples\" readonly type=\"number\" data-field=\"disease_negative\"></paper-input>\n    <paper-input label=\"No Confidence Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"no_confidence-samples\" readonly type=\"number\" data-field=\"disease_no_confidence\"></paper-input>\n    <paper-input label=\"Disease Morbidity\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"morbidity-count\" readonly type=\"number\" data-field=\"disease_morbidity\"></paper-input>\n    <paper-input label=\"Disease Mortality\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"mortality-count\" readonly type=\"number\" data-field=\"disease_mortality\"></paper-input>\n    <h4 class=\"new-title col-xs-12\">Species in dataset</h4>\n    <iron-autogrow-textarea id=\"species-list\" class=\"project-field col-md-6 col-xs-12\" rows=\"3\" placeholder=\"Taxon List\" readonly></iron-autogrow-textarea>\n    <p class=\"col-xs-12\">Etc</p>\n  </div>\n</section>\n<section id=\"submission-section col-xs-12\">\n  <div class=\"pull-right\">\n    <button id=\"upload-data\" class=\"btn btn-success click\" data-function=\"finalizeData\"><iron-icon icon=\"icons:lock-open\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Private Project</button>\n    <button id=\"reset-data\" class=\"btn btn-danger click\" data-function=\"resetForm\">Reset Form</button>\n  </div>\n</section>";
  $("main #main-body").append(html);
  ta = p$("#project-notes").textarea;
  $(ta).keyup(function() {
    return p$("#note-preview").markdown = $(this).val();
  });
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
    buttonLabel = p$("#data-encumbrance-toggle").checked ? "<iron-icon icon=\"social:public\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Public Project" : "<iron-icon icon=\"icons:lock\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Private Project";
    return $("#upload-data").html(buttonLabel);
  });
  bindClicks();
  return false;
};

finalizeData = function() {

  /*
   * Make sure everythign is uploaded, validate, and POST to the server
   */
  var author, dataCheck, e, title;
  startLoad();
  try {
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
    author = $.cookie(adminParams.domain + "_link");
    if (isNull(_adp.projectId)) {
      _adp.projectId = md5("" + geo.dataTable + author + (Date.now()));
    }
    title = p$("#project-title").value;
    return mintBcid(_adp.projectId, title, function(result) {
      var args, authorData, aweb, cartoData, catalogNumbers, center, clade, date, dates, dispositions, distanceFromCenter, e, el, excursion, fieldNumbers, input, key, l, len, len1, len2, m, mString, methods, months, o, postData, ref, ref1, ref2, ref3, ref4, ref5, row, rowLat, rowLng, sampleMethods, taxonData, taxonObject, uDate, uTime, years;
      try {
        if (!result.status) {
          console.error(result.error);
          stopLoadError(result.human_error);
          return false;
        }
        dataAttrs.ark = result.ark;
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
        excursion = 0;
        if (uploadedData != null) {
          dates = new Array();
          months = new Array();
          years = new Array();
          methods = new Array();
          catalogNumbers = new Array();
          fieldNumbers = new Array();
          dispositions = new Array();
          sampleMethods = new Array();
          ref1 = Object.toArray(uploadedData);
          for (m = 0, len1 = ref1.length; m < len1; m++) {
            row = ref1[m];
            date = (ref2 = row.dateCollected) != null ? ref2 : row.dateIdentified;
            uTime = excelDateToUnixTime(date);
            dates.push(uTime);
            uDate = new Date(uTime);
            mString = dateMonthToString(uDate.getUTCMonth());
            if (indexOf.call(months, mString) < 0) {
              months.push(mString);
            }
            if (ref3 = uDate.getFullYear(), indexOf.call(years, ref3) < 0) {
              years.push(uDate.getFullYear());
            }
            if (row.catalogNumber != null) {
              catalogNumbers.push(row.catalogNumber);
            }
            fieldNumbers.push(row.fieldNumber);
            rowLat = row.decimalLatitude;
            rowLng = row.decimalLongitude;
            distanceFromCenter = geo.distance(rowLat, center.lat, rowLng, center.lng);
            if (distanceFromCenter > excursion) {
              excursion = distanceFromCenter;
            }
            if (row.sampleType != null) {
              if (ref4 = row.sampleType, indexOf.call(sampleMethods, ref4) < 0) {
                sampleMethods.push(row.sampleType);
              }
            }
            if (row.specimenDisposition != null) {
              if (ref5 = row.specimenDisposition, indexOf.call(dispositions, ref5) < 0) {
                dispositions.push(row.sampleDisposition);
              }
            }
          }
        }
        console.info("Got uploaded data", uploadedData);
        console.info("Got date ranges", dates);
        months.sort();
        years.sort();
        postData.sampled_collection_start = dates.min();
        postData.sampled_collection_end = dates.max();
        console.info("Collected from", dates.min(), dates.max());
        postData.sample_catalog_numbers = catalogNumbers.join(",");
        postData.sample_field_numbers = fieldNumbers.join(",");
        postData.sampling_months = months.join(",");
        postData.sampling_years = years.join(",");
        postData.sample_methods_used = sampleMethods.join(",");
        if (dataFileParams != null ? dataFileParams.hasDataFile : void 0) {
          postData.sample_raw_data = "https://amphibiandisease.org/" + dataFileParams.fileName;
        }
        postData.lat = center.lat;
        postData.lng = center.lng;
        postData.radius = toInt(excursion * 1000);
        postData.locality = _adp.locality;
        postData.bounding_box_n = geo.computedBoundingRectangle.north;
        postData.bounding_box_s = geo.computedBoundingRectangle.south;
        postData.bounding_box_e = geo.computedBoundingRectangle.east;
        postData.bounding_box_w = geo.computedBoundingRectangle.west;
        postData.author = $.cookie(adminParams.domain + "_link");
        authorData = {
          name: p$("#project-author").value,
          contact_email: p$("#author-email").value,
          affiliation: p$("#project-affiliation").value,
          lab: p$("#project-pi").value,
          diagnostic_lab: p$("#project-lab").value,
          entry_date: Date.now()
        };
        postData.author_data = JSON.stringify(authorData);
        cartoData = {
          table: geo.dataTable,
          raw_data: dataFileParams,
          bounding_polygon: typeof geo !== "undefined" && geo !== null ? geo.canonicalBoundingBox : void 0,
          bounding_polygon_geojson: typeof geo !== "undefined" && geo !== null ? geo.geoJsonBoundingBox : void 0
        };
        postData.carto_id = JSON.stringify(cartoData);
        postData.project_id = _adp.projectId;
        postData.project_obj_id = dataAttrs.ark;
        postData["public"] = p$("#data-encumbrance-toggle").checked;
        taxonData = _adp.data.taxa.validated;
        postData.sampled_clades = _adp.data.taxa.clades.join(",");
        postData.sampled_species = _adp.data.taxa.list.join(",");
        for (o = 0, len2 = taxonData.length; o < len2; o++) {
          taxonObject = taxonData[o];
          aweb = taxonObject.response.validated_taxon;
          console.info("Aweb taxon result:", aweb);
          clade = aweb.order.toLowerCase();
          key = "includes_" + clade;
          postData[key] = true;
          if ((postData.includes_anura != null) !== false && (postData.includes_caudata != null) !== false && (postData.includes_gymnophiona != null) !== false) {
            break;
          }
        }
        args = "perform=new&data=" + (jsonTo64(postData));
        console.info("Data object constructed:", postData);
        return $.post(adminParams.apiTarget, args, "json").done(function(result) {
          if (result.status === true) {
            toastStatusMessage("Data successfully saved to server");
            bsAlert("Project ID #<strong>" + postData.project_id + "</strong> created", "success");
            stopLoad();
            delay(1000, function() {
              return loadEditor(_adp.projectId);
            });
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
      } catch (_error) {
        e = _error;
        stopLoadError("There was a problem with the application. Please try again later. (E-003)");
        console.error("JavaScript error in saving data (E-003)! FinalizeData said: " + e.message);
        return console.warn(e.stack);
      }
    });
  } catch (_error) {
    e = _error;
    stopLoadError("There was a problem with the application. Please try again later. (E-004)");
    console.error("JavaScript error in saving data (E-004)! FinalizeData said: " + e.message);
    return console.warn(e.stack);
  }
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
            sw: [bbEW.N, bbNS.j],
            north: bbEW.j,
            south: bbEW.N,
            east: bbNS.j,
            west: bbNS.N
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
      coordinates: cpHull
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

bootstrapUploader = function(uploadFormId, bsColWidth) {
  var html, selector;
  if (uploadFormId == null) {
    uploadFormId = "file-uploader";
  }
  if (bsColWidth == null) {
    bsColWidth = "col-md-4";
  }

  /*
   * Bootstrap the file uploader into existence
   */
  selector = "#" + uploadFormId;
  if (!$(selector).exists()) {
    html = "<form id=\"" + uploadFormId + "-form\" class=\"" + bsColWidth + " clearfix\">\n  <p class=\"visible-xs-block\">Tap the button to upload a file</p>\n  <fieldset class=\"hidden-xs\">\n    <legend>Upload Files</legend>\n    <div id=\"" + uploadFormId + "\" class=\"media-uploader outline media-upload-target\">\n    </div>\n  </fieldset>\n</form>";
    $("main #uploader-container-section").append(html);
    console.info("Appended upload form");
    $(selector).submit(function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
  }
  return verifyLoginCredentials(function() {
    var needsInit;
    if (window.dropperParams == null) {
      window.dropperParams = new Object();
    }
    window.dropperParams.dropTargetSelector = selector;
    window.dropperParams.uploadPath = "uploaded/" + user + "/";
    needsInit = window.dropperParams.hasInitialized === true;
    loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
      console.info("Loaded drag drop helper");
      if (needsInit) {
        console.info("Reinitialized dropper");
        try {
          window.dropperParams.initialize();
        } catch (_error) {
          console.warn("Couldn't reinitialize dropper!");
        }
      }
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
          $("#validator-progress-container").remove();
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
  $("#validator-progress-container").remove();
  renderValidateProgress();
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
      $("#upload-data").attr("disabled", "disabled");
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
      uploadedData = result.data;
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
  $("#validator-progress-container paper-progress").removeAttr("indeterminate");
  serverPath = helperDir + "/js-dragdrop/uploaded/" + user + "/" + removeFile;
  args = "action=removefile&path=" + (encode64(removeFile)) + "&user=" + user;
  return false;
};

newGeoDataHandler = function(dataObject) {
  var author, center, cleanValue, column, coords, coordsPoint, d, data, date, e, fimsExtra, getCoordsFromData, k, month, n, parsedData, projectIdentifier, row, rows, sampleRow, samplesMeta, skipCol, t, tRow, totalData, value;
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
    if (geo.geocoder == null) {
      try {
        geo.geocoder = new google.maps.Geocoder;
      } catch (_error) {}
    }
    try {
      sampleRow = dataObject[0];
    } catch (_error) {
      toastStatusMessage("Your data file was malformed, and could not be parsed. Please try again.");
      removeDataFile();
      return false;
    }
    if (!((sampleRow.decimalLatitude != null) && (sampleRow.decimalLongitude != null) && (sampleRow.coordinateUncertaintyInMeters != null))) {
      toastStatusMessage("Data are missing required geo columns. Please reformat and try again.");
      console.info("Missing: ", sampleRow.decimalLatitude != null, sampleRow.decimalLongitude != null, sampleRow.coordinateUncertaintyInMeters != null);
      removeDataFile();
      return false;
    }
    if (!(isNumber(sampleRow.decimalLatitude) && isNumber(sampleRow.decimalLongitude) && isNumber(sampleRow.coordinateUncertaintyInMeters))) {
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
    toastStatusMessage("Please wait, parsing your data");
    $("#data-parsing").removeAttr("indeterminate");
    p$("#data-parsing").max = rows;
    for (n in dataObject) {
      row = dataObject[n];
      tRow = new Object();
      for (column in row) {
        value = row[column];
        column = column.trim();
        skipCol = false;
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
            skipCol = true;
            break;
          case "specimenDisposition":
            column = "sampleDisposition";
            break;
          case "sampleType":
            column = "sampleMethod";
            break;
          case "elevation":
            column = "alt";
            break;
          case "dateCollected":
          case "dateIdentified":
            column = "dateIdentified";
            t = excelDateToUnixTime(value);
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
            if (!isNumber(value)) {
              stopLoadError("Detected an invalid number for " + column + " at row " + n + " ('" + value + "')");
              return false;
            }
            if (column === "decimalLatitude" && (-90 > value && value > 90)) {
              stopLoadError("Detected an invalid latitude " + value + " at row " + n);
              return false;
            }
            if (column === "decimalLongitude" && (-180 > value && value > 180)) {
              stopLoadError("Detected an invalid longitude " + value + " at row " + n);
              return false;
            }
            if (column === "coordinateUncertaintyInMeters" && value <= 0) {
              stopLoadError("Coordinate uncertainty must be >= 0 at row " + n);
              return false;
            }
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
        if (!skipCol) {
          tRow[column] = cleanValue;
        }
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
      if (modulo(n, 500) === 0 && n > 0) {
        toastStatusMessage("Processed " + n + " rows ...");
      }
      p$("#data-parsing").value = n + 1;
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
    center = getMapCenter(geo.boundingBox);
    geo.reverseGeocode(center.lat, center.lng, geo.boundingBox, function(locality) {
      _adp.locality = locality;
      dataAttrs.locality = locality;
      try {
        p$("#locality-input").value = locality;
        return p$("#locality-input").readonly = true;
      } catch (_error) {}
    });
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
    if (isNull(_adp.projectId)) {
      author = $.cookie(adminParams.domain + "_link");
      _adp.projectId = md5("" + projectIdentifier + author + (Date.now()));
    }
    totalData = {
      transectRing: geo.boundingBox,
      data: parsedData,
      samples: samplesMeta
    };
    validateData(totalData, function(validatedData) {
      var cladeList, e, i, l, len, noticeHtml, originalTaxon, ref, ref1, taxon, taxonList, taxonListString, taxonString;
      taxonListString = "";
      taxonList = new Array();
      cladeList = new Array();
      i = 0;
      ref = validatedData.validated_taxa;
      for (l = 0, len = ref.length; l < len; l++) {
        taxon = ref[l];
        taxonString = taxon.genus + " " + taxon.species;
        if (taxon.response.original_taxon != null) {
          console.info("Taxon obj", taxon);
          originalTaxon = "" + (taxon.response.original_taxon.slice(0, 1).toUpperCase()) + (taxon.response.original_taxon.slice(1));
          noticeHtml = "<div class=\"alert alert-info alert-dismissable amended-taxon-notice col-md-6 col-xs-12 project-field\" role=\"alert\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n    Your entry '<em>" + originalTaxon + "</em>' was a synonym in the AmphibiaWeb database. It was automatically converted to '<em>" + taxonString + "</em>' below. <a href=\"" + taxon.response.validated_taxon.uri_or_guid + "\" target=\"_blank\">See the AmphibiaWeb entry <span class=\"glyphicon glyphicon-new-window\"></span></a>\n</div>";
          $("#species-list").before(noticeHtml);
        }
        if (!isNull(taxon.subspecies)) {
          taxonString += " " + taxon.subspecies;
        }
        if (i > 0) {
          taxonListString += "\n";
        }
        taxonListString += "" + taxonString;
        taxonList.push(taxonString);
        try {
          if (ref1 = taxon.response.validated_taxon.family, indexOf.call(cladeList, ref1) < 0) {
            cladeList.push(taxon.response.validated_taxon.family);
          }
        } catch (_error) {
          e = _error;
          console.warn("Couldn't get the family! " + e.message, taxon.response);
          console.warn(e.stack);
        }
        ++i;
      }
      p$("#species-list").bindValue = taxonListString;
      dataAttrs.dataObj = validatedData;
      if ((typeof _adp !== "undefined" && _adp !== null ? _adp.data : void 0) == null) {
        if (typeof _adp === "undefined" || _adp === null) {
          window._adp = new Object();
        }
        window._adp.data = new Object();
      }
      _adp.data.dataObj = validatedData;
      _adp.data.taxa = new Object();
      _adp.data.taxa.list = taxonList;
      _adp.data.taxa.clades = cladeList;
      _adp.data.taxa.validated = validatedData.validated_taxa;
      return geo.requestCartoUpload(validatedData, projectIdentifier, "create", function(table) {
        return mapOverlayPolygon(validatedData.transectRing);
      });
    });
  } catch (_error) {
    e = _error;
    console.error(e.message);
    toastStatusMessage("There was a problem parsing your data");
  }
  return false;
};

dateMonthToString = function(month) {
  var conversionObj, rv;
  conversionObj = {
    0: "January",
    1: "February",
    2: "March",
    3: "April",
    4: "May",
    5: "June",
    6: "July",
    7: "August",
    8: "September",
    9: "October",
    10: "November",
    11: "December"
  };
  try {
    rv = conversionObj[month];
  } catch (_error) {
    rv = month;
  }
  return rv;
};

excelDateToUnixTime = function(excelTime) {
  var daysFrom1900to1970, daysFrom1904to1970, secondsPerDay, t;
  try {
    if ((0 < excelTime && excelTime < 10e5)) {

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
      t = ((excelTime - daysFrom1900to1970) * secondsPerDay) * 1000;
    } else {
      t = Date.parse(excelTime);
    }
  } catch (_error) {
    t = Date.now();
  }
  return t;
};

renderValidateProgress = function() {

  /*
   * Show paper-progress bars as validation goes
   *
   * https://elements.polymer-project.org/elements/paper-progress
   */
  var html;
  html = "<div id=\"validator-progress-container\" class=\"col-md-6 col-xs-12\">\n  <label for=\"data-parsing\">Data Parsing:</label><paper-progress id=\"data-parsing\" class=\"blue\" indeterminate></paper-progress>\n  <label for=\"data-validation\">Data Validation:</label><paper-progress id=\"data-validation\" class=\"cyan\" indeterminate></paper-progress>\n  <label for=\"taxa-validation\">Taxa Validation:</label><paper-progress id=\"taxa-validation\" class=\"teal\" indeterminate></paper-progress>\n  <label for=\"data-sync\">Estimated Data Sync Progress:</label><paper-progress id=\"data-sync\" indeterminate></paper-progress>\n</div>";
  if (!$("#validator-progress-container").exists()) {
    $("#file-uploader-form").after(html);
  }
  return false;
};

$(function() {
  if ($("#next").exists()) {
    $("#next").unbind().click(function() {
      return openTab(adminParams.adminPageUrl);
    });
  }
  loadJS("bower_components/bootstrap/dist/js/bootstrap.min.js", function() {
    return $("body").tooltip({
      selector: "[data-toggle='tooltip']"
    });
  });
  return checkFileVersion(false, "js/admin.min.js");
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

loadEditor = function(projectPreload) {

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
    window.projectParams = new Object();
    window.projectParams.pid = projectId;
    verifyLoginCredentials(function(credentialResult) {
      var args, opid, userDetail;
      userDetail = credentialResult.detail;
      user = userDetail.uid;
      opid = projectId;
      projectId = encodeURIComponent(projectId);
      args = "perform=get&project=" + projectId;
      return $.post(adminParams.apiTarget, args, "json").done(function(result) {
        var affixOptions, anuraState, authorData, cartoParsed, caudataState, collectionRangePretty, conditionalReadonly, creation, d1, d2, deleteCardAction, e, error, googleMap, gymnophionaState, html, i, icon, l, len, len1, len2, len3, m, mapHtml, mdNotes, month, monthPretty, months, noteHtml, o, p, point, poly, popManageUserAccess, project, publicToggle, ref, ref1, ref2, ref3, ta, topPosition, usedPoints, userHtml, year, yearPretty, years;
        try {
          console.info("Server said", result);
          if (result.status !== true) {
            error = (ref = result.human_error) != null ? ref : result.error;
            if (error == null) {
              error = "Unidentified Error";
            }
            stopLoadError("There was a problem loading your project (" + error + ")");
            console.error("Couldn't load project! (POST OK) Error: " + result.error);
            console.warn("Attempted", adminParams.apiTarget + "?" + args);
            return false;
          }
          if (result.user.has_edit_permissions !== true) {
            if (result.user.has_view_permissions || result.project["public"].toBool() === true) {
              loadProject(opid, "Ineligible to edit " + opid + ", loading as read-only");
              return false;
            }
            alertBadProject(opid);
            return false;
          }
          toastStatusMessage("Good user, would load editor for project");
          project = result.project;
          project.access_data.total = Object.toArray(project.access_data.total);
          project.access_data.total.sort();
          project.access_data.editors_list = Object.toArray(project.access_data.editors_list);
          project.access_data.viewers_list = Object.toArray(project.access_data.viewers_list);
          project.access_data.editors = Object.toArray(project.access_data.editors);
          project.access_data.viewers = Object.toArray(project.access_data.viewers);
          console.info("Project access lists:", project.access_data);
          popManageUserAccess = function() {
            return verifyLoginCredentials(function(credentialResult) {
              var authorDisabled, dialogHtml, editDisabled, isAuthor, isEditor, isViewer, l, len, ref1, theirHtml, uid, userHtml, viewerDisabled;
              userHtml = "";
              ref1 = project.access_data.total;
              for (l = 0, len = ref1.length; l < len; l++) {
                user = ref1[l];
                theirHtml = user + " <span class='set-permission-block'>";
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
                if (result.user.has_edit_permissions && user !== isAuthor && user !== result.user.user.userdata.username) {
                  theirHtml += "<paper-icon-button icon=\"icons:delete\" class=\"set-permission\" data-permission=\"delete\" data-user=\"" + uid + "\">\n</paper-icon-button>";
                }
                userHtml += "<li>" + theirHtml + "</span></li>";
              }
              userHtml = "<ul class=\"simple-list\">\n  " + userHtml + "\n</ul>";
              if (project.access_data.total.length === 1) {
                userHtml += "<div id=\"single-user-warning\">\n  <iron-icon icon=\"icons:warning\"></iron-icon> <strong>Head's-up</strong>: You can't change permissions when a project only has one user. Consider adding another user first.\n</div>";
              }
              dialogHtml = "<paper-dialog modal id=\"user-setter-dialog\">\n  <h2>Manage \"" + project.project_title + "\" users</h2>\n  <paper-dialog-scrollable>\n    " + userHtml + "\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button class=\"add-user\" dialog-confirm><iron-icon icon=\"social:group-add\"></iron-icon> Add Users</paper-button>\n    <paper-button class=\"close-dialog\" dialog-dismiss>Done</paper-button>\n  </div>\n</paper-dialog>";
              $("#user-setter-dialog").remove();
              $("body").append(dialogHtml);
              $(".set-permission").unbind().click(function() {
                var j64, permission, permissionsObj, userList;
                user = $(this).attr("data-user");
                permission = $(this).attr("data-permission");
                permissionsObj = new Object();
                userList = new Array();
                userList.push(user);
                permissionsObj[permission] = userList;
                j64 = jsonTo64(permissionsObj);
                args = "perform=editaccess&project=" + window.projectParams.pid + "&deltas=" + j64;
                toastStatusMessage("Would grant " + user + " permission '" + permission + "'");
                console.log("Would push args to", adminParams.apiTarget + "?" + args);
                return false;
              });
              $(".add-user").unbind().click(function() {
                showAddUserDialog(project.access_data.total);
                return false;
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
              icon = "<iron-icon icon=\"social:person\"></iron-icon>";
            } else if (indexOf.call(project.access_data.editors_list, user) >= 0) {
              icon = "<iron-icon icon=\"image:edit\"></iron-icon>";
            } else if (indexOf.call(project.access_data.viewers_list, user) >= 0) {
              icon = "<iron-icon icon=\"image:remove-red-eye\"></iron-icon>";
            }
            userHtml += "<tr>\n  <td colspan=\"5\">" + user + "</td>\n  <td class=\"text-center\">" + icon + "</td>\n</tr>";
          }
          icon = project["public"].toBool() ? "<iron-icon icon=\"social:public\" class=\"material-green\" data-toggle=\"tooltip\" title=\"Public Project\"></iron-icon>" : "<iron-icon icon=\"icons:lock\" class=\"material-red\" data-toggle=\"tooltip\" title=\"Private Project\"></iron-icon>";
          publicToggle = !project["public"].toBool() ? result.user.is_author ? "<div class=\"col-xs-12\">\n  <paper-toggle-button id=\"public\" class=\"project-params danger-toggle red\">\n    <iron-icon icon=\"icons:warning\"></iron-icon>\n    Make this project public\n  </paper-toggle-button> <span class=\"text-muted small\">Once saved, this cannot be undone</span>\n</div>" : "<!-- This user does not have permission to toggle the public state of this project -->" : "<!-- This project is already public -->";
          conditionalReadonly = result.user.has_edit_permissions ? "" : "readonly";
          anuraState = project.includes_anura.toBool() ? "checked disabled" : "disabled";
          caudataState = project.includes_caudata.toBool() ? "checked disabled" : "disabled";
          gymnophionaState = project.includes_gymnophiona.toBool() ? "checked disabled" : "disabled";
          try {
            cartoParsed = JSON.parse(deEscape(project.carto_id));
          } catch (_error) {
            console.error("Couldn't parse the carto JSON!", project.carto_id);
            stopLoadError("We couldn't parse your data. Please try again later.");
            cartoParsed = new Object();
          }
          mapHtml = "";
          if (((ref2 = cartoParsed.bounding_polygon) != null ? ref2.paths : void 0) != null) {
            poly = cartoParsed.bounding_polygon;
            mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
            usedPoints = new Array();
            ref3 = poly.paths;
            for (m = 0, len1 = ref3.length; m < len1; m++) {
              point = ref3[m];
              if (indexOf.call(usedPoints, point) < 0) {
                usedPoints.push(point);
                mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
              }
            }
            mapHtml += "    </google-map-poly>";
          }
          googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + project.lat + "\" longitude=\"" + project.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui>\n  " + mapHtml + "\n</google-map>";
          geo.googleMapWebComponent = googleMap;
          deleteCardAction = result.user.is_author ? "<div class=\"card-actions\">\n      <paper-button id=\"delete-project\"><iron-icon icon=\"icons:delete\" class=\"material-red\"></iron-icon> Delete this project</paper-button>\n    </div>" : "";
          mdNotes = isNull(project.sample_notes) ? "*No notes for this project*" : project.sample_notes;
          noteHtml = "<h3>Project Notes</h3>\n<ul class=\"nav nav-tabs\" id=\"markdown-switcher\">\n  <li role=\"presentation\" class=\"active\" data-view=\"md\"><a href=\"#markdown-switcher\">Preview</a></li>\n  <li role=\"presentation\" data-view=\"edit\"><a href=\"#markdown-switcher\">Edit</a></li>\n</ul>\n<iron-autogrow-textarea id=\"project-notes\" class=\"markdown-pair project-param\" rows=\"3\" data-field=\"sample_notes\" hidden>" + project.sample_notes + "</iron-autogrow-textarea>\n<marked-element class=\"markdown-pair project-param\" id=\"note-preview\">\n  <div class=\"markdown-html\"></div>\n  <script type=\"text/markdown\">" + mdNotes + "</script>\n</marked-element>";
          try {
            authorData = JSON.parse(project.author_data);
            creation = new Date(authorData.entry_date);
          } catch (_error) {
            authorData = new Object();
            creation = new Object();
            creation.toLocaleString = function() {
              return "Error retrieving creation time";
            };
          }
          monthPretty = "";
          months = project.sampling_months.split(",");
          i = 0;
          for (o = 0, len2 = months.length; o < len2; o++) {
            month = months[o];
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
          years = project.sampling_years.split(",");
          i = 0;
          for (p = 0, len3 = years.length; p < len3; p++) {
            year = years[p];
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
          d1 = new Date(toInt(project.sampled_collection_start));
          d2 = new Date(toInt(project.sampled_collection_end));
          collectionRangePretty = (dateMonthToString(d1.getMonth())) + " " + (d1.getFullYear()) + " &#8212; " + (dateMonthToString(d2.getMonth())) + " " + (d2.getFullYear());
          html = "<h2 class=\"clearfix newtitle col-xs-12\">Managing " + project.project_title + " " + icon + "<br/><small>Project #" + opid + "</small></h2>\n" + publicToggle + "\n<section id=\"manage-users\" class=\"col-xs-12 col-md-4 pull-right\">\n  <paper-card class=\"clearfix\" heading=\"Project Collaborators\" elevation=\"2\">\n    <div class=\"card-content\">\n      <table class=\"table table-striped table-condensed table-responsive table-hover clearfix\">\n        <thead>\n          <tr>\n            <td colspan=\"5\">User</td>\n            <td>Permissions</td>\n          </tr>\n        </thead>\n        <tbody>\n          " + userHtml + "\n        </tbody>\n      </table>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button class=\"manage-users\" id=\"manage-users\">Manage Users</paper-button>\n    </div>\n  </paper-card>\n</section>\n<section id=\"project-basics\" class=\"col-xs-12 col-md-8 clearfix\">\n  <h3>Project Basics</h3>\n  <paper-input readonly label=\"Project Identifier\" value=\"" + project.project_id + "\" id=\"project_id\" class=\"project-param\"></paper-input>\n  <paper-input readonly label=\"Project Creation\" value=\"" + (creation.toLocaleString()) + "\" id=\"project_creation\" class=\"project-param\"></paper-input>\n  <paper-input readonly label=\"Project ARK\" value=\"" + project.project_obj_id + "\" id=\"project_creation\" class=\"project-param\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Project Title\" value=\"" + project.project_title + "\" id=\"project-title\" data-field=\"project_title\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Primary Pathogen\" value=\"" + project.disease + "\" data-field=\"disease\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"PI Lab\" value=\"" + project.pi_lab + "\" id=\"project-title\" data-field=\"pi_lab\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Project Reference\" value=\"" + project.reference_id + "\" id=\"project-reference\" data-field=\"reference_id\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Publication DOI\" value=\"" + project.publication + "\" id=\"doi\" data-field=\"publication\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Project Contact\" value=\"" + authorData.name + "\" id=\"project-contact\"></paper-input>\n  <gold-email-input " + conditionalReadonly + " class=\"project-param\" label=\"Contact Email\" value=\"" + authorData.contact_email + "\" id=\"contact-email\"></gold-email-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Diagnostic Lab\" value=\"" + authorData.diagnostic_lab + "\" id=\"project-lab\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Affiliation\" value=\"" + authorData.affiliation + "\" id=\"project-affiliation\"></paper-input>\n</section>\n<section id=\"notes\" class=\"col-xs-12 col-md-8 clearfix\">\n  " + noteHtml + "\n</section>\n<section id=\"data-management\" class=\"col-xs-12 col-md-4 pull-right\">\n  <paper-card class=\"clearfix\" heading=\"Project Data\" elevation=\"2\" id=\"data-card\">\n    <div class=\"card-content\">\n      <div class=\"variable-card-content\">\n      Your project does/does not have data associated with it. (Does should note overwrite, and link to cartoParsed.raw_data.filePath for current)\n      </div>\n      <div id=\"append-replace-data-toggle\">\n        <span class=\"toggle-off-label iron-label\">Append Data</span>\n        <paper-toggle-button id=\"replace-data-toggle\" checked>Replace Data</paper-toggle-button>\n      </div>\n      <div id=\"uploader-container-section\">\n      </div>\n    </div>\n  </paper-card>\n  <paper-card class=\"clearfix\" heading=\"Project Status\" elevation=\"2\" id=\"save-card\">\n    <div class=\"card-content\">\n      <p>Notice if there's unsaved data or not. Buttons below should dynamically disable/enable based on appropriate state.</p>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button id=\"save-project\"><iron-icon icon=\"icons:save\" class=\"material-green\"></iron-icon> Save Project</paper-button>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button id=\"discard-changes-exit\"><iron-icon icon=\"icons:undo\"></iron-icon> Discard Changes &amp; Exit</paper-button>\n    </div>\n    " + deleteCardAction + "\n  </paper-card>\n</section>\n<section id=\"project-data\" class=\"col-xs-12 col-md-8 clearfix\">\n  <h3>Project Data Overview</h3>\n    <h4>Project Studies:</h4>\n      <paper-checkbox " + anuraState + ">Anura</paper-checkbox>\n      <paper-checkbox " + caudataState + ">Caudata</paper-checkbox>\n      <paper-checkbox " + gymnophionaState + ">Gymnophiona</paper-checkbox>\n      <paper-input readonly label=\"Sampled Species\" value=\"" + (project.sampled_species.split(",").join(", ")) + "\"></paper-input>\n      <paper-input readonly label=\"Sampled Clades\" value=\"" + (project.sampled_clades.split(",").join(", ")) + "\"></paper-input>\n      <p class=\"text-muted\">\n        <span class=\"glyphicon glyphicon-info-sign\"></span> There are " + (project.sampled_species.split(",").length) + " species in this dataset, across " + (project.sampled_clades.split(",").length) + " clades\n      </p>\n    <h4>Sample Metrics</h4>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken from " + collectionRangePretty + "</p>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken in " + monthPretty + "</p>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were sampled in " + yearPretty + "</p>\n      <p class=\"text-muted\"><iron-icon icon=\"icons:language\"></iron-icon> The effective project center is at (" + project.lat + ", " + project.lng + ") with an effective sample radius of " + project.radius + "m and a resulting locality <strong class='locality'>" + project.locality + "</strong></p>\n      <p class=\"text-muted\"><iron-icon icon=\"editor:insert-chart\"></iron-icon> The dataset contains " + project.disease_positive + " positive samples (" + (toInt(project.disease_positive * 100 / project.disease_samples)) + "%), " + project.disease_negative + " negative samples (" + (toInt(project.disease_negative * 100 / project.disease_samples)) + "%), and " + project.disease_no_confidence + " inconclusive samples (" + (toInt(project.disease_no_confidence * 100 / project.disease_samples)) + "%)</p>\n    <h4>Locality &amp; Transect Data</h4>\n      " + googleMap + "\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n  <h3>Project Meta Parameters</h3>\n    <h4>Project funding status</h4>\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n      <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"\" value=\"\" id=\"\"></paper-input>\n</section>";
          $("#main-body").html(html);
          ta = p$("#project-notes").textarea;
          $(ta).keyup(function() {
            return p$("#note-preview").markdown = $(this).val();
          });
          $("#markdown-switcher li").click(function() {
            $("#markdown-switcher li").removeClass("active");
            $(".markdown-pair").removeAttr("hidden");
            $(this).addClass("active");
            switch ($(this).attr("data-view")) {
              case "md":
                return $("#project-notes").attr("hidden", "hidden");
              case "edit":
                return $("#note-preview").attr("hidden", "hidden");
            }
          });
          $("#delete-project").click(function() {
            var confirmButton;
            confirmButton = "<paper-button id=\"confirm-delete-project\" class=\"materialred\">\n  <iron-icon icon=\"icons:warning\"></iron-icon> Confirm Project Deletion\n</paper-button>";
            $(this).replaceWith(confirmButton);
            $("#confirm-delete-project").click(function() {
              toastStatusMessage("TODO Would delete this project");
              return false;
            });
            return false;
          });
          $("#save-project").click(function() {
            var button;
            if ($("#confirm-delete-project").exists()) {
              button = "<paper-button id=\"delete-project\"><iron-icon icon=\"icons:delete\" class=\"material-red\"></iron-icon> Delete this project</paper-button>";
              $("#confirm-delete-project").replaceWith(button);
            }
            toastStatusMessage("TODO Would save this project");
            return false;
          });
          $("#discard-changes-exit").click(function() {
            showEditList();
            return false;
          });
          topPosition = $("#data-management").offset().top;
          affixOptions = {
            top: topPosition,
            bottom: 0,
            target: window
          };
          $("#manage-users").click(function() {
            return popManageUserAccess();
          });
          $(".danger-toggle").on("iron-change", function() {
            if ($(this).get(0).checked) {
              return $(this).find("iron-icon").addClass("material-red");
            } else {
              return $(this).find("iron-icon").removeClass("material-red");
            }
          });
          return getProjectCartoData(project.carto_id);
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
  if (projectPreload == null) {
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
  } else {
    editProject(projectPreload);
  }
  return false;
};

showAddUserDialog = function(refAccessList) {

  /*
   * Open up a dialog to show the "Add a user" interface
   *
   * @param Array refAccessList  -> array of emails already with access
   */
  var dialogHtml;
  dialogHtml = "<paper-dialog modal id=\"add-new-user\">\n<h2>Add New User To Project</h2>\n<paper-dialog-scrollable>\n  <p>Search by email, real name, or username below. Click on a search result to queue a user for adding.</p>\n  <div class=\"form-horizontal\" id=\"search-user-form-container\">\n    <div class=\"form-group\">\n      <label for=\"search-user\" class=\"sr-only form-label\">Search User</label>\n      <input type=\"text\" id=\"search-user\" name=\"search-user\" class=\"form-control\"/>\n    </div>\n    <paper-material id=\"user-search-result-container\" class=\"pop-result\" hidden>\n      <div class=\"result-list\">\n        <div class=\"user-search-result\" data-uid=\"456\"><span class=\"email\">foo@bar.com</span> | <span class=\"name\">Jane Smith</span> | <span class=\"user\">FooBar</span></div>\n        <div class=\"user-search-result\" data-uid=\"123\"><span class=\"email\">foo2@bar.com</span> | <span class=\"name\">John Smith</span> | <span class=\"user\">FooBar2</span></div>\n      </div>\n    </paper-material>\n  </div>\n  <p>Adding users:</p>\n  <ul class=\"simple-list\" id=\"user-add-queue\">\n    <!--\n      <li class=\"list-add-users\" data-uid=\"789\">\n        jsmith@sample.com\n      </li>\n    -->\n  </ul>\n</paper-dialog-scrollable>\n<div class=\"buttons\">\n  <paper-button id=\"add-user\"><iron-icon icon=\"social:person-add\"></iron-icon> Save Additions</paper-button>\n  <paper-button dialog-dismiss>Cancel</paper-button>\n</div>\n</paper-dialog>";
  if (!$("#add-new-user").exists()) {
    $("body").append(dialogHtml);
  }
  safariDialogHelper("#add-new-user");
  $("#search-user").keyup(function() {
    var debugHtml;
    console.log("Should search", $(this).val());
    if (!$("#debug-alert").exists()) {
      debugHtml = "<div class=\"alert alert-warning\" id=\"debug-alert\">\n  Would search against \"<span id=\"debug-placeholder\"></span>\". Incomplete. Sample result shown.\n</div>";
      $(this).before(debugHtml);
    }
    $("#debug-placeholder").text($(this).val());
    if (isNull($(this).val())) {
      return $("#user-search-result-container").prop("hidden", "hidden");
    } else {
      return $("#user-search-result-container").removeAttr("hidden");
    }
  });
  $("body .user-search-result").click(function() {
    var currentQueueUids, email, l, len, listHtml, ref, uid;
    uid = $(this).attr("data-uid");
    console.info("Clicked on " + uid);
    email = $(this).find(".email").text();
    currentQueueUids = new Array();
    ref = $("#user-add-queue .list-add-users");
    for (l = 0, len = ref.length; l < len; l++) {
      user = ref[l];
      currentQueueUids.push($(user).attr("data-uid"));
    }
    if (indexOf.call(refAccessList, email) < 0) {
      if (indexOf.call(currentQueueUids, uid) < 0) {
        listHtml = "<li class=\"list-add-users\" data-uid=\"" + uid + "\">" + email + "</li>";
        $("#user-add-queue").append(listHtml);
        $("#search-user").val("");
        return $("#user-search-result-container").prop("hidden", "hidden");
      } else {
        toastStatusMessage(email + " is already in the addition queue");
        return false;
      }
    } else {
      toastStatusMessage(email + " already has access to this project");
      return false;
    }
  });
  $("#add-user").click(function() {
    var args, jsonUids, l, len, ref, toAddUids, uidArgs;
    toAddUids = new Array();
    ref = $("#user-add-queue .list-add-users");
    for (l = 0, len = ref.length; l < len; l++) {
      user = ref[l];
      toAddUids.push($(user).attr("data-uid"));
    }
    if (toAddUids.length < 1) {
      toastStatusMessage("Please add at least one user to the access list.");
      return false;
    }
    console.info("Saving list of " + toAddUids.length + " UIDs to " + window.projectParams.pid, toAddUids);
    jsonUids = {
      add: toAddUids
    };
    uidArgs = jsonTo64(jsonUids);
    args = "perform=editaccess&project=" + window.projectParams.pid + "&deltas=" + uidArgs;
    toastStatusMessage("Would save the list above of " + toAddUids.length + " UIDs to " + window.projectParams.pid);
    return console.log("Would push args to", adminParams.apiTarget + "?" + args);
  });
  return false;
};

getProjectCartoData = function(cartoObj) {

  /*
   * Get the data from CartoDB, map it out, show summaries, etc.
   *
   * @param string|Object cartoObj -> the (JSON formatted) carto data blob.
   */
  var apiPostSqlQuery, args, cartoData, cartoQuery, cartoTable, html, zoom;
  if (typeof cartoObj !== "object") {
    try {
      cartoData = JSON.parse(deEscape(cartoObj));
    } catch (_error) {
      console.error("cartoObj must be JSON string or obj, given", cartoObj);
      console.warn("Cleaned obj:", deEscape(cartoObj));
      stopLoadError("Couldn't parse data");
      return false;
    }
  } else {
    cartoData = cartoObj;
  }
  cartoTable = cartoData.table;
  console.info("Working with Carto data base set", cartoData);
  try {
    zoom = getMapZoom(cartoData.bounding_polygon.paths, "#transect-viewport");
    console.info("Got zoom", zoom);
    $("#transect-viewport").attr("zoom", zoom);
  } catch (_error) {}
  toastStatusMessage("Would ping CartoDB and fetch data for table " + cartoTable);
  cartoQuery = "SELECT genus, specificEpithet, diseaseTested, diseaseDetected, originalTaxa, ST_asGeoJSON(the_geom) FROM " + cartoTable + ";";
  console.info("Would ping cartodb with", cartoQuery);
  apiPostSqlQuery = encodeURIComponent(encode64(cartoQuery));
  args = "action=fetch&sql_query=" + apiPostSqlQuery;
  $.post("api.php", args, "json").done(function(result) {
    var error, geoJson, k, lat, lng, marker, note, ref, row, rows, taxa, truncateLength, workingMap;
    console.info("Carto query got result:", result);
    if (!result.status) {
      error = (ref = result.human_error) != null ? ref : result.error;
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
      workingMap += marker;
    }
    workingMap += "</google-map>\n<p class=\"text-muted\"><span class=\"glyphicon glyphicon-info-sign\"></span> There are <span class='carto-row-count'>" + result.parsed_responses[0].total_rows + "</span> sample points in this dataset</p>";
    $("#transect-viewport").replaceWith(workingMap);
    return stopLoad();
  }).fail(function(result, status) {
    console.error("Couldn't talk to back end server to ping carto!");
    return stopLoadError("There was a problem communicating with the server. Please try again in a bit. (E-002)");
  });
  window.dataFileparams = cartoData.raw_data;
  if (cartoData.raw_data.hasDataFile) {
    html = "<p>\n  Your project already has data associated with it. <span id=\"last-modified-file\"></span>\n</p>\n<button id=\"download-project-file\" class=\"btn btn-primary center-block click\" data-href=\"" + cartoData.raw_data.fileName + "\"><iron-icon icon=\"icons:cloud-download\"></iron-icon> Download File</button>\n<p>You can upload more data below, or replace this existing data.</p>";
    $("#data-card .card-content .variable-card-content").html(html);
    $.get("meta.php", "do=get_last_mod&file=" + cartoData.raw_data.fileName, "json").done(function(result) {
      var iso, t, time, timeString;
      time = toInt(result.last_mod) * 1000;
      console.log("Last modded", time, result);
      if (isNumber(time)) {
        t = new Date(time);
        iso = t.toISOString();
        timeString = "" + (iso.slice(0, iso.search("T")));
        $("#last-modified-file").text("Last uploaded on " + timeString + ".");
      } else {
        console.warn("Didn't get a number back to check last mod time for " + cartoData.raw_data.fileName);
      }
      return false;
    }).fail(function(result, status) {
      console.warn("Couldn't get last mod time for " + cartoData.raw_data.fileName);
      return false;
    });
  } else {
    $("#data-card .card-content .variable-card-content").html("<p>You can upload data to your project here:</p>");
    $("#append-replace-data-toggle").attr("hidden", "hidden");
  }
  bootstrapUploader("data-card-uploader", "");
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

loadSUProjectBrowser = function() {
  startAdminActionHelper();
  startLoad();
  verifyLoginCredentials(function(result) {
    var args, rawSu;
    rawSu = toInt(result.detail.userdata.su_flag);
    if (!rawSu.toBool()) {
      stopLoadError("Sorry, you must be an admin to do this");
      return false;
    }
    args = "perform=sulist";
    return $.get(adminParams.apiTarget, args, "json").done(function(result) {
      var error, html, icon, list, projectDetails, projectId, ref, ref1;
      if (result.status !== true) {
        error = (ref = result.human_error) != null ? ref : "Sorry, you can't do that right now";
        stopLoadError(error);
        console.error("Can't do SU listing!");
        console.warn(result);
        populateAdminActions();
        return false;
      }
      html = "<h2 class=\"new-title col-xs-12\">All Projects</h2>\n<ul id=\"project-list\" class=\"col-xs-12 col-md-6\">\n</ul>";
      $("#main-body").html(html);
      list = new Array();
      ref1 = result.projects;
      for (projectId in ref1) {
        projectDetails = ref1[projectId];
        list.push(projectId);
        icon = projectDetails["public"].toBool() ? "<iron-icon icon=\"social:public\"></iron-icon>" : "<iron-icon icon=\"icons:lock\"></iron-icon>";
        html = "<li>\n  <button class=\"btn btn-primary\" data-project=\"" + projectId + "\" data-toggle=\"tooltip\" title=\"Project #" + (projectId.substring(0, 8)) + "...\">\n    " + icon + " " + projectDetails.title + "\n  </button>\n</li>";
        $("#project-list").append(html);
      }
      $("#project-list button").unbind().click(function() {
        var project;
        project = $(this).attr("data-project");
        return loadEditor(project);
      });
      return stopLoad();
    }).error(function(result, status) {
      return stopLoadError("There was a problem loading projects");
    });
  });
  return false;
};


/*
 * Split-out coffeescript file for data validation.
 * This file contains async validation code to check entries.
 *
 * This is included in ./js/admin.js via ./Gruntfile.coffee
 *
 * For administrative functions for project creation, editing, or
 * viewing, check ./coffee/admin.coffee, ./coffee/admin-editor.coffee,
 * and ./coffee/admin-viewer.coffee (respectively).
 *
 * @path ./coffee/admin-validation.coffee
 * @author Philip Kahn
 */

if (typeof window.validationMeta !== "object") {
  window.validationMeta = new Object();
}

validateData = function(dataObject, callback) {
  var timer;
  if (callback == null) {
    callback = null;
  }

  /*
   *
   */
  console.info("Doing nested validation");
  timer = Date.now();
  renderValidateProgress();
  validateFimsData(dataObject, function() {
    return validateTaxonData(dataObject, function() {
      var elapsed;
      elapsed = Date.now() - timer;
      console.info("Validation took " + elapsed + "ms", dataObject);
      cleanupToasts();
      toastStatusMessage("Your dataset has been successfully validated");
      if (typeof callback === "function") {
        return callback(dataObject);
      } else {
        console.warn("validateData had no defined callback!");
        return console.info("Got back", dataObject);
      }
    });
  });
  return false;
};

validateFimsData = function(dataObject, callback) {
  var fimsPostTarget;
  if (callback == null) {
    callback = null;
  }

  /*
   *
   *
   * @param Object dataObject -> object with at least one key, "data",
   *  containing the parsed data to be validated by FIMS
   * @param function callback -> callback function
   */
  console.info("FIMS Validating", dataObject.data);
  $("#data-validation").removeAttr("indeterminate");
  p$("#data-validation").max = Object.size(dataObject.data);
  fimsPostTarget = "";
  if (typeof callback === "function") {
    p$("#data-validation").value = Object.size(dataObject.data);
    callback(dataObject);
  }
  return false;
};

mintBcid = function(projectId, title, callback) {

  /*
   *
   * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
   *
   * Resolve the ARK with
   * https://n2t.net/
   */
  var args, resultObj;
  if (typeof callback !== "function") {
    console.warn("mintBcid() requires a callback function");
    return false;
  }
  resultObj = new Object();
  args = "perform=mint&link=" + projectId + "&title=" + (post64(title));
  $.post(adminParams.apiTarget, args, "json").done(function(result) {
    console.log("Got", result);
    if (!result.status) {
      stopLoadError(result.human_error);
      console.error(result.error);
      return false;
    }
    return resultObj = result;
  }).error(function(result, status) {
    resultObj.ark = null;
    return false;
  }).always(function() {
    console.info("mintBcid is calling back", resultObj);
    return callback(resultObj);
  });
  return false;
};

validateTaxonData = function(dataObject, callback) {
  var data, grammar, n, row, taxa, taxaPerRow, taxaString, taxon, taxonValidatorLoop;
  if (callback == null) {
    callback = null;
  }

  /*
   *
   */
  data = dataObject.data;
  taxa = new Array();
  taxaPerRow = new Object();
  for (n in data) {
    row = data[n];
    taxon = {
      genus: row.genus,
      species: row.specificEpithet,
      subspecies: row.infraspecificEpithet,
      clade: row.cladeSampled
    };
    if (!taxa.containsObject(taxon)) {
      taxa.push(taxon);
    }
    taxaString = taxon.genus + " " + taxon.species;
    if (!isNull(taxon.subspecies)) {
      taxaString += " " + taxon.subspecies;
    }
    if (taxaPerRow[taxaString] == null) {
      taxaPerRow[taxaString] = new Array();
    }
    taxaPerRow[taxaString].push(n);
  }
  console.info("Found " + taxa.length + " unique taxa:", taxa);
  grammar = taxa.length > 1 ? "taxa" : "taxon";
  toastStatusMessage("Validating " + taxa.length + " uniqe " + grammar);
  console.info("Replacement tracker", taxaPerRow);
  $("#taxa-validation").removeAttr("indeterminate");
  p$("#taxa-validation").max = taxa.length;
  (taxonValidatorLoop = function(taxonArray, key) {
    taxaString = taxonArray[key].genus + " " + taxonArray[key].species;
    if (!isNull(taxonArray[key].subspecies)) {
      taxaString += " " + taxonArray[key].subspecies;
    }
    return validateAWebTaxon(taxonArray[key], function(result) {
      var e, l, len, message, replaceRows;
      if (result.invalid === true) {
        cleanupToasts();
        stopLoadError(result.response.human_error);
        console.error(result.response.error);
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. " + result.response.human_error + " We stopped validation at that point. Please correct taxonomy issues and try uploading again.";
        bsAlert(message);
        removeDataFile();
        return false;
      }
      try {
        replaceRows = taxaPerRow[taxaString];
        console.info("Replacing rows @ " + taxaString, replaceRows, taxonArray[key]);
        for (l = 0, len = replaceRows.length; l < len; l++) {
          row = replaceRows[l];
          dataObject.data[row].genus = result.genus;
          dataObject.data[row].specificEpithet = result.species;
          if (result.subspecies == null) {
            result.subspecies = "";
          }
          dataObject.data[row].infraspecificEpithet = result.subspecies;
          dataObject.data[row].originalTaxa = taxaString;
        }
      } catch (_error) {
        e = _error;
        console.warn("Problem replacing rows! " + e.message);
        console.warn(e.stack);
      }
      taxonArray[key] = result;
      p$("#taxa-validation").value = key;
      key++;
      if (key < taxonArray.length) {
        if (modulo(key, 50) === 0) {
          toastStatusMessage("Validating taxa " + key + " of " + taxonArray.length + " ...");
        }
        return taxonValidatorLoop(taxonArray, key);
      } else {
        p$("#taxa-validation").value = key;
        dataObject.validated_taxa = taxonArray;
        console.info("Calling back!", dataObject);
        return callback(dataObject);
      }
    });
  })(taxa, 0);
  return false;
};

validateAWebTaxon = function(taxonObj, callback) {
  var args, doCallback, ref;
  if (callback == null) {
    callback = null;
  }

  /*
   *
   *
   * @param Object taxonObj -> object with keys "genus", "species", and
   *   optionally "subspecies"
   * @param function callback -> Callback function
   */
  if (((ref = window.validationMeta) != null ? ref.validatedTaxons : void 0) == null) {
    if (typeof window.validationMeta !== "object") {
      window.validationMeta = new Object();
    }
    window.validationMeta.validatedTaxons = new Array();
  }
  doCallback = function(validatedTaxon) {
    if (typeof callback === "function") {
      callback(validatedTaxon);
    }
    return false;
  };
  if (window.validationMeta.validatedTaxons.containsObject(taxonObj)) {
    console.info("Already validated taxon, skipping revalidation", taxonObj);
    doCallback(taxonObj);
    return false;
  }
  args = "action=validate&genus=" + taxonObj.genus + "&species=" + taxonObj.species;
  if (taxonObj.subspecies != null) {
    args += "&subspecies=" + taxonObj.subspecies;
  }
  $.post("api.php", args, "json").done(function(result) {
    if (result.status) {
      taxonObj.genus = result.validated_taxon.genus;
      taxonObj.species = result.validated_taxon.species;
      taxonObj.subspecies = result.validated_taxon.subspecies;
      window.validationMeta.validatedTaxons.push(taxonObj);
    } else {
      taxonObj.invalid = true;
    }
    taxonObj.response = result;
    doCallback(taxonObj);
    return false;
  }).fail(function(result, status) {
    var prettyTaxon;
    prettyTaxon = taxonObj.genus + " " + taxonObj.species;
    prettyTaxon = taxonObj.subspecies != null ? prettyTaxon + " " + taxonObj.subspecies : prettyTaxon;
    bsAlert("<strong>Problem validating taxon:</strong> " + prettyTaxon + " couldn't be validated.");
    return console.warn("Warning: Couldn't validated " + prettyTaxon + " with AmphibiaWeb");
  });
  return false;
};

//# sourceMappingURL=maps/admin.js.map
