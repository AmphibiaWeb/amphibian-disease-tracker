window.locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined

window.debounce_timer = null

isBool = (str,strict = false) ->
  if strict
    return typeof str is "boolean"
  try
    if typeof str is "boolean"
      return str is true or str is false
    if typeof str is "string"
      return str.toLowerCase() is "true" or str.toLowerCase() is "false"
    if typeof str is "number"
      return str is 1 or str is 0
    false
  catch e
    return false

isEmpty = (str) -> not str or str.length is 0

isBlank = (str) -> not str or /^\s*$/.test(str)

isNull = (str) ->
  try
    if isEmpty(str) or isBlank(str) or not str?
      unless str is false or str is 0 then return true
  catch e
    return false
  false

isJson = (str) ->
  if typeof str is 'object' then return true
  try
    JSON.parse(str)
    return true
  catch e
    return false
  false

isNumber = (n) -> not isNaN(parseFloat(n)) and isFinite(n)

toFloat = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseFloat(str)

toInt = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseInt(str)

String::toBool = ->
  test = @toString().toLowerCase()
  test is 'true' or test is "1"

Boolean::toBool = -> @toString() is "true"

Number::toBool = -> @toString() is "1"

String::addSlashes = ->
  `this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0')`


Object.size = (obj) ->
  if typeof obj isnt "object"
    try
      return obj.length
    catch e
      console.error("Passed argument isn't an object and doesn't have a .length parameter")
      console.warn(e.message)
  size = 0
  size++ for key of obj when obj.hasOwnProperty(key)
  size

delay = (ms,f) -> setTimeout(f,ms)

roundNumber = (number,digits = 0) ->
  multiple = 10 ** digits
  Math.round(number * multiple) / multiple


roundNumberSigfig = (number, digits = 0) ->
  newNumber = roundNumber(number, digits).toString()
  digArr = newNumber.split(".")
  if digArr.length is 1
    return "#{newNumber}.#{Array(digits + 1).join("0")}"
  trailingDigits = digArr.pop()
  significand = "#{digArr[0]}."
  if trailingDigits.length is digits
    return newNumber
  needDigits = digits - trailingDigits.length
  trailingDigits += Array(needDigits + 1).join("0")
  "#{significand}#{trailingDigits}"


jsonTo64 = (obj) ->
  if typeof obj is "array"
    obj = toObject(arr)
  objString = JSON.stringify(obj)
  encodeURIComponent(encode64(objString))

encode64 = (string) ->
  try
    Base64.encode(string)
  catch e
    console.warn("Bad encode string provided")
    string
decode64 = (string) ->
  try
    Base64.decode(string)
  catch e
    console.warn("Bad decode string provided")
    string


isHovered = (selector) ->
  $("#{selector}:hover").length > 0


jQuery.fn.exists = -> jQuery(this).length > 0

jQuery.fn.isVisible = ->
  jQuery(this).is(":visible") and jQuery(this).css("visibility") isnt "hidden"

jQuery.fn.hasChildren = ->
  Object.size(jQuery(this).children()) > 3

byteCount = (s) => encodeURI(s).split(/%..|./).length - 1

`function shuffle(o) { //v1.0
    for (var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
}`



toObject = (array) ->
  rv = new Object()
  for index, element of array
    if element isnt undefined then rv[index] = element
  rv


loadJS = (src, callback = new Object(), doCallbackOnError = true) ->
  ###
  # Load a new javascript file
  #
  # If it's already been loaded, jump straight to the callback
  #
  # @param string src The source URL of the file
  # @param function callback Function to execute after the script has
  #                          been loaded
  # @param bool doCallbackOnError Should the callback be executed if
  #                               loading the script produces an error?
  ###
  if $("script[src='#{src}']").exists()
    if typeof callback is "function"
      try
        callback()
      catch e
        console.error "Script is already loaded, but there was an error executing the callback function - #{e.message}"
    # Whether or not there was a callback, end the script
    return true
  # Create a new DOM selement
  s = document.createElement("script")
  # Set all the attributes. We can be a bit redundant about this
  s.setAttribute("src",src)
  s.setAttribute("async","async")
  s.setAttribute("type","text/javascript")
  s.src = src
  s.async = true
  # Onload function
  onLoadFunction = ->
    state = s.readyState
    try
      if not callback.done and (not state or /loaded|complete/.test(state))
        callback.done = true
        if typeof callback is "function"
          try
            callback()
          catch e
            console.error "Postload callback error - #{e.message}"
            console.warn e.stack
    catch e
      console.error "Onload error - #{e.message}"
  # Error function
  errorFunction = ->
    console.warn "There may have been a problem loading #{src}"
    try
      unless callback.done
        callback.done = true
        if typeof callback is "function" and doCallbackOnError
          try
            callback()
          catch e
            console.error "Post error callback error - #{e.message}"
    catch e
      console.error "There was an error in the error handler! #{e.message}"
  # Set the attributes
  s.setAttribute("onload",onLoadFunction)
  s.setAttribute("onreadystate",onLoadFunction)
  s.setAttribute("onerror",errorFunction)
  s.onload = s.onreadystate = onLoadFunction
  s.onerror = errorFunction
  document.getElementsByTagName('head')[0].appendChild(s)
  true

window.loadJS = loadJS

String::toTitleCase = ->
  # From http://stackoverflow.com/a/6475125/1877527
  str =
    @replace /([^\W_]+[^\s-]*) */g, (txt) ->
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

  # Certain minor words should be left lowercase unless
  # they are the first or last words in the string
  lowers = [
    "A"
    "An"
    "The"
    "And"
    "But"
    "Or"
    "For"
    "Nor"
    "As"
    "At"
    "By"
    "For"
    "From"
    "In"
    "Into"
    "Near"
    "Of"
    "On"
    "Onto"
    "To"
    "With"
    ]
  for lower in lowers
    lowerRegEx = new RegExp("\\s#{lower}\\s","g")
    str = str.replace lowerRegEx, (txt) -> txt.toLowerCase()

  # Certain words such as initialisms or acronyms should be left
  # uppercase
  uppers = [
    "Id"
    "Tv"
    ]
  for upper in uppers
    upperRegEx = new RegExp("\\b#{upper}\\b","g")
    str = str.replace upperRegEx, upper.toUpperCase()
  str


Function::debounce = (threshold = 300, execAsap = false, timeout = debounce_timer, args...) ->
  # Borrowed from http://coffeescriptcookbook.com/chapters/functions/debounce
  # Only run the prototyped function once per interval.
  func = this
  delayed = ->
    func.apply(func, args) unless execAsap
    console.log("Debounce applied")
  if timeout?
    try
      clearTimeout(timeout)
    catch e
      # just do nothing
  else if execAsap
    func.apply(obj, args)
    console.log("Executed immediately")
  setTimeout(delayed, threshold)

randomInt = (lower = 0, upper = 1) ->
  start = Math.random()
  if not lower?
    [lower, upper] = [0, lower]
  if lower > upper
    [lower, upper] = [upper, lower]
  return Math.floor(start * (upper - lower + 1) + lower)



toastStatusMessage = (message, type = "warning", fallbackContainer = "body", selector = "#js-uploader-status-message") ->
  ###
  # Pop up a status message
  # Uses the Bootstrap alert dialog
  #
  # See
  # http://getbootstrap.com/components/#alerts
  # for available types
  ###
  if not $(selector).exists()
    html = """
    <div class="alert alert-#{type} alert-dismissable" role="alert" id="#{selector.slice(1)}">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <div class="alert-message"></div>
    </div>
    """
    topContainer = if $("main").exists() then "main" else if $("article").exists() then "article" else fallbackContainer
    $(topContainer).prepend(html)
  $("#{selector} .alert-message").html(message)

window.dropperParams ?= new Object()
dropperParams.toastStatusMessage = toastStatusMessage

openLink = (url) ->
  if not url? then return false
  window.open(url)
  false

openTab = (url) ->
  openLink(url)

goTo = (url) ->
  if not url? then return false
  window.location.href = url
  false


mapNewWindows = (stopPropagation = true) ->
  # Do new windows
  $(".newwindow").each ->
    # Add a click and keypress listener to
    # open links with this class in a new window
    curHref = $(this).attr("href")
    if not curHref?
      # Support non-standard elements
      curHref = $(this).attr("data-href")
    openInNewWindow = (url) ->
      if not url? then return false
      window.open(url)
      return false
    $(this).click (e) ->
      if stopPropagation
        e.preventDefault()
        e.stopPropagation()
      openInNewWindow(curHref)
    $(this).keypress ->
      openInNewWindow(curHref)

dropperParams.mapNewWindows = mapNewWindows

deepJQuery = (selector) ->
  ###
  # Do a shadow-piercing selector
  #
  # Cross-browser, works with Chrome, Firefox, Opera, Safari, and IE
  # Falls back to standard jQuery selector when everything fails.
  ###
  try
    # Chrome uses /deep/ which has been deprecated
    # See http://dev.w3.org/csswg/css-scoping/#deep-combinator
    # https://w3c.github.io/webcomponents/spec/shadow/#composed-trees
    # This is current as of Chrome 44.0.2391.0 dev-m
    # See https://code.google.com/p/chromium/issues/detail?id=446051
    unless $("html /deep/ #{selector}").exists()
      throw("Bad /deep/ selector")
    return $("html /deep/ #{selector}")
  catch e
    try
      # Firefox uses >>> instead of "deep"
      # https://developer.mozilla.org/en-US/docs/Web/Web_Components/Shadow_DOM
      # This is actually the correct selector
      unless $("html >>> #{selector}").exists()
        throw("Bad >>> selector")
      return $("html >>> #{selector}")
    catch e
      # These don't match at all -- do the normal jQuery selector
      return $(selector)

d$ = (selector) ->
  deepJQuery(selector)


bindClicks = (selector = ".click") ->
  ###
  # Helper function. Bind everything with a selector
  # to execute a function data-function or to go to a
  # URL data-href.
  ###
  $(selector).each ->
    try
      url = $(this).attr("data-href")
      if not isNull(url)
        $(this).unbind()
        # console.log("Binding a url to ##{$(this).attr("id")}")
        try
          if url is uri.o.attr("path") and $(this).prop("tagName").toLowerCase() is "paper-tab"
            $(this).parent().prop("selected",$(this).index())
        catch e
          console.warn("tagname lower case error")
        $(this).click ->
          try
            if $(this).attr("newTab")?.toBool() or $(this).attr("newtab")?.toBool() or $(this).attr("data-newtab")?.toBool()
              openTab(url)
            else
              goTo(url)
          catch
            goTo(url)
        return url
      else
        # Check for onclick function
        callable = $(this).attr("data-function")
        if callable?
          $(this).unbind()
          # console.log("Binding #{callable}() to ##{$(this).attr("id")}")
          $(this).click ->
            try
              console.log("Executing bound function #{callable}()")
              window[callable]()
            catch e
              console.error("'#{callable}()' is a bad function - #{e.message}")
    catch e
      console.error("There was a problem binding to ##{$(this).attr("id")} - #{e.message}")
  false

getPosterFromSrc = (srcString) ->
  ###
  # Take the "src" attribute of a video and get the
  # "png" screencap from it, and return the value.
  ###
  try
    split = srcString.split(".")
    dummy = split.pop()
    split.push("png");
    return split.join(".")
  catch e
    return ""

lightboxImages = (selector = ".lightboximage", lookDeeply = false) ->
  ###
  # Lightbox images with this selector
  #
  # If the image has it, wrap it in an anchor and bind;
  # otherwise just apply to the selector.
  #
  # Requires ImageLightbox
  # https://github.com/rejas/imagelightbox
  ###
  # The options!
  options =
      onStart: ->
        overlayOn()
      onEnd: ->
        overlayOff()
        activityIndicatorOff()
      onLoadStart: ->
        activityIndicatorOn()
      onLoadEnd: ->
        activityIndicatorOff()
      allowedTypes: 'png|jpg|jpeg|gif|bmp|webp'
      quitOnDocClick: true
      quitOnImgClick: true
  jqo = if lookDeeply then d$(selector) else $(selector)
  jqo
  .click (e) ->
    try
      $(this).imageLightbox(options).startImageLightbox()
      # We want to stop the events propogating up for these
      e.preventDefault()
      e.stopPropagation()
      console.warn("Event propagation was stopped when clicking on this.")
    catch e
      console.error("Unable to lightbox this image!")
  # Set up the items
  .each ->
    console.log("Using selectors '#{selector}' / '#{this}' for lightboximages")
    try
      if $(this).prop("tagName").toLowerCase() is "img" and $(this).parent().prop("tagName").toLowerCase() isnt "a"
        tagHtml = $(this).removeClass("lightboximage").prop("outerHTML")
        imgUrl = switch
          when not isNull($(this).attr("data-layzr-retina"))
            $(this).attr("data-layzr-retina")
          when not isNull($(this).attr("data-layzr"))
            $(this).attr("data-layzr")
          else
            $(this).attr("src")
        $(this).replaceWith("<a href='#{imgUrl}' class='lightboximage'>#{tagHtml}</a>")
    catch e
      console.log("Couldn't parse through the elements")


activityIndicatorOn = ->
  $('<div id="imagelightbox-loading"><div></div></div>' ).appendTo('body')
activityIndicatorOff = ->
  $('#imagelightbox-loading').remove()
  $("#imagelightbox-overlay").click ->
    # Clicking anywhere on the overlay clicks on the image
    # It loads too late to let the quitOnDocClick work
    $("#imagelightbox").click()
overlayOn = ->
  $('<div id="imagelightbox-overlay"></div>').appendTo('body')
overlayOff = ->
  $('#imagelightbox-overlay').remove()

formatScientificNames = (selector = ".sciname") ->
    $(".sciname").each ->
      # Is it italic?
      nameStyle = if $(this).css("font-style") is "italic" then "normal" else "italic"
      $(this).css("font-style",nameStyle)

prepURI = (string) ->
  string = encodeURIComponent(string)
  string.replace(/%20/g,"+")


window.locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined

getLocation = (callback = undefined) ->
  geoSuccess = (pos,callback) ->
    window.locationData.lat = pos.coords.latitude
    window.locationData.lng = pos.coords.longitude
    window.locationData.acc = pos.coords.accuracy
    window.locationData.last = Date.now() # ms, unix time
    if callback?
      callback(window.locationData)
    false
  geoFail = (error,callback) ->
    locationError = switch error.code
      when 0 then "There was an error while retrieving your location: #{error.message}"
      when 1 then "The user prevented this page from retrieving a location"
      when 2 then "The browser was unable to determine your location: #{error.message}"
      when 3 then "The browser timed out retrieving your location."
    console.error(locationError)
    if callback?
      callback(false)
    false
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition(geoSuccess,geoFail,window.locationData.params)
  else
    console.warn("This browser doesn't support geolocation!")
    if callback?
      callback(false)

getMaxZ = ->
  mapFunction = ->
    $.map $("body *"), (e,n) ->
      if $(e).css("position") isnt "static"
        return parseInt $(e).css("z-index") or 1
  Math.max.apply null, mapFunction()

foo = ->
  toastStatusMessage("Sorry, this feature is not yet finished")
  stopLoad()
  false


$ ->
  bindClicks()
  window.bindClicks = bindClicks
  window.mapNewWindows = mapNewWindows

###
# This is the main scripting file to handle the drag and drop uploads.
#
# It requires a few dependencies from core.coffee, and the two files
# are concatenated by the Gruntfile in this repository.
###

# We want to make sure that the user can define dropperParams early,
# and not erase their customizations.
unless window.dropperParams?
  window.dropperParams = new Object()
# Path to where meta.php lives. This is the file that handles the
# server-side upload.
dropperParams.metaPath ?= ""
# Where are the uploaded images kept?
dropperParams.uploadPath ?= "uploaded_images/"
# We require some stuff, most notably Dropzone.
dropperParams.dependencyPath ?= "bower_components/"
## Deprecated
## dropperParams.md5Path = "#{dropperParams.dependencyPath}JavaScript-MD5/js/md5.min.js"
# Maximum width of generated thumbnail
dropperParams.thumbWidth ?= 640
# Maximum height of generated thumbnail
dropperParams.thumbHeight ?= 480
# Should a progress bar be generated and displayed below the upload target?
dropperParams.showProgress ?= true
# An array of CSS selectors for targets that can initiate the upload
# on click. False means no targets take a click.
dropperParams.clickTargets ?= false
# Mime types
dropperParams.mimeTypes ?= "image/*,video/mp4,video/3gpp,audio/*"


handleDragDropImage = (uploadTargetSelector = "#upload-image", callback) ->
  ###
  # Take a drag-and-dropped image, and save it out to the database.
  # This function should be called on page load.
  #
  # This function is Shadow-DOM aware, and will work on Webcomponents.
  ###
  # Calculate the paths based on declared parameters.
  # dropperParams.dropzonePath = "#{dropperParams.dependencyPath}dropzone/dist/min/dropzone.min.js"
  dropperParams.dropzonePath = "#{dropperParams.metaPath}js/dropzone-custom.min.js"
  dropperParams.bootstrapPath = "#{dropperParams.dependencyPath}bootstrap/dist/js/bootstrap.min.js"
  # If no callback is provided, we use this default one
  unless typeof callback is "function"
    callback = (file, result) ->
      if typeof result isnt "object"
        console.error "Dropzone returned an error - #{result}"
        dropperParams.toastStatusMessage("<strong>Error</strong> There was a problem with the server handling your image. Please try again.", "danger", "main")
        return false
      unless result.status is true
        # Yikes! Didn't work
        result.human_error ?= "There was a problem uploading your image."
        dropperParams.toastStatusMessage("<strong>Error</strong> #{result.human_error}", "danger", "main")
        console.error("Error uploading!",result)
        return false
      try
        console.info "Server returned the following result:", result
        console.info "The script returned the following file information:", file
        dropperParams.dropzone.removeAllFiles()
        dropperParams.toastStatusMessage("Upload complete", "success", "main")
      catch e
        console.error("There was a problem with upload post-processing - #{e.message}")
        console.warn("Using",fileName,result)
        dropperParams.toastStatusMessage("<strong>Error</strong> Your upload completed, but we couldn't post-process it.", "danger", "main")
      false
  ## The main script
  # Load dependencies
  loadJS dropperParams.bootstrapPath
  loadJS dropperParams.dropzonePath, ->
    # Dropzone has been loaded!
    # Add the CSS
    c = document.createElement("link")
    c.setAttribute("rel","stylesheet")
    c.setAttribute("type","text/css")
    # Load up the stylesheets for this. Includes bootstrap.
    c.setAttribute("href","#{dropperParams.metaPath}css/main.min.css")
    document.getElementsByTagName('head')[0].appendChild(c)
    Dropzone.autoDiscover = false
    # See http://www.dropzonejs.com/#configuration
    defaultText = dropperParams.uploadText ? "Drop your file here to upload"
    dragCancel = ->
      d$(uploadTargetSelector)
      .css("box-shadow","")
      .css("border","")
      d$("#{uploadTargetSelector} .dz-message span").text(defaultText)
    cleanup = (dzregion) ->
      d$("#{uploadTargetSelector} + .image-upload-progress").remove()
      # Undo position relative
      d$("#do-upload-image")
      .css("top","")
      .css("position","")
      try
        dzregion.removeAllFiles()
    dropzoneConfig =
      url: "#{dropperParams.metaPath}meta.php?do=upload_file&uploadpath=#{dropperParams.uploadPath}&thumb_width=#{dropperParams.thumbWidth}&thumb_height=#{dropperParams.thumbHeight}"
      acceptedFiles: dropperParams.mimeTypes
      autoProcessQueue: true
      maxFiles: 1
      dictDefaultMessage: defaultText
      clickable: dropperParams.clickTargets
      init: ->
        # See http://www.dropzonejs.com/#events
        @on "error", (file, errorMessage) =>
          dropperParams.toastStatusMessage("An error occured sending your file to the server - #{errorMessage}", "danger", "main")
          console.error "Got the following file details back:", file
          cleanup(this)
        @on "canceled", =>
          dropperParams.toastStatusMessage("Upload canceled.", "info", "main")
          cleanup(this)
        @on "dragover", ->
          d$("#{uploadTargetSelector} .dz-message span").text defaultText
          ###
          # We want to hint a good hover -- so we use CSS
          #
          # box-shadow: 0px 0px 15px rgba(15,157,88,.8);
          # border: 1px solid #0F9D58;
          ###
          d$(uploadTargetSelector)
          .css("box-shadow","0px 0px 15px rgba(15,157,88,.8)")
          .css("border","1px solid #0F9D58")
        @on "dragleave", ->
          dragCancel()
        @on "dragend", ->
          dragCancel()
        @on "drop", ->
          dragCancel()
        @on "uploadprogress", (file, progress, bytes) ->
          if dropperParams.showProgress is true
            progressBar = d$("#{uploadTargetSelector} + .image-upload-progress")
            unless progressBar.exists()
              # Show a bootstrap progress bar
              # http://getbootstrap.com/components/#progress
              html = """
              <div class="image-upload-progress">
                <div class="progress">
                  <div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="min-width:2em;">
                    <span class="upload-percent">0</span>%<span class="sr-only"> Complete</span>
                  </div>
                </div>
                <p class="text-center text-muted"><span class="bytes-done">0</span>/<span class="bytes-total">0</span> bytes</p>
              </div>
              """
              d$(uploadTargetSelector).after(html)
              progressBar = d$("#{uploadTargetSelector} + .image-upload-progress")
              # Offset the upload button
              buttonOffsetHeight = $(".image-upload-progress").outerHeight() + $("#profile_new_message").height() + $("#do-upload-image").outerHeight()
              $("#do-upload-image")
              .css("top","-#{buttonOffsetHeight}px!important")
              .css("position","relative!important")
            progress = toInt(progress)
            # Handle the upload
            progressBar.find(".progress-bar")
            .attr("aria-valuenow",progress)
            .css("width","#{progress}%")
            progressBar.find(".upload-percent").text(progress)
            progressBar.find(".bytes-done").text(bytes)
            progressBar.find(".bytes-total").text(file.size)
        @on "success", (file, result) =>
          cleanup(this)
          callback(file, result)
    # Create the upload target
    unless d$(uploadTargetSelector).hasClass("dropzone")
      d$(uploadTargetSelector).addClass("dropzone")
    try
      fileUploadDropzone = new Dropzone(d$(uploadTargetSelector).get(0), dropzoneConfig)
    catch e
      console.warn "Warning! The drop target may be misconfigured. Dropzone said '#{e.message}'"
      dropperParams.config = dropzoneConfig
      console.info "Your dropzone configuration has been saved in dropperParams.config"
    dropperParams.dropzone = fileUploadDropzone
  false

# Export
dropperParams.handleDragDropImage = handleDragDropImage
