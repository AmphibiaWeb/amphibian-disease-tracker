
/*
 * Project-specific code
 */
var checkProjectAuthorization;

checkProjectAuthorization = function(projectId) {
  if (projectId == null) {
    projectId = _adp.projectId;
  }
  console.info("Checking authorization for " + projectId);
  checkLoggedIn(function(result) {
    if (!result.status) {
      console.info("Non logged-in user");
      return false;
    } else {

    }
  });
  return false;
};

$(function() {
  _adp.projectId = uri.o.param("id");
  return checkProjectAuthorization();
});

//# sourceMappingURL=maps/project.js.map
