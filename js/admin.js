
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
var _7zHandler, alertBadProject, bootstrapTransect, bootstrapUploader, checkInitLoad, copyMarkdown, csvHandler, dataAttrs, dataFileParams, delayFimsRecheck, excelDateToUnixTime, excelHandler, excelHandler2, finalizeData, getCanonicalDataCoords, getInfoTooltip, getProjectCartoData, getTableCoordinates, getUploadIdentifier, helperDir, imageHandler, loadCreateNewProject, loadEditor, loadProject, loadProjectBrowser, loadSUProjectBrowser, mapAddPoints, mapOverlayPolygon, mintBcid, mintExpedition, newGeoDataHandler, pointStringToLatLng, pointStringToPoint, popManageUserAccess, populateAdminActions, removeDataFile, renderValidateProgress, resetForm, revalidateAndUpdateData, saveEditorData, showAddUserDialog, singleDataFileHelper, startAdminActionHelper, startEditorUploader, stopLoadBarsError, uploadedData, user, userEmail, userFullname, validateAWebTaxon, validateData, validateFimsData, validateTaxonData, verifyLoginCredentials, zipHandler,
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
  var e, error1;
  try {
    verifyLoginCredentials(function(data) {
      var articleHtml;
      articleHtml = "<h3>\n  Welcome, " + ($.cookie(adminParams.domain + "_name")) + "\n</h3>\n<section id='admin-actions-block' class=\"row center-block text-center\">\n  <div class='bs-callout bs-callout-info'>\n    <p>Please be patient while the administrative interface loads.</p>\n  </div>\n</section>";
      $("main #main-body").before(articleHtml);
      $(".fill-user-fullname").text($.cookie(adminParams.domain + "_fullname"));
      checkInitLoad(function() {
        populateAdminActions();
        return bindClicks();
      });
      return false;
    });
  } catch (error1) {
    e = error1;
    $("main #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>");
  }
  return false;
};

populateAdminActions = function() {
  var adminActions, state, url;
  url = uri.urlString + "admin-page.html";
  state = {
    "do": "home",
    prop: null
  };
  history.pushState(state, "Admin Home", url);
  $(".hanging-alert").remove();
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
  var error1, html, input, l, len, ref, state, ta, url;
  url = uri.urlString + "admin-page.html#action:create-project";
  state = {
    "do": "action",
    prop: "create-project"
  };
  history.pushState(state, "Create New Project", url);
  startAdminActionHelper();
  html = "<h2 class=\"new-title col-xs-12\">Project Title</h2>\n<paper-input label=\"Project Title\" id=\"project-title\" class=\"project-field col-md-6 col-xs-12\" required auto-validate data-field=\"project_title\"></paper-input>\n<h2 class=\"new-title col-xs-12\">Project Parameters</h2>\n<section class=\"project-inputs clearfix col-xs-12\">\n  <div class=\"row\">\n    <paper-input label=\"Primary Pathogen Studied\" id=\"project-disease\" class=\"project-field col-md-6 col-xs-8\" required auto-validate data-field=\"disease\"></paper-input>\n      " + (getInfoTooltip("Bd, Bsal, or other. If empty, we'll take it from your data.")) + "\n      <button class=\"btn btn-default fill-pathogen col-xs-1\" data-pathogen=\"Batrachochytrium dendrobatidis\">Bd</button>\n      <button class=\"btn btn-default fill-pathogen col-xs-1\" data-pathogen=\"Batrachochytrium salamandrivorans \">Bsal</button>\n    <paper-input label=\"Pathogen Strain\" id=\"project-disease-strain\" class=\"project-field col-md-6 col-xs-11\" data-field=\"disease_strain\"></paper-input>" + (getInfoTooltip("For example, Hepatitus A, B, C would enter the appropriate letter here")) + "\n    <paper-input label=\"Project Reference\" id=\"reference-id\" class=\"project-field col-md-6 col-xs-11\" data-field=\"reference_id\"></paper-input>\n    " + (getInfoTooltip("E.g.  a DOI or other reference")) + "\n    <paper-input label=\"Publication DOI\" id=\"pub-doi\" class=\"project-field col-md-6 col-xs-11\" data-field=\"publication\"></paper-input>\n    <h2 class=\"new-title col-xs-12\">Lab Parameters</h2>\n    <paper-input label=\"Project PI\" id=\"project-pi\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate data-field=\"pi_lab\"></paper-input>\n    <paper-input label=\"Project Contact\" id=\"project-author\" class=\"project-field col-md-6 col-xs-12\" value=\"" + userFullname + "\"  required auto-validate></paper-input>\n    <gold-email-input label=\"Contact Email\" id=\"author-email\" class=\"project-field col-md-6 col-xs-12\" value=\"" + userEmail + "\"  required auto-validate></gold-email-input>\n    <paper-input label=\"Diagnostic Lab\" id=\"project-lab\" class=\"project-field col-md-6 col-xs-12\"  required auto-validate></paper-input>\n    <paper-input label=\"Affiliation\" id=\"project-affiliation\" class=\"project-field col-md-6 col-xs-11\"  required auto-validate></paper-input> " + (getInfoTooltip("Of project PI. e.g., UC Berkeley")) + "\n    <h2 class=\"new-title col-xs-12\">Project Notes</h2>\n    <iron-autogrow-textarea id=\"project-notes\" class=\"project-field col-md-6 col-xs-11\" rows=\"3\" data-field=\"sample_notes\"></iron-autogrow-textarea>" + (getInfoTooltip("Project notes or brief abstract; accepts Markdown ")) + "\n    <marked-element class=\"project-param col-md-6 col-xs-12\" id=\"note-preview\">\n      <div class=\"markdown-html\"></div>\n    </marked-element>\n    <h2 class=\"new-title col-xs-12\">Data Permissions</h2>\n    <div class=\"col-xs-12\">\n      <span class=\"toggle-off-label iron-label\">Private Dataset</span>\n      <paper-toggle-button id=\"data-encumbrance-toggle\" class=\"red\">Public Dataset</paper-toggle-button>\n    </div>\n    <h2 class=\"new-title col-xs-12\">Project Area of Interest</h2>\n    <div class=\"col-xs-12\">\n      <p>\n        This represents the approximate collection region for your samples.\n        <br/>\n        <strong>\n          The last thing you do (search, build a locality, or upload data) will be your dataset's canonical locality.\n        </strong>.\n      </p>\n      <span class=\"toggle-off-label iron-label\">Locality Name</span>\n      <paper-toggle-button id=\"transect-input-toggle\">Coordinate List</paper-toggle-button>\n    </div>\n    <p id=\"transect-instructions\" class=\"col-xs-12\"></p>\n    <div id=\"transect-input\" class=\"col-md-6 col-xs-12\">\n      <div id=\"transect-input-container\" class=\"clearfix\">\n      </div>\n      <p class=\"computed-locality\" id=\"computed-locality\">\n        You may also click on the map to outline a region of interest, then click \"Build Map\" below to calculate a locality.\n      </p>\n      <br/><br/>\n      <button class=\"btn btn-primary\" disabled id=\"init-map-build\">\n        <iron-icon icon=\"maps:map\"></iron-icon>\n        Build Map\n        <small>\n          (<span class=\"points-count\">0</span> points)\n        </small>\n      </button>\n      <paper-icon-button icon=\"icons:restore\" id=\"reset-map-builder\" data-toggle=\"tooltip\" title=\"Reset Points\"></paper-icon-button>\n    </div>\n    <div id=\"carto-rendered-map\" class=\"col-md-6\">\n      <div id=\"carto-map-container\" class=\"carto-map map\">\n      </div>\n    </div>\n    <div class=\"col-xs-12\">\n      <br/>\n      <paper-checkbox checked id=\"has-data\">My project already has data</paper-checkbox>\n      <br/>\n    </div>\n  </div>\n</section>\n<section id=\"uploader-container-section\" class=\"data-section col-xs-12\">\n  <h2 class=\"new-title\">Uploading your project data</h2>\n  <p>Drag and drop as many files as you need below. </p>\n  <p>\n    Please note that the data <strong>must</strong> have a header row,\n    and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, and <code>coordinateUncertaintyInMeters</code>. Your project must also be titled before uploading data.\n  </p>\n  <div class=\"alert alert-info\" role=\"alert\">\n    We've partnered with the Biocode FIMS project and you can get a template with definitions at <a href=\"http://biscicol.org/biocode-fims/templates.jsp\" class=\"newwindow alert-link\" data-newtab=\"true\">biscicol.org <span class=\"glyphicon glyphicon-new-window\"></span></a>. Select \"Amphibian Disease\" from the dropdown menu, and select your fields for your template. Your data will be validated with the same service.\n  </div>\n  <div class=\"alert alert-warning\" role=\"alert\">\n    <strong>If the data is in Excel</strong>, ensure that it is the first sheet in the workbook. Data across multiple sheets in one workbook may be improperly processed.\n  </div>\n</section>\n<section class=\"project-inputs clearfix data-section col-xs-12\">\n  <div class=\"row\">\n    <h2 class=\"new-title col-xs-12\">Project Data Summary</h2>\n    <h3 class=\"new-title col-xs-12\">Calculated Data Parameters</h3>\n    <paper-input label=\"Samples Counted\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"samplecount\" readonly type=\"number\" data-field=\"disease_samples\"></paper-input>\n    <paper-input label=\"Positive Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"positive-samples\" readonly type=\"number\" data-field=\"disease_positive\"></paper-input>\n    <paper-input label=\"Negative Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"negative-samples\" readonly type=\"number\" data-field=\"disease_negative\"></paper-input>\n    <paper-input label=\"No Confidence Samples\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"no_confidence-samples\" readonly type=\"number\" data-field=\"disease_no_confidence\"></paper-input>\n    <paper-input label=\"Disease Morbidity\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"morbidity-count\" readonly type=\"number\" data-field=\"disease_morbidity\"></paper-input>\n    <paper-input label=\"Disease Mortality\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"mortality-count\" readonly type=\"number\" data-field=\"disease_mortality\"></paper-input>\n    <h4 class=\"new-title col-xs-12\">Species in dataset</h4>\n    <iron-autogrow-textarea id=\"species-list\" class=\"project-field col-md-6 col-xs-12\" rows=\"3\" placeholder=\"Taxon List\" readonly></iron-autogrow-textarea>\n    <p class=\"col-xs-12\">Etc</p>\n  </div>\n</section>\n<section id=\"submission-section\" class=\"col-xs-12\">\n  <div class=\"pull-right\">\n    <button id=\"upload-data\" class=\"btn btn-success click\" data-function=\"finalizeData\"><iron-icon icon=\"icons:lock-open\"></iron-icon> <span class=\"label-with-data\">Save Data &amp;</span> Create Private Project</button>\n    <button id=\"reset-data\" class=\"btn btn-danger click\" data-function=\"resetForm\">Reset Form</button>\n  </div>\n</section>";
  $("main #main-body").append(html);
  mapNewWindows();
  try {
    ref = $("paper-input[required]");
    for (l = 0, len = ref.length; l < len; l++) {
      input = ref[l];
      p$(input).validate();
    }
  } catch (error1) {
    console.warn("Couldn't pre-validate fields");
  }
  $(".fill-pathogen").click(function() {
    var pathogen;
    pathogen = $(this).attr("data-pathogen");
    p$("#project-disease").value = pathogen;
    return false;
  });
  $("#init-map-build").click(function() {
    return doMapBuilder(window.mapBuilder, null, function(map) {
      html = "<p class=\"text-muted\" id=\"computed-locality\">\n  Computed locality: <strong>" + map.locality + "</strong>\n</p>";
      $("#computed-locality").remove();
      $("#transect-input-container").after(html);
      return false;
    });
  });
  $("#reset-map-builder").click(function() {
    window.mapBuilder.points = new Array();
    $("#init-map-build").attr("disabled", "disabled");
    return $("#init-map-build .points-count").text(window.mapBuilder.points.length);
  });
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
  console.log("Getting location, prerequisite to setting up map ...");
  getLocation(function() {
    var mapOptions;
    _adp.currentLocation = new Point(window.locationData.lat, window.locationData.lng);
    mapOptions = {
      bsGrid: ""
    };
    console.log("Location fetched, setting up map ...");
    return createMap2(null, mapOptions);
  });
  bindClicks();
  return false;
};

finalizeData = function() {

  /*
   * Make sure everythign is uploaded, validate, and POST to the server
   */
  var author, dataCheck, e, error1, file, ref, title;
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
      } catch (undefined) {}
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
    file = (ref = dataFileParams != null ? dataFileParams.filePath : void 0) != null ? ref : null;
    return mintBcid(_adp.projectId, file, title, function(result) {
      var catalogNumbers, center, date, dates, dispositions, distanceFromCenter, e, el, error1, error2, error3, excursion, fieldNumbers, hull, input, key, l, len, len1, len2, m, mString, methods, months, o, point, postBBLocality, postData, ref1, ref2, ref3, ref4, ref5, ref6, row, rowLat, rowLng, sampleMethods, uDate, uTime, years;
      try {
        if (!result.status) {
          console.error(result.error);
          bsAlert(result.human_error, "danger");
          stopLoadError(result.human_error);
          return false;
        }
        dataAttrs.ark = result.ark;
        if (dataAttrs.data_ark == null) {
          dataAttrs.data_ark = new Array();
        }
        dataAttrs.data_ark.push(result.ark + "::" + dataFileParams.fileName);
        postData = new Object();
        ref1 = $(".project-field");
        for (l = 0, len = ref1.length; l < len; l++) {
          el = ref1[l];
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
          ref2 = Object.toArray(uploadedData);
          for (m = 0, len1 = ref2.length; m < len1; m++) {
            row = ref2[m];
            date = (ref3 = row.dateCollected) != null ? ref3 : row.dateIdentified;
            uTime = excelDateToUnixTime(date);
            dates.push(uTime);
            uDate = new Date(uTime);
            mString = dateMonthToString(uDate.getUTCMonth());
            if (indexOf.call(months, mString) < 0) {
              months.push(mString);
            }
            if (ref4 = uDate.getFullYear(), indexOf.call(years, ref4) < 0) {
              years.push(uDate.getFullYear());
            }
            if (row.catalogNumber != null) {
              catalogNumbers.push(row.catalogNumber);
            }
            fieldNumbers.push(row.fieldNumber);
            rowLat = row.decimalLatitude;
            rowLng = row.decimalLongitude;
            distanceFromCenter = geo.distance(rowLat, rowLng, center.lat, center.lng);
            if (distanceFromCenter > excursion) {
              excursion = distanceFromCenter;
            }
            if (row.sampleType != null) {
              if (ref5 = row.sampleType, indexOf.call(sampleMethods, ref5) < 0) {
                sampleMethods.push(row.sampleType);
              }
            }
            if (row.specimenDisposition != null) {
              if (ref6 = row.specimenDisposition, indexOf.call(dispositions, ref6) < 0) {
                dispositions.push(row.sampleDisposition);
              }
            }
          }
          console.info("Got date ranges", dates);
          months.sort();
          years.sort();
          postData.sampled_collection_start = dates.min();
          postData.sampled_collection_end = dates.max();
          console.info("Collected from", dates.min(), dates.max());
          postData.sampling_months = months.join(",");
          postData.sampling_years = years.join(",");
          console.info("Got uploaded data", uploadedData);
          postData.sample_catalog_numbers = catalogNumbers.join(",");
          postData.sample_field_numbers = fieldNumbers.join(",");
          postData.sample_methods_used = sampleMethods.join(",");
        } else {
          if (geo.canonicalHullObject != null) {
            hull = geo.canonicalHullObject.hull;
            for (o = 0, len2 = hull.length; o < len2; o++) {
              point = hull[o];
              distanceFromCenter = geo.distance(point.lat, point.lng, center.lat, center.lng);
              if (distanceFromCenter > excursion) {
                excursion = distanceFromCenter;
              }
            }
          }
        }
        if (dataFileParams != null ? dataFileParams.hasDataFile : void 0) {
          if (dataFileParams.filePath.search(helperDir === -1)) {
            dataFileParams.filePath = "" + helperDir + dataFileParams.filePath;
          }
          postData.sample_raw_data = "https://amphibiandisease.org/" + dataFileParams.filePath;
        }
        postData.lat = center.lat;
        postData.lng = center.lng;
        postData.radius = toInt(excursion * 1000);
        postBBLocality = function() {
          var args, authorData, aweb, cartoData, clade, error1, len3, q, ref7, ref8, taxonData, taxonObject;
          console.info("Computed locality " + _adp.locality);
          postData.locality = _adp.locality;
          if (geo.computedBoundingRectangle != null) {
            postData.bounding_box_n = geo.computedBoundingRectangle.north;
            postData.bounding_box_s = geo.computedBoundingRectangle.south;
            postData.bounding_box_e = geo.computedBoundingRectangle.east;
            postData.bounding_box_w = geo.computedBoundingRectangle.west;
          }
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
          try {
            postData.project_obj_id = _adp.fims.expedition.ark;
          } catch (error1) {
            mintExpedition(_adp.projectId, null, function() {
              return postBBLocality();
            });
            return false;
          }
          if (dataAttrs.data_ark == null) {
            dataAttrs.data_ark = new Array();
          }
          postData.dataset_arks = dataAttrs.data_ark.join(",");
          postData.project_dir_identifier = getUploadIdentifier();
          postData["public"] = p$("#data-encumbrance-toggle").checked;
          if ((typeof _adp !== "undefined" && _adp !== null ? (ref7 = _adp.data) != null ? (ref8 = ref7.taxa) != null ? ref8.validated : void 0 : void 0 : void 0) != null) {
            taxonData = _adp.data.taxa.validated;
            postData.sampled_clades = _adp.data.taxa.clades.join(",");
            postData.sampled_species = _adp.data.taxa.list.join(",");
            for (q = 0, len3 = taxonData.length; q < len3; q++) {
              taxonObject = taxonData[q];
              aweb = taxonObject.response.validated_taxon;
              console.info("Aweb taxon result:", aweb);
              clade = aweb.order.toLowerCase();
              key = "includes_" + clade;
              postData[key] = true;
              if ((postData.includes_anura != null) !== false && (postData.includes_caudata != null) !== false && (postData.includes_gymnophiona != null) !== false) {
                break;
              }
            }
          }
          args = "perform=new&data=" + (jsonTo64(postData));
          console.info("Data object constructed:", postData);
          return $.post(adminParams.apiTarget, args, "json").done(function(result) {
            if (result.status === true) {
              bsAlert("Project ID #<strong>" + postData.project_id + "</strong> created", "success");
              stopLoad();
              delay(1000, function() {
                return loadEditor(_adp.projectId);
              });
              toastStatusMessage("Data successfully saved to server");
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
        console.info("Checking locality ...");
        if ((geo.computedLocality != null) || !dataFileParams.hasDataFile) {
          if (geo.computedLocality != null) {
            console.info("Already have locality");
            _adp.locality = geo.computedLocality;
          } else {
            try {
              console.info("Took written locality");
              _adp.locality = p$("#locality-input").value;
            } catch (error1) {
              console.info("Can't figure out locality");
              _adp.locality = "";
            }
          }
          if (!dataFileParams.hasDataFile) {
            return mintExpedition(_adp.projectId, null, function() {
              return postBBLocality();
            });
          } else {
            return postBBLocality();
          }
        } else if (dataFileParams.hasDataFile) {
          if (center == null) {
            center = getMapCenter(geo.boundingBox);
          }
          console.info("Computing locality with reverse geocode from", center, geo.boundingBox);
          return geo.reverseGeocode(center.lat, center.lng, geo.boundingBox, function(result) {
            console.info("Computed locality " + result);
            _adp.locality = result;
            return postBBLocality();
          });
        } else {
          try {
            _adp.locality = p$("#locality-input").value;
          } catch (error2) {
            _adp.locality = "";
          }
          console.warn("How did we get to this state? No locality precomputed, no data file");
          return postBBLocality();
        }
      } catch (error3) {
        e = error3;
        stopLoadError("There was a problem with the application. Please try again later. (E-003)");
        console.error("JavaScript error in saving data (E-003)! FinalizeData said: " + e.message);
        return console.warn(e.stack);
      }
    });
  } catch (error1) {
    e = error1;
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
      var bbEW, bbNS, boundingBox, bounds, doCallback, e, error1, lat, lng, loc;
      if (status === google.maps.GeocoderStatus.OK) {
        console.info("Google said:", result);
        if (!$("#locality-lookup-result").exists()) {
          $("#carto-rendered-map").prepend("<div class=\"alert alert-info alert-dismissable\" role=\"alert\" id=\"locality-lookup-result\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>Location Found</strong>: <span class=\"lookup-name\"></span>\n</div>");
        }
        $("#locality-lookup-result .lookup-name").text(result[0].formatted_address);
        _adp.locality = result[0].formatted_address;
        loc = result[0].geometry.location;
        lat = loc.lat();
        lng = loc.lng();
        bounds = result[0].geometry.viewport;
        try {
          bbEW = bounds.R;
          bbNS = bounds.j;
          boundingBox = {
            nw: [bbEW.j, bbNS.R],
            ne: [bbEW.j, bbNS.j],
            se: [bbEW.R, bbNS.R],
            sw: [bbEW.R, bbNS.j],
            north: bbEW.j,
            south: bbEW.R,
            east: bbNS.j,
            west: bbNS.R
          };
        } catch (error1) {
          e = error1;
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
    var e, error1, mapOptions, p, postRunCallback;
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
      $("#carto-map-container").empty();
      mapOptions = {
        selector: "#carto-map-container",
        bsGrid: ""
      };
      $(mapOptions.selector).empty();
      postRunCallback = function() {
        stopLoad();
        return false;
      };
      if (geo.dataTable != null) {
        return getCanonicalDataCoords(geo.dataTable, mapOptions, function() {
          return postRunCallback();
        });
      } else {
        mapOptions.boundingBox = overlayBoundingBox;
        p = new Point(centerLat, centerLng);
        return createMap2([p], mapOptions, function() {
          return postRunCallback();
        });
      }
    } catch (error1) {
      e = error1;
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
    $("#transect-input-container").html(transectInput);
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
  var chAltPoints, chPoints, chSortedPoints, coordinateArray, cpHull, e, eastCoord, error1, gMapPaths, gMapPathsAlt, gMapPoly, gPolygon, geoJSON, geoMultiPoly, k, mpArr, northCoord, points, southCoord, temp, westCoord;
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
    } catch (error1) {
      e = error1;
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
        var e, error1;
        try {
          this.iw.open(map, this);
          return console.info("Opening infoWindow #" + this.iwk);
        } catch (error1) {
          e = error1;
          return console.error("Invalid infowindow @ " + this.iwk + "!", infoWindows, markerContainer, this.iw);
        }
      });
    }
    geo.markers = markers;
  }
  return markers;
};

getCanonicalDataCoords = function(table, options, callback) {
  if (options == null) {
    options = _adp.defaultMapOptions;
  }
  if (callback == null) {
    callback = createMap2;
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
    var args, getCols;
    getCols = "SELECT * FROM " + table + " WHERE FALSE";
    args = "action=fetch&sql_query=" + (post64(getCols));
    return $.post("api.php", args, "json").done(function(result) {
      var apiPostSqlQuery, col, colRemap, cols, colsArr, k, r, ref, sqlQuery, type, v;
      r = JSON.parse(result.post_response[0]);
      cols = new Object();
      ref = r.fields;
      for (k in ref) {
        v = ref[k];
        cols[k] = v;
      }
      _adp.activeCols = cols;
      colsArr = new Array();
      colRemap = new Object();
      for (col in cols) {
        type = cols[col];
        if (col !== "id" && col !== "the_geom") {
          colsArr.push(col);
          colRemap[col.toLowerCase()] = col;
        }
      }
      sqlQuery = "SELECT ST_AsText(the_geom), " + (colsArr.join(",")) + " FROM " + table;
      apiPostSqlQuery = encodeURIComponent(encode64(sqlQuery));
      args = "action=fetch&sql_query=" + apiPostSqlQuery;
      return $.post("api.php", args, "json").done(function(result) {
        var cartoResponse, coords, i, info, point, realRow, ref1, row, textPoint, val;
        cartoResponse = result.parsed_responses[0];
        coords = new Array();
        info = new Array();
        _adp.cartoRows = new Object();
        ref1 = cartoResponse.rows;
        for (i in ref1) {
          row = ref1[i];
          _adp.cartoRows[i] = new Object();
          for (col in row) {
            val = row[col];
            realRow = colRemap[col];
            _adp.cartoRows[i][realRow] = val;
          }
          textPoint = row.st_astext;
          if (isNull(row.infraspecificepithet)) {
            row.infraspecificepithet = "";
          }
          point = pointStringToLatLng(textPoint);
          data = {
            title: row.catalognumber + ": " + row.genus + " " + row.specificepithet + " " + row.infraspecificepithet,
            html: "<p>\n  <span class=\"sciname italic\">" + row.genus + " " + row.specificepithet + " " + row.infraspecificepithet + "</span> collected on " + row.dateidentified + "\n</p>\n<p>\n  <strong>Status:</strong>\n  Sampled by " + row.samplemethod + ", disease status " + row.diseasedetected + " for " + row.diseasetested + "\n</p>"
          };
          point.infoWindow = data;
          coords.push(point);
          info.push(data);
        }
        dataAttrs.coords = coords;
        dataAttrs.markerInfo = info;
        console.info("Calling back with", coords, options);
        return callback(coords, options);
      }).error(function(result, status) {
        if ((dataAttrs != null ? dataAttrs.coords : void 0) != null) {
          return callback(dataAttrs.coords, options);
        } else {
          stopLoadError("Couldn't get bounding coordinates from data");
          return console.error("No valid coordinates accessible!");
        }
      });
    }).error(function(result, status) {
      return false;
    });
  });
  return false;
};

getUploadIdentifier = function() {
  var author, projectIdentifier, seed;
  if (isNull(_adp.uploadIdentifier)) {
    if (isNull(_adp.projectId)) {
      author = $.cookie(adminParams.domain + "_link");
      if (isNull(_adp.projectIdentifierString)) {
        seed = isNull(p$("#project-title").value) ? randomString(16) : p$("#project-title").value;
        projectIdentifier = "t" + md5(seed + author);
        _adp.projectIdentifierString = projectIdentifier;
      }
      _adp.projectId = md5("" + projectIdentifier + author + (Date.now()));
    }
    _adp.uploadIdentifier = md5("" + user + _adp.projectId);
  }
  return _adp.uploadIdentifier;
};

bootstrapUploader = function(uploadFormId, bsColWidth, callback) {
  var author, html, projectIdentifier, selector, uploadIdentifier;
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
  author = $.cookie(adminParams.domain + "_link");
  uploadIdentifier = getUploadIdentifier();
  projectIdentifier = _adp.projectIdentifierString;
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
    window.dropperParams.uploadPath = "uploaded/" + (getUploadIdentifier()) + "/";
    needsInit = window.dropperParams.hasInitialized === true;
    loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
      var error1;
      console.info("Loaded drag drop helper");
      if (needsInit) {
        console.info("Reinitialized dropper");
        try {
          window.dropperParams.initialize();
        } catch (error1) {
          console.warn("Couldn't reinitialize dropper!");
        }
      }
      window.dropperParams.postUploadHandler = function(file, result) {

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
        var e, error2, fileName, linkPath, longType, mediaType, pathPrefix, previewHtml, thumbPath;
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
          pathPrefix = "helpers/js-dragdrop/uploaded/" + (getUploadIdentifier()) + "/";
          fileName = result.full_path.split("/").pop();
          thumbPath = result.wrote_thumb;
          mediaType = result.mime_provided.split("/")[0];
          longType = result.mime_provided.split("/")[1];
          linkPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.wrote_file : "" + pathPrefix + thumbPath;
          previewHtml = (function() {
            switch (mediaType) {
              case "image":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\" data-link-path=\"" + linkPath + "\">\n  <img src=\"" + linkPath + "\" alt='Uploaded Image' class=\"img-circle thumb-img img-responsive\"/>\n    <p class=\"text-muted\">\n      " + file.name + " -> " + fileName + "\n      (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n        Original Image\n      </a>)\n    </p>\n</div>";
              case "audio":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <audio src=\"" + linkPath + "\" controls preload=\"auto\">\n    <span class=\"glyphicon glyphicon-music\"></span>\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              case "video":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <video src=\"" + linkPath + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + thumbPath + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              default:
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\" data-link-path=\"" + linkPath + "\">\n  <span class=\"glyphicon glyphicon-file\"></span>\n  <p class=\"text-muted\">" + file.name + " -> " + fileName + "</p>\n</div>";
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
        } catch (error2) {
          e = error2;
          return toastStatusMessage("Your file uploaded successfully, but there was a problem in the post-processing.");
        }
      };
      if (typeof callback === "function") {
        return callback();
      }
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
  if (dataFileParams.hasDataFile === true && newFile !== dataFileParams.filePath) {
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

excelHandler = function(path, hasHeaders, callbackSkipsGeoHandler) {
  var args, correctedPath, helperApi;
  if (hasHeaders == null) {
    hasHeaders = true;
  }
  startLoad();
  $("#validator-progress-container").remove();
  renderValidateProgress();
  helperApi = helperDir + "excelHelper.php";
  correctedPath = path;
  if (path.search(helperDir) !== -1) {
    console.info("removing '" + helperDir + "'");
    correctedPath = path.slice(helperDir.length);
  }
  console.info("Pinging for " + correctedPath);
  args = "action=parse&path=" + correctedPath + "&sheets=Samples";
  $.get(helperApi, args, "json").done(function(result) {
    console.info("Got result", result);
    if (result.status === false) {
      bsAlert("There was a problem verifying your upload. Please try again.", "danger");
      stopLoadError("There was a problem processing your data");
      return false;
    }
    return singleDataFileHelper(path, function() {
      var nameArr, rows;
      $("#upload-data").attr("disabled", "disabled");
      nameArr = path.split("/");
      dataFileParams.hasDataFile = true;
      dataFileParams.fileName = nameArr.pop();
      dataFileParams.filePath = correctedPath;
      rows = Object.size(result.data);
      uploadedData = result.data;
      _adp.parsedUploadedData = result.data;
      if (typeof callbackSkipsGeoHandler !== "function") {
        newGeoDataHandler(result.data);
      } else {
        console.warn("Skipping newGeoDataHandler() !");
        callbackSkipsGeoHandler(result.data);
      }
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
  var nameArr;
  nameArr = path.split("/");
  dataFileParams.hasDataFile = true;
  dataFileParams.fileName = nameArr.pop();
  dataFileParams.filePath = correctedPath;
  geoDataHandler();
  return false;
};

copyMarkdown = function(selector, zeroClipEvent, html5) {
  var ark, clip, clipboardData, e, error1, url, zcConfig;
  if (html5 == null) {
    html5 = true;
  }
  if ((typeof _adp !== "undefined" && _adp !== null ? _adp.zcClient : void 0) == null) {
    zcConfig = {
      swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
    };
    ZeroClipboard.config(zcConfig);
    _adp.zcClient = new ZeroClipboard($(selector).get(0));
    $("#copy-ark").click(function() {
      return copyLink(_adp.zcClient);
    });
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
  if (typeof zeroClipObj !== "undefined" && zeroClipObj !== null) {
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

imageHandler = function(path) {
  var divEl;
  divEl = $("div[data-link-path='" + path + "']");
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
  serverPath = helperDir + "/js-dragdrop/uploaded/" + _adp.uploadIdentifier + "/" + removeFile;
  args = "action=removefile&path=" + (encode64(serverPath)) + "&user=" + user;
  return false;
};

newGeoDataHandler = function(dataObject, skipCarto) {
  var author, center, cleanValue, column, coords, coordsPoint, d, data, date, e, error1, error2, error3, error4, error5, fimsExtra, getCoordsFromData, k, missingHtml, missingRequired, missingStatement, month, n, parsedData, projectIdentifier, row, rows, sampleRow, samplesMeta, skipCol, t, tRow, totalData, trimmed, value;
  if (dataObject == null) {
    dataObject = new Object();
  }
  if (skipCarto == null) {
    skipCarto = false;
  }

  /*
   * Data expected in form
   *
   * Obj {ROW_INDEX: {"col1":"data", "col2":"data"}}
   *
   * FIMS data format:
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
   *
   * Requires columns "decimalLatitude", "decimalLongitude", "coordinateUncertaintyInMeters"
   */
  try {
    if (geo.geocoder == null) {
      try {
        geo.geocoder = new google.maps.Geocoder;
      } catch (undefined) {}
    }
    try {
      sampleRow = dataObject[0];
    } catch (error1) {
      toastStatusMessage("Your data file was malformed, and could not be parsed. Please try again.");
      removeDataFile();
      return false;
    }
    if (isNull(sampleRow.decimalLatitude) || isNull(sampleRow.decimalLongitude) || isNull(sampleRow.coordinateUncertaintyInMeters)) {
      toastStatusMessage("Data are missing required geo columns. Please reformat and try again.");
      missingStatement = "You're missing ";
      missingRequired = new Array();
      if (isNull(sampleRow.decimalLatitude)) {
        missingRequired.push("decimalLatitude");
      }
      if (isNull(sampleRow.decimalLongitude)) {
        missingRequired.push("decimalLongitude");
      }
      if (isNull(sampleRow.coordinateUncertaintyInMeters)) {
        missingRequired.push("coordinateUncertaintyInMeters");
      }
      missingStatement += missingRequired.length > 1 ? "some required columns: " : "a required column: ";
      missingHtml = missingRequired.join("</code>, <code>");
      missingStatement += "<code>" + missingHtml + "</code>";
      bsAlert(missingStatement, "danger");
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
    try {
      p$("#samplecount").value = rows;
    } catch (undefined) {}
    if (isNull($("#project-disease").val())) {
      try {
        p$("#project-disease").value = sampleRow.diseaseTested;
      } catch (undefined) {}
    }
    parsedData = new Object();
    dataAttrs.coords = new Array();
    dataAttrs.coordsFull = new Array();
    dataAttrs.fimsData = new Array();
    fimsExtra = new Object();
    toastStatusMessage("Please wait, parsing your data");
    $("#data-parsing").removeAttr("indeterminate");
    try {
      p$("#data-parsing").max = rows;
    } catch (undefined) {}
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
              stopLoadBarsError(null, "Detected an invalid number for " + column + " at row " + n + " ('" + value + "')");
              return false;
            }
            if (column === "decimalLatitude" && (-90 > value && value > 90)) {
              stopLoadBarsError(null, "Detected an invalid latitude " + value + " at row " + n);
              return false;
            }
            if (column === "decimalLongitude" && (-180 > value && value > 180)) {
              stopLoadBarsError(null, "Detected an invalid longitude " + value + " at row " + n);
              return false;
            }
            if (column === "coordinateUncertaintyInMeters" && value <= 0) {
              stopLoadBarsError(null, "Coordinate uncertainty must be >= 0 at row " + n);
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
          case "fieldNumber":
            try {
              trimmed = value.trim();
              trimmed = trimmed.replace(/^([a-zA-Z]+) (\d+)$/mg, "$1$2");
              cleanValue = trimmed;
            } catch (error2) {
              cleanValue = value;
            }
            break;
          default:
            try {
              cleanValue = value.trim();
            } catch (error3) {
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
      } catch (error4) {
        console.warn("Couldn't store FIMS extra data", fimsExtra);
      }
      parsedData[n] = tRow;
      if (modulo(n, 500) === 0 && n > 0) {
        toastStatusMessage("Processed " + n + " rows ...");
      }
      try {
        p$("#data-parsing").value = n + 1;
      } catch (undefined) {}
    }
    if (isNull(_adp.projectIdentifierString)) {
      projectIdentifier = "t" + md5(p$("#project-title").value + author);
      _adp.projectIdentifierString = projectIdentifier;
    } else {
      projectIdentifier = _adp.projectIdentifierString;
    }
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
      } catch (undefined) {}
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
      } catch (undefined) {}
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
    try {
      p$("#positive-samples").value = samplesMeta.positive;
      p$("#negative-samples").value = samplesMeta.negative;
      p$("#no_confidence-samples").value = samplesMeta.no_confidence;
      p$("#morbidity-count").value = samplesMeta.morbidity;
      p$("#mortality-count").value = samplesMeta.mortality;
    } catch (undefined) {}
    if (isNull(_adp.projectId)) {
      author = $.cookie(adminParams.domain + "_link");
      _adp.projectId = md5("" + projectIdentifier + author + (Date.now()));
    }
    totalData = {
      transectRing: geo.boundingBox,
      data: parsedData,
      samples: samplesMeta,
      dataSrc: "" + helperDir + dataFileParams.filePath
    };
    if ((typeof _adp !== "undefined" && _adp !== null ? _adp.data : void 0) == null) {
      if (typeof _adp === "undefined" || _adp === null) {
        window._adp = new Object();
      }
      window._adp.data = new Object();
    }
    _adp.data.pushDataUpload = totalData;
    validateData(totalData, function(validatedData) {
      var cladeList, e, error5, i, l, len, noticeHtml, originalTaxon, ref, ref1, taxon, taxonList, taxonListString, taxonString;
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
        if (indexOf.call(taxonList, taxonString) < 0) {
          if (i > 0) {
            taxonListString += "\n";
          }
          taxonListString += "" + taxonString;
          taxonList.push(taxonString);
        }
        try {
          if (ref1 = taxon.response.validated_taxon.family, indexOf.call(cladeList, ref1) < 0) {
            cladeList.push(taxon.response.validated_taxon.family);
          }
        } catch (error5) {
          e = error5;
          console.warn("Couldn't get the family! " + e.message, taxon.response);
          console.warn(e.stack);
        }
        ++i;
      }
      try {
        p$("#species-list").bindValue = taxonListString;
      } catch (undefined) {}
      dataAttrs.dataObj = validatedData;
      _adp.data.dataObj = validatedData;
      _adp.data.taxa = new Object();
      _adp.data.taxa.list = taxonList;
      _adp.data.taxa.clades = cladeList;
      _adp.data.taxa.validated = validatedData.validated_taxa;
      if (!(typeof skipCarto === "function" || skipCarto === true)) {
        return geo.requestCartoUpload(validatedData, projectIdentifier, "create", function(table, coords, options) {
          return createMap2(coords, options, function() {
            window.mapBuilder.points = new Array();
            $("#init-map-build").attr("disabled", "disabled");
            return $("#init-map-build .points-count").text(window.mapBuilder.points.length);
          });
        });
      } else {
        if (typeof skipCarto === "function") {
          return skipCarto(validatedData, projectIdentifier);
        } else {
          return console.warn("Carto upload was skipped, but no callback provided");
        }
      }
    });
  } catch (error5) {
    e = error5;
    console.error("Error parsing data - " + e.message);
    console.warn(e.stack);
    toastStatusMessage("There was a problem parsing your data");
  }
  return false;
};

excelDateToUnixTime = function(excelTime) {
  var daysFrom1900to1970, daysFrom1904to1970, error1, secondsPerDay, t;
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
  } catch (error1) {
    t = Date.now();
  }
  return t;
};

renderValidateProgress = function(placeAfterSelector, returnIt) {
  var html;
  if (placeAfterSelector == null) {
    placeAfterSelector = "#file-uploader-form";
  }
  if (returnIt == null) {
    returnIt = false;
  }

  /*
   * Show paper-progress bars as validation goes
   *
   * https://elements.polymer-project.org/elements/paper-progress
   */
  html = "<div id=\"validator-progress-container\" class=\"col-md-6 col-xs-12\">\n  <label for=\"data-parsing\">Data Parsing:</label><paper-progress id=\"data-parsing\" class=\"blue\" indeterminate></paper-progress>\n  <label for=\"data-validation\">Data Validation:</label><paper-progress id=\"data-validation\" class=\"cyan\" indeterminate></paper-progress>\n  <label for=\"taxa-validation\">Taxa Validation:</label><paper-progress id=\"taxa-validation\" class=\"teal\" indeterminate></paper-progress>\n  <label for=\"data-sync\">Estimated Data Sync Progress:</label><paper-progress id=\"data-sync\" indeterminate></paper-progress>\n</div>";
  if (!$("#validator-progress-container").exists()) {
    $(placeAfterSelector).after(html);
  }
  if (returnIt) {
    return html;
  }
  return false;
};

checkInitLoad = function(callback) {
  var fragment, fragmentSettings, projectId;
  $("#please-wait-prefill").remove();
  projectId = uri.o.param("id");
  if (!isNull(projectId)) {
    loadEditor(projectId);
  } else {
    if (typeof callback === "string") {
      fragment = callback;
    } else if (typeof callback === "object") {
      fragment = callback["do"] + ":" + callback.prop;
    } else {
      fragment = uri.o.attr("fragment");
    }
    if (!isNull(fragment)) {
      fragmentSettings = fragment.split(":");
      console.info("Looking at fragment", fragment, fragmentSettings);
      switch (fragmentSettings[0]) {
        case "edit":
          loadEditor(fragmentSettings[1]);
          break;
        case "action":
          switch (fragmentSettings[1]) {
            case "show-editable":
              loadEditor();
              break;
            case "create-project":
              loadCreateNewProject();
              break;
            case "show-viewable":
              loadProjectBrowser();
              break;
            case "show-su-viewable":
              loadSUProjectBrowser();
          }
          break;
        case "home":
          populateAdminActions();
      }
    } else if (typeof callback === "function") {
      callback();
    }
  }
  return false;
};

window.onpopstate = function(event) {
  console.log("State popped", event, event.state);
  checkInitLoad(event.state);
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
  checkFileVersion(false, "js/admin.min.js");
  return $("paper-icon-button[icon='icons:dashboard']").removeAttr("data-href").unbind("click").click(function() {
    return populateAdminActions();
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
    var state, url;
    startAdminActionHelper();
    url = uri.urlString + "admin-page.html#edit:" + projectId;
    state = {
      "do": "edit",
      prop: projectId
    };
    history.pushState(state, "Editing #" + projectId, url);
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
        var affixOptions, anuraState, authorData, bb, cartoParsed, caudataState, centerPoint, collectionRangePretty, conditionalReadonly, createMapOptions, creation, d1, d2, deleteCardAction, e, error, error1, error2, error3, error4, fundingHtml, googleMap, gymnophionaState, html, i, icon, l, len, len1, len2, m, mapHtml, mdFunding, mdNotes, month, monthPretty, months, monthsReal, noteHtml, o, poly, project, publicToggle, ref, ref1, ref2, ref3, ref4, ta, topPosition, uid, userHtml, year, yearPretty, years, yearsReal;
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
              delay(1000, function() {
                return loadProject(projectId);
              });
              return false;
            }
            alertBadProject(opid);
            return false;
          }
          project = result.project;
          project.access_data.total = Object.toArray(project.access_data.total);
          project.access_data.total.sort();
          project.access_data.editors_list = Object.toArray(project.access_data.editors_list);
          project.access_data.viewers_list = Object.toArray(project.access_data.viewers_list);
          project.access_data.editors = Object.toArray(project.access_data.editors);
          project.access_data.viewers = Object.toArray(project.access_data.viewers);
          console.info("Project access lists:", project.access_data);
          _adp.projectData = project;
          _adp.fetchResult = result;
          userHtml = "";
          ref1 = project.access_data.total;
          for (l = 0, len = ref1.length; l < len; l++) {
            user = ref1[l];
            try {
              uid = project.access_data.composite[user]["user_id"];
            } catch (undefined) {}
            icon = "";
            if (user === project.access_data.author) {
              icon = "<iron-icon icon=\"social:person\"></iron-icon>";
            } else if (indexOf.call(project.access_data.editors_list, user) >= 0) {
              icon = "<iron-icon icon=\"image:edit\"></iron-icon>";
            } else if (indexOf.call(project.access_data.viewers_list, user) >= 0) {
              icon = "<iron-icon icon=\"icons:visibility\"></iron-icon>";
            }
            userHtml += "<tr class=\"user-permission-list-row\" data-user=\"" + uid + "\">\n  <td colspan=\"5\">" + user + "</td>\n  <td class=\"text-center user-current-permission\">" + icon + "</td>\n</tr>";
          }
          icon = project["public"].toBool() ? "<iron-icon icon=\"social:public\" class=\"material-green\" data-toggle=\"tooltip\" title=\"Public Project\"></iron-icon>" : "<iron-icon icon=\"icons:lock\" class=\"material-red\" data-toggle=\"tooltip\" title=\"Private Project\"></iron-icon>";
          publicToggle = !project["public"].toBool() ? result.user.is_author ? "<div class=\"col-xs-12\">\n  <paper-toggle-button id=\"public\" class=\"project-params danger-toggle red\">\n    <iron-icon icon=\"icons:warning\"></iron-icon>\n    Make this project public\n  </paper-toggle-button> <span class=\"text-muted small\">Once saved, this cannot be undone</span>\n</div>" : "<!-- This user does not have permission to toggle the public state of this project -->" : "<!-- This project is already public -->";
          conditionalReadonly = result.user.has_edit_permissions ? "" : "readonly";
          anuraState = project.includes_anura.toBool() ? "checked disabled" : "disabled";
          caudataState = project.includes_caudata.toBool() ? "checked disabled" : "disabled";
          gymnophionaState = project.includes_gymnophiona.toBool() ? "checked disabled" : "disabled";
          try {
            cartoParsed = JSON.parse(deEscape(project.carto_id));
          } catch (error1) {
            console.error("Couldn't parse the carto JSON!", project.carto_id);
            stopLoadError("We couldn't parse your data. Please try again later.");
            cartoParsed = new Object();
          }
          mapHtml = "";
          try {
            bb = Object.toArray(cartoParsed.bounding_polygon);
          } catch (error2) {
            bb = null;
          }
          createMapOptions = {
            boundingBox: bb,
            classes: "carto-data map-editor",
            bsGrid: "",
            skipPoints: false,
            skipHull: false,
            onlyOne: true
          };
          geo.mapOptions = createMapOptions;
          if (((ref2 = cartoParsed.bounding_polygon) != null ? ref2.paths : void 0) == null) {
            googleMap = "<google-map id=\"transect-viewport\" latitude=\"" + project.lat + "\" longitude=\"" + project.lng + "\" fit-to-markers map-type=\"hybrid\" disable-default-ui  apiKey=\"" + gMapsApiKey + "\">\n</google-map>";
          }
          if (googleMap == null) {
            googleMap = "";
          }
          geo.googleMapWebComponent = googleMap;
          deleteCardAction = result.user.is_author ? "<div class=\"card-actions\">\n      <paper-button id=\"delete-project\"><iron-icon icon=\"icons:delete\" class=\"material-red\"></iron-icon> Delete this project</paper-button>\n    </div>" : "";
          mdNotes = isNull(project.sample_notes) ? "*No notes for this project*" : project.sample_notes.unescape();
          noteHtml = "<h3>Project Notes</h3>\n<ul class=\"nav nav-tabs\" id=\"markdown-switcher\">\n  <li role=\"presentation\" class=\"active\" data-view=\"md\"><a href=\"#markdown-switcher\">Preview</a></li>\n  <li role=\"presentation\" data-view=\"edit\"><a href=\"#markdown-switcher\">Edit</a></li>\n</ul>\n<iron-autogrow-textarea id=\"project-notes\" class=\"markdown-pair project-param\" rows=\"3\" data-field=\"sample_notes\" hidden " + conditionalReadonly + ">" + project.sample_notes + "</iron-autogrow-textarea>\n<marked-element class=\"markdown-pair\" id=\"note-preview\">\n  <div class=\"markdown-html\"></div>\n  <script type=\"text/markdown\">" + mdNotes + "</script>\n</marked-element>";
          mdFunding = isNull(project.extended_funding_reach_goals) ? "*No funding reach goals*" : project.extended_funding_reach_goals.unescape();
          fundingHtml = "<ul class=\"nav nav-tabs\" id=\"markdown-switcher-funding\">\n  <li role=\"presentation\" class=\"active\" data-view=\"md\"><a href=\"#markdown-switcher-funding\">Preview</a></li>\n  <li role=\"presentation\" data-view=\"edit\"><a href=\"#markdown-switcher-funding\">Edit</a></li>\n</ul>\n<iron-autogrow-textarea id=\"project-funding\" class=\"markdown-pair project-param\" rows=\"3\" data-field=\"extended_funding_reach_goals\" hidden " + conditionalReadonly + ">" + project.extended_funding_reach_goals + "</iron-autogrow-textarea>\n<marked-element class=\"markdown-pair\" id=\"preview-funding\">\n  <div class=\"markdown-html\"></div>\n  <script type=\"text/markdown\">" + mdFunding + "</script>\n</marked-element>";
          try {
            authorData = JSON.parse(project.author_data);
            creation = new Date(toInt(authorData.entry_date));
          } catch (error3) {
            authorData = new Object();
            creation = new Object();
            creation.toLocaleString = function() {
              return "Error retrieving creation time";
            };
          }
          monthPretty = "";
          months = project.sampling_months.split(",");
          monthsReal = new Array();
          i = 0;
          for (m = 0, len1 = months.length; m < len1; m++) {
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
              monthsReal.push(month);
              month = dateMonthToString(month);
            }
            monthPretty += month;
          }
          i = 0;
          yearPretty = "";
          years = project.sampling_years.split(",");
          yearsReal = new Array();
          i = 0;
          for (o = 0, len2 = years.length; o < len2; o++) {
            year = years[o];
            ++i;
            if (isNumber(year)) {
              yearsReal.push(toInt(year));
              if (i > 1 && i === years.length) {
                if (yearsReal.length > 2) {
                  yearPretty += ",";
                }
                yearPretty += " and ";
              } else if (i > 1) {
                yearPretty += ", ";
              }
              yearPretty += year;
            }
          }
          if (years.length === 1) {
            yearPretty = "the year " + yearPretty;
          } else {
            yearPretty = "the years " + yearPretty;
          }
          years = yearsReal;
          if (toInt(project.sampled_collection_start) > 0) {
            d1 = new Date(toInt(project.sampled_collection_start));
            d2 = new Date(toInt(project.sampled_collection_end));
            collectionRangePretty = (dateMonthToString(d1.getMonth())) + " " + (d1.getFullYear()) + " &#8212; " + (dateMonthToString(d2.getMonth())) + " " + (d2.getFullYear());
          } else {
            collectionRangePretty = "<em>(no data)</em>";
          }
          if (months.length === 0 || isNull(monthPretty)) {
            monthPretty = "<em>(no data)</em>";
          }
          if (years.length === 0 || isNull(yearPretty)) {
            yearPretty = "<em>(no data)</em>";
          }
          html = "<h2 class=\"clearfix newtitle col-xs-12\">Managing " + project.project_title + " " + icon + " <paper-icon-button icon=\"icons:visibility\" class=\"click\" data-href=\"" + uri.urlString + "/project.php?id=" + opid + "\" data-toggle=\"tooltip\" title=\"View in Project Viewer\" data-newtab=\"true\"></paper-icon-button><br/><small>Project #" + opid + "</small></h2>\n" + publicToggle + "\n<section id=\"manage-users\" class=\"col-xs-12 col-md-4 pull-right\">\n  <paper-card class=\"clearfix\" heading=\"Project Collaborators\" elevation=\"2\">\n    <div class=\"card-content\">\n      <table class=\"table table-striped table-condensed table-responsive table-hover clearfix\" id=\"permissions-table\">\n        <thead>\n          <tr>\n            <td colspan=\"5\">User</td>\n            <td>Permissions</td>\n          </tr>\n        </thead>\n        <tbody>\n          " + userHtml + "\n        </tbody>\n      </table>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button class=\"manage-users\" id=\"manage-users\">Manage Users</paper-button>\n    </div>\n  </paper-card>\n</section>\n<section id=\"project-basics\" class=\"col-xs-12 col-md-8 clearfix\">\n  <h3>Project Basics</h3>\n  <paper-input readonly label=\"Project Identifier\" value=\"" + project.project_id + "\" id=\"project_id\" class=\"project-param\"></paper-input>\n  <paper-input readonly label=\"Project Creation\" value=\"" + (creation.toLocaleString()) + "\" id=\"project_creation\" class=\"author-param\" data-key=\"entry_date\" data-value=\"" + authorData.entry_date + "\"></paper-input>\n  <paper-input readonly label=\"Project ARK\" value=\"" + project.project_obj_id + "\" id=\"project_creation\" class=\"project-param\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Project Title\" value=\"" + project.project_title + "\" id=\"project-title\" data-field=\"project_title\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Primary Pathogen\" value=\"" + project.disease + "\" data-field=\"disease\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"PI Lab\" value=\"" + project.pi_lab + "\" id=\"project-title\" data-field=\"pi_lab\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Project Reference\" value=\"" + project.reference_id + "\" id=\"project-reference\" data-field=\"reference_id\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"project-param\" label=\"Publication DOI\" value=\"" + project.publication + "\" id=\"doi\" data-field=\"publication\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"author-param\" data-key=\"name\" label=\"Project Contact\" value=\"" + authorData.name + "\" id=\"project-contact\"></paper-input>\n  <gold-email-input " + conditionalReadonly + " class=\"author-param\" data-key=\"contact_email\" label=\"Contact Email\" value=\"" + authorData.contact_email + "\" id=\"contact-email\"></gold-email-input>\n  <paper-input " + conditionalReadonly + " class=\"author-param\" data-key=\"diagnostic_lab\" label=\"Diagnostic Lab\" value=\"" + authorData.diagnostic_lab + "\" id=\"project-lab\"></paper-input>\n  <paper-input " + conditionalReadonly + " class=\"author-param\" data-key=\"affiliation\" label=\"Affiliation\" value=\"" + authorData.affiliation + "\" id=\"project-affiliation\"></paper-input>\n</section>\n<section id=\"notes\" class=\"col-xs-12 col-md-8 clearfix\">\n  " + noteHtml + "\n</section>\n<section id=\"data-management\" class=\"col-xs-12 col-md-4 pull-right\">\n  <paper-card class=\"clearfix\" heading=\"Project Data\" elevation=\"2\" id=\"data-card\">\n    <div class=\"card-content\">\n      <div class=\"variable-card-content\">\n      Your project does/does not have data associated with it. (Does should note overwrite, and link to cartoParsed.raw_data.filePath for current)\n      </div>\n      <div id=\"append-replace-data-toggle\">\n        <span class=\"toggle-off-label iron-label\">Append/Amend Data\n          <span class=\"glyphicon glyphicon-info-sign\" data-toggle=\"tooltip\" title=\"If you upload a dataset, append all rows as additional data, and modify existing ones by fieldNumber\"></span>\n        </span>\n        <paper-toggle-button id=\"replace-data-toggle\" disabled>Replace Data</paper-toggle-button>\n        <span class=\"glyphicon glyphicon-info-sign\" data-toggle=\"tooltip\" title=\"If you upload data, archive current data and only have new data parsed\"></span>\n      </div>\n      <div id=\"uploader-container-section\">\n      </div>\n    </div>\n  </paper-card>\n  <paper-card class=\"clearfix\" heading=\"Project Status\" elevation=\"2\" id=\"save-card\">\n    <div class=\"card-content\">\n      <p>Notice if there's unsaved data or not. Buttons below should dynamically disable/enable based on appropriate state.</p>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button id=\"save-project\"><iron-icon icon=\"icons:save\" class=\"material-green\"></iron-icon> Save Project</paper-button>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button id=\"reparse-project\"><iron-icon icon=\"icons:cached\" class=\"materialindigotext\"></iron-icon>Re-parse Data, Save Project &amp; Reload</paper-button>\n    </div>\n    <div class=\"card-actions\">\n      <paper-button id=\"discard-changes-exit\"><iron-icon icon=\"icons:undo\"></iron-icon> Discard Changes &amp; Exit</paper-button>\n    </div>\n    " + deleteCardAction + "\n  </paper-card>\n</section>\n<section id=\"project-data\" class=\"col-xs-12 col-md-8 clearfix\">\n  <h3>Project Data Overview</h3>\n    <h4>Project Studies:</h4>\n      <paper-checkbox " + anuraState + ">Anura</paper-checkbox>\n      <paper-checkbox " + caudataState + ">Caudata</paper-checkbox>\n      <paper-checkbox " + gymnophionaState + ">Gymnophiona</paper-checkbox>\n      <paper-input readonly label=\"Sampled Species\" value=\"" + (project.sampled_species.split(",").sort().join(", ")) + "\"></paper-input>\n      <paper-input readonly label=\"Sampled Clades\" value=\"" + (project.sampled_clades.split(",").sort().join(", ")) + "\"></paper-input>\n      <p class=\"text-muted\">\n        <span class=\"glyphicon glyphicon-info-sign\"></span> There are " + (project.sampled_species.split(",").length) + " species in this dataset, across " + (project.sampled_clades.split(",").length) + " clades\n      </p>\n    <h4>Sample Metrics</h4>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken from " + collectionRangePretty + "</p>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were taken in " + monthPretty + "</p>\n      <p class=\"text-muted\"><span class=\"glyphicon glyphicon-calendar\"></span> Data were sampled in " + yearPretty + "</p>\n      <p class=\"text-muted\"><iron-icon icon=\"icons:language\"></iron-icon> The effective project center is at (" + (roundNumberSigfig(project.lat, 6)) + ", " + (roundNumberSigfig(project.lng, 6)) + ") with a sample radius of " + project.radius + "m and a resulting locality <strong class='locality'>" + project.locality + "</strong></p>\n      <p class=\"text-muted\"><iron-icon icon=\"editor:insert-chart\"></iron-icon> The dataset contains " + project.disease_positive + " positive samples (" + (roundNumber(project.disease_positive * 100 / project.disease_samples)) + "%), " + project.disease_negative + " negative samples (" + (roundNumber(project.disease_negative * 100 / project.disease_samples)) + "%), and " + project.disease_no_confidence + " inconclusive samples (" + (roundNumber(project.disease_no_confidence * 100 / project.disease_samples)) + "%)</p>\n    <h4 id=\"map-header\">Locality &amp; Transect Data</h4>\n      <div id=\"carto-map-container\" class=\"clearfix\">\n      " + googleMap + "\n      </div>\n  <h3>Project Meta Parameters</h3>\n    <h4>Project funding status</h4>\n      " + fundingHtml + "\n      <div class=\"row\">\n        <span class=\"pull-left\" style=\"margin-top:1.75em;vertical-align:bottom;padding-left:15px\">$</span><paper-input " + conditionalReadonly + " class=\"project-param col-xs-11\" label=\"Additional Funding Request\" value=\"" + project.more_analysis_funding_request + "\" id=\"more-analysis-funding\" data-field=\"more_analysis_funding_request\" type=\"number\"></paper-input>\n      </div>\n</section>";
          $("#main-body").html(html);
          if (((ref3 = cartoParsed.bounding_polygon) != null ? ref3.paths : void 0) != null) {
            centerPoint = new Point(project.lat, project.lng);
            geo.centerPoint = centerPoint;
            geo.mapOptions = createMapOptions;
            createMap2([centerPoint], createMapOptions, function(map) {
              var tryReload;
              geo.mapOptions.selector = map.selector;
              if (!$(map.selector).exists()) {
                return (tryReload = function() {
                  if ($("#map-header").exists()) {
                    $("#map-header").after(map.html);
                    return googleMap = map.html;
                  } else {
                    return delay(250, function() {
                      return tryReload();
                    });
                  }
                })();
              }
            });
            poly = cartoParsed.bounding_polygon;
            googleMap = (ref4 = geo.googleMapWebComponent) != null ? ref4 : "";
          }
          try {
            p$("#project-notes").bindValue = project.sample_notes.unescape();
          } catch (undefined) {}
          try {
            p$("#project-funding").bindValue = project.extended_funding_reach_goals.unescape();
          } catch (undefined) {}
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
          ta = p$("#project-funding").textarea;
          $(ta).keyup(function() {
            return p$("#preview-funding").markdown = $(this).val();
          });
          $("#markdown-switcher-funding li").click(function() {
            $("#markdown-switcher-funding li").removeClass("active");
            $(".markdown-pair").removeAttr("hidden");
            $(this).addClass("active");
            switch ($(this).attr("data-view")) {
              case "md":
                return $("#project-funding").attr("hidden", "hidden");
              case "edit":
                return $("#preview-funding").attr("hidden", "hidden");
            }
          });
          $("#delete-project").click(function() {
            var confirmButton;
            confirmButton = "<paper-button id=\"confirm-delete-project\" class=\"materialred\">\n  <iron-icon icon=\"icons:warning\"></iron-icon> Confirm Project Deletion\n</paper-button>";
            $(this).replaceWith(confirmButton);
            $("#confirm-delete-project").click(function() {
              var el;
              startLoad();
              el = this;
              args = "perform=delete&id=" + project.id;
              $.post(adminParams.apiTarget, args, "json").done(function(result) {
                if (result.status === true) {
                  stopLoad();
                  toastStatusMessage("Successfully deleted Project #" + project.project_id);
                  return delay(1000, function() {
                    return populateAdminActions();
                  });
                } else {
                  stopLoadError(result.human_error);
                  return $(el).remove();
                }
              }).error(function(result, status) {
                console.error("Server error", result, status);
                return stopLoadError("Error deleting project");
              });
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
            saveEditorData(true);
            return false;
          });
          $("#discard-changes-exit").click(function() {
            showEditList();
            return false;
          });
          $("#reparse-project").click(function() {
            revalidateAndUpdateData();
            return false;
          });
          topPosition = $("#data-management").offset().top;
          affixOptions = {
            top: topPosition,
            bottom: 0,
            target: window
          };
          $("#manage-users").click(function() {
            return popManageUserAccess(_adp.projectData);
          });
          $(".danger-toggle").on("iron-change", function() {
            if ($(this).get(0).checked) {
              return $(this).find("iron-icon").addClass("material-red");
            } else {
              return $(this).find("iron-icon").removeClass("material-red");
            }
          });
          console.info("Getting carto data with id " + project.carto_id + " and options", createMapOptions);
          return getProjectCartoData(project.carto_id, createMapOptions);
        } catch (error4) {
          e = error4;
          stopLoadError("There was an error loading your project");
          console.error("Unhandled exception loading project! " + e.message);
          console.warn(e.stack);
          loadEditor();
          return false;
        }
      }).error(function(result, status) {
        stopLoadError("We couldn't load your project. Please try again.");
        return loadEditor();
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
      var args, state, url;
      url = uri.urlString + "admin-page.html#action:show-editable";
      state = {
        "do": "action",
        prop: "show-editable"
      };
      history.pushState(state, "Viewing Editable Projects", url);
      startLoad();
      args = "perform=list";
      return $.get(adminParams.apiTarget, args, "json").done(function(result) {
        var accessIcon, authoredList, html, icon, k, projectId, projectTitle, publicList, ref, ref1, ref2;
        html = "<h2 class=\"new-title col-xs-12\">Editable Projects</h2>\n<ul id=\"project-list\" class=\"col-xs-12 col-md-6\">\n</ul>";
        $("#main-body").html(html);
        publicList = new Array();
        ref = result.public_projects;
        for (k in ref) {
          projectId = ref[k];
          publicList.push(projectId);
        }
        authoredList = new Array();
        ref1 = result.authored_projects;
        for (k in ref1) {
          projectId = ref1[k];
          authoredList.push(projectId);
        }
        ref2 = result.projects;
        for (projectId in ref2) {
          projectTitle = ref2[projectId];
          accessIcon = indexOf.call(publicList, projectId) >= 0 ? "<iron-icon icon=\"social:public\"></iron-icon>" : "<iron-icon icon=\"icons:lock\"></iron-icon>";
          icon = indexOf.call(authoredList, projectId) >= 0 ? "<iron-icon icon=\"social:person\" data-toggle=\"tooltip\" title=\"Author\"></iron-icon>" : "<iron-icon icon=\"social:group\" data-toggle=\"tooltip\" title=\"Collaborator\"></iron-icon>";
          if (indexOf.call(authoredList, projectId) >= 0) {
            html = "<li>\n  <button class=\"btn btn-primary\" data-project=\"" + projectId + "\">\n    " + accessIcon + " " + projectTitle + " / #" + (projectId.substring(0, 8)) + "\n  </button>\n  " + icon + "\n</li>";
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

popManageUserAccess = function(project, result) {
  if (project == null) {
    project = _adp.projectData;
  }
  if (result == null) {
    result = _adp.fetchResult;
  }
  return verifyLoginCredentials(function(credentialResult) {
    var authorDisabled, currentPermission, currentRole, dialogHtml, editDisabled, isAuthor, isEditor, isViewer, l, len, ref, theirHtml, uid, userHtml, viewerDisabled;
    userHtml = "";
    ref = project.access_data.total;
    for (l = 0, len = ref.length; l < len; l++) {
      user = ref[l];
      uid = project.access_data.composite[user]["user_id"];
      theirHtml = user + " <span class='set-permission-block' data-user='" + uid + "'>";
      isAuthor = user === project.access_data.author;
      isEditor = indexOf.call(project.access_data.editors_list, user) >= 0;
      isViewer = !isEditor;
      editDisabled = isEditor || isAuthor ? "disabled" : "data-toggle='tooltip' title='Make Editor'";
      viewerDisabled = isViewer || isAuthor ? "disabled" : "data-toggle='tooltip' title='Make Read-Only'";
      authorDisabled = isAuthor ? "disabled" : "data-toggle='tooltip' title='Grant Ownership'";
      currentRole = isAuthor ? "author" : isEditor ? "edit" : "read";
      currentPermission = "data-current='" + currentRole + "'";
      theirHtml += "<paper-icon-button icon=\"image:edit\" " + editDisabled + " class=\"set-permission\" data-permission=\"edit\" data-user=\"" + uid + "\" " + currentPermission + "> </paper-icon-button>\n<paper-icon-button icon=\"icons:visibility\" " + viewerDisabled + " class=\"set-permission\" data-permission=\"read\" data-user=\"" + uid + "\" " + currentPermission + "> </paper-icon-button>";
      if (result.user.is_author) {
        theirHtml += "<paper-icon-button icon=\"social:person\" " + authorDisabled + " class=\"set-permission\" data-permission=\"author\" data-user=\"" + uid + "\" " + currentPermission + "> </paper-icon-button>";
      }
      if (result.user.has_edit_permissions && user !== isAuthor && user !== result.user) {
        theirHtml += "<paper-icon-button icon=\"icons:delete\" class=\"set-permission\" data-permission=\"delete\" data-user=\"" + uid + "\" " + currentPermission + ">\n</paper-icon-button>";
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
    userEmail = user;
    $(".set-permission").unbind().click(function() {
      var args, confirm, current, el, error1, j64, permission, permissionsObj;
      user = $(this).attr("data-user");
      permission = $(this).attr("data-permission");
      current = $(this).attr("data-current");
      el = this;
      if (permission !== "delete") {
        permissionsObj = {
          changes: {
            0: {
              newRole: permission,
              currentRole: current,
              uid: user
            }
          }
        };
      } else {
        try {
          confirm = $(this).attr("data-confirm").toBool();
        } catch (error1) {
          confirm = false;
        }
        if (!confirm) {
          $(this).addClass("extreme-danger").attr("data-confirm", "true");
          return false;
        }
        permissionsObj = {
          "delete": {
            0: {
              currentRole: current,
              uid: user
            }
          }
        };
      }
      startLoad();
      j64 = jsonTo64(permissionsObj);
      args = "perform=editaccess&project=" + window.projectParams.pid + "&deltas=" + j64;
      console.log("Would push args to", "" + uri.urlString + adminParams.apiTarget + "?" + args);
      $.post("" + uri.urlString + adminParams.apiTarget, args, "json").done(function(result) {
        var error, k, objPrefix, ref1, ref2, ref3, ref4, useIcon, userObj;
        console.log("Server permissions alter said", result);
        if (result.status !== true) {
          error = (ref1 = (ref2 = result.human_error) != null ? ref2 : result.error) != null ? ref1 : "We couldn't update user permissions";
          stopLoadError(error);
          return false;
        }
        if (permission !== "delete") {
          $(".set-permission-block[data-user='" + user + "'] paper-icon-button[data-permission='" + permission + "']").attr("disabled", "disabled").attr("data-current", permission);
          $(".set-permission-block[data-user='" + user + "'] paper-icon-button:not([data-permission='" + permission + "'])").removeAttr("disabled");
          useIcon = $(".set-permission-block[data-user='" + user + "'] paper-icon-button[data-permission='" + permission + "']").attr("icon");
          $(".user-permission-list-row[data-user='" + {
            user: user
          } + "'] .user-current-permission iron-icon").attr("icon", useIcon);
          toastStatusMessage(user + " granted " + permission + " permissions");
        } else {
          $(".set-permission-block[data-user='" + user + "']").parent().remove();
          $(".user-permission-list-row[data-user='" + {
            user: user
          } + "']").remove();
          toastStatusMessage("Removed " + user + " from project #" + window.projectParams.pid);
          objPrefix = current === "read" ? "viewers" : "editors";
          delete _adp.projectData.access_data.composite[userEmail];
          ref3 = _adp.projectData.access_data[objPrefix + "_list"];
          for (k in ref3) {
            userObj = ref3[k];
            try {
              if (typeof userObj !== "object") {
                continue;
              }
              if (userObj.user_id === user) {
                delete _adp.projectData.access_data[objPrefix + "_list"][k];
              }
            } catch (undefined) {}
          }
          ref4 = _adp.projectData.access_data[objPrefix];
          for (k in ref4) {
            userObj = ref4[k];
            try {
              if (typeof userObj !== "object") {
                continue;
              }
              if (userObj.user_id === user) {
                delete _adp.projectData.access_data[objPrefix][k];
              }
            } catch (undefined) {}
          }
        }
        _adp.projectData.access_data.raw = result.new_access_saved;
        return stopLoad();
      }).error(function(result, status) {
        console.error("Server error", result, status);
        return stopLoadError("Problem changing permissions");
      });
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

showAddUserDialog = function(refAccessList) {

  /*
   * Open up a dialog to show the "Add a user" interface
   *
   * @param Array refAccessList  -> array of emails already with access
   */
  var dialogHtml;
  dialogHtml = "<paper-dialog modal id=\"add-new-user\">\n<h2>Add New User To Project</h2>\n<paper-dialog-scrollable>\n  <p>Search by email, real name, or username below. Click on a search result to queue a user for adding.</p>\n  <div class=\"form-horizontal\" id=\"search-user-form-container\">\n    <div class=\"form-group\">\n      <label for=\"search-user\" class=\"sr-only form-label\">Search User</label>\n      <input type=\"text\" id=\"search-user\" name=\"search-user\" class=\"form-control\"/>\n    </div>\n    <paper-material id=\"user-search-result-container\" class=\"pop-result\" hidden>\n      <div class=\"result-list\">\n      </div>\n    </paper-material>\n  </div>\n  <p>Adding users:</p>\n  <ul class=\"simple-list\" id=\"user-add-queue\">\n    <!--\n      <li class=\"list-add-users\" data-uid=\"789\">\n        jsmith@sample.com\n      </li>\n    -->\n  </ul>\n</paper-dialog-scrollable>\n<div class=\"buttons\">\n  <paper-button id=\"add-user\"><iron-icon icon=\"social:person-add\"></iron-icon> Save Additions</paper-button>\n  <paper-button dialog-dismiss>Cancel</paper-button>\n</div>\n</paper-dialog>";
  if (!$("#add-new-user").exists()) {
    $("body").append(dialogHtml);
  }
  safariDialogHelper("#add-new-user");
  $("#search-user").keyup(function() {
    var searchHelper;
    console.log("Should search", $(this).val());
    searchHelper = function() {
      var search;
      search = $("#search-user").val();
      if (isNull(search)) {
        return $("#user-search-result-container").prop("hidden", "hidden");
      } else {
        return $.post(uri.urlString + "/api.php", "action=search_users&q=" + search, "json").done(function(result) {
          var badge, bonusClass, html, l, len, prefix, users;
          console.info(result);
          users = Object.toArray(result.result);
          if (users.length > 0) {
            $("#user-search-result-container").removeAttr("hidden");
            html = "";
            for (l = 0, len = users.length; l < len; l++) {
              user = users[l];
              if (_adp.projectData.access_data.composite[user.email] != null) {
                prefix = "<iron-icon icon=\"icons:done-all\" class=\"materialgreen round\"></iron-icon>";
                badge = "<paper-badge for=\"" + user.uid + "-email\" icon=\"icons:done-all\" label=\"Already Added\"> </paper-badge>";
                bonusClass = "noclick";
              } else {
                prefix = "";
                badge = "";
                bonusClass = "";
              }
              html += "<div class=\"user-search-result " + bonusClass + "\" data-uid=\"" + user.uid + "\" id=\"" + user.uid + "-result\">\n  <span class=\"email search-result-detail\" id=\"" + user.uid + "-email\">" + prefix + user.email + "</span>\n    |\n  <span class=\"name search-result-detail\" id=\"" + user.uid + "-name\">" + user.full_name + "</span>\n    |\n  <span class=\"user search-result-detail\" id=\"" + user.uid + "-handle\">" + user.handle + "</span></div>";
            }
            $("#user-search-result-container").html(html);
            return $(".user-search-result:not(.noclick)").click(function() {
              var email, len1, listHtml, m, ref, uid;
              uid = $(this).attr("data-uid");
              console.info("Clicked on " + uid);
              email = $(this).find(".email").text();
              if ((typeof _adp !== "undefined" && _adp !== null ? _adp.currentQueueUids : void 0) == null) {
                if (typeof _adp === "undefined" || _adp === null) {
                  window._adp = new Object();
                }
                _adp.currentQueueUids = new Array();
              }
              ref = $("#user-add-queue .list-add-users");
              for (m = 0, len1 = ref.length; m < len1; m++) {
                user = ref[m];
                _adp.currentQueueUids.push($(user).attr("data-uid"));
              }
              if (indexOf.call(refAccessList, email) < 0) {
                if (indexOf.call(_adp.currentQueueUids, uid) < 0) {
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
          } else {
            return $("#user-search-result-container").prop("hidden", "hidden");
          }
        }).error(function(result, status) {
          return console.error(result, status);
        });
      }
    };
    return searchHelper.debounce();
  });
  $("#add-user").click(function() {
    var args, jsonUids, l, len, ref, toAddEmails, toAddUids, uidArgs;
    startLoad();
    toAddUids = new Array();
    toAddEmails = new Array();
    ref = $("#user-add-queue .list-add-users");
    for (l = 0, len = ref.length; l < len; l++) {
      user = ref[l];
      toAddUids.push($(user).attr("data-uid"));
      toAddEmails.push(user);
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
    console.log("Would push args to", adminParams.apiTarget + "?" + args);
    return $.post(adminParams.apiTarget, args, "json").done(function(result) {
      var error, html, i, icon, len1, m, ref1, ref2, tense, uid, userObj;
      console.log("Server permissions said", result);
      if (result.status !== true) {
        error = (ref1 = (ref2 = result.human_error) != null ? ref2 : result.error) != null ? ref1 : "We couldn't update user permissions";
        stopLoadError(error);
        return false;
      }
      stopLoad();
      tense = toAddUids.length === 1 ? "viewer" : "viewers";
      toastStatusMessage("Successfully added " + toAddUids.length + " " + tense + " to the project");
      $("#user-add-queue").empty();
      icon = "<iron-icon icon=\"icons:visibility\"></iron-icon>";
      i = 0;
      for (m = 0, len1 = toAddUids.length; m < len1; m++) {
        uid = toAddUids[m];
        user = toAddEmails[i];
        ++i;
        html = "<tr class=\"user-permission-list-row\" data-user=\"" + uid + "\">\n  <td colspan=\"5\">" + user + "</td>\n  <td class=\"text-center user-current-permission\">" + icon + "</td>\n</tr>";
        $("#permissions-table").append(html);
        userObj = {
          email: user,
          user_id: uid,
          permission: "READ"
        };
        _adp.projectData.access_data.total.push(user);
        _adp.projectData.access_data.viewers_list.push(user);
        _adp.projectData.access_data.viewers.push(userObj);
        _adp.projectData.access_data.raw = result.new_access_saved;
        _adp.projectData.access_data.composite[user] = userObj;
      }
      return p$("#add-new-user").close();
    }).error(function(result, status) {
      return console.error("Server error", result, status);
    });
  });
  return false;
};

getProjectCartoData = function(cartoObj, mapOptions) {

  /*
   * Get the data from CartoDB, map it out, show summaries, etc.
   *
   * @param string|Object cartoObj -> the (JSON formatted) carto data blob.
   */
  var args, cartoData, cartoTable, error1, getCols, zoom;
  if (typeof cartoObj !== "object") {
    try {
      cartoData = JSON.parse(deEscape(cartoObj));
    } catch (error1) {
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
  } catch (undefined) {}
  getCols = "SELECT * FROM " + table + " WHERE FALSE";
  args = "action=fetch&sql_query=" + (post64(getCols));
  $.post("api.php", args, "json").done(function(result) {
    var apiPostSqlQuery, cartoQuery, col, colRemap, cols, colsArr, filePath, html, k, r, ref, type, v;
    r = JSON.parse(result.post_response[0]);
    cols = new Object();
    ref = r.fields;
    for (k in ref) {
      v = ref[k];
      cols[k] = v;
    }
    _adp.activeCols = cols;
    colsArr = new Array();
    colRemap = new Object();
    for (col in cols) {
      type = cols[col];
      if (col !== "id" && col !== "the_geom") {
        colsArr.push(col);
        colRemap[col.toLowerCase()] = col;
      }
    }
    cartoQuery = "SELECT " + (colsArr.join(",")) + ", ST_asGeoJSON(the_geom) FROM " + cartoTable + ";";
    console.info("Would ping cartodb with", cartoQuery);
    apiPostSqlQuery = encodeURIComponent(encode64(cartoQuery));
    args = "action=fetch&sql_query=" + apiPostSqlQuery;
    $.post("api.php", args, "json").done(function(result) {
      var base, base1, center, error, error2, geoJson, i, infoWindow, lat, lng, marker, note, point, pointArr, realRow, ref1, ref2, ref3, ref4, ref5, ref6, ref7, row, rows, taxa, totalRows, truncateLength, val, workingMap;
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
      _adp.cartoRows = new Object();
      for (i in rows) {
        row = rows[i];
        _adp.cartoRows[i] = new Object();
        for (col in row) {
          val = row[col];
          realRow = colRemap[col];
          _adp.cartoRows[i][realRow] = val;
        }
      }
      truncateLength = 0 - "</google-map>".length;
      try {
        workingMap = geo.googleMapWebComponent.slice(0, truncateLength);
      } catch (error2) {
        workingMap = "<google-map>";
      }
      pointArr = new Array();
      for (k in rows) {
        row = rows[k];
        geoJson = JSON.parse(row.st_asgeojson);
        lat = geoJson.coordinates[0];
        lng = geoJson.coordinates[1];
        point = new Point(lat, lng);
        point.infoWindow = new Object();
        point.data = row;
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
        infoWindow = "<p>\n  <em>" + row.genus + " " + row.specificepithet + "</em> " + note + "\n  <br/>\n  Tested <strong>" + row.diseasedetected + "</strong> for " + row.diseasetested + "\n</p>";
        point.infoWindow.html = infoWindow;
        marker = "<google-map-marker latitude=\"" + lat + "\" longitude=\"" + lng + "\" data-disease-detected=\"" + row.diseasedetected + "\">\n" + infoWindow + "\n</google-map-marker>";
        workingMap += marker;
        pointArr.push(point);
      }
      if (!(((cartoData != null ? (ref2 = cartoData.bounding_polygon) != null ? ref2.paths : void 0 : void 0) != null) && ((cartoData != null ? (ref3 = cartoData.bounding_polygon) != null ? ref3.fillColor : void 0 : void 0) != null))) {
        try {
          _adp.canonicalHull = createConvexHull(pointArr, true);
          try {
            cartoObj = new Object();
            if (cartoData == null) {
              cartoData = new Object();
            }
            if (cartoData.bounding_polygon == null) {
              cartoData.bounding_polygon = new Object();
            }
            cartoData.bounding_polygon.paths = _adp.canonicalHull.hull;
            if ((base = cartoData.bounding_polygon).fillOpacity == null) {
              base.fillOpacity = defaultFillOpacity;
            }
            if ((base1 = cartoData.bounding_polygon).fillColor == null) {
              base1.fillColor = defaultFillColor;
            }
            _adp.projectData.carto_id = JSON.stringify(cartoData);
          } catch (undefined) {}
        } catch (undefined) {}
      }
      totalRows = (ref4 = result.parsed_responses[0].total_rows) != null ? ref4 : 0;
      if (pointArr.length > 0 || (mapOptions != null ? (ref5 = mapOptions.boundingBox) != null ? ref5.length : void 0 : void 0) > 0) {
        mapOptions.skipHull = false;
        if (pointArr.length === 0) {
          center = (ref6 = (ref7 = geo.centerPoint) != null ? ref7 : [mapOptions.boundingBox[0].lat, mapOptions.boundingBox[0].lng]) != null ? ref6 : [window.locationData.lat, window.locationData.lng];
          pointArr.push(center);
        }
        mapOptions.onClickCallback = function() {
          return console.log("No callback for data-provided maps.");
        };
        return createMap2(pointArr, mapOptions, function(map) {
          var after;
          after = "<p class=\"text-muted\"><span class=\"glyphicon glyphicon-info-sign\"></span> There are <span class='carto-row-count'>" + totalRows + "</span> sample points in this dataset</p>";
          $(map.selector).after;
          return stopLoad();
        });
      } else {
        console.info("Classic render.", mapOptions, pointArr.length);
        workingMap += "</google-map>\n<p class=\"text-muted\"><span class=\"glyphicon glyphicon-info-sign\"></span> There are <span class='carto-row-count'>" + totalRows + "</span> sample points in this dataset</p>";
        $("#transect-viewport").replaceWith(workingMap);
        return stopLoad();
      }
    }).fail(function(result, status) {
      console.error("Couldn't talk to back end server to ping carto!");
      return stopLoadError("There was a problem communicating with the server. Please try again in a bit. (E-002)");
    });
    window.dataFileparams = cartoData.raw_data;
    if (cartoData.raw_data.hasDataFile) {
      filePath = cartoData.raw_data.filePath;
      if (filePath.search(helperDir) === -1) {
        filePath = "" + helperDir + filePath;
      }
      html = "<p>\n  Your project already has data associated with it. <span id=\"last-modified-file\"></span>\n</p>\n<button id=\"download-project-file\" class=\"btn btn-primary center-block click download-file\" data-href=\"" + filePath + "\"><iron-icon icon=\"icons:cloud-download\"></iron-icon> Download File</button>\n<p>You can upload more data below, or replace this existing data.</p>";
      $("#data-card .card-content .variable-card-content").html(html);
      args = "do=get_last_mod&file=" + filePath;
      console.info("Timestamp: ", uri.urlString + "meta.php?" + args);
      $.get("meta.php", args, "json").done(function(result) {
        var iso, t, time, timeString;
        time = toInt(result.last_mod) * 1000;
        console.log("Last modded", time, result);
        if (isNumber(time)) {
          t = new Date(time);
          iso = t.toISOString();
          timeString = "" + (iso.slice(0, iso.search("T")));
          $("#last-modified-file").text("Last uploaded on " + timeString + ".");
          bindClicks();
        } else {
          console.warn("Didn't get a number back to check last mod time for " + filePath);
        }
        return false;
      }).fail(function(result, status) {
        console.warn("Couldn't get last mod time for " + filePath);
        return false;
      });
    } else {
      $("#data-card .card-content .variable-card-content").html("<p>You can upload data to your project here:</p>");
      $("#append-replace-data-toggle").attr("hidden", "hidden");
    }
    return startEditorUploader();
  }).error(function(result, status) {
    return false;
  });
  return false;
};

startEditorUploader = function() {
  var animations;
  if (!$("link[href='components/neon-animation/animations/fade-out-animation.html']").exists()) {
    animations = "<link rel=\"import\" href=\"components/neon-animation/animations/fade-in-animation.html\" />\n<link rel=\"import\" href=\"components/neon-animation/animations/fade-out-animation.html\" />";
    $("head").append(animations);
  }
  bootstrapUploader("data-card-uploader", "", function() {
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
      var dialogHtml, e, error1, fileName, html, linkPath, longType, mediaType, pathPrefix, previewHtml, thumbPath;
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
        html = renderValidateProgress("dont-exist", true);
        dialogHtml = "  <paper-dialog modal id=\"upload-progress-dialog\"\n    entry-animation=\"fade-in-animation\"\n    exit-animation=\"fade-out-animation\">\n    <h2>Upload Progress</h2>\n    <paper-dialog-scrollable>\n      <div id=\"upload-progress-container\" style=\"min-width:80vw; \">\n      </div>\n      " + html + "\n<p class=\"col-xs-12\">Species in dataset</p>\n<iron-autogrow-textarea id=\"species-list\" class=\"project-field  col-xs-12\" rows=\"3\" placeholder=\"Taxon List\" readonly></iron-autogrow-textarea>\n    </paper-dialog-scrollable>\n    <div class=\"buttons\">\n      <paper-button id=\"close-overlay\">Close</paper-button>\n    </div>\n  </paper-dialog>";
        $("#upload-progress-dialog").remove();
        $("body").append(dialogHtml);
        p$("#upload-progress-dialog").open();
        $("#close-overlay").click(function() {
          return p$("#upload-progress-dialog").close();
        });
        console.info("Server returned the following result:", result);
        console.info("The script returned the following file information:", file);
        pathPrefix = "helpers/js-dragdrop/uploaded/" + (getUploadIdentifier()) + "/";
        fileName = result.full_path.split("/").pop();
        thumbPath = result.wrote_thumb;
        mediaType = result.mime_provided.split("/")[0];
        longType = result.mime_provided.split("/")[1];
        linkPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.wrote_file : "" + pathPrefix + thumbPath;
        previewHtml = (function() {
          switch (mediaType) {
            case "image":
              return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <img src=\"" + linkPath + "\" alt='Uploaded Image' class=\"img-circle thumb-img img-responsive\"/>\n    <p class=\"text-muted\">\n      " + file.name + " -> " + fileName + "\n  (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n    Original Image\n  </a>)\n    </p>\n</div>";
            case "audio":
              return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <audio src=\"" + linkPath + "\" controls preload=\"auto\">\n    <span class=\"glyphicon glyphicon-music\"></span>\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
            case "video":
              return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <video src=\"" + linkPath + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + thumbPath + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
            default:
              return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\" data-link-path=\"" + linkPath + "\">\n  <span class=\"glyphicon glyphicon-file\"></span>\n  <p class=\"text-muted\">" + file.name + " -> " + fileName + "</p>\n</div>";
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
                excelHandler2(linkPath);
                break;
              case "zip":
              case "x-zip-compressed":
                if (file.type === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || linkPath.split(".").pop() === "xlsx") {
                  excelHandler2(linkPath);
                } else {
                  zipHandler(linkPath);
                }
                break;
              case "x-7z-compressed":
                _7zHandler(linkPath);
                p$("#upload-progress-dialog").close();
            }
            break;
          case "text":
            csvHandler();
            p$("#upload-progress-dialog").close();
            break;
          case "image":
            imageHandler();
            p$("#upload-progress-dialog").close();
        }
      } catch (error1) {
        e = error1;
        toastStatusMessage("Your file uploaded successfully, but there was a problem in the post-processing.");
      }
      return false;
    };
  });
  return false;
};

excelHandler2 = function(path, hasHeaders, callbackSkipsRevalidate) {
  var args, correctedPath, helperApi;
  if (hasHeaders == null) {
    hasHeaders = true;
  }
  startLoad();
  $("#validator-progress-container").remove();
  renderValidateProgress("#upload-progress-container");
  helperApi = helperDir + "excelHelper.php";
  correctedPath = path;
  if (path.search(helperDir) !== -1) {
    console.info("removing '" + helperDir + "'");
    correctedPath = path.slice(helperDir.length);
  }
  console.info("Pinging for " + correctedPath);
  args = "action=parse&path=" + correctedPath + "&sheets=Samples";
  $.get(helperApi, args, "json").done(function(result) {
    var nameArr, rows;
    console.info("Got result", result);
    if (result.status === false) {
      bsAlert("There was a problem verifying your upload. Please try again.", "danger");
      stopLoadError("There was a problem processing your data");
      return false;
    }
    $("#upload-data").attr("disabled", "disabled");
    nameArr = path.split("/");
    dataFileParams.hasDataFile = true;
    dataFileParams.fileName = nameArr.pop();
    dataFileParams.filePath = correctedPath;
    rows = Object.size(result.data);
    uploadedData = result.data;
    _adp.parsedUploadedData = result.data;
    if (typeof callbackSkipsRevalidate !== "function") {
      revalidateAndUpdateData(result);
    } else {
      console.warn("Skipping Revalidator() !");
      callbackSkipsRevalidate(result);
    }
    return stopLoad();
  }).fail(function(result, error) {
    console.error("Couldn't POST");
    console.warn(result, error);
    return stopLoadError();
  });
  return false;
};

revalidateAndUpdateData = function(newFilePath) {
  var cartoData, dataCallback, dialogHtml, error1, html, link, passedData, path, ref, ref1, skipHandler;
  if (newFilePath == null) {
    newFilePath = false;
  }
  if (!$("#upload-progress-dialog").exists()) {
    html = renderValidateProgress("dont-exist", true);
    dialogHtml = "  <paper-dialog modal id=\"upload-progress-dialog\"\n    entry-animation=\"fade-in-animation\"\n    exit-animation=\"fade-out-animation\">\n    <h2>Upload Progress</h2>\n    <paper-dialog-scrollable>\n      <div id=\"upload-progress-container\" style=\"min-width:80vw; \">\n      </div>\n      " + html + "\n<p class=\"col-xs-12\">Species in dataset</p>\n<iron-autogrow-textarea id=\"species-list\" class=\"project-field  col-xs-12\" rows=\"3\" placeholder=\"Taxon List\" readonly></iron-autogrow-textarea>\n    </paper-dialog-scrollable>\n    <div class=\"buttons\">\n      <paper-button id=\"close-overlay\">Close</paper-button>\n    </div>\n  </paper-dialog>";
    $("#upload-progress-dialog").remove();
    $("body").append(dialogHtml);
    p$("#upload-progress-dialog").open();
    $("#close-overlay").click(function() {
      return p$("#upload-progress-dialog").close();
    });
  }
  try {
    cartoData = JSON.parse(_adp.projectData.carto_id.unescape());
    _adp.cartoData = cartoData;
  } catch (error1) {
    link = $.cookie(uri.domain + "_link");
    cartoData = {
      table: _adp.projectIdentifierString + ("_" + link),
      bounding_polygon: new Object()
    };
  }
  skipHandler = false;
  if (newFilePath !== false) {
    if (typeof newFilePath === "object") {
      skipHandler = true;
      passedData = newFilePath.data;
      path = newFilePath.path.requested_path;
    } else {
      path = newFilePath;
    }
  } else {
    path = _adp.projectData.sample_raw_data.slice(uri.urlString.length);
    if (path == null) {
      if ((dataFileParams != null ? dataFileParams.filePath : void 0) != null) {
        path = dataFileParams.filePath;
      } else {
        path = cartoData.raw_data.filePath;
      }
    }
  }
  _adp.projectIdentifierString = cartoData.table.split("_")[0];
  _adp.projectId = _adp.projectData.project_id;
  if (((ref = _adp.fims) != null ? (ref1 = ref.expedition) != null ? ref1.expeditionId : void 0 : void 0) == null) {
    _adp.fims = {
      expedition: {
        expeditionId: 26,
        ark: _adp.projectData.project_obj_id
      }
    };
  }
  dataCallback = function(data) {
    var allowedOperations, operation;
    allowedOperations = ["edit", "create"];
    operation = p$("#replace-data-toggle").checked ? "create" : "edit";
    if (indexOf.call(allowedOperations, operation) < 0) {
      console.error(operation + " is not an allowed operation on a data set!");
      console.info("Allowed operations are ", allowedOperations);
      toastStatusMessage("Sorry, '" + operation + "' isn't an allowed operation.");
      return false;
    }
    if (operation === "create") {
      newGeoDataHandler(data, function(validatedData, projectIdentifier) {
        geo.requestCartoUpload(validatedData, projectIdentifier, "create", function(table, coords, options) {
          bsAlert("Hang on for a moment while we reprocess this for saving", "info");
          cartoData.table = geo.dataTable;
          _adp.projectData.carto_id = JSON.stringify(cartoData);
          path = dataFileParams.filePath;
          revalidateAndUpdateData(path);
          return false;
        });
        return false;
      });
      return false;
    }
    newGeoDataHandler(data, function(validatedData, projectIdentifier) {
      var args, dataTable, hash, secret;
      console.info("Ready to update", validatedData);
      dataTable = cartoData.table;
      data = validatedData.data;
      if (typeof data !== "object") {
        console.info("This function requires the base data to be a JSON object.");
        toastStatusMessage("Your data is malformed. Please double check your data and try again.");
        return false;
      }
      if (isNull(dataTable)) {
        console.error("Must use a defined table name!");
        toastStatusMessage("You must name your data table");
        return false;
      }
      link = $.cookie(uri.domain + "_link");
      hash = $.cookie(uri.domain + "_auth");
      secret = $.cookie(uri.domain + "_secret");
      if (!((link != null) && (hash != null) && (secret != null))) {
        console.error("You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret);
        toastStatusMessage("Sorry, you're not logged in. Please log in and try again.");
        return false;
      }
      args = "hash=" + hash + "&secret=" + secret + "&dblink=" + link;
      if ((typeof adminParams !== "undefined" && adminParams !== null ? adminParams.apiTarget : void 0) == null) {
        console.warn("Administration file not loaded. Upload cannot continue");
        stopLoadError("Administration file not loaded. Upload cannot continue");
        return false;
      }
      return $.post(adminParams.apiTarget, args, "json").done(function(result) {
        var alt, bb_east, bb_north, bb_south, bb_west, colArr, column, columnDatatype, columnNamesList, coordinate, coordinatePair, dataGeometry, defaultPolygon, e, err, error2, error3, error4, fieldNumber, geoJson, geoJsonGeom, geoJsonVal, i, iIndex, l, lat, lats, len, len1, ll, lng, lngs, lookupMap, m, n, ref2, ref3, ref4, ref5, ref6, refRow, refRowNum, row, sampleLatLngArray, sqlQuery, sqlWhere, transectPolygon, trimmed, userTransectRing, value, valuesArr, valuesList;
        if (result.status) {
          console.info("Validated data", validatedData);
          sampleLatLngArray = new Array();
          lats = new Array();
          lngs = new Array();
          for (n in data) {
            row = data[n];
            ll = new Array();
            for (column in row) {
              value = row[column];
              switch (column) {
                case "decimalLongitude":
                  ll[1] = value;
                  lngs.push(value);
                  break;
                case "decimalLatitude":
                  ll[0] = value;
                  lats.push(value);
              }
            }
            sampleLatLngArray.push(ll);
          }
          bb_north = (ref2 = lats.max()) != null ? ref2 : 0;
          bb_south = (ref3 = lats.min()) != null ? ref3 : 0;
          bb_east = (ref4 = lngs.max()) != null ? ref4 : 0;
          bb_west = (ref5 = lngs.min()) != null ? ref5 : 0;
          defaultPolygon = [[bb_north, bb_west], [bb_north, bb_east], [bb_south, bb_east], [bb_south, bb_west]];
          try {
            if (typeof data.transectRing === "string") {
              userTransectRing = JSON.parse(validatedData.transectRing);
            } else {
              userTransectRing = validatedData.transectRing;
            }
            userTransectRing = Object.toArray(userTransectRing);
            i = 0;
            for (l = 0, len = userTransectRing.length; l < len; l++) {
              coordinatePair = userTransectRing[l];
              if (coordinatePair instanceof Point) {
                coordinatePair = coordinatePair.toGeoJson();
                userTransectRing[i] = coordinatePair;
              }
              if (coordinatePair.length !== 2) {
                throw {
                  message: "Bad coordinate length for '" + coordinatePair + "'"
                };
              }
              for (m = 0, len1 = coordinatePair.length; m < len1; m++) {
                coordinate = coordinatePair[m];
                if (!isNumber(coordinate)) {
                  throw {
                    message: "Bad coordinate number '" + coordinate + "'"
                  };
                }
              }
              ++i;
            }
          } catch (error2) {
            e = error2;
            console.warn("Error parsing the user transect ring - " + e.message);
            userTransectRing = void 0;
          }
          transectPolygon = userTransectRing != null ? userTransectRing : defaultPolygon;
          geoJson = {
            type: "GeometryCollection",
            geometries: [
              {
                type: "MultiPoint",
                coordinates: sampleLatLngArray
              }, {
                type: "Polygon",
                coordinates: transectPolygon
              }
            ]
          };
          dataGeometry = "ST_AsBinary(" + (JSON.stringify(geoJson)) + ", 4326)";
          columnDatatype = getColumnObj();
          try {
            lookupMap = new Object();
            ref6 = _adp.cartoRows;
            for (i in ref6) {
              row = ref6[i];
              fieldNumber = row.fieldNumber;
              try {
                trimmed = fieldNumber.trim();
              } catch (error3) {
                continue;
              }
              trimmed = trimmed.replace(/^([a-zA-Z]+) (\d+)$/mg, "$1$2");
              fieldNumber = trimmed;
              lookupMap[fieldNumber] = i;
            }
          } catch (error4) {
            console.warn("Couldn't make lookupMap");
          }
          sqlQuery = "";
          valuesList = new Array();
          columnNamesList = new Array();
          columnNamesList.push("id int");
          _adp.rowsCount = Object.size(data);
          for (i in data) {
            row = data[i];
            i = toInt(i);
            valuesArr = new Array();
            lat = 0;
            lng = 0;
            alt = 0;
            err = 0;
            geoJsonGeom = {
              type: "Point",
              coordinates: new Array()
            };
            iIndex = i + 1;
            fieldNumber = row.fieldNumber;
            try {
              refRowNum = lookupMap[fieldNumber];
            } catch (undefined) {}
            refRow = null;
            if (refRowNum != null) {
              refRow = _adp.cartoRows[refRowNum];
            }
            colArr = new Array();
            for (column in row) {
              value = row[column];
              if (i === 0) {
                columnNamesList.push(column + " " + columnDatatype[column]);
              }
              try {
                value = value.replace("'", "&#95;");
              } catch (undefined) {}
              switch (column) {
                case "decimalLongitude":
                  geoJsonGeom.coordinates[1] = value;
                  break;
                case "decimalLatitude":
                  geoJsonGeom.coordinates[0] = value;
                  break;
                case "fieldNumber":
                  if (refRow != null) {
                    continue;
                  }
              }
              if (refRow != null) {
                if (refRow[column] === value) {
                  continue;
                }
              }
              if (typeof value === "string") {
                if (refRow != null) {
                  valuesArr.push((column.toLowerCase()) + "='" + value + "'");
                } else {
                  valuesArr.push("'" + value + "'");
                }
              } else if (isNull(value)) {
                if (refRow != null) {
                  valuesArr.push((column.toLowerCase()) + "=null");
                } else {
                  valuesArr.push("null");
                }
              } else {
                if (refRow != null) {
                  valuesArr.push((column.toLowerCase()) + "=" + value);
                } else {
                  valuesArr.push(value);
                }
              }
              colArr.push(column);
            }
            geoJsonVal = "ST_SetSRID(ST_Point(" + geoJsonGeom.coordinates[0] + "," + geoJsonGeom.coordinates[1] + "),4326)";
            if (refRow != null) {
              valuesArr.push("the_geom=" + geoJsonVal);
            } else {
              colArr.push("the_geom");
              valuesArr.push(geoJsonVal);
            }
            if (refRow != null) {
              sqlWhere = " WHERE fieldnumber='" + fieldNumber + "';";
              sqlQuery += "UPDATE " + dataTable + " SET " + (valuesArr.join(", ")) + " " + sqlWhere;
            } else {
              sqlQuery += "INSERT INTO " + dataTable + " (" + (colArr.join(",")) + ") VALUES (" + (valuesArr.join(",")) + "); ";
            }
          }
          console.log(sqlQuery);
          foo();
          return false;
          geo.postToCarto(sqlQuery, dataTable, function(table, coords, options) {
            var faux;
            console.info("Post carto callback fn");
            try {
              p$("#taxa-validation").value = 0;
              p$("#taxa-validation").indeterminate = true;
            } catch (undefined) {}
            _adp.canonicalHull = createConvexHull(coords, true);
            cartoData.bounding_polygon.paths = _adp.canonicalHull.hull;
            _adp.projectData.carto_id = JSON.stringify(cartoData);
            faux = {
              data: _adp.cartoRows
            };
            validateTaxonData(faux, function(taxa) {
              var arks, aweb, catalogNumbers, center, clade, cladeList, date, dates, dispositions, distanceFromCenter, error5, excursion, fieldNumbers, finalize, fullPath, key, len2, len3, len4, mString, methods, months, noticeHtml, o, originalTaxon, q, ref10, ref11, ref12, ref13, ref14, ref15, ref16, ref7, ref8, ref9, rowLat, rowLng, s, sampleMethods, taxon, taxonList, taxonListString, taxonObject, taxonString, uDate, uTime, years;
              validatedData.validated_taxa = taxa.validated_taxa;
              _adp.projectData.includes_anura = false;
              _adp.projectData.includes_caudata = false;
              _adp.projectData.includes_gymnophiona = false;
              ref7 = validatedData.validated_taxa;
              for (o = 0, len2 = ref7.length; o < len2; o++) {
                taxonObject = ref7[o];
                aweb = taxonObject.response.validated_taxon;
                console.info("Aweb taxon result:", aweb);
                clade = aweb.order.toLowerCase();
                key = "includes_" + clade;
                _adp.projectData[key] = true;
                if (_adp.projectData.includes_anura !== false && _adp.projectData.includes_caudata !== false && _adp.projectData.includes_gymnophiona !== false) {
                  break;
                }
              }
              taxonListString = "";
              taxonList = new Array();
              cladeList = new Array();
              i = 0;
              ref8 = validatedData.validated_taxa;
              for (q = 0, len3 = ref8.length; q < len3; q++) {
                taxon = ref8[q];
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
                if (indexOf.call(taxonList, taxonString) < 0) {
                  if (i > 0) {
                    taxonListString += "\n";
                  }
                  taxonListString += "" + taxonString;
                  taxonList.push(taxonString);
                }
                try {
                  if (ref9 = taxon.response.validated_taxon.family, indexOf.call(cladeList, ref9) < 0) {
                    cladeList.push(taxon.response.validated_taxon.family);
                  }
                } catch (error5) {
                  e = error5;
                  console.warn("Couldn't get the family! " + e.message, taxon.response);
                  console.warn(e.stack);
                }
                ++i;
              }
              try {
                p$("#species-list").bindValue = taxonListString;
              } catch (undefined) {}
              dataAttrs.dataObj = validatedData;
              _adp.data.dataObj = validatedData;
              _adp.data.taxa = new Object();
              _adp.data.taxa.list = taxonList;
              _adp.data.taxa.clades = cladeList;
              _adp.data.taxa.validated = validatedData.validated_taxa;
              _adp.projectData.sampled_species = taxonList.join(",");
              _adp.projectData.sampled_clades = cladeList.join(",");
              _adp.projectData.disease_morbidity = validatedData.samples.morbidity;
              _adp.projectData.disease_mortality = validatedData.samples.mortality;
              _adp.projectData.disease_positive = validatedData.samples.positive;
              _adp.projectData.disease_negative = validatedData.samples.negative;
              _adp.projectData.disease_no_confidence = validatedData.samples.no_confidence;
              center = getMapCenter(geo.boundingBox);
              excursion = 0;
              dates = new Array();
              months = new Array();
              years = new Array();
              methods = new Array();
              catalogNumbers = new Array();
              fieldNumbers = new Array();
              dispositions = new Array();
              sampleMethods = new Array();
              ref10 = Object.toArray(_adp.cartoRows);
              for (s = 0, len4 = ref10.length; s < len4; s++) {
                row = ref10[s];
                date = (ref11 = row.dateCollected) != null ? ref11 : row.dateIdentified;
                uTime = excelDateToUnixTime(date);
                dates.push(uTime);
                uDate = new Date(uTime);
                mString = dateMonthToString(uDate.getUTCMonth());
                if (indexOf.call(months, mString) < 0) {
                  months.push(mString);
                }
                if (ref12 = uDate.getFullYear(), indexOf.call(years, ref12) < 0) {
                  years.push(uDate.getFullYear());
                }
                if (row.catalogNumber != null) {
                  catalogNumbers.push(row.catalogNumber);
                }
                fieldNumbers.push(row.fieldNumber);
                rowLat = row.decimalLatitude;
                rowLng = row.decimalLongitude;
                distanceFromCenter = geo.distance(rowLat, rowLng, center.lat, center.lng);
                if (distanceFromCenter > excursion) {
                  excursion = distanceFromCenter;
                }
                if (row.sampleType != null) {
                  if (ref13 = row.sampleType, indexOf.call(sampleMethods, ref13) < 0) {
                    sampleMethods.push(row.sampleType);
                  }
                }
                if (row.specimenDisposition != null) {
                  if (ref14 = row.specimenDisposition, indexOf.call(dispositions, ref14) < 0) {
                    dispositions.push(row.sampleDisposition);
                  }
                }
              }
              console.info("Got date ranges", dates);
              months.sort();
              years.sort();
              _adp.projectData.sampled_collection_start = dates.min();
              _adp.projectData.sampled_collection_end = dates.max();
              console.info("Collected from", dates.min(), dates.max());
              _adp.projectData.sampling_months = months.join(",");
              _adp.projectData.sampling_years = years.join(",");
              _adp.projectData.sample_catalog_numbers = catalogNumbers.join(",");
              _adp.projectData.sample_field_numbers = fieldNumbers.join(",");
              _adp.projectData.sample_methods_used = sampleMethods.join(",");
              finalize = function() {
                _adp.skipRead = true;
                saveEditorData(true, function() {
                  if (localStorage._adp == null) {
                    return document.location.reload(true);
                  }
                });
                return false;
              };
              fullPath = "" + uri.urlString + validatedData.dataSrc;
              if (fullPath !== _adp.projectData.sample_raw_data) {
                arks = _adp.projectData.dataset_arks.split(",");
                if (((ref15 = _adp.fims) != null ? (ref16 = ref15.expedition) != null ? ref16.ark : void 0 : void 0) == null) {
                  if (_adp.fims == null) {
                    _adp.fims = new Object();
                  }
                  if (_adp.fims.expedition == null) {
                    _adp.fims.expedition = new Object();
                  }
                  _adp.fims.expedition.ark = _adp.projectData.project_obj_id;
                }
                mintBcid(_adp.projectId, fullPath, _adp.projectData.project_title, function(result) {
                  var file, fileA, newArk;
                  if (result.ark != null) {
                    fileA = fullPath.split("/");
                    file = fileA.pop();
                    newArk = result.ark + "::" + file;
                    arks.push(newArk);
                    _adp.projectData.dataset_arks = arks.join(",");
                  } else {
                    console.warn("Couldn't mint!");
                  }
                  _adp.previousRawData = _adp.projectData.sample_raw_data;
                  _adp.projectData.sample_raw_data = fullPath;
                  return finalize();
                });
              } else {
                finalize();
              }
              return false;
            });
            return false;
          });
          return false;
        } else {
          return stopLoadError("Error updating Carto");
        }
      }).error(function(result, status) {
        return stopLoadError("Error updating Carto");
      });
    });
    return false;
  };
  if (!skipHandler) {
    excelHandler2(path, true, function(resultObj) {
      var data;
      data = resultObj.data;
      return dataCallback(data);
    });
  } else {
    dataCallback(passedData);
  }
  return false;
};

saveEditorData = function(force, callback) {
  var args, authorObj, el, key, l, len, len1, m, postData, ref, ref1, ref2;
  if (force == null) {
    force = false;
  }

  /*
   * Actually do the file saving
   */
  startLoad();
  $(".hanging-alert").remove();
  if (force || (localStorage._adp == null)) {
    postData = _adp.projectData;
    try {
      postData.access_data = _adp.projectData.access_data.raw;
    } catch (undefined) {}
    if (_adp.skipRead !== true) {
      ref = $(".project-param:not([readonly])");
      for (l = 0, len = ref.length; l < len; l++) {
        el = ref[l];
        key = $(el).attr("data-field");
        if (isNull(key)) {
          continue;
        }
        postData[key] = p$(el).value;
      }
      authorObj = new Object();
      ref1 = $(".author-param");
      for (m = 0, len1 = ref1.length; m < len1; m++) {
        el = ref1[m];
        key = $(el).attr("data-key");
        authorObj[key] = (ref2 = $(el).attr("data-value")) != null ? ref2 : p$(el).value;
      }
      postData.author_data = JSON.stringify(authorObj);
    }
    _adp.postedSaveData = postData;
    _adp.postedSaveTimestamp = Date.now();
  } else {
    window._adp = JSON.parse(localStorage._adp);
    postData = _adp.postedSaveData;
  }
  console.log("Sending to server", postData);
  args = "perform=save&data=" + (jsonTo64(postData));
  $.post("" + uri.urlString + adminParams.apiTarget, args, "json").done(function(result) {
    var error, ref3, ref4;
    console.info("Save result: server said", result);
    if (result.status !== true) {
      error = (ref3 = (ref4 = result.human_error) != null ? ref4 : result.error) != null ? ref3 : "There was an error saving to the server";
      stopLoadError("There was an error saving to the server");
      localStorage._adp = JSON.stringify(_adp);
      bsAlert("<strong>Save Error:</strong> " + error + ". An offline backup has been made.", "danger");
      console.error(result.error);
      return false;
    }
    stopLoad();
    toastStatusMessage("Save successful");
    _adp.projectData = result.project.project;
    return delete localStorage._adp;
  }).error(function(result, status) {
    stopLoadError("Sorry, there was an error communicating with the server");
    localStorage._adp = JSON.stringify(_adp);
    bsAlert("<strong>Save Error</strong>: We had trouble communicating with the server and your data was NOT saved. Please try again in a bit. An offline backup has been made.", "danger");
    return console.error(result, status);
  }).always(function() {
    if (typeof callback === "function") {
      return callback();
    }
  });
  return false;
};

$(function() {
  var alertHtml, d;
  if (localStorage._adp != null) {
    window._adp = JSON.parse(localStorage._adp);
    d = new Date(_adp.postedSaveTimestamp);
    alertHtml = "<strong>You have offline save information</strong> &#8212; did you want to save it?\n<br/><br/>\nProject #" + _adp.postedSaveData.project_id + " on " + (d.toLocaleDateString()) + " at " + (d.toLocaleTimeString()) + "\n<br/><br/>\n<button class=\"btn btn-success\" id=\"offline-save\">\n  Save Now &amp; Refresh Page\n</button>";
    bsAlert(alertHtml, "info");
    return $("#offline-save").click(function() {
      return saveEditorData(false, function() {
        return document.location.reload(true);
      });
    });
  }
});


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
  var args, state, url;
  url = uri.urlString + "admin-page.html#action:show-viewable";
  state = {
    "do": "action",
    prop: "show-viewable"
  };
  history.pushState(state, "Viewing Personal Project List", url);
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
      icon = indexOf.call(publicList, projectId) >= 0 ? "<iron-icon icon=\"social:public\"></iron-icon>" : "<iron-icon icon=\"icons:lock\"></iron-icon>";
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
  goTo(uri.urlString + "project.php?id=" + projectId);
  return false;
};

loadSUProjectBrowser = function() {
  var state, url;
  url = uri.urlString + "admin-page.html#action:show-su-viewable";
  state = {
    "do": "action",
    prop: "show-su-viewable"
  };
  history.pushState(state, "Viewing Superuser Project List", url);
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
  _adp.validationDataObject = dataObject;
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

stopLoadBarsError = function(currentTimeout, message) {
  var el, l, len, others;
  try {
    clearTimeout(currentTimeout);
  } catch (undefined) {}
  $("#validator-progress-container paper-progress[indeterminate]").addClass("error-progress").removeAttr("indeterminate");
  others = $("#validator-progress-container paper-progress:not([indeterminate])");
  for (l = 0, len = others.length; l < len; l++) {
    el = others[l];
    try {
      if (p$(el).value !== p$(el).max) {
        $(el).addClass("error-progress");
        $(el).find("#primaryProgress").css("background", "#F44336");
      }
    } catch (undefined) {}
  }
  if (message != null) {
    bsAlert("<strong>Data Validation Error</strong: " + message, "danger");
    stopLoadError("There was a problem validating your data");
  }
  return false;
};

delayFimsRecheck = function(originalResponse, callback) {
  var args, cookies;
  cookies = encodeURIComponent(originalResponse.responses.login_response.cookies);
  args = "perform=validate&auth=" + cookies;
  $.post(adminParams.apiTarget, args, "json").done(function(result) {
    console.log("Server said", result);
    if (typeof callback === "function") {
      return callback();
    } else {
      return console.warn("Warning: delayed recheck had no callback");
    }
  }).error(function(result, status) {
    console.error(status + ": Couldn't check status on FIMS server!");
    console.warn("Server said", result.responseText);
    return stopLoadError("There was a problem validating your data, please try again later");
  });
  return false;
};

validateFimsData = function(dataObject, callback) {
  var animateProgress, args, data, ref, ref1, rowCount, src, timerPerRow, validatorTimeout;
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
  if (typeof (typeof _adp !== "undefined" && _adp !== null ? (ref = _adp.fims) != null ? (ref1 = ref.expedition) != null ? ref1.expeditionId : void 0 : void 0 : void 0) !== "number") {
    if (_adp.hasRunMintCallback === true) {
      console.error("Couldn't run validateFimsData(); called itself back recursively. There may be a problem with the server. ");
      stopLoadError("Couldn't validate your data, please try again later");
      _adp.hasRunMintCallback = false;
      return false;
    }
    _adp.hasRunMintCallback = false;
    console.warn("Haven't minted expedition yet! Minting that first");
    mintExpedition(_adp.projectId, p$("#project-title").value, function() {
      _adp.hasRunMintCallback = true;
      return validateFimsData(dataObject, callback);
    });
    return false;
  }
  console.info("FIMS Validating", dataObject.data);
  $("#data-validation").removeAttr("indeterminate");
  rowCount = Object.size(dataObject.data);
  try {
    p$("#data-validation").max = rowCount * 2;
  } catch (undefined) {}
  timerPerRow = 20;
  validatorTimeout = null;
  (animateProgress = function() {
    var error1, error2, val;
    try {
      val = p$("#data-validation").value;
    } catch (error1) {
      return false;
    }
    if (val >= rowCount) {
      clearTimeout(validatorTimeout);
      return false;
    }
    ++val;
    try {
      p$("#data-validation").value = val;
    } catch (error2) {
      return false;
    }
    return validatorTimeout = delay(timerPerRow, function() {
      return animateProgress();
    });
  })();
  data = jsonTo64(dataObject.data);
  src = post64(dataObject.dataSrc);
  args = "perform=validate&datasrc=" + src + "&link=" + _adp.projectId;
  console.info("Posting ...", "" + uri.urlString + adminParams.apiTarget + "?" + args);
  $.post("" + uri.urlString + adminParams.apiTarget, args, "json").done(function(result) {
    var error, errorClass, errorList, errorMessages, errorType, errors, html, k, key, message, overrideShowErrors, ref2, ref3, ref4, ref5, ref6, ref7, statusTest;
    console.log("FIMS validate result", result);
    if (result.status !== true) {
      stopLoadError("There was a problem talking to the server");
      error = (ref2 = (ref3 = result.human_error) != null ? ref3 : result.error) != null ? ref2 : "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again.";
      bsAlert("<strong>Server Error:</strong> " + error, "danger");
      stopLoadBarsError(validatorTimeout);
      return false;
    }
    statusTest = ((ref4 = result.validate_status) != null ? ref4.status : void 0) != null ? result.validate_status.status : result.validate_status;
    if (result.validate_status === "FIMS_SERVER_DOWN") {
      toastStatusMessage("Validation server is down, proceeding ...");
      bsAlert("<strong>FIMS error</strong>: The validation server is down, we're trying to finish up anyway.", "warning");
    } else if (statusTest !== true) {
      overrideShowErrors = false;
      stopLoadError("There was a problem with your dataset");
      error = (ref5 = (ref6 = (ref7 = result.validate_status.error) != null ? ref7 : result.human_error) != null ? ref6 : result.error) != null ? ref5 : "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again.";
      if (error.length > 255) {
        overrideShowErrors = true;
        error = error.substr(0, 255) + "[...] and more.";
      }
      bsAlert("<strong>FIMS reported an error validating your data:</strong> " + error, "danger");
      stopLoadBarsError(validatorTimeout);
      errors = result.validate_status.errors;
      if (Object.size(errors) > 1 || overrideShowErrors) {
        html = "<div class=\"error-block\" id=\"validation-error-block\">\n  <p><strong>Your dataset had errors</strong>. Here's a summary:</p>\n  <table class=\"table-responsive table-striped table-condensed table table-bordered table-hover\" >\n    <thead>\n      <tr>\n        <th>Error Type</th>\n        <th>Error Message</th>\n      </tr>\n    </thhead>\n    <tbody>";
        for (key in errors) {
          errorType = errors[key];
          for (errorClass in errorType) {
            errorMessages = errorType[errorClass];
            errorList = "<ul>";
            for (k in errorMessages) {
              message = errorMessages[k];
              message = message.stripHtml(true);
              if (/\[(?:((?:"(\w+)"((, )?))*?))\]/m.test(message)) {
                message = message.replace(/"(\w+)"/mg, "<code>$1</code>");
              }
              errorList += "<li>" + message + "</li>";
            }
            errorList += "</ul>";
            html += "<tr>\n  <td><strong>" + (errorClass.stripHtml(true)) + "</strong></td>\n  <td>" + errorList + "</td>\n</tr>";
          }
        }
        html += "    </tbody>\n  </table>\n</div>";
        $("#validator-progress-container").append(html);
        $("#validator-progress-container").get(0).scrollIntoView();
      }
      return false;
    }
    try {
      p$("#data-validation").value = p$("#data-validation").max;
      clearTimeout(validatorTimeout);
    } catch (undefined) {}
    if (typeof callback === "function") {
      return callback(dataObject);
    }
  }).error(function(result, status) {
    clearTimeout(validatorTimeout);
    console.error(status + ": Couldn't upload to FIMS server!");
    console.warn("Server said", result.responseText);
    stopLoadError("There was a problem validating your data, please try again later");
    return false;
  });
  return false;
};

mintBcid = function(projectId, datasetUri, title, callback) {
  var addToExp, args, ref, ref1, resultObj;
  if (datasetUri == null) {
    datasetUri = dataFileParams != null ? dataFileParams.filePath : void 0;
  }

  /*
   *
   * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
   *
   * Resolve the ARK with
   * https://n2t.net/
   */
  if (typeof callback !== "function") {
    console.warn("mintBcid() requires a callback function");
    return false;
  }
  resultObj = new Object();
  addToExp = (typeof _adp !== "undefined" && _adp !== null ? (ref = _adp.fims) != null ? (ref1 = ref.expedition) != null ? ref1.ark : void 0 : void 0 : void 0) != null;
  args = "perform=mint&link=" + projectId + "&title=" + (post64(title)) + "&file=" + datasetUri + "&expedition=" + addToExp;
  $.post(adminParams.apiTarget, args, "json").done(function(result) {
    console.log("Got", result);
    if (!result.status) {
      stopLoadError(result.human_error);
      console.error(result.error);
      return false;
    }
    return resultObj = result;
  }).error(function(result, status) {
    resultObj = {
      ark: null,
      error: status,
      human_error: result.responseText,
      status: false
    };
    return false;
  }).always(function() {
    console.info("mintBcid is calling back", resultObj);
    return callback(resultObj);
  });
  return false;
};

mintExpedition = function(projectId, title, callback) {
  var args, publicProject, resultObj;
  if (projectId == null) {
    projectId = _adp.projectId;
  }
  if (title == null) {
    title = p$("#project-title").value;
  }

  /*
   *
   * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
   *
   * Resolve the ARK with
   * https://n2t.net/
   */
  if (typeof callback !== "function") {
    console.warn("mintExpedition() requires a callback function");
    return false;
  }
  resultObj = new Object();
  publicProject = p$("#data-encumbrance-toggle").checked;
  if (typeof publicProject !== "boolean") {
    publicProject = false;
  }
  args = "perform=create_expedition&link=" + projectId + "&title=" + (post64(title)) + "&public=" + publicProject;
  $.post(adminParams.apiTarget, args, "json").done(function(result) {
    console.log("Expedition got", result);
    if (!result.status) {
      stopLoadError(result.human_error);
      console.error(result.error);
      return false;
    }
    resultObj = result;
    if ((typeof _adp !== "undefined" && _adp !== null ? _adp.fims : void 0) == null) {
      if (typeof _adp === "undefined" || _adp === null) {
        window._adp = new Object();
      }
      _adp.fims = new Object();
    }
    return _adp.fims.expedition = {
      permalink: result.project_permalink,
      ark: result.ark,
      expeditionId: result.fims_expedition_id,
      fimsRawResponse: result.responses.expedition_response
    };
  }).error(function(result, status) {
    resultObj.ark = null;
    return false;
  }).always(function() {
    console.info("mintExpedition is calling back", resultObj);
    return callback(resultObj);
  });
  return false;
};

validateTaxonData = function(dataObject, callback) {
  var data, grammar, length, n, row, taxa, taxaPerRow, taxaString, taxon, taxonValidatorLoop;
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
  length = Object.toArray(data).length;
  toastStatusMessage("Validating " + taxa.length + " unique " + grammar + " from " + length + " rows ...");
  console.info("Replacement tracker", taxaPerRow);
  $("#taxa-validation").removeAttr("indeterminate");
  try {
    p$("#taxa-validation").max = taxa.length;
  } catch (undefined) {}
  (taxonValidatorLoop = function(taxonArray, key) {
    taxaString = taxonArray[key].genus + " " + taxonArray[key].species;
    if (!isNull(taxonArray[key].subspecies)) {
      taxaString += " " + taxonArray[key].subspecies;
    }
    return validateAWebTaxon(taxonArray[key], function(result) {
      var e, error1, l, len, message, replaceRows;
      if (result.invalid === true) {
        cleanupToasts();
        stopLoadError(result.response.human_error);
        console.error(result.response.error);
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. " + result.response.human_error + " We stopped validation at that point. Please correct taxonomy issues and try uploading again.";
        bsAlert(message);
        removeDataFile();
        stopLoadBarsError();
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
      } catch (error1) {
        e = error1;
        console.warn("Problem replacing rows! " + e.message);
        console.warn(e.stack);
      }
      taxonArray[key] = result;
      try {
        p$("#taxa-validation").value = key;
      } catch (undefined) {}
      key++;
      if (key < taxonArray.length) {
        if (modulo(key, 50) === 0) {
          toastStatusMessage("Validating taxa " + key + " of " + taxonArray.length + " ...");
        }
        return taxonValidatorLoop(taxonArray, key);
      } else {
        try {
          p$("#taxa-validation").value = key;
        } catch (undefined) {}
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
      if (taxonObj.clade == null) {
        taxonObj.clade = result.validated_taxon.family;
      }
      window.validationMeta.validatedTaxons.push(taxonObj);
    } else {
      taxonObj.invalid = true;
    }
    taxonObj.response = result;
    doCallback(taxonObj);
    return false;
  }).error(function(result, status) {
    var prettyTaxon;
    prettyTaxon = taxonObj.genus + " " + taxonObj.species;
    prettyTaxon = taxonObj.subspecies != null ? prettyTaxon + " " + taxonObj.subspecies : prettyTaxon;
    bsAlert("<strong>Problem validating taxon:</strong> " + prettyTaxon + " couldn't be validated.");
    return console.warn("Warning: Couldn't validated " + prettyTaxon + " with AmphibiaWeb");
  });
  return false;
};

//# sourceMappingURL=maps/admin.js.map
