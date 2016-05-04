
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
  var el, i, inputs, key, len, parentKey, response, tmp, val;
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
  tmp = new Object();
  inputs = $(".profile-data:not(.from-base-profile) .user-input");
  for (i = 0, len = inputs.length; i < len; i++) {
    el = inputs[i];
    val = p$(el).value;
    key = $(el).attr("data-source");
    parentKey = $(el).parents("[data-source]").attr("data-source");
    tmp[parentKey][key] = val;
  }
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
  var args, data;
  foo();
  return false;
  startLoad();
  data = constructProfileJson(true);
  args = "perform=" + profileAction + "&data=" + data;
  $.post(apiTarget, args, "json").done(function(result) {
    $("#save-profile").attr("disabled", "disabled");
    stopLoad();
    return false;
  }).fail(function(result, status) {
    stopLoadError();
    return false;
  });
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
  $("#main-body input").keyup(function() {
    $("#save-profile").removeAttr("disabled");
    return false;
  });
  return false;
});

//# sourceMappingURL=maps/profile.js.map
