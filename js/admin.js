
/*
 * The main coffeescript file for administrative stuff
 * Triggered from admin-page.html
 */
var _7zHandler, bootstrapUploader, csvHandler, dataFileParams, excelHandler, helperDir, imageHandler, loadCreateNewProject, loadEditor, loadProjectBrowser, newGeoDataHandler, populateAdminActions, removeDataFile, singleDataFileHelper, startAdminActionHelper, user, verifyLoginCredentials, zipHandler;

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
  adminActions = "<paper-button id=\"new-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:add\"></iron-icon>\n    Create New Project\n</paper-button>\n<paper-button id=\"edit-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:create\"></iron-icon>\n    Edit Existing Project\n</paper-button>\n<paper-button id=\"view-project\" class=\"admin-action col-md-3 col-sm-4 col-xs-12\" raised>\n  <iron-icon icon=\"icons:visibility\"></iron-icon>\n    View All Projects\n</paper-button>";
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
  html = "<h2 class=\"new-title\">Project Title</h2>\n<paper-input label=\"Project Title\" id=\"project-title\" class=\"project-field col-md-6 col-xs-12\" required autovalidate></paper-input>\n<h2 class=\"new-title\">Project Parameters</h2>\n<section class=\"project-inputs clearfix\">\n  <paper-input label=\"Primary Disease Studied\" id=\"project-disease\" class=\"project-field col-md-6 col-xs-12\" required autovalidate></paper-input>\n  <paper-input label=\"Project Reference\" id=\"reference-id\" class=\"project-field col-md-6 col-xs-12\"></paper-input>\n  <h2>Lab Parameters</h2>\n  <paper-input label=\"Project PI\" id=\"project-pi\" class=\"project-field col-md-6 col-xs-12\"></paper-input>\n  <paper-input label=\"Project Contact\" id=\"project-author\" class=\"project-field col-md-6 col-xs-12\"></paper-input>\n  <gold-email-input label=\"Contact Email\" id=\"author-email\" class=\"project-field col-md-6 col-xs-12\"></gold-email-input>\n  <paper-input label=\"Project Lab\" id=\"project-lab\" class=\"project-field col-md-6 col-xs-12\"></paper-input>\n  <h2>Data Parameters</h2>\n  <paper-input label=\"Samples Counted\" placeholder=\"Please upload a data file to see sample count\" class=\"project-field col-md-6 col-xs-12\" id=\"samplecount\" readonly type=\"number\"></paper-input>\n</section>\n<p>Etc</p>\n<h2 class=\"new-title\">Uploading your project data</h2>\n<p>Drag and drop as many files as you need below. </p>\n<p>\n  To save your project, we need at least one file with structured data containing coordinates.\n  Please note that the data <strong>must</strong> have a header row,\n  and the data <strong>must</strong> have the columns <code>decimalLatitude</code>, <code>decimalLongitude</code>, <code>alt</code>, and <code>coordinateUncertaintyInMeters</code>.\n</p>";
  $("main #main-body").append(html);
  bootstrapUploader();
  foo();
  return false;
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
    $("main #main-body").append(html);
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
