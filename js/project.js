
/*
 * Project-specific code
 */
var checkProjectAuthorization;

checkProjectAuthorization = function(projectId, callback) {
  if (projectId == null) {
    projectId = _adp.projectId;
  }
  console.info("Checking authorization for " + projectId);
  checkLoggedIn(function(result) {
    var args, dest;
    if (!result.status) {
      console.info("Non logged-in user");
      return false;
    } else {
      dest = uri.urlString + "/admin-api.php";
      args = "perfom=check_access&project=" + projectId;
      return $.post(dest, args, "json").done(function(result) {
        if (result.status) {
          console.info("User is authorized");
          if (typeof callback === "function") {
            return callback(result);
          }
        } else {
          return console.info("User is unauthorized");
        }
      }).error(function(result, status) {
        return console.log("Error checking server", result, status);
      });
    }
  });
  return false;
};

$(function() {
  _adp.projectId = uri.o.param("id");
  return checkProjectAuthorization();
});

//# sourceMappingURL=maps/project.js.map
