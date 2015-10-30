
/*
 * The main coffeescript file for administrative stuff
 * Triggered from admin-page.html
 */
var bootstrapUploader, verifyLoginCredentials;

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
    html = "<form id=\"" + uploadFormId + "-form\">\n  <div id=\"" + uploadFormId + "\" class=\"media-uploader outline\">\n  </div>\n</form>";
    $("main").append(html);
  }
  return loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
    console.info("Loaded drag drop helper");
    return false;
  });
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
