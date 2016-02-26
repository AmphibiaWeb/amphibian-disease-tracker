
/*
 * Project-specific code
 */
var checkProjectAuthorization, renderEmail;

checkProjectAuthorization = function(projectId, callback) {
  if (projectId == null) {
    projectId = _adp.projectId;
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
    var authorData, html;
    console.info("Checked response");
    console.log(result);
    authorData = result.author_data;
    html = "<div class=\"row\">\n  <paper-input readonly class=\"col-xs-8 col-md-10\" label=\"Contact Email\" value=\"" + authorData.contact_email + "\"></paper-input>\n  <div class=\"col-xs-4 col-md-2\">\n    <paper-icon-button icon=\"communication:email\" class=\"click materialblue\" id=\"contact-email-send\" data-href=\"mailto:" + authorData.contact_email + "\"></paper-icon-button>\n  </div>\n</div>";
    $("#email-fill").replaceWith(html);
    bindClicks("#contact-email-send");
    return stopLoad();
  }).error(function(result, status) {
    stopLoadError("Sorry, there was a problem getting the contact email");
    return false;
  });
  return false;
};

$(function() {
  _adp.projectId = uri.o.param("id");
  return checkProjectAuthorization();
});

//# sourceMappingURL=maps/project.js.map
