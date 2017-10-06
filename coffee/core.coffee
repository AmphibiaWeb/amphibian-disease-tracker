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

window._adp ?= new Object()

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

isNull = (str, dirty = false) ->
  if typeof str is "object"
    try
      l = str.length
      if l?
        try
          return l is 0
      return Object.size is 0
  try
    if isEmpty(str) or isBlank(str) or not str?
      #unless (str is false or str is 0) and not dirty
      unless str is false or str is 0
        return true
      if dirty
        if str is false or str is 0
          return true
  catch e
    return false
  try
    str = str.toString().toLowerCase()
  if str is "undefined" or str is "null"
    return true
  if dirty and (str is "false" or str is "0")
    return true
  false


isJson = (str) ->
  if typeof str is 'object' and not isArray str then return true
  try
    JSON.parse(str)
    return true
  catch
    return false
  false

isArray = (arr) ->
  try
    shadow = arr.slice 0
    shadow.push "foo"
    return true
  catch
    return false


isNumber = (n) -> not isNaN(parseFloat(n)) and isFinite(n)

toFloat = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseFloat(str)

toInt = (str) ->
  if typeof str is "string"
    # Snip CSS measurements
    str = str
      .replace("px","")
      .replace("em","")
      .replace("rem","")
      .replace("vw","")
      .replace("vh","")
  if not isNumber(str) or isNull(str) then return 0
  f = parseFloat(str) # For stuff like 1.2e12
  parseInt(f)

String::toAscii = ->
  ###
  # Remove MS Word bullshit
  ###
  @replace(/[\u2018\u2019\u201A\u201B\u2032\u2035]/g, "'")
    .replace(/[\u201C\u201D\u201E\u201F\u2033\u2036]/g, '"')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/[\u2026]/g, '...')
    .replace(/\u02C6/g, "^")
    .replace(/\u2039/g, "")
    .replace(/[\u02DC|\u00A0]/g, " ")


String::toBool = ->
  test = @toString().toLowerCase()
  test is 'true' or test is "1"

Boolean::toBool = -> @toString() is "true"

Number::toBool = -> @toString() is "1"

String::addSlashes = ->
  `this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0')`

Array::max = -> Math.max.apply null, this

Array::min = -> Math.min.apply null, this

Array::containsObject = (obj) ->
  # Value-ish rather than indexOf
  # Uses underscore, but since I don't usually use it ...
  try
    res = _.find this, (val) ->
      _.isEqual obj, val
    typeof res is "object"
  catch e
    console.error "Please load underscore.js before using this."
    console.info  "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"

Object.toArray = (obj) ->
  try
    shadowObj = obj.slice 0
    shadowObj.push "foo" # Throws error on obj
    return obj
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

Object.doOnSortedKeys = (obj, fn) ->
  sortedKeys = Object.keys(obj).sort()
  for key in sortedKeys
    data = obj[key]
    fn data

delay = (ms,f) -> setTimeout(f,ms)
interval = (ms,f) -> setInterval(f,ms)

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


String::stripHtml = (stripChildren = false) ->
  str = this
  if stripChildren
    # Pull out the children
    str = str.replace /<(\w+)(?:[^"'>]|"[^"]*"|'[^']*')*>(?:((?:.)*?))<\/?\1(?:[^"'>]|"[^"]*"|'[^']*')*>/mg, ""
  # Script tags
  str = str.replace /<script[^>]*>([\S\s]*?)<\/script>/gmi, ''
  # HTML tags
  str = str.replace /<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, ''
  str

String::unescape = (strict = false) ->
  ###
  # Take escaped text, and return the unescaped version
  #
  # @param string str | String to be used
  # @param bool strict | Stict mode will remove all HTML
  #
  # Test it here:
  # https://jsfiddle.net/tigerhawkvok/t9pn1dn5/
  #
  # Code: https://gist.github.com/tigerhawkvok/285b8631ed6ebef4446d
  ###
  # Create a dummy element
  element = document.createElement("div")
  decodeHTMLEntities = (str) ->
    if str? and typeof str is "string"
      unless strict is true
        # escape HTML tags
        str = escape(str).replace(/%26/g,'&').replace(/%23/g,'#').replace(/%3B/g,';')
      else
        str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '')
        str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '')
      element.innerHTML = str
      if element.innerText
        # Do we support innerText?
        str = element.innerText
        element.innerText = ""
      else
        # Firefox
        str = element.textContent
        element.textContent = ""
    unescape(str)
  # Remove encoded or double-encoded tags
  tmp = deEscape(this)
  # Run it
  decodeHTMLEntities(tmp)


deEscape = (string) ->
  string = string.replace(/\&amp;#/mg, '&#') # The rest
  string = string.replace(/\&quot;/mg, '"')
  string = string.replace(/\&quote;/mg, '"')
  string = string.replace(/\&#95;/mg, '_')
  string = string.replace(/\&#39;/mg, "'")
  string = string.replace(/\&#34;/mg, '"')
  string = string.replace(/\&#62;/mg, '>')
  string = string.replace(/\&#60;/mg, '<')
  string


String::escapeQuotes = ->
  str = this.replace /"/mg, "&#34;"
  str = str.replace /'/mg, "&#39;"
  str


getElementHtml = (el) ->
  el.outerHTML


jQuery.fn.outerHTML = ->
  e = $(this).get(0)
  e.outerHTML


jQuery.fn.outerHtml = ->
  $(this).outerHTML()


buildQuery = (obj) ->
  queryList = new Array()
  for k, v of obj
    key = k.replace /[^A-Za-z\-_\[\]]/img, ""
    value = encodeURIComponent(v).replace /\%20/g, "+"
    queryList.push """#{key}=#{value}"""
  queryList.join "&"

buildArgs = buildQuery

`
jQuery.fn.selectText = function(){
    var doc = document
        , element = this[0]
        , range, selection
    ;
    if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) {
        selection = window.getSelection();
        range = document.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
};
`


copyText = (text, zcObj, zcElement) ->
  ###
  #
  ###
  unless window.copyDebouncer?
    window.copyDebouncer = new Object()
  if Date.now() - window.copyDebouncer.last < 300
    console.warn "Skipping copy on debounce"
    return false
  window.copyDebouncer.last = Date.now()
  identifier = md5 $(zcElement).html()
  try
    clipboardData =
      dataType: "text/plain"
      data: text
    clip = new ClipboardEvent "copy", clipboardData
    document.dispatchEvent clip
    return false
  if _adp.copyObject?[identifier]?
    clipboardData =
      "text/plain": text
    console.info "Setting up clipboard events for \"#{text}\""
    _adp.copyObject[identifier].setData clipboardData
    # $(zcElement)
    # .unbind("click")
    # .click ->
    #   _adp.copyObject[identifier].setData clipboardData
    _adp.copyObject[identifier].on "copy", (e) ->
      try
        e.clipboardData =
          setData: _adp.copyObject[identifier].setData clipboardData
    _adp.copyObject[identifier].on "aftercopy", (e) ->
      if e.data["text/plain"] is text
        toastStatusMessage "Copied to clipboard"
        console.info "Succesfully copied", e.data["text/plain"]
        window.hasRetriedCopy = false
      else
        if e.data["text/plain"]
          # We copied, but copied the wrong thing
          console.warn "Incorrect copy: instead of '#{text}', '#{e.data["text/plain"]}'"
          # Try again
          unless window.hasRetriedCopy
            window.hasRetriedCopy = true
            delete window.copyDebouncer.last
            delay 100, ->
              console.warn "Re-trying copy"
              $(zcElement).click()
              console.info "Sent click"
          else
            console.error "Re-copy failed!"
            toastStatusMessage "Error copying to clipboard. Please try again"
        else
          console.error "Bad data passed", e.data["text/plain"]
          toastStatusMessage "Error copying to clipboard. Please try again"
          window.hasRetriedCopy = false
      window.resetClipboard = false
      _adp.copyObject[identifier].setData clipboardData
    _adp.copyObject[identifier].on "error", (e) ->
      console.error "Error copying to clipboard"
      console.warn "Got", e
      if e.name is "flash-overdue"
        # ZeroClipboard.destroy()
        if window.resetClipboard is true
          console.error "Resetting ZeroClipboard didn't work!"
          return false
        ZeroClipboard.on "ready", ->
          # Re-call
          window.resetClipboard = true
          copyLink window.tempZC, text
        window.tempZC = new ZeroClipboard zcElement
      # Case for no flash at all
      if e.name is "flash-disabled"
        # stuff
        console.info "No flash on this system"
        ZeroClipboard.destroy()
        $(".click-copy").remove()
        p$("paper-dialog").refit()
        toastStatusMessage "Clipboard copying isn't available on your system"
  else
    console.error "Can't copy: zcObject doesn't exist for identifier #{identifier}"
  false


bindCopyEvents = (selector = ".click-copy") ->
  loadJS "bower_components/zeroclipboard/dist/ZeroClipboard.min.js", ->
    zcConfig =
      swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
    ZeroClipboard.config zcConfig
    for el in $(selector)
      identifier = md5 $(el).html()
      unless _adp.copyObject?
        _adp.copyObject = new Object()
      unless _adp.copyObject[identifier]?
        console.info "Setting up copy events for identifier", identifier
        _adp.copyObject[identifier] = new ZeroClipboard el
        text = $(el).attr "data-clipboard-text"
        if isNull text
          copySelector = $(el).attr "data-copy-selector"
          text = $(copySelector).val()
          if isNull text
            try
              text = p$(copySelector).value
        console.info "Registering copy text", text
        try
          delete window.copyDebouncer.last
        copyText text, _adp.copyObject[identifier], el
      else
        console.info "Copy event already set up for identifier", identifier
      # $(this).click ->
      #   text = $(this).attr "data-clipboard-text"
      #   if isNull text
      #     copySelector = $(this).attr "data-copy-selector"
      #     text = $(copySelector).val()
      #     if isNull text
      #       try
      #         text = p$(copySelector).value
      #     console.info "Copying text", text
      #   copyText text, zcObj, this
      #   false
  false


buildQuery = (obj) ->
  queryList = new Array()
  for k, v of obj
    key = k.replace /[^A-Za-z\-_\[\]]/img, ""
    value = encodeURIComponent(v).replace /\%20/g, "+"
    queryList.push """#{key}=#{value}"""
  queryList.join "&"



jsonTo64 = (obj, encode = true) ->
  ###
  #
  # @param obj
  # @param boolean encode -> URI encode base64 string
  ###
  try
    shadowObj = obj.slice 0
    shadowObj.push "foo" # Throws error on obj
    obj = toObject obj
  objString = JSON.stringify obj
  if encode is true
    encoded = post64 objString
  else
    encoded = encode64 encoded
  encoded


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

post64 = (string) ->
  s64 = encode64 string
  p64 = encodeURIComponent s64
  p64

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


Function::getName = ->
  ###
  # Returns a unique identifier for a function
  ###
  name = this.name
  unless name?
    name = this.toString().substr( 0, this.toString().indexOf( "(" ) ).replace( "function ", "" );
  if isNull name
    name = md5 this.toString()
  name

Function::debounce = (threshold = 300, execAsap = false, timeout = window.debounce_timer, args...) ->
  ###
  # Borrowed from http://coffeescriptcookbook.com/chapters/functions/debounce
  # Only run the prototyped function once per interval.
  #
  # @param threshold -> Timeout in ms
  # @param execAsap -> Do it NAOW
  # @param timeout -> backup timeout object
  ###
  unless window.core?.debouncers?
    unless window.core?
      window.core = new Object()
    core.debouncers = new Object()
  try
    key = this.getName()
  try
    if core.debouncers[key]?
      timeout = core.debouncers[key]
  func = this
  delayed = ->
    if key?
      clearTimeout timeout
      delete core.debouncers[key]
    func.apply(func, args) unless execAsap
    # console.info("Debounce applied")
  if timeout?
    try
      clearTimeout timeout
    catch e
      # just do nothing
  if execAsap
    func.apply(obj, args)
    console.log("Executed #{key} immediately")
    return false
  if key?
    # console.log "Debouncing '#{key}' for #{threshold} ms"
    core.debouncers[key] = delay threshold, ->
      delayed()
  else
    console.log "Delaying '#{key}' for #{threshold} ms"
    window.debounce_timer = delay threshold, ->
      delayed()



randomInt = (lower = 0, upper = 1) ->
  start = Math.random()
  if not lower?
    [lower, upper] = [0, lower]
  if lower > upper
    [lower, upper] = [upper, lower]
  return Math.floor(start * (upper - lower + 1) + lower)


randomString = (length = 8) ->
  i = 0
  charBottomSearchSpace = 65 # "A"
  charUpperSearchSpace = 126
  stringArray = new Array()
  while i < length
    ++i
    # Search space
    char = randomInt charBottomSearchSpace, charUpperSearchSpace
    stringArray.push String.fromCharCode char
  stringArray.join ""


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


stopLoadError = (message, elId = "loader", fadeOut = 10000) ->
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
      window.metaTracker.toastTracker = new Array()
      window.metaTracker.isToasting = false
  if window.metaTracker.isToasting
    timeout = delay 250, ->
      # Wait and call again
      toastStatusMessage(message, className, duration, selector)
    window.metaTracker.toastTracker.push timeout
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
  .html(message)
  .addClass(className)
  try
    p$(selector).show()
  delay duration + 500, ->
    # A short time after it hides, clean it up
    try
      isOpen = p$(selector).opened
    catch
      isOpen = false
    unless isOpen
      $(selector).empty()
      $(selector).removeClass(className)
      $(selector).attr("text","")
    window.metaTracker.isToasting = false


cleanupToasts = ->
  for timeout in window.metaTracker.toastTracker
    try
      clearTimeout timeout

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
  useSelectors = [
    ".newwindow"
    ".newWindow"
    ".new-window"
    "[newwindow]"
    "[new-window]"
    ]
  for selector in useSelectors
    $(selector).each ->
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
  false

deepJQuery = (selector) ->
  ###
  # Do a shadow-piercing selector
  #
  # Cross-browser, works with Chrome, Firefox, Opera, Safari, and IE
  # Falls back to standard jQuery selector when everything fails.
  ###
  if not jQuery?
    console.warn "Danger -- jQuery isn't defined. Selectors may fail."
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
      # These don't match at all -- try p$ wrapped in jQuery (for the
      # expected return type)
      return $(p$(selector))

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
      url = $(this).attr("data-href") ? $(this).attr "href"
      if not isNull(url)
        # console.log("Binding a url to ##{$(this).attr("id")}")
        try
          tagType = $(this).prop("tagName").toLowerCase()
        catch
          tagType = null
        try
          if url is uri.o.attr("path") and tagType is "paper-tab"
            $(this).parent().prop("selected",$(this).index())
        catch e
          console.warn("tagname lower case error")
        newTab = $(this).attr("newTab")?.toBool() or $(this).attr("newtab")?.toBool() or $(this).attr("data-newtab")?.toBool()
        if tagType is "a" and not newTab
          # next iteration
          return true
        if tagType is "a"
          $(this).keypress ->
            openTab url
        $(this)
        .unbind()
        .click (e) ->
          # Prevent links from auto-triggering
          e.preventDefault()
          e.stopPropagation()
          try
            if newTab
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
              try
                args = null
                unless isNull $(this).attr "data-args"
                  args = $(this).attr("data-args").split(",")
              try
                if args?
                  window[callable](args...)
                else
                  window[callable]()
              catch
                window[callable]()
            catch e
              console.error("'#{callable}()' is a bad function - #{e.message}")
    catch e
      console.error("There was a problem binding to ##{$(this).attr("id")} - #{e.message}")
  try
    bindCollapsors()
  false



bindCollapsors = (selector = ".collapse-trigger") ->
  ###
  # Bind the events for collapse-triggers
  ###
  toggleEvent = (caller) ->
    target = $(caller).attr "data-target"
    unless $(target).exists()
      console.error "Couldn't find target #{target}"
      return false
    validTargetElements = [
      "iron-collapse"
      ]
    if p$(target).tagName.toLowerCase() in validTargetElements
      p$(target).toggle()
    else
      console.error "Target type #{p$(target).tagName.toLowerCase()} is an invalid target"
    false
  for toggle in $(selector)
    $(toggle).click ->
      toggleEvent.debounce 50, null, null, this
  false



dateMonthToString = (month) ->
  conversionObj =
    0: "January"
    1: "February"
    2: "March"
    3: "April"
    4: "May"
    5: "June"
    6: "July"
    7: "August"
    8: "September"
    9: "October"
    10: "November"
    11: "December"
  try
    rv = conversionObj[month]
  catch
    rv = month
  rv



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
      genus = $(this).find(".genus").text()
      species = $(this).find(".species").text()
      if not isNull(genus) and not isNull(species)
        $(this)
        .unbind()
        .addClass "sciname-click"
        .click ->
          target = "#{uri.urlString}dashboard.php?taxon=#{genus}+#{species}"
          goTo target
          false

prepURI = (string) ->
  string = encodeURIComponent(string)
  string.replace(/%20/g,"+")


window.locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined

getLocation = (callback = undefined) ->
  retryTimeout = 1500
  geoSuccess = (pos) ->
    clearTimeout window.geoTimeout
    window.locationData.lat = pos.coords.latitude
    window.locationData.lng = pos.coords.longitude
    window.locationData.acc = pos.coords.accuracy
    last = window.locationData.last
    window.locationData.last = Date.now() # ms, unix time
    elapsed = window.locationData.last - last
    if elapsed < retryTimeout
      # Don't run too many times
      return false
    console.info "Successfully set location"
    if typeof callback is "function"
      callback(window.locationData)
    false
  geoFail = (error) ->
    clearTimeout window.geoTimeout
    locationError = switch error.code
      when 0 then "There was an error while retrieving your location: #{error.message}"
      when 1 then "The user prevented this page from retrieving a location"
      when 2 then "The browser was unable to determine your location: #{error.message}"
      when 3 then "The browser timed out retrieving your location."
    console.error(locationError)
    if typeof callback is "function"
      callback(false)
    false
  # Actual location query
  if navigator.geolocation
    console.log "Querying location"
    navigator.geolocation.getCurrentPosition(geoSuccess,geoFail,window.locationData.params)
    window.geoTimeout = delay 1500, ->
      getLocation callback
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
    <div class="alert alert-#{type} alert-dismissable hanging-alert" role="alert" id="#{selector.slice(1)}">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <div class="alert-message"></div>
    </div>
    """
    topContainer = if $("main").exists() then "main" else if $("article").exists() then "article" else fallbackContainer
    $(topContainer).prepend(html)
  else
    $(selector).removeClass "alert-warning alert-info alert-danger alert-success"
    $(selector).addClass "alert-#{type}"
  $("#{selector} .alert-message").html(message)
  bindClicks()
  mapNewWindows()
  false


animateHoverShadows = (selector = "paper-card.card-tile", defaultElevation = 2, raisedElevation = 4) ->
  handlerIn = ->
    $(this).attr "elevation", raisedElevation
  handlerOut = ->
    $(this).attr "elevation", defaultElevation
  $(selector).hover handlerIn, handlerOut
  false


allError = (message) ->
  stopLoadError message
  bsAlert message, "danger"
  console.error message
  false


checkFileVersion = (forceNow = false, file = "js/c.min.js", callback) ->
  ###
  # Check to see if the file on the server is up-to-date with what the
  # user sees.
  #
  # @param bool forceNow force a check now
  ###
  unless _adp?.lastModChecked?
    unless window._adp?
      window._adp = new Object()
    window._adp.lastModChecked = new Object()
  key = file.split("/").pop().split(".")[0]
  checkVersion = (filePath = file, modKey = key) ->
    $.get("#{uri.urlString}meta.php","do=get_last_mod&file=#{filePath}","json")
    .done (result) ->
      window._adp.lastModChecked[modKey] = Date.now()
      if forceNow
        # console.log("Forced version check:",result)
        doNothing()
      unless isNumber result.last_mod
        return false
      unless _adp.lastMod?
        window._adp.lastMod = new Object()
      unless _adp.lastMod[modKey]?
        window._adp.lastMod[modKey] = result.last_mod
      if result.last_mod > _adp.lastMod[modKey]
        # File has updated
        html = """
        <div id="outdated-warning" class="alert alert-warning alert-dismissible fade in" role="alert">
          <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <strong>We have page updates!</strong> This page has been updated since you last refreshed. <a class="alert-link" id="refresh-page" style="cursor:pointer">Click here to refresh now</a> and get bugfixes and updates.
        </div>
        """
        unless $("#outdated-warning").exists()
          $("body").append(html)
          $("#refresh-page").click ->
            document.location.reload(true)
        console.warn "Your current version of this page is out of date! Please refresh the page."
      else if forceNow
        doNothing()
        # console.info "Your version of this page is up to date: have #{window._adp.lastMod[modKey]}, got #{result.last_mod}"
    .fail ->
      console.warn("Couldn't check file version!!")
    .always ->
      delay 5*60*1000, ->
        # Delay 5 minutes
        checkVersion(filePath, modKey)
      if typeof callback is "function"
        callback()
  try
    keyExists = window._adp.lastMod[key]
  catch
    keyExists = false
  if forceNow or not window._adp.lastMod? or not keyExists
    try
      # For fifteen seconds, ignore a force
      unless (Date.now() - toInt window._adp.lastModChecked[key]) < (15 * 1000)
        checkVersion(file, key)
    catch
      # Fail safely
      checkVersion(file, key)
    return true
  false

window.checkFileVersion = checkFileVersion


fixTruncatedJson = (str) ->
  # Converted from
  # https://gist.github.com/kekscom/10925007
  json = str
  chunk = json
  q = false
  m = false
  stack = []
  while m = chunk.match /[^\{\[\]\}"]*([\{\[\]\}"])/
    switch m[1]
      when "{"
        stack.push "}"
      when "["
        stack.push "]"
      when "}", "]"
        stack.pop()
      when '"'
        unless q
          q = true
          stack.push '"'
        else
          q = false
          stack.pop()
    chunk = chunk.substring m[0].length
    # End stack builder
  if chunk[chunk.length - 1] is ":"
    json += '""'

  while stack.length
    json += stack.pop()
  try
    return JSON.parse json
  catch
    return false


checkLoggedIn = (callback) ->
  ###
  # Checks the login credentials against the server.
  # This should not be used in place of sending authentication
  # information alongside a restricted action, as a malicious party
  # could force the local JS check to succeed.
  # SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
  ###
  hash = $.cookie("#{uri.domain}_auth")
  secret = $.cookie("#{uri.domain}_secret")
  link = $.cookie("#{uri.domain}_link")
  args = "hash=#{hash}&secret=#{secret}&dblink=#{link}"
  loginTarget = "#{uri.urlString}admin/async_login_handler.php"
  $.post loginTarget, args, "json"
  .done (result) ->
    console.info "Got", result
    callback(result)
  .fail (result,status) ->
    response =
      status: false
    callback(response)
  false


doNothing = ->
  return null


downloadCSVFile = (data, options, callback) ->
  ###
  # Options:
  #
  options = new Object()
  options.create ?= false
  options.downloadFile ?= "datalist.csv"
  options.classes ?= "btn btn-default"
  options.buttonText ?= "Download File"
  options.iconHtml ?= """<iron-icon icon="icons:cloud-download"></iron-icon>"""
  options.selector ?= "#download-file"
  options.splitValues ?= false
  ###
  # unless options?
  #   options =
  #     downloadFile: "cleaned-dataset-#{Date.now()}.csv"
  #     selector: "#download-server-parsed-data"
  #     create: true
  try
    postMessageContent =
      action: "csv"
      data: data
      options: options
    # Send the message
    worker = new Worker "js/global-search-worker.min.js"
    console.info "Generating an off-thread worker for CSV population"
    worker.addEventListener "message", (e) ->
      # Web worker callback
      html = e.data.html
      file = e.data.file
      options = e.data.options
      console.info "CSV Web worker returned", e.data
      # Helper callback
      postCallback = ->
        # Insert it into the DOM
        selector = options.selector
        if options.create is true and not $(selector).exists()
          $(selector).append html
        else
          $(selector)
          .attr("download", options.downloadFile)
          .attr("href",file)
          .removeClass "disabled"
          .removeAttr "disabled"
        false
      # Possibly execute callback
      if typeof callback is "function"
        try
          callback ->
            postCallback()
        catch
          postCallback()
      else
        postCallback()
    worker.postMessage postMessageContent
  catch e
    ###
    # Classic way! Do it on thread
    ###
    console.warn "Web workers aren't supported or otherwise failed"
    console.warn e.message
    console.warn "Doing work on-thread"
    downloadCSVFileOnThread data, options
  false


downloadCSVFileOnThread = (data, options) ->
  ###
  # On-Thread fallback for Web Worker
  #
  # Check downloadCSVFile for canonical version
  ###
  textAsset = ""
  if isJson data
    console.info "Parsing as JSON string"
    jsonObject = JSON.parse data
  else if isArray data
    console.info "Parsing as array"
    jsonObject = toObject data
  else if typeof data is "object"
    console.info "Parsing as object"
    jsonObject = data
  else
    console.error "Unexpected data type '#{typeof data}' for downloadCSVFile()", data
    return false
  # Make sure options are available the rest of the way down
  unless options?
    options = new Object()
  options.create ?= false
  options.downloadFile ?= "datalist.csv"
  options.classes ?= "btn btn-default"
  options.buttonText ?= "Download File"
  options.iconHtml ?= """<iron-icon icon="icons:cloud-download"></iron-icon>"""
  options.selector ?= "#download-file"
  options.splitValues ?= false
  options.cascadeObjects ?= false
  options.objectAsValues ?= true # false
  # Parse it
  headerPlaceholder = new Array()
  do parser = (jsonObj = jsonObject, cascadeObjects = options.cascadeObjects) ->
    row = 0
    if options.objectAsValues
      options.splitValues = "::@@::"
    for key, value of jsonObj
      if typeof value is "function" then continue
      ++row
      # Escape as per RFC4180
      # https://tools.ietf.org/html/rfc4180#page-2
      try
        escapedKey = key.toString().replace(/"/g,'""')
        if row is 1
          unless options.objectAsValues
            console.log "Boring options", options.objectAsValues, options
            headerPlaceholder.push escapedKey
          else
            console.info "objectAsValues set"
            for col, data of value
              if isArray options.acceptableCols
                if col in options.acceptableCols
                  headerPlaceholder.push col
              else
                headerPlaceholder.push col
            console.log "Using as header", headerPlaceholder
        if typeof value is "object" and cascadeObjects
          # Parse it differently
          value = parser(value, true)
        handleValue = (providedValue = value, providedOptions = options) ->
          # Parse it all
          if isNull value
            escapedValue = ""
          else
            if typeof providedValue is "object"
              providedValue = JSON.stringify providedValue
            providedValue = providedValue.toString()
            tempValue = providedValue.replace(/"/g,'""')
            tempValue = tempValue.replace(/,/g,'\,')
            tempValue = tempValue.replace(/<\/p><p>/g,'","')
            if typeof providedOptions.splitValues is "string"
              tempValueArr = tempValue.split providedOptions.splitValues
              tempValue = tempValueArr.join "\",\""
              escapedKey = false
            escapedValue = tempValue
          if escapedKey is false
            # Special case of split values
            tmpTextAsset = "\"#{escapedValue}\"\n"
          else if isNumber escapedKey
            tmpTextAsset = "\"#{escapedValue}\","
          else unless isNull escapedKey
            tmpTextAsset = """"#{escapedKey}","#{escapedValue}"

            """
          tmpTextAsset
        # Build the textAsset string
        unless options.objectAsValues
          textAsset += handleValue(value)
        else
          tmpRow = new Array()
          for col in headerPlaceholder
            dataVal = value[col]
            if typeof dataVal is "object"
              try
                dataVal = JSON.stringify dataVal
                dataVal = dataVal.replace(/"/g,'""')
            tmpRow.push dataVal
          tmpRowString = tmpRow.join options.splitValues
          textAsset += handleValue tmpRowString, options
      catch e
        console.warn "Unable to run key #{key} on row #{row}", value, jsonObj
        console.warn e.stack
  textAsset = textAsset.trim()
  k = 0
  for col in headerPlaceholder
    col = col.replace(/"/g,'""')
    headerPlaceholder[k] = col
    ++k
  if options.objectAsValues
    options.header = headerPlaceholder
  if isArray options.header
    headerStr = options.header.join "\",\""
    textAsset = """
    "#{headerStr}"
    #{textAsset}
    """
    # CoffeScript 1.10 has a bug with """ leading ", so we needed to
    # start on a new line above. Remove it.
    textAsset = textAsset.trim()
    header = "present" # https://tools.ietf.org/html/rfc4180#page-4
  else
    # https://tools.ietf.org/html/rfc4180#page-4
    header = "absent"
  if textAsset.slice(-1) is ","
    textAsset = textAsset.slice(0, -1)
  file = "data:text/csv;charset=utf-8;header=#{header}," + encodeURIComponent(textAsset)
  selector = options.selector
  if options.create is true
    c = $(selector).find("button").length
    id = "#{selector.slice(1)}-download-button-#{c}"
    html = """
    <a id="#{id}" class="#{options.classes}" href="#{file}" download="#{options.downloadFile}">
      #{options.iconHtml}
      #{options.buttonText}
    </a>
    """
    $(selector).append html
  else
    $(selector)
    .attr("download", options.downloadFile)
    .attr("href",file)
  file


linkUsers = (selector = ".is-user") ->
  ###
  # Links users to user profiles
  #
  # See #107 for description
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/107
  ###
  profilePageUri = "https://amphibiandisease.org/profile.php"
  profilePageArg = "?id="
  $(selector)
  .addClass "linked-user-profile"
  .attr "title", "Visit Profile"
  .attr "data-toggle", "tooltip"
  .click ->
    # Check the attrs set
    setUid = $(this).attr "data-uid"
    setEmail = $(this).attr "data-email"
    # Preferred case: go directly by UID
    unless isNull setUid
      dest = "#{profilePageUri}#{profilePageArg}#{setUid}"
      document.location.href = dest
      return false
    # Do we have an email to check?
    if isNull setEmail
      # Try the contents of the tag
      searchRaw = $(this).text()
      if isNull searchRaw
        searchRaw = $(this).attr "data-name"
        if isNull searchRaw
          console.error "Unable to find a search criterion!"
          return false
      cols = "name"
    else
      searchRaw = setEmail
      cols = "username,alternate_email"
    # An email is set, look it up
    startLoad()
    search = encodeURIComponent searchRaw
    args = "action=search_users&q=#{search}&cols=#{cols}"
    $.post "#{uri.urlString}api.php", args, "json"
    .done (result) ->
      console.info "Found", result
      if result.status isnt true
        console.error "Error searching for profile"
        stopLoadError "There was an error looking up the user. Please try again later."
        return false
      profiles = Object.toArray result.result
      if profiles.length < 1
        stopLoadError "Couldn't find user '#{searchRaw}'"
        return false
      stopLoad()
      defaultProfile = profiles[0]
      uid = defaultProfile.uid
      dest = "#{profilePageUri}#{profilePageArg}#{uid}"
      document.location.href = dest
      false
    .fail (result, status) ->
      console.error result, status
      stopLoadError "Error communicating with server. Please try again later."
      false
    false
  false






fetchCitation = (citationQuery, callback) ->
  ###
  # Fetch and format a citation. Uses CrossRef API:
  # https://github.com/CrossRef/rest-api-doc/blob/master/rest_api.md
  #
  # Output format should be Proceedings B style:
  # https://www.zotero.org/styles/proceedings-of-the-royal-society-b?source=1
  # http://rspb.royalsocietypublishing.org/faq#question1
  #
  # Example:
  #
  # Oneal E, Knowles LL. 2012 Ecological selection as the cause and sexual differentiation as the consequence of species divergence? Proc R Soc B 280: 20122236; doi: 10.1098/rspb.2012.2236
  #
  # @param string citationQuery -> pre-formatted string for the
  #   CrossRef API.
  # @param function callback -> callback for the citation. Callback
  #   provided with  the citation as arg1, then the PDF URL as arg2.
  ###
  postUrl = "https://api.crossref.org/works/"
  eQ = encodeURIComponent citationQuery
  totalUrl = "#{postUrl}#{citationQuery}"
  $.get totalUrl, "", "json"
  .done (result) ->
    console.info "Citation base", result
    j = result.message
    authors = new Array()
    i = 0
    authorJoin = ", "
    for author in j.author
      initialsArray = author.given.split " "
      initials = ""
      for givenPart in initialsArray
        n = givenPart.slice 0, 1
        initials += n
      authorString = "#{author.family} #{initials}"
      authors.push authorString
      ++i
      if i > 2
        ++i
        authors.push "et al"
        break
    if i is 2
      authorJoin = " and "
    published = j["published-print"]?["date-parts"]?[0]?[0] ? j["published-online"]?["date-parts"]?[0]?[0] ? "In press"
    issue = unless isNull j.issue then "(#{j.issue})" else ""
    if isNull j.volume
      j.volume = ""
    if isNull(j.volume) and isNull(issue)
      volBlob = ""
    else
      volBlob = "#{j.volume}#{issue}:"
    try
      try
        doi = j.DOI
        doiNumbers = doi.replace(/[^0-9]/mg, "")
        doiContinuous = doiNumbers.slice -8
        continuous = " #{doiContinuous}; doi: #{doi}"
      catch
        # Go classic
        continuous = "#{j.page}."
      citation = """
      #{authors.join(authorJoin)}. #{published} #{j.title[0]}. #{j["container-title"][0]} #{volBlob}#{continuous}
      """
    catch e
      console.warn "Couldn't generate full citation"
      console.warn j
      citation = """
      #{authors.join(", ")}. #{j.title[0]}. #{j["container-title"][0]}. In press.
      """
    console.log citation
    if typeof callback is "function"
      try
        url = unless isNull(j.URL) then j.URL else j.link[0].URL
        if url.search("http:") isnt -1
          # Security
          url = url.replace(/^(http):\/\/(([a-z0-9]+\.?)+)(.*)$/g, "https://$2$4")
      catch
        url = "https://dx.doi.og/#{citationQuery}"
      try
        callback citation, url
      catch e
        console.error "Callback failed, couldn't display citation - #{e.message}"
        console.warn e.stack
        stopLoadError "Failed to display citation"
    false
  .fail (result, status) ->
    console.error "Failed to fetch citation"
    stopLoadError "Failed to fetch citation"
  false



cancelAsyncOperation = (caller, asyncOperation = _adp.currentAsyncJqxhr) ->
  ###
  # Abort the current operation
  #
  # https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/abort
  ###
  try
    if caller?
      $(caller).remove()
  try
    if asyncOperation.readyState is XMLHttpRequest.DONE
      console.warn "Couldn't cancel operation -- it's already completed"
      return false
    asyncOperation.abort()
    # Do a host of cancellation events
    try
      stopLoadBarsError null, "Operation Cancelled"
    catch
      stopLoadError "Operation Cancelled"
  catch
    console.error "Couldn't abort current async operation"
  false



generateCSVFromResults = (resultArray, caller, selector = "#modal-sql-details-list") ->
  ###
  # Main CSV record generator. Generally the one called, and may
  # instance the web worker copy.
  ###
  # toastStatusMessage "This may take a few seconds, please wait"
  startTime = Date.now()
  console.info "Source CSV data:", resultArray
  options =
    objectAsValues: true
    downloadFile: "adp-global-search-result-data_#{Date.now()}.csv"
    # acceptableCols: [
    #   "collectionid"
    #   "catalognumber"
    #   "fieldnumber"
    #   "sampleid"
    #   "diseasetested"
    #   "diseasestrain"
    #   "samplemethod"
    #   "sampledisposition"
    #   "diseasedetected"
    #   "fatal"
    #   "cladesampled"
    #   "genus"
    #   "specificepithet"
    #   "infraspecificepithet"
    #   "lifestage"
    #   "dateidentified"
    #   "decimallatitude"
    #   "decimallongitude"
    #   "alt"
    #   "coordinateuncertaintyinmeters"
    #   "collector"
    #   "fimsextra"
    #   "originaltaxa"
    #   ]
  # Fire up the web worker
  try
    downloadCSVFile resultArray, options, (postCallback) ->
      $("#download-file").remove()
      html = """
          <a tabindex="-1" id="download-file" class="paper-button-link">
            <paper-button disabled>
              <iron-icon icon="icons:cloud-download"></iron-icon>
              Download File
            </paper-button>
          </a>
      """
      $(caller).replaceWith html
      $("#{selector} #download-file paper-button").removeAttr "disabled"
      if typeof postCallback is "function"
        try
          postCallback()
        catch e
          console.warn "Couldn't run postCallbacak after downloadCSV file -- #{e.message}"
      elapsed = Date.now() - startTime
      console.debug "GenerateCSVFromResults completed in #{elapsed}ms"
      stopLoad()
  catch
    animateLoad()
    stopLoadError "Sorry, there was a problem with this dataset and we can't generate a downloadable file."
  false




validateAWebTaxon = (taxonObj, callback = null) ->
  ###
  #
  #
  # @param Object taxonObj -> object with keys "genus", "species", and
  #   optionally "subspecies"
  # @param function callback -> Callback function
  ###
  unless window.validationMeta?.validatedTaxons?
    # Just being thorough on this check
    unless typeof window.validationMeta is "object"
      window.validationMeta = new Object()
    # Create the array if it doesn't exist yet
    window.validationMeta.validatedTaxons = new Array()
  doCallback = (validatedTaxon) ->
    if typeof callback is "function"
      callback(validatedTaxon)
    false
  # Check the taxon against pre-validated ones
  if window.validationMeta.validatedTaxons.containsObject taxonObj
    console.info "Already validated taxon, skipping revalidation", taxonObj
    doCallback(taxonObj)
    return false
  args = "action=validate&genus=#{taxonObj.genus}&species=#{taxonObj.species}"
  if taxonObj.subspecies?
    args += "&subspecies=#{taxonObj.subspecies}"
  _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
  .done (result) ->
    if result.status
      # Success! Save validated taxon, and run callback
      taxonObj.genus = result.validated_taxon.genus
      taxonObj.species = result.validated_taxon.species
      taxonObj.subspecies = result.validated_taxon.subspecies
      taxonObj.clade ?= result.validated_taxon.family
      window.validationMeta.validatedTaxons.push taxonObj
    else
      taxonObj.invalid = true
    taxonObj.response = result
    doCallback(taxonObj)
    return false
  .fail (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false





###
# Show page citationsin the overflow for non-project pages
###
makePageCitationOverflow = ->
  # Are we on a project-specific page
  projectPageRequiredParams = [
    "project_id"
    "id"
    "projectid"
    ]
  for param in projectPageRequiredParams
    unless isNull uri.o.param param
      console.info "Not creating overflow citation - page is project-specific"
      return false
  if uri.o.data.seg.path[0] is "admin-login.php"
    return false
  # Create the citation
  ###
  # Sample:
  #
  # AmphibiaWeb. 2016. Amphibian Disease Portal <http://amphibiandisease.org>. University of California, Berkeley, CA, USA. Accessed 27 Sep 2016.
  ###
  d = new Date()
  month = dateMonthToString d.getMonth()
  citationString = """
    AmphibiaWeb. #{d.getUTCFullYear()}. #{$("title").text()} &lt;#{uri.o.data.attr.source}&gt;. University of California, Berkeley, CA, USA. Accessed #{d.getUTCDate()} #{month} #{d.getUTCFullYear()}.
  """
  citationHtml = """
  <paper-dialog id="page-citation" modal>
    <h2>Citation</h2>
    <paper-dialog-scrollable>
      <div>
        <p style="opacity:0">
          #{citationString}
        </p>
        <paper-input value="#{citationString.escapeQuotes()}" label="Citation" readonly></paper-input>
      </div>
    </paper-dialog-scrollable>
    <div class="buttons">
      <paper-button dialog-dismiss>Close</paper-button>
    </div>
  </paper-dialog>
  """
  # Insert the menu item
  itemId = "dialog-trigger-item"
  try
    item = document.createElement "paper-item"
    item.setAttribute "id", itemId
    item.textContent = "Show Citation"
    menu = p$("header paper-menu")
    Polymer.dom(menu).appendChild item
  catch
    item = """
    <paper-item id="#{itemId}">
      Show Citation
    </paper-item>
    """
    $("header paper-menu-button .paper-menu").append item
  # Bind the item
  $("#page-citation").remove()
  $("body").append citationHtml
  # dom appendchild can be slow, let's wait a tick.
  delay 250, ->
    $("##{itemId}").click ->
      console.debug "Clicked trigger item"
      p$("#page-citation").open()
  citationString


delayPolymerBind = (selector, callback, iter = 0) ->
  unless typeof window._dpb is "object"
    window._dpb = new Object()
  uid = md5(selector) + md5(callback)
  if isNull window._dpb[uid]
    window._dpb[uid] = false
  superSlowBackup = 1000
  if Polymer?.Base?.$$?
    if window._dpb[uid] is false
      iter = 0
      window._dpb[uid] = true
    try
      element = Polymer.Base.$$(selector)
      callback(element)
      # Some browsers are stupid slow, do it again
      delay superSlowBackup, ->
        console.info "Doing #{superSlowBackup}ms delay callback for #{selector}"
        callback(element)
    catch e
      console.warn "Error trying to do the delayed polymer bind - #{e.message}"
      if iter < 10
        ++iter
        # Do a very short wait and try again, in case it's transient
        delay 75, ->
          delayPolymerBind selector, callback, iter
      else
        # See
        # https://github.com/Polymer/polymer/issues/2246
        console.error "Persistent error in polymer binding (#{e.message})"
        console.error e.stack
        # Attempt the last-ditch
        element = $(selector).get(0)
        callback(element)
        delay superSlowBackup, ->
          element = document.querySelector(selector)
          console.info "Doing #{superSlowBackup}ms delay callback for #{selector}"
          console.info "Using element", element
          callback(element)
  else
    if iter < 50
      delay 100, ->
        ++iter
        delayPolymerBind selector, callback, iter
    else
      console.error "Failed to verify Polymer was set up, attempting manual"
      element = document.querySelector(selector)
      callback element
  false




$ ->
  bindClicks()
  formatScientificNames()
  lightboxImages()
  animateHoverShadows()
  checkFileVersion()
  linkUsers()
  try
    $(".do-mailto").click ->
      email = $(this).attr "data-email"
      document.location.href = "mailto:#{email}"
      false
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
        if typeof loadAdminUi isnt "function"
          loadAdminUi = ->
            html = """
      <div class='bs-callout bs-callout-danger'>
        <h4>Error loading administration</h4>
        <p>
          We failed to load the administrative interface. Try refreshing the page.
        </p>
        <p>
          If you continue to see this error, please check your network connection.
        </p>
      </div>            
            """
            $("main #main-body").html html
            false
        loadAdminUi()
    else
      console.info "No admin setup requested"
    # Let clicking on username load up profile page
    $("header .header-bar-user-name").click ->
      goTo "#{uri.urlString}profile.php"
  # Lazy-load syntax highlighter
  loadJS "#{uri.urlString}js/prism.js"
  try
    makePageCitationOverflow()
  try
    delay 500, ->
      setupDebugContext()
