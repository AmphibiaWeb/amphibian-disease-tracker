###
# Drag-drop initialization
#
# If not using an application framework, place the code from
# `integration.coffee` after this comment.
###


###
# Watch DOM for element availability.
#
# Directly lifted from
# http://ryanmorr.com/using-mutation-observers-to-watch-for-element-availability/
###
`
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
`




$ ->
  # Configuration
  console.info "Configuring dropper parameters"
  window.dropperParams ?= new Object()
  window.dropperParams.metaPath = "/media-uploader/"
  window.dropperParams.uploadPath = "uploaded/"
  window.dropperParams.dependencyPath = "/media-uploader/bower_components/"
  window.dropperParams.showProgress = true
  window.dropperParams.dropTargetSelector ?= "#profile_new_message"
  # Add a click target
  uploadButton = """
  <button class="upload-image media-uploader btn btn primary" id="do-upload-image"><span class="icon-batch-image" style="position:relative; right:3px;"></span></button>
  """
  window.dropperParams.clickTargets = ["#do-upload-image"]

  console.log window.dropperParams

  # Load Bootstrap's JS
  loadJS dropperParams.bootstrapPath
  # We shouldn't actually instantiate the dropper until the element
  # exists
  ready dropperParams.dropTargetSelector, (element) ->
    console.info "#{dropperParams.dropTargetSelector} is ready, binding"
    $(window.dropperParams.dropTargetSelector).parent().after uploadButton
    # Do base binding
    # The post upload handler should be in integration.coffee, and
    # should either be here, or directly integrated into a greater application
    window.dropperParams.handleDragDropImage dropperParams.dropTargetSelector, dropperParams.postUploadHandler
