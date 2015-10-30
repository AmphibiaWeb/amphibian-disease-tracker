###
# Drag-Drop integration to be "dropped" into the application handler.
#
# Write here, compile it, and place the compiled result in your
# application code.
#
# If no application handler is used, put this in the
# client-bootstrapper.coffee file
###

unless window.dropperParams?
  window.dropperParams = new Object()

window.dropperParams.dropTargetSelector = "#profile_new_message"

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
