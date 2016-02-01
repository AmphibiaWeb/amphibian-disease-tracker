# Set up basic URI parameters
# Uses
# https://github.com/allmarkedup/purl
try
  uri = new Object()
  uri.o = $.url()
  uri.urlString = uri.o.attr('protocol') + '://' + uri.o.attr('host')  + uri.o.attr("directory")
  uri.query = uri.o.attr("fragment")
catch e
  console.warn("PURL not installed!")

window.locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined

window.debounce_timer = null

window.adminParams ?= new Object()

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

String::toBool = -> @toString().toLowerCase() is 'true' or @toString() is "1"

Boolean::toBool = -> @toString() is 'true'

Number::toBool = -> @toString() is "1"

String::addSlashes = ->
  `this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0')`

Array::max = -> Math.max.apply null, this

Array::min = -> Math.min.apply null, this


Object.toArray = (obj) ->
  Object.keys(obj).map (key) =>
    obj[key]

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

jQuery.fn.polymerSelected = (setSelected = undefined, attrLookup = "attrForSelected") ->
  ###
  # See
  # https://elements.polymer-project.org/elements/paper-menu
  # https://elements.polymer-project.org/elements/paper-radio-group
  #
  # @param attrLookup is based on
  # https://elements.polymer-project.org/elements/iron-selector?active=Polymer.IronSelectableBehavior
  ###
  attr = $(this).attr(attrLookup)
  if setSelected?
    if not isBool(setSelected)
      try
        $(this).get(0).select(setSelected)
      catch e
        return false
    else
      $(this).parent().children().removeAttribute("aria-selected")
      $(this).parent().children().removeAttribute("active")
      $(this).parent().children().removeClass("iron-selected")
      $(this).prop("selected",setSelected)
      $(this).prop("active",setSelected)
      $(this).prop("aria-selected",setSelected)
      if setSelected is true
        $(this).addClass("iron-selected")
  else
    val = undefined
    try
      val = $(this).get(0).selected
      if isNumber(val) and not isNull(attr)
        itemSelector = $(this).find("paper-item")[toInt(val)]
        val = $(itemSelector).attr(attr)
    catch e
      return false
    if val is "null" or not val?
      val = undefined
    val

jQuery.fn.polymerChecked = (setChecked = undefined) ->
  # See
  # https://www.polymer-project.org/docs/elements/paper-elements.html#paper-dropdown-menu
  if setChecked?
    jQuery(this).prop("checked",setChecked)
  else
    val = jQuery(this)[0].checked
    if val is "null" or not val?
      val = undefined
    val


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
            console.error "Postload callback error for #{src} - #{e.message}"
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

# Animations


animateLoad = (elId = "loader") ->
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
  #
  # Uses Polymer 1.0
  ###
  if isNumber(elId) then elId = "loader"
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  try
    if not $(selector).exists()
      $("body").append("<paper-spinner id=\"#{elId}\" active></paper-spinner")
    else
      $(selector).attr("active",true)
    false
  catch e
    console.log('Could not animate loader', e.message)


startLoad = animateLoad

stopLoad = (elId = "loader", fadeOut = 1000) ->
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  try
    if $(selector).exists()
      $(selector).addClass("good")
      delay fadeOut, ->
        $(selector).removeClass("good")
        $(selector).removeAttr("active")
  catch e
    console.log('Could not stop load animation', e.message)


stopLoadError = (message, elId = "loader", fadeOut = 5000) ->
  if elId.slice(0,1) is "#"
    selector = elId
    elId = elId.slice(1)
  else
    selector = "##{elId}"
  try
    if $(selector).exists()
      $(selector).addClass("bad")
      if message? then toastStatusMessage(message,"",fadeOut)
      delay fadeOut, ->
        $(selector).removeClass("bad")
        $(selector).removeAttr("active")
  catch e
    console.log('Could not stop load error animation', e.message)


toastStatusMessage = (message, className = "", duration = 3000, selector = "#status-message") ->
  ###
  # Pop up a status message
  ###
  unless window.metaTracker?.isToasting?
    unless window.metaTracker?
      window.metaTracker = new Object()
      window.metaTracker.isToasting = false
  if window.metaTracker.isToasting
    delay 250, ->
      # Wait and call again
      toastStatusMessage(message, className, duration, selector)
    return false
  window.metaTracker.isToasting = true
  if not isNumber(duration)
    duration = 3000
  if selector.slice(0,1) is not "#"
    selector = "##{selector}"
  if not $(selector).exists()
    html = "<paper-toast id=\"#{selector.slice(1)}\" duration=\"#{duration}\"></paper-toast>"
    $(html).appendTo("body")
  $(selector)
  .attr("text",message)
  .text(message)
  .addClass(className)
  $(selector).get(0).show()
  delay duration + 500, ->
    # A short time after it hides, clean it up
    $(selector).empty()
    $(selector).removeClass(className)
    $(selector).attr("text","")
    window.metaTracker.isToasting = false

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
    $(this).click (e) ->
      if stopPropagation
        e.preventDefault()
        e.stopPropagation()
      openTab(curHref)
    $(this).keypress ->
      openTab(curHref)

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
u  false

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

doCORSget = (url, args, callback = undefined, callbackFail = undefined) ->
  corsFail = ->
    if typeof callbackFail is "function"
      callbackFail()
    else
      throw new Error("There was an error performing the CORS request")
  # First try the jquery way
  settings =
    url: url
    data: args
    type: "get"
    crossDomain: true
  try
    $.ajax(settings)
    .done (result) ->
      if typeof callback is "function"
        callback()
        return false
      console.log(response)
    .fail (result,status) ->
      console.warn("Couldn't perform jQuery AJAX CORS. Attempting manually.")
  catch e
    console.warn("There was an error using jQuery to perform the CORS request. Attemping manually.")
  # Then try the long way
  url = "#{url}?#{args}"
  createCORSRequest = (method = "get", url) ->
    # From http://www.html5rocks.com/en/tutorials/cors/
    xhr = new XMLHttpRequest()
    if "withCredentials" of xhr
      # Check if the XMLHttpRequest object has a "withCredentials"
      # property.
      # "withCredentials" only exists on XMLHTTPRequest2 objects.
      xhr.open(method,url,true)
    else if typeof XDomainRequest isnt "undefined"
      # Otherwise, check if XDomainRequest.
      # XDomainRequest only exists in IE, and is IE's way of making CORS requests.
      xhr = new XDomainRequest()
      xhr.open(method,url)
    else
      xhr = null
    return xhr
  # Now execute it
  xhr = createCORSRequest("get",url)
  if !xhr
    throw new Error("CORS not supported")
  xhr.onload = ->
    response = xhr.responseText
    if typeof callback is "function"
      callback(response)
    console.log(response)
    return false
  xhr.onerror = ->
    console.warn("Couldn't do manual XMLHttp CORS request")
    # Place this in the last error
    corsFail()
  xhr.send()
  false


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
  loadJS "bower_components/imagelightbox/dist/imagelightbox.min.js", ->
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


safariDialogHelper = (selector = "#download-chooser", counter = 0, callback) ->
  ###
  # Help Safari display paper-dialogs
  ###
  unless typeof callback is "function"
    callback = ->
      bindDismissalRemoval()
  if counter < 10
    try
      # Safari is stupid and like to throw an error. Presumably
      # it's VERY slow about creating the element.
      d$(selector).get(0).open()
      delay 125, ->
        d$(selector).get(0).refit()
      if typeof callback is "function"
        callback()
      stopLoad()
    catch e
      # Ah, Safari threw an error. Let's delay and try up to
      # 10x.
      newCount = counter + 1
      delayTimer = 250
      delay delayTimer, ->
        console.warn "Trying again to display dialog after #{newCount * delayTimer}ms"
        safariDialogHelper(selector, newCount, callback)
  else
    stopLoadError("Unable to show dialog. Please try again.")


bindDismissalRemoval = ->
  $("[dialog-dismiss]")
  .unbind()
  .click ->
    $(this).parents("paper-dialog").remove()

p$ = (selector) ->
  # Try to get an object the Polymer way, then if it fails,
  # do jQuery
  try
    $$(selector)[0]
  catch
    $(selector).get(0)


bsAlert = (message, type = "warning", fallbackContainer = "body", selector = "#bs-alert") ->
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


animateHoverShadows = (selector = "paper-card.card-tile", defaultElevation = 2, raisedElevation = 4) ->
  handlerIn = ->
    $(this).attr "elevation", raisedElevation
  handlerOut = ->
    $(this).attr "elevation", defaultElevation
  $(selector).hover handlerIn, handlerOut    
  false


$ ->
  bindClicks()
  formatScientificNames()
  lightboxImages()
  animateHoverShadows()
  try
    $("body").tooltip
      selector: "[data-toggle='tooltip']"
  catch e
    console.warn("Tooltips were attempted to be set up, but do not exist")
  try
    checkAdmin()
    if adminParams?.loadAdminUi is true
      #console.info "Doing admin setup"
      loadJS "js/admin.js", ->
        console.info "Loaded admin file"
        loadAdminUi()
    else
      console.info "No admin setup requested"

###
# Do Georeferencing from data
#
# Plug into CartoDB via
# http://docs.cartodb.com/cartodb-platform/cartodb-js.html
###

uri.domain = uri.o.attr("host").split(".").reverse().pop()

# CartoDB account name
cartoAccount = "tigerhawkvok"

# Google Maps API key
# This can be public, since we've restricted the referrer
gMapsApiKey = "AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"


cartoMap = null
cartoVis = null

adData = new Object()
window.geo = new Object()
geo.GLOBE_WIDTH_GOOGLE = 256 # Constant

geo.init = (doCallback) ->
  ###
  # Initialization script for the mapping protocols.
  # Urls are taken from
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html
  ###
  try
    # Center on Berkeley
    window.locationData.lat = 37.871527
    window.locationData.lng = -122.262113
    # Now get the real location
    getLocation()
  cartoDBCSS = """
  <link rel="stylesheet" href="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css" />
  """
  $("head").append cartoDBCSS
  doCallback ?= ->
    createMap adData.cartoRef
    false
  window.gMapsCallback = ->
    # Now that that's loaded, we can load CartoDB ...
    loadJS "https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false
  # First, we have to load the Google Maps library
  loadJS "https://maps.googleapis.com/maps/api/js?key=#{gMapsApiKey}&callback=gMapsCallback"


getMapCenter = (bb) ->
  if bb?
    i = 0
    totalLat = 0.0
    for k, coords of bb
      ++i
      totalLat += coords[0]
      console.info coords, i, totalLat
    centerLat = toFloat(totalLat) / toFloat(i)
    i = 0
    totalLng = 0.0
    for k, coords of bb
      ++i
      totalLng += coords[1]
    centerLng = toFloat(totalLng) / toFloat(i)
    centerLat = toFloat(centerLat)
    centerLng = toFloat(centerLng)
    center =
      lat: centerLat
      lng: centerLng
  else
    center =
      lat: window.locationData.lat
      lng: window.locationData.lng
  center


getMapZoom = (bb) ->
  ###
  # Get the zoom factor for Google Maps
  ###
  if bb?
    eastMost = -180
    westMost = 180
    for k, coords of bb
      if coords[1] < westMost
        westMost = coords[1]
      if coords[1] > eastMost
        eastMost = coords[1]
    angle = eastMost - westMost
    if angle < 0
      angle += 360
    mapWidth = $(geo.mapSelector).width() ? 650
    adjAngle = 360 / angle
    mapScale = adjAngle / geo.GLOBE_WIDTH_GOOGLE
    # Calculate the zoom factor
    # http://stackoverflow.com/questions/6048975/google-maps-v3-how-to-calculate-the-zoom-level-for-a-given-bounds
    zoomCalc = toInt(Math.log(mapWidth * mapScale) / Math.LN2)
    oz = zoomCalc
    --zoomCalc # Zoom out one point, less tight fit
    zo = zoomCalc
    if zoomCalc < 1
      zoomCalc = 7
    # console.info "Calculated zoom #{zoomCalc}, from original #{oz} and loosened #{zo} from", bb, mapWidth, mapScale
  else
    zoomCalc = 7
  zoomCalc

geo.getMapZoom = getMapZoom


defaultMapMouseOverBehaviour = (e, latlng, pos, data, layerNumber) ->
  console.log(e, latlng, pos, data, layerNumber);

createMap = (dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28", targetId = "carto-map-container", options, callback) ->
  ###
  # Creates a map and does some simple bindings.
  #
  # The default data is the one from the documentation, and shouldn't
  # be used in production.
  #
  # See:
  # http://docs.cartodb.com/cartodb-platform/cartodb-js.html#api-methods
  ###
  unless dataVisIdentifier?
    console.info "Can't create map without a data visualization identifier"
  # Set up post-configuration helper
  geo.mapId = targetId
  geo.mapSelector = "##{targetId}"
  postConfig = ->
    options ?=
      cartodb_logo: false
      https: true
      mobile_layout: true
      gmaps_base_type: "hybrid"
      center_lat: window.locationData.lat
      center_lon: window.locationData.lng
      zoom: getMapZoom(geo.boundingBox)
    geo.mapParams = options
    unless $("##{targetId}").exists()
      fakeDiv = """
      <div id="#{targetId}" class="carto-map wide-map">
        <!-- Dynamically inserted from unavailable target -->
      </div>
      """
      $("main #main-body").append fakeDiv
    unless typeof callback is "function"
      callback = (layer, cartoMap) ->
        # For whatever reason, we still need to manually add the data
        cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
        .done (layer) ->
          # The actual interaction infowindow popup is decided on the data
          # page in Carto
          geo.mapLayer = layer
          try
            layer.setInteraction true
            layer.on "featureOver", defaultMapMouseOverBehaviour
          catch
            console.warn "Can't set carto map interaction"
    # Create a map layer
    googleMapOptions =
      center: new google.maps.LatLng(options.center_lat, options.center_lon)
      zoom: options.zoom
      mapTypeId: google.maps.MapTypeId.HYBRID
    geo.googleMap = new google.maps.Map document.getElementById(targetId), googleMapOptions
    geo.cartoMap = geo.googleMap
    gMapCallback = (layer) ->
      console.info "Fetched data into Google Map from CartoDB account #{cartoAccount}, from data set #{dataVisIdentifier}"
      geo.mapLayer = layer
      geo.cartoMap = geo.googleMap
      clearTimeout forceCallback
      if typeof callback is "function"
        callback(layer, geo.cartoMap)
      false
    try
      console.info "About to render map with options", geo.cartoUrl, options
      cartodb.createLayer(geo.googleMap, geo.cartoUrl, options).addTo(geo.googleMap)
      .on "done", (layer) ->
        gMapCallback(layer)
      .on "error", (errorString) ->
        toastStatusMessage("Couldn't load maps!")
        console.error "Couldn't get map - #{errorString}"
      forceCallback = delay 1000, ->
        if typeof callback is "function"
          console.warn "Callback wasn't called, forcing"
          callback(null, geo.cartoMap)
    catch
      # Try the callback anyway
      console.warn "The map threw an error! #{e.message}"
      console.wan e.stack
      clearTimeout forceCallback
      if typeof callback is "function"
        callback(null, geo.cartoMap)
    false
  ###
  # Now that we have the helper function, let's get the viz data
  ###
  unless typeof dataVisIdentifier is "object"
    # Is the dataVisIdentifier the whole url?
    if /^https?:\/\/.*$/m.test(dataVisIdentifier)
      # For a complete URL, we just reassign
      dataVisUrl = dataVisIdentifier
    else
      dataVisUrl = "https://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataVisIdentifier}/viz.json"
    geo.cartoUrl = dataVisUrl
    postConfig()
  else
    # Construct our own data for viz.jon to use with our data
    # Sample
    # http://tigerhawkvok.cartodb.com/api/v2/viz/38544c04-5e56-11e5-8515-0e4fddd5de28/viz.json
    dataVisJson = new Object()
    sampleUrl = "http://tigerhawkvok.cartodb.com/api/v2/viz/38544c04-5e56-11e5-8515-0e4fddd5de28/viz.json"
    $.get sampleUrl, "", "json"
    .done (result) ->
      dataVisJson = result
      for key, value of dataVisIdentifier
        # Merge them
        # Overwrite full dataset with user provided one
        dataVisJson[key] = value
    .fail (result, status) ->
      # Get something!
      dataVisJson = dataVisIdentifier
    .always ->
      dataVisUrl = dataVisJson
      geo.cartoUrl = dataVisUrl
      postConfig()

geo.requestCartoUpload = (totalData, dataTable, operation, callback) ->
  ###
  # Acts as a shim between the server-side uploader and the client.
  # Send a request to the server to authenticate the current user
  # status, then, if successful, do an authenticated upload to the
  # client.
  #
  # Among other things, this approach secures the cartoDB API on the server.
  ###
  try
    data = totalData.data
  # How's the data?
  if typeof data isnt "object"
    console.info "This function requires the base data to be a JSON object."
    toastStatusMessage "Your data is malformed. Please double check your data and try again."
    return false

  # Is this a legitimate operation?
  allowedOperations = [
    "edit"
    "insert"
    "delete"
    "create"
    ]
  unless operation in allowedOperations
    console.error "#{operation} is not an allowed operation on a data set!"
    console.info "Allowed operations are ", allowedOperations
    toastStatusMessage "Sorry, '#{operation}' isn't an allowed operation."
    return false

  if isNull dataTable
    console.error "Must use a defined table name!"
    toastStatusMessage "You must name your data table"
    return false

  # Is the user allowed and logged in?
  link = $.cookie "#{uri.domain}_link"
  hash = $.cookie "#{uri.domain}_auth"
  secret = $.cookie "#{uri.domain}_secret"
  unless link? and hash? and secret?
    console.error "You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret
    toastStatusMessage "Sorry, you're not logged in. Please log in and try again."
    return false

  # We want the data tables to be unique, so we'll suffix them with
  # the user link.
  dataTable = "#{dataTable}_#{link}"
  # dataTable = dataTable.slice(0,63)
  # Start doing real things
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  ## NOTE THIS SHOULD ACTUALLY VERIFY THAT THE DATA COULD BE WRITTEN
  # TO THIS PROJECT BY THIS PERSON!!!
  #
  # Some of this could, in theory, be done via
  # http://docs.cartodb.com/cartodb-platform/cartodb-js/sql/
  unless adminParams?.apiTarget?
    console.warn "Administration file not loaded. Upload cannot continue"
    stopLoadError "Administration file not loaded. Upload cannot continue"
    return false
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    if result.status
      ###
      # Now that we've done an authenticated request, and handled that
      # sort of error, we can actually use CartoDB's SQL API and
      # upload the data.
      #
      # http://docs.cartodb.com/cartodb-platform/sql-api.html
      #
      # The data itself will be preprocessed as a GeoJSON:
      # http://geojson.org/geojson-spec.html
      # http://www.postgis.org/documentation/manual-svn/ST_SetSRID.html
      # http://www.postgis.org/documentation/manual-svn/ST_Point.html
      #
      # Assume Spatial Reference System 4326, http://spatialreference.org/ref/epsg/4326/
      # http://www.postgis.org/documentation/manual-svn/using_postgis_dbmanagement.html#spatial_ref_sys
      ###
      sampleLatLngArray = new Array()
      # Before we begin parsing, throw up an overlay for the duration
      # Loop over the data and clean it up
      # Create a GeoJSON from the data
      lats = new Array()
      lngs = new Array()
      for n, row of data
        ll = new Array()
        for column, value of row
          switch column
            when "decimalLongitude"
              ll[1] = value
              lngs.push value
            when "decimalLatitude"
              ll[0] = value
              lats.push value
        sampleLatLngArray.push ll
      bb_north = lats.max() ? 0
      bb_south = lats.min() ? 0
      bb_east = lngs.max() ? 0
      bb_west = lngs.min() ? 0
      defaultPolygon = [
          [bb_north, bb_west]
          [bb_north, bb_east]
          [bb_south, bb_east]
          [bb_south, bb_west]
        ]
      # See if the user provided a good transect polygon
      try
        # See if the user provided a valid JSON string of coordinates
        userTransectRing = JSON.parse totalData.transectRing
        for coordinatePair in userTransectRing
          # Is it just two long?
          if coordinatePair.length isnt 2
            throw
              message: "Bad coordinate length for '#{coordinatePair}'"
          for coordinate in coordinatePair
            unless isNumber coordinate
              throw
                message: "Bad coordinate number '#{coordinate}'"
      catch e
        console.warn "Error parsing the user transect ring - #{e.message}"
        userTransectRing = undefined
      # Massive object row
      transectPolygon = userTransectRing ? defaultPolygon
      geoJson =
        type: "GeometryCollection"
        geometries: [
              type: "MultiPoint"
              coordinates: sampleLatLngArray # An array of all sample points
            ,
              type: "Polygon"
              coordinates: transectPolygon
          ]
      dataGeometry = "ST_AsBinary(#{JSON.stringify(geoJson)}, 4326)"
      # Rows per-sample ...
      # FIMS based
      # Uses DarwinCore terms
      # http://www.biscicol.org/biocode-fims/templates.jsp#
      # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-fims.csv
      columnDatatype =
        id: "int"
        collectionID: "varchar"
        catalogNumber: "varchar"
        fieldNumber: "varchar"
        diseaseTested: "varchar"
        diseaseStrain: "varchar"
        sampleMethod: "varchar"
        sampleDisposition: "varchar"
        diseaseDetected: "varchar"
        fatal: "boolean"
        cladeSampled: "varchar"
        genus: "varchar"
        specificEpithet: "varchar"
        infraspecificEpithet: "varchar"
        lifeStage: "varchar"
        dateIdentified: "date" # Should be ISO8601; coerce it!
        decimalLatitude: "decimal"
        decimalLongitude: "decimal"
        alt: "decimal"
        coordinateUncertaintyInMeters: "decimal"
        Collector: "varchar"
        fimsExtra: "json" # Text? http://www.postgresql.org/docs/9.3/static/datatype-json.html
        the_geom: "varchar"
      # Construct the SQL query
      switch operation
        when "edit"
          sqlQuery = "UPDATE #{dataTable} "
          foo()
          return false
          # Slice and dice!
        when "insert", "create"
          sqlQuery = ""
          if operation is "create"
            sqlQuery = "CREATE TABLE #{dataTable} "
          # Create a set of nice data blocks, then push that into the
          # query
          valuesList = ""
          # First row, the big collection
          dataObject =
            the_geom: dataGeometry
          # All the others ...
          valuesList = new Array()
          columnNamesList = new Array()
          columnNamesList.push "id int"
          for i, row of data
            i = toInt(i)
            console.log "Iter ##{i}", i is 0, `i == 0`
            # Each row ...
            valuesArr = new Array()
            lat = 0
            lng = 0
            alt = 0
            err = 0
            geoJsonGeom =
              type: "Point"
              coordinates: new Array()
            iIndex = i + 1
            valuesArr.push iIndex
            for column, value of row
              # Loop data ....
              if i is 0
                columnNamesList.push "#{column} #{columnDatatype[column]}"
              try
                # Strings only!
                value = value.replace("'", "&#95;")
              switch column
                # Assign geoJSON values
                when "decimalLongitude"
                  geoJsonGeom.coordinates[1] = value
                when "decimalLatitude"
                  geoJsonGeom.coordinates[0] = value
              if typeof value is "string"
                valuesArr.push "'#{value}'"
              else if isNull value
                valuesArr.push "null"
              else
                valuesArr.push value
            # Add a GeoJSON column and GeoJSON values
            if i is 0
              console.log "We're appending to col names list"
              columnNamesList.push "the_geom geometry"
              if operation is "create"
                sqlQuery = "#{sqlQuery} (#{columnNamesList.join(",")}); "
            geoJsonVal = "ST_SetSRID(ST_Point(#{geoJsonGeom.coordinates[0]},#{geoJsonGeom.coordinates[1]}),4326)"
            # geoJsonVal = "ST_AsBinary(#{JSON.stringify(geoJsonGeom)}, 4326)"
            valuesArr.push geoJsonVal
            valuesList.push "(#{valuesArr.join(",")})"
          # Create the final query
          # Remove the first comma of valuesList
          sqlQuery = "#{sqlQuery}INSERT INTO #{dataTable} VALUES #{valuesList.join(", ")};"
        when "delete"
          sqlQuery = "DELETE FROM #{dataTable} WHERE "
          # Deletion criteria ...
          foo()
          return false
      # Ping the server
      apiPostSqlQuery = encodeURIComponent encode64 sqlQuery
      args = "action=upload&sql_query=#{apiPostSqlQuery}"
      # console.info "Would query with args", args
      console.info "Querying:"
      console.info sqlQuery
      # $("#main-body").append "<pre>Would send Carto:\n\n #{sqlQuery}</pre>"
      console.info "GeoJSON:", geoJson
      console.info "GeoJSON String:", dataGeometry
      console.warn "Want to post:", "#{uri.urlString}api.php?#{args}"
      $.post "api.php", args, "json"
      .done (result) ->
        console.log "Got back", result
        if result.status isnt true
          console.error "Got an error from the server!"
          console.warn result
          toastStatusMessage "There was a problem uploading your data. Please try again."
          return false
        cartoResults = result.post_response
        cartoHasError = false
        for j, response of cartoResults
          unless isNull response?.error
            cartoHasError = response.error[0]
        unless cartoHasError is false
          stopLoadError "CartoDB returned an error: #{cartoHasError}"
          return false
        console.info "Carto was successful! Got results", cartoResults
        try
          # http://marianoguerra.github.io/json.human.js/
          prettyHtml = JsonHuman.format cartoResults
          # $("#main-body").append "<div class='alert alert-success'><strong>Success! Carto said</strong>#{$(prettyHtml).html()}</div>"
        bsAlert("Upload to CartoDB of table <code>#{dataTable}</code> was successful", "success")
        toastStatusMessage("Data parse and upload successful")
        geo.dataTable = dataTable
        # resultRows = cartoResults.rows
        # Update the overlay for sending to Carto
        # Post this data over to the back end
        # Update the UI
        # Get the blob URL ..
        # https://gis.stackexchange.com/questions/171283/get-a-viz-json-uri-from-a-table-name
        #
        dataBlobUrl = "" # The returned viz.json url
        unless isNull dataBlobUrl
          dataVisUrl = "https://#{cartoAccount}.cartodb.com/api/v2/viz/#{dataBlobUrl}/viz.json"
        else if typeof dataBlobUrl is "object"
          # Parse the object
          dataVisUrl = dataBlobUrl
        else
          dataVisUrl = ""
        parentCallback = ->
          if typeof callback is "function"
            callback(geo.dataTable)
          else
            console.info "requestCartoUpload recieved no callback"
        unless isNull cartoMap
          cartodb.createLayer(cartoMap, dataVisUrl).addTo cartoMap
          .done (layer) ->
            # The actual interaction infowindow popup is decided on the data
            # page in Carto
            layer.setInteraction true
            layer.on "featureOver", defaultMapMouseOverBehaviour
            parentCallback()
        else
          geo.init ->
            # Callback
            center = getMapCenter(geo.boundingBox)
            options =
              cartodb_logo: false
              https: true
              mobile_layout: true
              gmaps_base_type: "hybrid"
              center_lat: center.lat
              center_lon: center.lng
              zoom: getMapZoom(geo.boundingBox)
            createMap dataVisUrl, undefined, options, ->
              parentCallback()
            false
    else
      console.error "Unable to authenticate session. Please log in."
      toastStatusMessage "Sorry, your session has expired. Please log in and try again."
  .error (result, status) ->
    console.error "Couldn't communicate with server!", result, status
    console.warn "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
    toastStatusMessage "There was a problem communicating with the server. Please try again in a bit."
  false


sortPoints = (pointArray, asObj = true) ->
  ###
  # Take an array of points and return a Google Maps compatible array
  # of coordinate objects
  ###
  window.upper = upperLeft pointArray
  pointArray.sort pointSort
  sortedPoints = new Array()
  for coordPoint in pointArray
    if asObj
      sortedPoints.push coordPoint.getObj()
    else
      pointFunc = new Object()
      pointFunc.lat = ->
        return coordPoint.lat
      pointFunc.lng = ->
        return coordPoint.lng
      sortedPoints.push pointFunc
  delete window.upper
  sortedPoints


fPoint = (lat, lng) ->
  @latval = lat
  @lngval = lng
  @lat = ->
    @latval
  @lng = ->
    @lngval
  @toString = ->
    "(#{@x}, #{@y})"
  this.toString()


Point = (lat, lng) ->
  # From
  # http://stackoverflow.com/a/2863378
  @x = (lng + 180) * 360
  @y = (lat + 90) * 180
  @lat = lat
  @lng = lng
  @distance = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    Math.sqrt dx**2 + dy**2
  @slope = (that) ->
    dx = that.x - @x
    dy = that.y - @y
    dy / dx
  @toString = ->
    "(#{@x}, #{@y})"
  @getObj = ->
    o =
      lat: @lat
      lng: @lng
    o
  @getLatLng = ->
    if google?.maps?
      return new google.maps.LatLng(@lat,@lng)
    else
      return @getObj()
  @getLat = ->
    @lat
  @getLng = ->
    @lng
  this.toString()

geo.Point = Point
# Find a minimum convex polygon
`
// A custom sort function that sorts p1 and p2 based on their slope
// that is formed from the upper most point from the array of points.
function pointSort(p1, p2) {
    // Exclude the 'upper' point from the sort (which should come first).
    if(p1 == upper) return -1;
    if(p2 == upper) return 1;

    // Find the slopes of 'p1' and 'p2' when a line is
    // drawn from those points through the 'upper' point.
    var m1 = upper.slope(p1);
    var m2 = upper.slope(p2);

    // 'p1' and 'p2' are on the same line towards 'upper'.
    if(m1 == m2) {
        // The point closest to 'upper' will come first.
        return p1.distance(upper) < p2.distance(upper) ? -1 : 1;
    }

    // If 'p1' is to the right of 'upper' and 'p2' is the the left.
    if(m1 <= 0 && m2 > 0) return -1;

    // If 'p1' is to the left of 'upper' and 'p2' is the the right.
    if(m1 > 0 && m2 <= 0) return 1;

    // It seems that both slopes are either positive, or negative.
    return m1 > m2 ? -1 : 1;
}

// Find the upper most point. In case of a tie, get the left most point.
function upperLeft(points) {
    var top = points[0];
    for(var i = 1; i < points.length; i++) {
        var temp = points[i];
        if(temp.y > top.y || (temp.y == top.y && temp.x < top.x)) {
            top = temp;
        }
    }
    return top;
}`

geo.distance = (lat1, lng1, lat2, lng2) ->
  ###
  # Distance across Earth curvature
  ###
  # Radius of Earth, const (Volumentric Mean)
  # http://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
  R = 6371
  dLat = (lat2 - lat2).toRad()
  dLon = (lng2 - lng1).toRad()
  semiLat = dLat / 2
  semiLng = dLon / 2
  # Get the actual curves
  arc = Math.sin(semiLat)**2 + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(smiLng)**2
  curve = 2 * Math.atan2 Math.sqrt(arc), Math.sqrt(1-arc)
  # Return the real distance
  R * curve

###
# Minimum Convex Hull
# view-source:http://www.geocodezip.com/v3_map-markers_ConvexHull.asp
###
getConvexHull = (googleMapsMarkersArray) ->
  points = new Array()
  for marker in googleMapsMarkersArray
    points.push marker.getPosition()
  points.sort sortPointY
  points.sort sortPointX
  getConvexHullConfig(points)

sortPointX = (a, b) ->
  a.lng() - b.lng()

sortPointY = (a, b) ->
  a.lat() - b.lat()


getConvexHullPoints = (points) ->
  hullPoints = new Array()
  chainHull_2D points, points.length, hullPoints
  realHull = new Array()
  for point in hullPoints
    temp =
      lat: point.lat()
      lng: point.lng()
    realHull.push temp
  console.info "Got hull from #{points.length} points:", realHull
  realHull

getConvexHullConfig = (points, map = geo.googleMap) ->
  hullPoints = getConvexHullPoints points
  polygonConfig =
    map: map
    paths: hullPoints
    fillColor: "#ff7800"
    fillOpacity: 0.35
    strokeWidth: 2
    strokeColor: "#0000FF"
    strokeOpacity: 0.5
  # cHullPoly = new google.maps.Polygon polygonConfig
  # false

`
    var gmarkers = [];
    var points = [];
    var hullPoints = [];
    var map = null;
      var polyline;
     function calculateConvexHull() {
      if (polyline) polyline.setMap(null);
      document.getElementById("hull_points").innerHTML = "";
      points = [];
      for (var i=0; i < gmarkers.length; i++) {
        points.push(gmarkers[i].getPosition());
      }
      points.sort(sortPointY);
      points.sort(sortPointX);
      DrawHull();
}

     function sortPointX(a,b) { return a.lng() - b.lng(); }
     function sortPointY(a,b) { return a.lat() - b.lat(); }

     function DrawHull() {
     hullPoints = [];
     chainHull_2D( points, points.length, hullPoints );
     polyline = new google.maps.Polygon({
      map: map,
      paths:hullPoints,
      fillColor:"#FF0000",
      strokeWidth:2,
      fillOpacity:0.5,
      strokeColor:"#0000FF",
      strokeOpacity:0.5
     });
     displayHullPts();
}

function displayHullPts() {
     document.getElementById("hull_points").innerHTML = "";
     for (var i=0; i < hullPoints.length; i++) {
       document.getElementById("hull_points").innerHTML += hullPoints[i].toUrlValue()+"<br>";
     }
   }
`


`
// Copyright 2001, softSurfer (www.softsurfer.com)
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.
// http://softsurfer.com/Archive/algorithm_0203/algorithm_0203.htm
// Assume that a class is already given for the object:
//    Point with coordinates {float x, y;}
//===================================================================

// isLeft(): tests if a point is Left|On|Right of an infinite line.
//    Input:  three points P0, P1, and P2
//    Return: >0 for P2 left of the line through P0 and P1
//            =0 for P2 on the line
//            <0 for P2 right of the line

function sortPointX(a, b) {
    return a.lng() - b.lng();
}
function sortPointY(a, b) {
    return a.lat() - b.lat();
}

function isLeft(P0, P1, P2) {
    return (P1.lng() - P0.lng()) * (P2.lat() - P0.lat()) - (P2.lng() - P0.lng()) * (P1.lat() - P0.lat());
}
//===================================================================

// chainHull_2D(): A.M. Andrew's monotone chain 2D convex hull algorithm
// http://softsurfer.com/Archive/algorithm_0109/algorithm_0109.htm
//
//     Input:  P[] = an array of 2D points
//                   presorted by increasing x- and y-coordinates
//             n = the number of points in P[]
//     Output: H[] = an array of the convex hull vertices (max is n)
//     Return: the number of points in H[]


function chainHull_2D(P, n, H) {
    // the output array H[] will be used as the stack
    var bot = 0,
    top = (-1); // indices for bottom and top of the stack
    var i; // array scan index
    // Get the indices of points with min x-coord and min|max y-coord
    var minmin = 0,
        minmax;

    var xmin = P[0].lng();
    for (i = 1; i < n; i++) {
        if (P[i].lng() != xmin) {
            break;
        }
    }

    minmax = i - 1;
    if (minmax == n - 1) { // degenerate case: all x-coords == xmin
        H[++top] = P[minmin];
        if (P[minmax].lat() != P[minmin].lat()) // a nontrivial segment
            H[++top] = P[minmax];
        H[++top] = P[minmin]; // add polygon endpoint
        return top + 1;
    }

    // Get the indices of points with max x-coord and min|max y-coord
    var maxmin, maxmax = n - 1;
    var xmax = P[n - 1].lng();
    for (i = n - 2; i >= 0; i--) {
        if (P[i].lng() != xmax) {
            break;
        }
    }
    maxmin = i + 1;

    // Compute the lower hull on the stack H
    H[++top] = P[minmin]; // push minmin point onto stack
    i = minmax;
    while (++i <= maxmin) {
        // the lower line joins P[minmin] with P[maxmin]
        if (isLeft(P[minmin], P[maxmin], P[i]) >= 0 && i < maxmin) {
            continue; // ignore P[i] above or on the lower line
        }

        while (top > 0) { // there are at least 2 points on the stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break; // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    // Next, compute the upper hull on the stack H above the bottom hull
    if (maxmax != maxmin) { // if distinct xmax points
        H[++top] = P[maxmax]; // push maxmax point onto stack
    }

    bot = top; // the bottom point of the upper hull stack
    i = maxmin;
    while (--i >= minmax) {
        // the upper line joins P[maxmax] with P[minmax]
        if (isLeft(P[maxmax], P[minmax], P[i]) >= 0 && i > minmax) {
            continue; // ignore P[i] below or on the upper line
        }

        while (top > bot) { // at least 2 points on the upper stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break;  // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

// breaks algorithm
//        if (P[i].lng() == H[0].lng() && P[i].lat() == H[0].lat()) {
//            return top + 1; // special case (mgomes)
//        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    if (minmax != minmin) {
        H[++top] = P[minmin]; // push joining endpoint onto stack
    }

    return top + 1;
}
`


$ ->
  # init()
