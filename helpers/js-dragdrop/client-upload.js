
/*
 * Drag-drop initialization
 *
 * If not using an application framework, place the code from
 * `integration.coffee` after this comment.
 */

(function() {
  if (window.dropperParams == null) {
    window.dropperParams = new Object();
  }

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


  /*
   * Watch DOM for element availability.
   *
   * Directly lifted from
   * http://ryanmorr.com/using-mutation-observers-to-watch-for-element-availability/
   */

  
(function(win){
    'use strict';

    var listeners = [],
    doc = win.document,
    MutationObserver = win.MutationObserver || win.WebKitMutationObserver,
    observer;

    function ready(selector, fn){
        // Store the selector and callback to be monitored
        listeners.push({
            selector: selector,
            fn: fn
        });
        if(!observer){
            // Watch for changes in the document
            observer = new MutationObserver(check);
            observer.observe(doc.documentElement, {
                childList: true,
                subtree: true
            });
        }
        // Check if the element is currently in the DOM
        check();
    }

    function check(){
        // Check the DOM for elements matching a stored selector
        for(var i = 0, len = listeners.length, listener, elements; i < len; i++){
            listener = listeners[i];
            // Query for elements matching the specified selector
            elements = doc.querySelectorAll(listener.selector);
            for(var j = 0, jLen = elements.length, element; j < jLen; j++){
                element = elements[j];
                // Make sure the callback isn't invoked with the
                // same element more than once
                if(!element.ready){
                    element.ready = true;
                    // Invoke the callback with the element
                    listener.fn.call(element, element);
                }
            }
        }
    }

    // Expose 'ready'
    win.ready = ready;

})(this);
;

  $(function() {
    var base, uploadButton;
    console.info("Configuring dropper parameters");
    if (window.dropperParams == null) {
      window.dropperParams = new Object();
    }
    window.dropperParams.metaPath = "/helpers/js-dragdrop/";
    window.dropperParams.uploadPath = window.dropperParams.metaPath + "uploaded/";
    window.dropperParams.dependencyPath = window.dropperParams.metapath + "bower_components/";
    window.dropperParams.showProgress = true;
    if ((base = window.dropperParams).dropTargetSelector == null) {
      base.dropTargetSelector = "#file-uploader";
    }
    uploadButton = "<button class=\"upload-image media-uploader btn btn primary\" id=\"do-upload-file\"><span class=\"glyphicon glyphicon-cloud-upload\"></span></button>";
    window.dropperParams.clickTargets = ["#do-upload-file"];
    window.dropperParams.mimeTypes = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv,application/zip,application/x-7z-compressed,image/*";
    console.log(window.dropperParams);
    return ready(dropperParams.dropTargetSelector, function(element) {
      console.info(dropperParams.dropTargetSelector + " is ready, binding");
      $(window.dropperParams.dropTargetSelector).parent().after(uploadButton);
      return window.dropperParams.handleDragDropImage(dropperParams.dropTargetSelector, dropperParams.postUploadHandler);
    });
  });

}).call(this);

//# sourceMappingURL=js/maps/client-upload.js.map
