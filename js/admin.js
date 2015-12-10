
/*
 * The main coffeescript file for administrative stuff
 * Triggered from admin-page.html
 */
var _7zHandler, bootstrapTransect, bootstrapUploader, csvHandler, dataFileParams, excelHandler, finalizeData, helperDir, imageHandler, loadCreateNewProject, loadEditor, loadProjectBrowser, newGeoDataHandler, populateAdminActions, removeDataFile, resetForm, singleDataFileHelper, startAdminActionHelper, user, verifyLoginCredentials, zipHandler;

window.adminParams = new Object();

adminParams.domain = "amphibiandisease";

adminParams.apiTarget = "admin_api.php";

adminParams.adminPageUrl = "https://" + adminParams.domain + ".org/admin-page.html";

adminParams.loginDir = "admin/";

adminParams.loginApiTarget = adminParams.loginDir + "async_login_handler.php";

dataFileParams = new Object();

dataFileParams.hasDataFile = false;

dataFileParams.fileName = null;

dataFileParams.filePath = null;

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

loadEditor = function() {
  startAdminActionHelper();
  adData.cartoRef = "38544c04-5e56-11e5-8515-0e4fddd5de28";
  geo.init();
  foo();
  return false;
};

loadCreateNewProject = function() {
  var html;
  startAdminActionHelper();
  html = "<h2 class=\"new-title col-xs-12\">Project Title</h2>\n<paper-input label=\"Project Title\" id=\"project-title\" class=\"project-field col-md-6 col-xs-12\" required autovalidate=\"true\"></paper-input>\n<h2 class=\"new-title col-xs-12\">Project Parameters</h2>\n<section class=\"project-inputs clearfix col-xs-12\">\n  <div class=\"row\">\n    <paper-input label=\"Primary Disease Studied\" id=\"project-disease\" class=\"project-field col-md-6 col-xs-11\" required autovalidate=\"true\"></paper-input>\n    <span class=\"glyphicon glyphicon-info-sign col-xs-1\" data-toggle=\"tooltip\" title=\"Informational field tooltip\"></span>\n    <paper-input label=\"Project Reference\" id=\"reference-id\" class=\"project-field col-md-6 col-xs-12\"></paper-input>\n    <h2 class=\"new-title\">Lab Parameters</h2>\n    <paper-input label=\"Project PI\" id=\"project-pi\" class=\"project-field col-md-6 col-xs-12\"  required autovalidate=\"true\"></paper-input>\n    <paper-input label=\"Project Contact\" id=\"project-author\" class=\"project-field col-md-6 col-xs-12\"  required autovalidate=\"true\"></paper-input>\n    <gold-email-input label=\"Contact Email\" id=\"author-email\" class=\"project-field col-md-6 col-xs-12\"  required autovalidate=\"true\"></gold-email-input>\n    <paper-input label=\"Project Lab\" id=\"project-lab\" class=\"project-field col-md-6 col-xs-12\"  required autovalidate=\"true\"></paper-input>\n    <h2 class=\"new-title\">Project Notes</h2>\n    <iron-autogrow-textarea id=\"project-notes\" class=\"project-field col-md-6 col-xs-12\" rows=\"3\"></iron-autogrow-textarea>\n    <h2 class=\"new-title\">Data Permissions</h2>\n    <div class=\"col-xs-12\">\n      <span class=\"toggle-off-label iron-label\">Private Dataset</span>\n      <paper-toggle-button id=\"data-encumbrance-toggle\">Public Dataset</paper-toggle-button>\n    </div>\n      <p><strong>Smart selector here for registered users</strong>, only show when \"private\" toggle set</p>\n    <h2 class=\"new-title\">Project Area of Interest</h2>\n    <p>This represents the approximate collection region for your samples. If you don't enter anything, we'll guess from your dataset.</p>\n    <div class=\"col-xs-12\">\n      <span class=\"toggle-off-label iron-label\">Locality Name</span>\n      <paper-toggle-button id=\"transect-input-toggle\">Coordinate List</paper-toggle-button>\n    </div>\n    <p id=\"transect-instructions\" class=\"col-xs-12\"></p>\n    <div id=\"transect-input\" class=\"col-md-6 col-xs-12\">\n    </div>\n    <div id=\"carto-rendered-map\" class=\"col-md-6\">\n      <div id=\"carto-map-container\" class=\"carto-map map\">\n      </div>\n    </div>\n    <br/><br/>\n    <paper-checkbox checked id=\"has-data\">My project already has data</paper-checkbox>\n    <br/><br/>\n  </div>\n</section>\n<section id=\"uploader-container-section col-xs-12\" class=\"data-section\">\n  <h2 class=\"new-title\">Uploading your project data</h2>\n  <p>Drag and drop as many files as you need below. </p>\n  <p>\n    To save your project, we need at least one file with structured data containing coordinates.\n    Please note that the data <strong>must</strong> have a header row,\n    and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>alt</code>, and <code>coordinateUncertaintyInMeters</code>.\n  </p>\n</section>\n<section class=\"project-inputs clearfix data-section col-xs-12\">\n  <div class=\"row\">\n    <h2 class=\"new-title\">Project Data</h2>\n    <h3 class=\"new-title\">Data Parameters</h3>\n    <paper-input label=\"Samples Counted\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"samplecount\" readonly type=\"number\"></paper-input>\n    <p>Etc</p>\n  </div>      \n</section>\n<section id=\"submission-section col-xs-12\">\n  <div class=\"pull-right\">\n    <button id=\"upload-data\" class=\"btn btn-success click\" data-function=\"finalizeData\">Save Data &amp; Create Project</button>\n    <button id=\"reset-data\" class=\"btn btn-danger click\" data-function=\"resetForm\">Reset Form</button>\n  </div>\n</section>";
  $("main #main-body").append(html);
  bootstrapUploader();
  bootstrapTransect();
  $("#has-data").on("iron-change", function() {
    if (!$(this).get(0).checked) {
      return $(".data-section").attr("hidden", "hidden");
    } else {
      return $(".data-section").removeAttr("hidden");
    }
  });
  bindClicks();
  foo();
  return false;
};

finalizeData = function() {

  /*
   * Make sure everythign is uploaded, validate, and POST to the server
   */
  return foo();
};

resetForm = function() {

  /*
   * Kill it dead
   */
  return foo();
};

loadProjectBrowser = function() {
  var html;
  startAdminActionHelper();
  html = "<div class='bs-callout bs-callout-warn center-block col-md-5'>\n  <p>Function worked, there's just nothing to show yet.</p>\n  <p>Imagine the beautiful and functional browser of all projects you have access to of your dreams, here.</p>\n</div>";
  $("#main-body").html(html);
  adData.cartoRef = "38544c04-5e56-11e5-8515-0e4fddd5de28";
  geo.init();
  foo();
  return false;
};

bootstrapTransect = function() {

  /*
   *
   */
  var geocodeEvent, setupTransectUi, showCartoTransectMap;
  showCartoTransectMap = function(coordList) {
    foo();
    return false;
  };
  geocodeEvent = function() {
    var coords;
    window.geocodeLookupCallback = function() {
      var geocoder, locality, request;
      startLoad();
      locality = p$("#locality-input").value;
      geocoder = new google.maps.Geocoder();
      request = {
        address: locality
      };
      return geocoder.geocode(request, function(result, status) {
        var bbEW, bbNS, boundingBox, bounds, doCallback, lat, lng, loc;
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
          bbEW = bounds.O;
          bbNS = bounds.j;
          boundingBox = {
            nw: [bbEW.O, bbNS.O],
            ne: [bbEW.j, bbNS.O],
            sw: [bbEW.O, bbNS.j],
            se: [bbEW.j, bbNS.j]
          };
          console.info("Got bounds: ", [lat, lng], boundingBox);
          doCallback = function() {
            var options;
            options = {
              cartodb_logo: false,
              https: true,
              mobile_layout: true,
              gmaps_base_type: "hybrid",
              center_lat: lat,
              center_lon: lng,
              zoom: 7
            };
            $("#carto-map-container").empty();
            return createMap(null, "carto-map-container", options, function(vis, map) {
              return foo();
            });
          };
          loadJS("js/cartodb.js", doCallback, false);
          return stopLoad();
        } else {
          return stopLoadError("Couldn't find location: " + status);
        }
      });
    };
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
      loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=geocodeLookupCallback");
    } else {
      geocodeLookupCallback();
    }
    coords = new Array();
    showCartoTransectMap(coords);
    return false;
  };
  (setupTransectUi = function() {
    var instructions, transectInput;
    if (p$("#transect-input-toggle").checked) {
      instructions = "Please input a list of coordinates, in the form <code>lat, lng</code>, with one set on each line. <strong>Please press <kbd>enter</kbd> to insert a new line after your last coordinate</strong>.";
      transectInput = "<iron-autogrow-textarea id=\"coord-input\" class=\"\" required rows=\"3\"></iron-autogrow-textarea>";
    } else {
      instructions = "Please enter a name of a locality";
      transectInput = "<paper-input id=\"locality-input\" label=\"Locality\" class=\"pull-left\" required autovalidate></paper-input> <paper-icon-button class=\"pull-left\" id=\"do-search-locality\" icon=\"icons:search\"></paper-icon-button>";
    }
    $("#transect-instructions").html(instructions);
    $("#transect-input").html(transectInput);
    if (p$("#transect-input-toggle").checked) {
      $(p$("#coord-input").textarea).keyup((function(_this) {
        return function(e) {
          var coordPair, coordSplit, coords, coordsRaw, i, kc, len, lines, tmp, val;
          kc = e.keyCode ? e.keyCode : e.which;
          if (kc === 13) {
            val = $(p$("#coord-input").textarea).val();
            lines = val.split("\n").length;
            if (lines > 3) {
              coords = new Array();
              coordsRaw = val.split("\n");
              for (i = 0, len = coordsRaw.length; i < len; i++) {
                coordPair = coordsRaw[i];
                if (coordPair.search("," > 0 && !isNull(coordPair))) {
                  coordSplit = coordPair.split(",");
                  tmp = [toFloat(coordSplit[0]), toFloat(coordSplit[1])];
                  coords.push(tmp);
                }
              }
              if (coords.length >= 3) {
                console.info("Coords:", coords);
                return showCartoTransectMap(coords);
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
      $("#main-body").append(html);
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
  var cleanValue, column, d, date, daysFrom1900to1970, daysFrom1904to1970, e, month, n, parsedData, prettyHtml, projectIdentifier, row, rows, sampleRow, secondsPerDay, t, tRow, totalData, value;
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
    if (isNull(p$("#project-disease"))) {
      p$("#project-disease").value = sampleRow.diseaseTested;
    }
    parsedData = new Object();
    for (n in dataObject) {
      row = dataObject[n];
      tRow = new Object();
      for (column in row) {
        value = row[column];
        switch (column) {
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
      parsedData[n] = tRow;
    }
    try {
      prettyHtml = JsonHuman.format(parsedData);
      $("#main-body").append(prettyHtml);
    } catch (_error) {
      e = _error;
      console.warn("Couldn't pretty set!");
      console.warn(e.stack);
      console.info(parsedData);
    }
    projectIdentifier = "t" + md5(p$("#project-title").value + $.cookie(uri.domain + "_link"));
    totalData = {
      transectRing: void 0,
      data: parsedData
    };
    geo.requestCartoUpload(totalData, projectIdentifier, "create");
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

//# sourceMappingURL=maps/admin.js.map
