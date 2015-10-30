
/*
 * The main coffeescript file for administrative stuff
 * Triggered from admin-page.html
 */
var _7zHandler, bootstrapUploader, csvHandler, excelHandler, imageHandler, verifyLoginCredentials, zipHandler;

window.adminParams = new Object();

adminParams.domain = "amphibiandisease";

adminParams.apiTarget = "admin_api.php";

adminParams.adminPageUrl = "http://" + adminParams.domain + ".org/admin-page.html";

adminParams.loginDir = "admin/";

adminParams.loginApiTarget = adminParams.loginDir + "async_login_handler.php";

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
      articleHtml = "<h3>\n  Welcome, " + ($.cookie(adminParams.domain + "_name")) + "\n  <span id=\"pib-wrapper-settings\" class=\"pib-wrapper\" data-toggle=\"tooltip\" title=\"User Settings\" data-placement=\"bottom\">\n    <paper-icon-button icon='icons:settings-applications' class='click' data-href='" + data.login_url + "'></paper-icon-button>\n  </span>\n\n</h3>\n<div id='admin-actions-block'>\n  <div class='bs-callout bs-callout-info'>\n    <p>Please be patient while the administrative interface loads. TODO MAKE ADMIN UI</p>\n  </div>\n</div>";
      $("main #main-body").html(articleHtml);

      /*
       * Render out the admin UI
       * We want a search box that we pipe through the API
       * and display the table out for editing
       */
      if (typeof geo !== "undefined" && geo !== null) {
        geo.init();
      }
      bindClicks();
      return false;
    });
  } catch (_error) {
    e = _error;
    $("main #main-body").html("<div class='bs-callout bs-callout-danger'><h4>Application Error</h4><p>There was an error in the application. Please refresh and try again. If this persists, please contact administration.</p></div>");
  }
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
    html = "<form id=\"" + uploadFormId + "-form\" class=\"\">\n  <fieldset>\n    <legend>Upload Files</legend>\n    <div id=\"" + uploadFormId + "\" class=\"media-uploader outline\">\n    </div>\n  </fieldset>\n</form>";
    $("main").append(html);
    $(selector).submit(function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
  }
  return loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
    console.info("Loaded drag drop helper");
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
        pathPrefix = "helpers/js-dragdrop/uploaded/";
        result.full_path = result.wrote_file;
        result.thumb_path = result.wrote_thumb;
        mediaType = result.mime_provided.split("/")[0];
        longType = result.mime_provided.split("/")[1];
        linkPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.full_path : "" + pathPrefix + result.thumb_path;
        previewHtml = (function() {
          switch (mediaType) {
            case "image":
              return "<div class=\"uploaded-media center-block\">\n  <img src=\"" + linkPath + "\" alt='Uploaded Image' class=\"img-circle thumb-img img-responsive\"/>\n    <p class=\"text-muted\">\n      " + file.name + " -> " + result.full_path + "\n  (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n    Original Image\n  </a>)\n    </p>\n</div>";
            case "audio":
              return "<div class=\"uploaded-media center-block\">\n  <audio src=\"" + linkPath + "\" controls preload=\"auto\">\n    <span class=\"glyphicon glyphicon-music\"></span>\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + result.full_path + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
            case "video":
              return "<div class=\"uploaded-media center-block\">\n  <video src=\"" + linkPath + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + result.thumb_path + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + result.full_path + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
            default:
              return "<div class=\"uploaded-media center-block\">\n  <span class=\"glyphicon glyphicon-file\"></span>\n  <p class=\"text-muted\">" + file.name + " -> " + result.full_path + "</p>\n</div>";
          }
        })();
        $(window.dropperParams.dropTargetSelector).before(previewHtml);
        switch (mediaType) {
          case "application":
            switch (longType) {
              case "vnd.openxmlformats-officedocument.spreadsheetml.sheet":
              case "vnd.ms-excel":
                return excelHandler(linkPath);
              case "zip":
              case "x-zip-compressed":
                return zipHandler(linkPath);
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
    return false;
  });
};

excelHandler = function() {
  foo();
  return false;
};

csvHandler = function() {
  foo();
  return false;
};

imageHandler = function() {
  foo();
  return false;
};

zipHandler = function() {
  foo();
  return false;
};

_7zHandler = function() {
  foo();
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
