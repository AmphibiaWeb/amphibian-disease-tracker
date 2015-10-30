
/*
 * Drag-Drop integration to be "dropped" into the application handler.
 *
 * Write here, compile it, and place the compiled result in your
 * application code.
 *
 * If no application handler is used, put this in the
 * client-bootstrapper.coffee file
 */
if (window.dropperParams == null) {
  window.dropperParams = new Object();
}

window.dropperParams.dropTargetSelector = "#profile_new_message";

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
  var e, html, mediaType, pathPrefix, realPath, serverProcessFlag;
  window.dropperParams.dropzone.removeAllFiles();
  if (typeof result !== "object") {
    console.error("Dropzone returned an error - " + result);
    window.toastStatusMessage("<strong>Error</strong> There was a problem with the server handling your image. Please try again.", "danger", "#profile_conversation_wrapper");
    return false;
  }
  if (result.status !== true) {
    if (result.human_error == null) {
      result.human_error = "There was a problem uploading your image.";
    }
    window.toastStatusMessage("<strong>Error</strong> " + result.human_error, "danger", "#profile_conversation_wrapper");
    console.error("Error uploading!", result);
    return false;
  }
  try {
    console.info("Server returned the following result:", result);
    console.info("The script returned the following file information:", file);
    pathPrefix = "";
    result.full_path = result.wrote_file;
    result.thumb_path = result.wrote_thumb;
    mediaType = result.mime_provided.split("/")[0];
    serverProcessFlag = "<!--FlagProcessImage::" + mediaType + "::" + pathPrefix + result.full_path + "::" + pathPrefix + result.thumb_path + "-->";
    html = (function() {
      switch (mediaType) {
        case "image":
          return serverProcessFlag + "\n<div class='message-media'>\n  <a href=\"" + pathPrefix + result.full_path + "\" class=\"newwindow\">\n    <img src=\"" + pathPrefix + result.thumb_path + "\" />\n  </a>\n  <p class=\"text-muted\">Click the thumbnail for a full-sized image (" + file.name + ")</p>\n</div>";
        case "audio":
          return serverProcessFlag + "\n<div class=\"message-media\">\n  <audio src=\"" + pathPrefix + result.full_path + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + result.thumb_path + "\" alt=\"Audio Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    (<a href=\"" + pathPrefix + result.full_path + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
        case "video":
          return serverProcessFlag + "\n<div class=\"message-media\">\n  <video src=\"" + pathPrefix + result.full_path + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + result.thumb_path + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    (<a href=\"" + pathPrefix + result.full_path + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
      }
    })();
    window.dropperParams.richDisplay = html;
    $("#profile_messages").append(html);
    realPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.full_path : "" + pathPrefix + result.thumb_path;
  } catch (_error) {
    e = _error;
    console.error("There was a problem with upload post-processing - " + e.message);
    console.warn("Using", file.name, result);
    window.toastStatusMessage("<strong>Error</strong> Your upload completed, but we couldn't post-process it.", "danger", "#profile_conversation_wrapper");
  }
  return false;
};
