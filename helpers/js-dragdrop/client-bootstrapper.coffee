###
# Drag-drop initialization
#
# If not using an application framework, place the code from
# `integration.coffee` after this comment.
###


unless window.dropperParams?
  window.dropperParams = new Object()



window.dropperParams.postUploadHandler = (file, result) ->
  ###
  # The callback function for handleDragDropImage
  #
  # The "file" object contains information about the uploaded file,
  # such as name, height, width, size, type, and more. Check the
  # console logs in the demo for a full output.
  #
  # The result object contains the results of the upload. The "status"
  # key is true or false depending on the status of the upload, and
  # the other most useful keys will be "full_path" and "thumb_path".
  #
  # When invoked, it calls the "self" helper methods to actually do
  # the file sending.
  ###
  # Clear out the file uploader
  window.dropperParams.dropzone.removeAllFiles()

  if typeof result isnt "object"
    console.error "Dropzone returned an error - #{result}"
    window.toastStatusMessage("<strong>Error</strong> There was a problem with the server handling your image. Please try again.", "danger", "#profile_conversation_wrapper")
    return false
  unless result.status is true
    # Yikes! Didn't work
    result.human_error ?= "There was a problem uploading your image."
    window.toastStatusMessage("<strong>Error</strong> #{result.human_error}", "danger", "#profile_conversation_wrapper")
    console.error("Error uploading!",result)
    return false
  try
    console.info "Server returned the following result:", result
    console.info "The script returned the following file information:", file
    # EG, an S3 bucket
    pathPrefix = ""
    # Replace full_path and thumb_path with "wrote"
    result.full_path = result.wrote_file
    result.thumb_path = result.wrote_thumb
    mediaType = result.mime_provided.split("/")[0]
    serverProcessFlag = "<!--FlagProcessImage::#{mediaType}::#{pathPrefix}#{result.full_path}::#{pathPrefix}#{result.thumb_path}-->"
    html = switch mediaType
      when "image" then """#{serverProcessFlag}
        <div class='message-media'>
          <a href="#{pathPrefix}#{result.full_path}" class="newwindow">
            <img src="#{pathPrefix}#{result.thumb_path}" />
          </a>
          <p class="text-muted">Click the thumbnail for a full-sized image (#{file.name})</p>
        </div>
        """
      when "audio" then """#{serverProcessFlag}
      <div class="message-media">
        <audio src="#{pathPrefix}#{result.full_path}" controls preload="auto">
          <img src="#{pathPrefix}#{result.thumb_path}" alt="Audio Thumbnail" class="img-responsive" />
          <p>
            Your browser doesn't support the HTML5 <code>audio</code> element.
            Please download the file below.
          </p>
        </audio>
        <p class="text-muted">
          (<a href="#{pathPrefix}#{result.full_path}" class="newwindow" download="#{file.name}">
            Original Media
          </a>)
        </p>
      </div>
      """
      when "video" then """#{serverProcessFlag}
      <div class="message-media">
        <video src="#{pathPrefix}#{result.full_path}" controls preload="auto">
          <img src="#{pathPrefix}#{result.thumb_path}" alt="Video Thumbnail" class="img-responsive" />
          <p>
            Your browser doesn't support the HTML5 <code>video</code> element.
            Please download the file below.
          </p>
        </video>
        <p class="text-muted">
          (<a href="#{pathPrefix}#{result.full_path}" class="newwindow" download="#{file.name}">
            Original Media
          </a>)
        </p>
      </div>
      """
    window.dropperParams.richDisplay = html
    $("#profile_messages").append(html) ## Test, displays only
    realPath = if file.size < 5*1024*1024 or mediaType isnt "image" then "#{pathPrefix}#{result.full_path}" else "#{pathPrefix}#{result.thumb_path}"
    # Actually send the message    
  catch e
    console.error("There was a problem with upload post-processing - #{e.message}")
    console.warn("Using",file.name,result)
    window.toastStatusMessage("<strong>Error</strong> Your upload completed, but we couldn't post-process it.", "danger", "#profile_conversation_wrapper")
  false



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
  window.dropperParams.metaPath = "/helpers/js-dragdrop/"
  window.dropperParams.uploadPath = "#{window.dropperParams.metaPath}uploaded/"
  window.dropperParams.dependencyPath = "#{window.dropperParams.metapath}bower_components/"
  window.dropperParams.showProgress = true
  window.dropperParams.dropTargetSelector ?= "#file-uploader"
  # Add a click target
  uploadButton = """
  <button class="upload-image media-uploader btn btn primary" id="do-upload-file"><span class="glyphicon glyphicon-cloud-upload"></span></button>
  """
  window.dropperParams.clickTargets = ["#do-upload-file"]
  window.dropperParams.mimeTypes = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv,application/zip,application/x-7z-compressed,image/*"

  console.log window.dropperParams
  # We shouldn't actually instantiate the dropper until the element
  # exists
  ready dropperParams.dropTargetSelector, (element) ->
    console.info "#{dropperParams.dropTargetSelector} is ready, binding"
    $(window.dropperParams.dropTargetSelector).parent().after uploadButton
    # Do base binding
    # The post upload handler should be in integration.coffee, and
    # should either be here, or directly integrated into a greater application
    window.dropperParams.handleDragDropImage dropperParams.dropTargetSelector, dropperParams.postUploadHandler
