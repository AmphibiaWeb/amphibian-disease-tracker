
/*
 *
 *
 *
 * See
 * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
 */
var apiTarget, conditionalLoadAccountSettingsOptions, constructProfileJson, loadUserBadges, profileAction, saveProfileChanges, setupProfileImageUpload;

profileAction = "update_profile";

apiTarget = uri.urlString + "/admin-api.php";

loadUserBadges = function() {

  /*
   *
   */
  return false;
};

setupProfileImageUpload = function() {

  /*
   * Bootstrap an uploader for images
   */
  return false;
};

conditionalLoadAccountSettingsOptions = function() {

  /*
   * Verify the account ownership, and if true, provide options for
   * various account settings.
   *
   * Largely acts as links back to admin-login.php
   */
  return false;
};

constructProfileJson = function(encodeForPosting) {
  var response;
  if (encodeForPosting == null) {
    encodeForPosting = false;
  }

  /*
   * Read all the fields and return a JSON formatted for the database
   * field
   *
   * See Github Issue #48
   *
   * @param bool encodeForPosting -> when true, returns a URI-encoded
   *   base64 string, rather than an actual object.
   */
  response = false;
  if (encodeForPosting) {
    response = post64(response);
  }
  return response;
};

saveProfileChanges = function() {

  /*
   * Post the appropriate JSON to the server and give user feedback
   * based on the response
   */
  var args;
  foo();
  return false;
  args = "perform=" + profileAction + "&data=";
  $.post(apiTarget, args, "json");
  return false;
};

$(function() {
  try {
    loadUserBadges();
  } catch (undefined) {}
  try {
    setupProfileImageUpload();
  } catch (undefined) {}
  try {
    conditionalLoadAccountSettingsOptions();
  } catch (undefined) {}
  $("#save-profile").click(function() {
    saveProfileChanges();
    return false;
  });
  return false;
});

//# sourceMappingURL=maps/profile.js.map
