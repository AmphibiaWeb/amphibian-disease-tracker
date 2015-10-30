
/*
 * Drag-drop initialization
 *
 * If not using an application framework, place the code from
 * `integration.coffee` after this comment.
 */


/*
 * Watch DOM for element availability.
 *
 * Directly lifted from
 * http://ryanmorr.com/using-mutation-observers-to-watch-for-element-availability/
 */

(function() {
  
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
    window.dropperParams.metaPath = "/media-uploader/";
    window.dropperParams.uploadPath = "uploaded/";
    window.dropperParams.dependencyPath = "/media-uploader/bower_components/";
    window.dropperParams.showProgress = true;
    if ((base = window.dropperParams).dropTargetSelector == null) {
      base.dropTargetSelector = "#profile_new_message";
    }
    uploadButton = "<button class=\"upload-image media-uploader btn btn primary\" id=\"do-upload-image\"><span class=\"icon-batch-image\" style=\"position:relative; right:3px;\"></span></button>";
    window.dropperParams.clickTargets = ["#do-upload-image"];
    console.log(window.dropperParams);
    loadJS(dropperParams.bootstrapPath);
    return ready(dropperParams.dropTargetSelector, function(element) {
      console.info(dropperParams.dropTargetSelector + " is ready, binding");
      $(window.dropperParams.dropTargetSelector).parent().after(uploadButton);
      return window.dropperParams.handleDragDropImage(dropperParams.dropTargetSelector, dropperParams.postUploadHandler);
    });
  });

}).call(this);

//# sourceMappingURL=js/maps/client-upload.js.map
