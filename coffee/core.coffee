# Basic inits
root = exports ? this

isBool = (str) -> str is true or str is false

isEmpty = (str) -> not str or str.length is 0

isBlank = (str) -> not str or /^\s*$/.test(str)

isNull = (str) ->
  try
    if isEmpty(str) or isBlank(str) or not str?
      unless str is false or str is 0 then return true
  catch
  false

isJson = (str) ->
  if typeof str is 'object' then return true
  try
    JSON.parse(str)
    return true
  catch
  false

isNumber = (n) -> not isNaN(parseFloat(n)) and isFinite(n)

toFloat = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseFloat(str)

toInt = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseInt(str)

`function toObject(arr) {
    var rv = {};
    for (var i = 0; i < arr.length; ++i)
        if (arr[i] !== undefined) rv[i] = arr[i];
    return rv;
}`

String::toBool = -> this.toString() is 'true'

Boolean::toBool = -> this.toString() is 'true' # In case lazily tested

Object.size = (obj) ->
  size = 0
  size++ for key of obj when obj.hasOwnProperty(key)
  size

delay = (ms,f) -> setTimeout(f,ms)

roundNumber = (number,digits = 0) ->
  multiple = 10 ** digits
  Math.round(number * multiple) / multiple

jQuery.fn.exists = -> jQuery(this).length > 0

jQuery.fn.isVisible = ->
  jQuery(this).css("display") isnt "none"

jQuery.fn.hasChildren = ->
  Object.size(jQuery(this).children()) > 3

byteCount = (s) => encodeURI(s).split(/%..|./).length - 1

`function shuffle(o) { //v1.0
    for (var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
}`

window.debounce_timer = null
debounce: (func, threshold = 300, execAsap = false) ->
  # Borrowed from http://coffeescriptcookbook.com/chapters/functions/debounce
  # Only run the prototyped function once per interval.
  (args...) ->
    obj = this
    delayed = ->
      func.apply(obj, args) unless execAsap
    if window.debounce_timer?
      clearTimeout(window.debounce_timer)
    else if (execAsap)
      func.apply(obj, args)
    window.debounce_timer = setTimeout(delayed, threshold)

Function::debounce = (threshold = 300, execAsap = false, timeout = window.debounce_timer, args...) ->
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
  window.debounce_timer = setTimeout(delayed, threshold)



loadJS = (src, callback = new Object(), doCallbackOnError = true) ->
  ###
  # Load a new javascript file
  #
  # If it's already been loaded, jump straight to the callback
  #
  # @param string src The source URL of the file
  # @param function callback Function to execute after the script has
  #                          been loaded
  # @param bool|func doCallbackOnError Should the callback be executed if
  #                                    loading the script produces an error?
  #                                    If function, do it.
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
    catch e
      console.error "Onload error - #{e.message}"
  # Error function
  errorFunction = ->
    console.warn "There may have been a problem loading #{src}"
    try
      unless callback.done
        callback.done = true
        if typeof callback is "function" and doCallbackOnError is true
          try
            callback()
          catch e
            console.error "Post error callback error - #{e.message}"
            console.warn e.stack
      if typeof doCallbackOnError is "function"
        try
          doCallbackOnError()
        catch e
          console.error "Couldn't run post-error function - #{e.message}"
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


mapNewWindows = ->
  # Do new windows
  $(".newwindow").each ->
    # Add a click and keypress listener to
    # open links with this class in a new window
    curHref = $(this).attr("href")
    openInNewWindow = (url) ->
      if not url? then return false
      window.open(url)
      return false
    $(this).click ->
      openInNewWindow(curHref)
    $(this).keypress ->
      openInNewWindow(curHref)

# Animations

unless _metaStatus?.isLoading?
  unless _metaStatus?
    window._metaStatus = new Object()
  _metaStatus.isLoading = false

animateLoad = (elId = "loader", iteration = 0) ->
  ###
  # Suggested CSS to go with this:
  #
  # #loader {
  #     position:fixed;
  #     top:50%;
  #     left:50%;
  # }
  # #loader.good::shadow .circle {
  #     border-color: rgba(46,190,17,0.9);
  # }
  # #loader.bad::shadow .circle {
  #     border-color:rgba(255,0,0,0.9);
  # }
  ###
  if isNumber(elId) then elId = "loader"
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  ###
  # This is there for Edge, which sometimes leaves an element
  # We declare this early because Polymer tries to be smart and not
  # actually activate when it's hidden. Thus, this is a prerequisite
  # to actually re-showing it once hidden.
  ###
  $(selector).removeAttr("hidden")
  unless window._metaStatus?.isLoading?
    unless window._metaStatus?
      window._metaStatus = new Object()
    window._metaStatus.isLoading = false
  try
    if window._metaStatus.isLoading
      # Don't do this again until it's done loading.
      if iteration < 100
        iteration++
        delay 100, ->
          animateLoad(elId, iteration)
        return false
      else
        # Still not done loading? This probably isn't important
        # anymore.
        console.warn("Loader timed out waiting for load completion")
        return false
    unless $(selector).exists()
      $("body").append("<paper-spinner id=\"#{elId}\" active></paper-spinner")
    else
      $(selector)
      .attr("active",true) # Chrome, etc., want this
      #.prop("active",true) # Edge wants this
    window._metaStatus.isLoading = true
    false
  catch e
    console.warn('Could not animate loader', e.message)

stopLoad = (elId = "loader", fadeOut = 1000, iteration = 0) ->
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  try
    unless _metaStatus.isLoading
      # Wait until it's loading before executing again
      if iteration < 100
        iteration++
        delay 100, ->
          stopLoad(elId, fadeOut, iteration)
        return false
      else
        # Probably not worth waiting for anymore
        return false
    if $(selector).exists()
      $(selector).addClass("good")
      do endLoad = ->
        delay fadeOut, ->
          $(selector)
          .removeClass("good")
          .attr("active",false)
          .removeAttr("active")
          # Timeout for animations. There aren't any at the moment,
          # but leaving this as a placeholder.
          delay 1, ->
            $(selector).prop("hidden",true) # This is there for Edge, which sometimes leaves an element
            ###
            # Now, the slower part.
            # Edge does weirdness with active being toggled off, but
            # everyone else should have hidden removed so animateLoad()
            # behaves well. So, we check our browser sniffing.
            ###
            if Browsers?.browser?
              aliases = [
                "Spartan"
                "Project Spartan"
                "Edge"
                "Microsoft Edge"
                "MS Edge"
                ]
              if Browsers.browser.browser.name in aliases or Browsers.browser.engine.name is "EdgeHTML"
                # Nuke it from orbit. It's a slight performance hit, but
                # it's the only way to be sure.
                $(selector).remove()
                _metaStatus.isLoading = false
              else
                $(selector).removeAttr("hidden")
                delay 50, ->
                  # Give the DOM a chance to reflect it's no longer hidden
                  _metaStatus.isLoading = false
            else
              # Just default to "everything but Edge"
              $(selector).removeAttr("hidden")
              delay 50, ->
                # Give the DOM a chance to reflect it's no longer hidden
                _metaStatus.isLoading = false
    false
  catch e
    console.warn('Could not stop load animation', e.message)


stopLoadError = (message, elId = "loader", fadeOut = 7500, iteration) ->
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  try
    unless _metaStatus.isLoading
      # Wait until it's loading before executing again
      if iteration < 100
        iteration++
        delay 100, ->
          stopLoadError(message, elId, fadeOut, iteration)
        return false
      else
        # Probably not worth waiting for anymore
        return false
    if $(selector).exists()
      $(selector).addClass("bad")
      if message? then toastStatusMessage(message,"",fadeOut)
      do endLoad = ->
        delay fadeOut, ->
          $(selector)
          .removeClass("bad")
          .prop("active",false)
          .removeAttr("active")
          # Timeout for animations. There aren't any at the moment,
          # but leaving this as a placeholder.
          delay 1, ->
            $(selector).prop("hidden",true) # This is there for Edge, which sometimes leaves an element
            ###
            # Now, the slower part.
            # Edge does weirdness with active being toggled off, but
            # everyone else should have hidden removed so animateLoad()
            # behaves well. So, we check our browser sniffing.
            ###
            if Browsers?.browser?
              aliases = [
                "Spartan"
                "Project Spartan"
                "Edge"
                "Microsoft Edge"
                "MS Edge"
                ]
              if Browsers.browser.browser.name in aliases or Browsers.browser.engine.name is "EdgeHTML"
                # Nuke it from orbit. It's a slight performance hit, but
                # it's the only way to be sure.
                $(selector).remove()
                _metaStatus.isLoading = false
              else
                $(selector).removeAttr("hidden")
                delay 50, ->
                  # Give the DOM a chance to reflect it's no longer hidden
                  _metaStatus.isLoading = false
            else
              # Just default to "everything but Edge"
              $(selector).removeAttr("hidden")
              delay 50, ->
                # Give the DOM a chance to reflect it's no longer hidden
                _metaStatus.isLoading = false
    false
  catch e
    console.warn('Could not stop load error animation', e.message)


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
  loadJS "#{window.totpParams.relative}bower_components/imagelightbox/dist/imagelightbox.min.js", ->
    jqo
    .click (e) ->
      try
        # We want to stop the events propogating up for these
        e.preventDefault()
        e.stopPropagation()
        $(this).imageLightbox(options).startImageLightbox()
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
            when not isNull($(this).attr("data-lightbox-image"))
              $(this).attr("data-lightbox-image")
            else
              $(this).attr("src")
          $(this).replaceWith("<a href='#{imgUrl}' class='lightboximage'>#{tagHtml}</a>")
          $("a[href='#{imgUrl}']").imageLightbox(options)
        # Otherwise, we shouldn't need to do anything
      catch e
        console.log("Couldn't parse through the elements")
    console.info "Lightboxed the following:", jqo




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


$ ->
  try
    lightboxImages()
  catch e
    console.warn "Couldn't lightbox images! #{e.message}"
    console.warn e.stack
  try
    if typeof picturefill is "function"
      window.picturefill()
  catch e
    # We don't actually care here, probably hasn't been imported
    console.warn("Could not execute picturefill.")
  mapNewWindows()
  # Load any calls the script asked for
  try
    window.totpParams.tfaLock ?= false
    window.latejs ?= new Object()
    window.latejs.done ?= false
    if window.latejs.done isnt true and window.totpParams.tfaLock isnt true
      # Has the user embedded their own scripts?
      if typeof lateJS is "function"
        lateJS()
  catch e
    console.warn("There was an error calling lateJS(). If you haven't set that up, you can safely ignore this.")
  try
    # The really last stuff
    if typeof loadLast is "function"
      loadLast()
  catch e
    console.warn("There was an error calling loadLast(). This may result in unexpected behaviour.")
