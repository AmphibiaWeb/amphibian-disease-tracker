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

# Login functions

unless typeof apiUri is "object"
  apiUri = new Object()
try
  apiUri.o = $.url()
catch
  if uri?.o?
    apiUri.o = uri.o
   else
     console.warn "The PURL library may be improperly loaded!"
# Why window.location? In case there's a domain in a url key
apiUri.urlString = window.location.origin  + "/" + totpParams.subdirectory
apiUri.query = apiUri.o.attr("fragment")
apiUri.targetApi = "async_login_handler.php"
apiUri.apiTarget = apiUri.urlString + apiUri.targetApi

if typeof window.passwords isnt 'object' then window.passwords = new Object()
window.passwords.goodbg = "#cae682"
window.passwords.badbg = "#e5786d"
# Password lengths can be overriden in CONFIG.php,
# which then defines the values for these before the script loads.
window.passwords.minLength ?= 8
window.passwords.overrideLength ?= 20

if typeof window.totpParams isnt 'object' then window.totpParams = new Object()
window.totpParams.popClass = "pop-panel"
# The value $redirect_url in CONFIG.php overrides this value
if not window.totpParams.home?
  window.totpParams.home =  apiUri.o.attr('protocol') + '://' + apiUri.o.attr('host') + '/'
if not window.totpParams.relative?
  window.totpParams.relative = ""
if not window.totpParams.subdirectory?
  window.totpParams.subdirectory = ""
window.totpParams.mainStylesheetPath = window.totpParams.relative+"css/otp_styles.css"
window.totpParams.popStylesheetPath = window.totpParams.relative+"css/otp_panels.css"
window.totpParams.combinedStylesheetPath = window.totpParams.relative+"css/otp.min.css"



delete url

checkPasswordLive = (selector = "#createUser_submit", firstPasswordSelector = "#password", secondPasswordSelector = "#password2", requirementsSelector = "#password_security") ->
  ###
  #
  ###
  pass = $(firstPasswordSelector).val()
  re = new RegExp("^(?:(?=^.{#{window.passwords.minLength},}$)((?=.*\\d)|(?=.*\\W+))(?![.\\n])(?=.*[A-Z])(?=.*[a-z]).*$)$")
  if pass.length >window.passwords.overrideLength or pass.match(re)
    $(firstPasswordSelector)
    .css("background",window.passwords.goodbg)
    .parent().parent().removeClass("has-error")
    .addClass("has-success")
    $("#feedback-status-1").replaceWith("<span id='feedback-status-1' class='glyphicon glyphicon-ok form-control-feedback' aria-hidden='true'></span>")
    window.passwords.basepwgood = true
  else
    $(firstPasswordSelector)
    .css("background",window.passwords.badbg)
    .parent().parent().removeClass("has-success")
    .addClass("has-error")
    $("#feedback-status-1").replaceWith("<span id='feedback-status-1' class='glyphicon glyphicon-remove form-control-feedback' aria-hidden='true'></span>")
    window.passwords.basepwgood = false
  evalRequirements(requirementsSelector, firstPasswordSelector)
  if not isNull($(secondPasswordSelector).val())
    checkMatchPassword(selector, firstPasswordSelector, secondPasswordSelector)
    toggleNewUserSubmit(selector)
  return false

checkMatchPassword = (selector = "#createUser_submit", firstPasswordSelector = "#password", secondPasswordSelector = "#password2") ->
  if $(firstPasswordSelector).val() is $(secondPasswordSelector).val()
    $(secondPasswordSelector)
    .css('background', window.passwords.goodbg)
    .parent().parent().removeClass("has-error")
    .addClass("has-success")
    $("#feedback-status-2").replaceWith("<span id='feedback-status-2' class='glyphicon glyphicon-ok form-control-feedback' aria-hidden='true'></span>")
    window.passwords.passmatch = true
  else
    $(secondPasswordSelector)
    .css('background', window.passwords.badbg)
    .parent().parent().removeClass("has-success")
    .addClass("has-error")
    $("#feedback-status-2").replaceWith("<span id='feedback-status-2' class='glyphicon glyphicon-remove form-control-feedback' aria-hidden='true'></span>")
    window.passwords.passmatch = false
  toggleNewUserSubmit(selector)
  return false

toggleNewUserSubmit = (selector = "#createUser_submit") ->
  try
    dbool = not(window.passwords.passmatch && window.passwords.basepwgood)
    $(selector).attr("disabled",dbool)
  catch e
    window.passwords.passmatch = false
    window.passwords.basepwgood = false

evalRequirements = (selector = "#password_security", passwordSelector = "#password") ->
  unless $("#strength-meter").exists()
    html = "<h4>Password Requirements</h4><div id='strength-meter'><div id='strength-requirements'><p style='float:left;margin-top:2em;font-weight:700;'>Character Classes:</p><div id='strength-alpha'><p class='label'>a</p><div class='strength-eval'></div></div><div id='strength-alphacap'><p class='label'>A</p><div class='strength-eval'></div></div><div id='strength-numspecial'><p class='label'>1/!</p><div class='strength-eval'></div></div></div><div id='strength-bar'><label for='password-strength'>Strength: </label><progress id='password-strength' max='5'></progress><p>Time to crack: <span id='crack-time'></span></p></div></div>"
    notice = "<br/><br/><p>We require a password of at least #{window.passwords.minLength} characters with at least one upper case letter, at least one lower case letter, and at least one digit or special character.</p><p>You can also use <a href='http://imgs.xkcd.com/comics/password_strength.png' class='lightboximage'>any long password</a> of at least #{window.passwords.overrideLength} characters, with no security requirements.</p>"
    $(selector)
    .html(html + notice)
    .removeClass('invisible')
    lightboxImages()
    $("#helpText").removeClass("invisible")
  pass = $(passwordSelector).val()
  pstrength = zxcvbn(pass)
  green_channel = (toInt(pstrength.score)+1) * 51
  red_channel = 255 - toInt(Math.pow(pstrength.score,2) * 16)
  if red_channel < 0 then red_channel = 0
  new_end = "rgb(#{red_channel},#{green_channel},0)"
  webkit_css = "\nprogress[value]::-webkit-progress-value {
    background: -webkit-linear-gradient(left,rgb(255,0,30),#{new_end}),
    -webkit-linear-gradient(top,rgba(255, 255, 255, .5),
	                           rgba(0, 0, 0, .5));
                             }"
  moz_css = "\nprogress::-moz-progress-bar {
    background: -moz-linear-gradient(left,rgb(255,0,30),#{new_end}),
    -moz-linear-gradient(top,rgba(255, 255, 255, .5),
	                           rgba(0, 0, 0, .5));
                             }"
  if not $("#dynamic").exists()
    $("<style type='text/css' id='dynamic' />").appendTo("head")
  $("#dynamic").text(webkit_css + moz_css)
  $(".strength-eval").css("background",window.passwords.badbg)
  if pass.length >= window.passwords.overrideLength then $(".strength-eval").css("background",window.passwords.goodbg)
  else
    if pass.match(/^(?:((?=.*\d)|(?=.*\W+)).*$)$/) then $("#strength-numspecial .strength-eval").css("background",window.passwords.goodbg)
    if pass.match(/^(?=.*[a-z]).*$/) then $("#strength-alpha .strength-eval").css("background",window.passwords.goodbg)
    if pass.match(/^(?=.*[A-Z]).*$/) then $("#strength-alphacap .strength-eval").css("background",window.passwords.goodbg)
  $("#password-strength").attr("value",pstrength.score+1);
  $("#crack-time").text(pstrength.crack_time_display)

doEmailCheck = ->
  # Perform a GET request to see if the chosen email is already taken

doTOTPSubmit = (home = window.totpParams.home) ->
  # Get the code from #totp_code and push it through
  # to async_login_handler.php , get the results and behave appropriately
  noSubmit()
  animateLoad()
  $("#verify_totp_button").prop("disabled",true)
  code = $("#totp_code").val()
  user = $("#username").val()
  pass = $("#password").val()
  ip = $("#remote").val()
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  args = "action=verifytotp&code=#{code}&user=#{user}&password=#{pass}&remote=#{ip}"
  totp = $.post(apiUrlString ,args,'json')
  totp.done (result) ->
    # Check the result
    if result.status is true
      # If it's good, set the cookies
      try
        $("#totp_message")
        .text("Correct!")
        .removeClass("alert-danger")
        .addClass("alert alert-success")
        i = 0
        $.each result["cookies"].raw_cookie, (key,val) ->
          try
            $.cookie(key,val,result["cookies"].expires)
          catch e
            console.error("Couldn't set cookies",result["cookies"].raw_cookie)
          i++
          if i is Object.size(result["cookies"].raw_cookie)
            # Take us home
            home ?= url.attr('protocol') + '://' + url.attr('host') + '/'
            stopLoad()
            delay 500, ->
              window.location.href = home
      catch e
        console.error("Unexpected error while validating",e.message);
    else
      $("#totp_message")
      .text(result.human_error)
      .addClass("alert alert-danger")
      $("#totp_code").val("") # Clear it
      $("#totp_code").focus()
      stopLoadError()
      console.error("Invalid code error",result.error,result);
  totp.fail (result,status) ->
    # Be smart about the failure
    $("#totp_message")
    .text("Failed to contact server. Please try again.")
    .addClass("alert alert-danger")
    console.error("AJAX failure",apiUrlString  + "?" + args,result,status)
    stopLoadError()
  totp.always ->
    $("#verify_totp_button").prop("disabled",false)
  false


doTOTPRemove = ->
  # Remove 2FA
  noSubmit()
  animateLoad()
  user = $("#username").val()
  pass = encodeURIComponent($("#password").val())
  code = $("#code").val()
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  args = "action=removetotp&code=#{code}&username=#{user}&password=#{pass}&base64=true"
  remove_totp = $.post(apiUrlString,args,'json')
  remove_totp.done (result) ->
    # Check the result
    unless result.status is true
      $("#totp_message")
      .text(result.human_error)
      .addClass("error")
      console.error(result.error)
      console.warn("#{apiUrlString}?#{args}")
      console.warn(result)
      stopLoadError()
      return false
    # Removed!
    $("#totp_message")
    .removeClass('error')
    .addClass('good')
    .text("Two-factor authentication removed for #{result.username}.")
    $("#totp_remove").remove()
    console.log(apiUrlString + "?" + args);
    console.log(result)
    stopLoad()
    return false
  remove_totp.fail (result,status) ->
    # Be smart about the failure
    $("#totp_message")
    .text("Failed to contact server. Please try again.")
    .addClass("error")
    console.error("AJAX failure",apiUrlString  + "?" + args,result,status)
    stopLoadError()

makeTOTP = ->
  # Create 2FA for the user
  noSubmit()
  animateLoad()
  # Call up the function, and replace #totp_add with a new form to verify
  user = $("#username").val()
  password = $("#password").val()
  hash = $("#hash").val()
  key = $("#secret").val()
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  args = "action=maketotp&password=#{password}&user=#{user}"
  totp = $.post(apiUrlString,args,'json')
  totp.done (result) ->
    # Yay! Replace the form ....
    if result.status is true
      $("#totp_message")
      .html("To continue, scan this barcode with your smartphone authenticator application. <small><button id='alt_totp_help' class='alert-link btn btn-link'>Don't have the app?</button></small>")
      .removeClass("error alert-danger alert-warning alert-success")
      .addClass("alert-info")
      console.log(result)
      svg = result.svg
      raw = result.raw
      # Name these in variables to avoid user conflicts
      show_secret_id = "show_secret"
      show_alt = "showAltBarcode"
      barcodeDiv = "secretBarcode"
      html = "<form id='totp_verify' onsubmit='event.preventDefault();' class='col-xs-12 clearfix'>
  <p class='text-muted text-center center-block'>If you're unable to scan the barcode below, <button href='#' id='#{show_secret_id}' class='btn btn-link'>click here to manually input your key.</button></p>
  <div id='#{barcodeDiv}' class='text-center center-block'>
    #{result.svg}
    <p class='text-muted text-center center-block'>Don't see the barcode? <a href='#' id='#{show_alt}' role='button' class='btn btn-link'>Click here</a></p>
  </div>
  <p >Once you've scanned the QR code above with your mobile app, enter the code generated by your app in the field below to verify your setup.</p>
  <fieldset class='form-inline'>
    <legend>Confirmation</legend>
    <div class='form-group'>
      <label for='code' class='sr-only'>Current Code:</label>
      <input type='number' pattern='[0-9]{6}' size='6' maxlength='6' id='code' name='code' placeholder='Code' class='form-control'/>
    </div>
    <input type='hidden' id='username' name='username' value='#{user}'/>
    <input type='hidden' id='hash' name='hash' value='#{hash}'/>
    <input type='hidden' id='secret' name='secret' value='#{key}'/>
    <button id='verify_totp_button' class='totpbutton btn btn-primary'>Verify</button>
  </fieldset>
</form>"
      $("#totp_start").remove()
      $("#totp_message").after(html)
      $("#alt_totp_help").click ->
        showInstructions()
      $("##{show_secret_id}").click ->
        popupSecret(result.human_secret)
      $("##{show_alt}").click ->
        altImg = "<img src='#{result.raw}' alt='TOTP barcode'/>"
        $("##{barcodeDiv}").html(altImg)

        $("##{show_alt}")
        .unbind()
        .text "Still don't see it? Click here again to open the image in a new tab."
        .click ->
          openTab result.url
          $("##{show_alt}").remove()
      $("#verify_totp_button").click ->
        noSubmit()
        saveTOTP(key,hash)
      $("#totp_verify").submit ->
        noSubmit()
        saveTOTP(key,hash)
      stopLoad()
    else
      console.error("Couldn't generate TOTP code",apiUrlString  + "?" + args)
      console.warn(result)
      $("#totp_message")
      .text("There was an error generating your code. #{result.message}")
      .addClass("error")
      stopLoadError()
  totp.fail (result,status) ->
    $("#totp_message")
    .text("Failed to contact server. Please try again.")
    .addClass("error")
    console.error("AJAX failure",apiUrlString  + "?" + args,result,status)
    stopLoadError()
  return false

saveTOTP = (key,hash) ->
  noSubmit()
  animateLoad()
  code = $("#code").val()
  hash = $("#hash").val()
  key = $("#secret").val()
  user = $("#username").val()
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  args = "action=savetotp&secret=#{key}&user=#{user}&hash=#{hash}&code=#{code}"
  totp = $.post(apiUrlString ,args,'json')
  totp.done (result) ->
    # We're done!
    if result.status is true
      html = "<h1>Done!</h1><h2>Write down and save this backup code. Without it, you cannot disable two-factor authentication if you lose your device.</h2><pre id='backup_code'>#{result.backup}</pre><br/><button id='to_home'>Home &#187;</a>"
      $("#totp_add").html(html)
      $("#to_home").click ->
        window.location.href = window.totpParams.home
      stopLoad()
    else
      html = "<p class='error' id='temp_error'>#{result.human_error}</p>"
      unless $("#temp_error").exists()
        $("#verify_totp_button").after(html)
      else
        $("#temp_error").html(html)
      console.error(result.error)
      stopLoadError()
  totp.fail (result,status) ->
    $("#totp_message").text("Failed to contact server. Please try again.")
    console.error("AJAX failure",result,status)
    stopLoadError()

popupSecret = (secret) ->
  # Overlay a pane showing the secret
  # Format it!
  $("<link/>",{
    rel:"stylesheet"
    type:"text/css"
    media:"screen"
    href:window.totpParams.popStylesheetPath
    }).appendTo("head")
  html="<div id='cover_wrapper'><div id='secret_id_panel' class='#{window.totpParams.popClass} cover_content'><p class='close-popup'>X</p><h2>#{secret}</h2></div></div>"
  $("article").after(html)
  $("article").addClass("blur")
  $(".close-popup").click ->
    $("#cover_wrapper").remove()
    $("article").removeClass("blur")

giveAltVerificationOptions = ->
  # Put up an overlay, and ask if the user wants to remove 2FA or get a text
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  user = $("#username").val()
  args = "action=cansms&user=#{user}"
  remove_id = "remove_totp_link"
  sms_id = "send_totp_sms"
  pane_id = "alt_auth_pane"
  pane_messages = "alt_auth_messages"

  # Is it already there?
  if $("##{pane_id}").exists()
    $("##{pane_id}").toggle("fast")
    return false

  messages = new Object()
  messages.remove = "<a href='#' id='#{remove_id}' role='button' class='btn btn-default'>Remove two-factor authentication</a>"
  # First see if the user can SMS at all before populating the message options

  sms = $.get(apiUrlString,args,'json')
  sms.done (result) ->
    if result[0] is true
      messages.sms = "<a href='#' id='#{sms_id}' role='button' class='btn btn-default'>Send SMS</a>"
    else
      console.warn("Couldn't get a valid result",result,apiUrlString+"?"+args)
    pop_content = ""
    $.each messages,(k,v) ->
      pop_content += v
    html = "<div id='#{pane_id}'><p>#{pop_content}</p><p id='#{pane_messages}'></p></div>"
    # Attach it to DOM
    $("#totp_submit").after(html)
    # Attach event handlers
    $("##{sms_id}").click ->
      # Attempt to send the TOTP
      args = "action=sendtotptext&user=#{user}"
      sms_totp = $.get(apiUrlString,args,'json')
      console.log("Sending message ...",apiUrlString+"?"+args)
      sms_totp.done (result) ->
        if result.status is true
          # Remove the pane and replace totp_message
          $("##{pane_id}").remove()
          $("#totp_message").text(result.message)
        else
          #Place a notice in pane_messages
          $("##{pane_messages}")
          .addClass("error")
          .text(result.human_error)
          console.error(result.error)
      sms_totp.fail (result,status) ->
        console.error("AJAX failure trying to send TOTP text",apiUrlString + "?" + args)
        console.error("Returns:",result,status)
  sms.fail (result,status) ->
    # Just don't populate the thing
    console.error("Could not check SMS-ability",result,status)
  sms.always ->
    $("##{remove_id}").click ->
      html = "\n  <p id='totp_message' class='error'>Are you sure you want to disable two-factor authentication?</p>\n  <form id='totp_remove' onsubmit='event.preventDefault();'>\n    <fieldset>\n      <legend>Remove Two-Factor Authentication</legend>\n      <input type='email' value='#{user}' readonly='readonly' id='username' name='username'/><br/>\n      <input type='password' id='password' name='password' placeholder='Password'/><br/>\n      <input type='text' id='code' name='code' placeholder='Authenticator Code or Backup Code' size='32' maxlength='32' autocomplete='off'/><br/>\n      <button id='remove_totp_button' class='totpbutton btn btn-danger'>Remove Two-Factor Authentication</button>\n    </fieldset>\n  </form>\n"
      $("#totp_prompt")
      .html(html)
      .attr("id","totp_remove_section")
      $("#totp_remove").submit ->
        doTOTPRemove()
      $("#remove_totp_button").click ->
        doTOTPRemove()

verifyPhone = ->
  noSubmit()
  # Verify phone auth status
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  auth = if $("#phone_auth").val()? then $("#phone_auth").val() else null
  user = $("#username").val()
  args = "action=verifyphone&username=#{user}&auth=#{auth}"
  verifyPhoneAjax = $.get(apiUrlString,args,'json')
  verifyPhoneAjax.done (result) ->
    if result.status is false
      # If key "is_good" isn't true, display the error
      if not $("#phone_verify_message").exists()
        $("#phone").before("<p id='phone_verify_message'></p>")
      if result.is_good is true
        $("#verify_phone_button").remove()
        message = "You've already verified your phone number, thanks!"
        setClass = "good"
      else
        message = result.human_error
        setClass = "error"
        console.error(result.error)
      $("#phone_verify_message")
      .text(message)
      .addClass(setClass)
      if result.fatal is true
        $("#verify_phone_button").attr("disabled",true)
        $("#verify_phone")
        .unbind('submit')
        .attr("onsubmit","")
      return false
    # If status is true, continue
    if result.status is true
      # Create verification field after #username
      if not $("#phone_auth").exists()
        $("#username").after("<br/><input type='text' length='8' name='phone_auth' id='phone_auth' placeholder='Authorization Code'/>")
      if not $("#phone_verify_message").exists()
        $("#phone").before("<p id='phone_verify_message'></p>")
      $("#phone_verify_message").text(result.message)
      # Relabel
      if result.is_good isnt true
        $("#verify_phone_button").text("Confirm")
      else
        $("#phone_auth").remove()
        $("#verify_later").remove()
        $("#verify_phone_button")
        .html("Continue &#187; ")
        .unbind('click')
        .click ->
          window.location.href = window.totpParams.home
    else
      # Something broke
      console.warn("Unexpected condition encountered verifying the phone number",apiUrlString)
      console.log(result)
      return false
  verifyPhoneAjax.fail (result,status) ->
    # Update a status message
    console.error("AJAX failure trying to send phone verification text",apiUrlString + "?" + args)
    console.error("Returns:",result,status)

showInstructions = (path = "help/instructions_pop.html") ->
  $("<link/>",{
    rel:"stylesheet"
    type:"text/css"
    media:"screen"
    href:window.totpParams.popStylesheetPath
    }).appendTo("head")
  # Load the instructions
  $.get "#{window.totpParams.relative}#{path}"
  .done (html) ->
    $("#login_block").after(html)
    $("#login_block").addClass("blur")
    # Fill the images
    assetPath = "#{window.totpParams.relative}assets/"
    $(".android").html("<img src='#{assetPath}playstore.png' alt='Google Play Store'/>")
    $(".ios").html("<img src='#{assetPath}appstore.png' alt='iOS App Store'/>")
    $(".wp8").html("<img src='#{assetPath}wpstore.png' alt='Windows Phone Store'/>")
    $(".large_totp_icon").each ->
      newSource = assetPath + $(this).attr("src")
      $(this).attr("src",newSource)
    $(".app_link_container a").addClass("newwindow")
    mapNewWindows()
    $(".close-popup").click ->
      $("#login_block").removeClass("blur")
      $("#cover_wrapper").remove()
  .fail (result,status) ->
    console.error("Failed to load instructions @ #{path}",result,status)





showAdvancedOptions = (domain, has2fa) ->
  advancedListId = "advanced_options_list"
  if $("##{advancedListId}").exists()
    $("##{advancedListId}").toggle("fast")
    return true
  html = "<ul id='#{advancedListId}' class='advanced-account-options'>"
  twoFactorPhrase = if has2fa then "Configure" else "Add"
  twoFactorClass = if has2fa then "btn-warning" else "btn-success"
  optionsHtml = [
    # Change password
    "<li><button id='changePassword' class='btn btn-info change-password'>Change Password</button></li>"
    # Two factor
    "<li><a href='?2fa=t' role='button' class='btn #{twoFactorClass} configure-tfa btn-success'>#{twoFactorPhrase} Two-Factor Authentication</a></li>"
    # Account removal
    "<li><button id='removeAccount' role='button' class='btn btn-danger remove-account'>Remove Account</button></li>"
    ]
  html += optionsHtml.join("\n\t")
  html += "</ul>"
  $("#settings_list").after(html)
  $("#removeAccount").click ->
    removeAccount(this, "#{domain}_user", has2fa)
  $("#changePassword").click ->
    beginChangePassword()

removeAccount = (caller,cookie_key,has2fa = true) ->
  # We only grab the username from the cookie to prevent any chance
  # that anyone other than the current user is set up
  username = $.cookie(cookie_key)
  removal_button = "remove_acct_button"
  section_id = "remove_account_section"
  tfaBlock = if has2fa then "\n      <input type='text' id='code' name='code' placeholder='Authenticator Code or Backup Code' size='32' maxlength='32' autocomplete='off'/><br/>" else ""
  html = "<section id='#{section_id}'>\n  <p id='remove_message' class='error'>Are you sure you want to remove your account?</p>\n  <form id='account_remove' onsubmit='event.preventDefault();'>\n    <fieldset>\n      <legend>Remove My Account</legend>\n      <input type='email' value='#{username}' readonly='readonly' id='username' name='username'/><br/>\n      <input type='password' id='password' name='password' placeholder='Password'/><br/>#{tfaBlock}\n      <button id='#{removal_button}' class='totpbutton btn btn-danger'>Remove My Account Permanantly</button> <button onclick=\"window.location.href=totpParams.home\" class='btn btn-primary'>Back to Safety</button>\n    </fieldset>\n  </form>\n</section>"
  if $("#login_block").exists()
    $("#login_block").replaceWith(html)
  else
    $(caller).after(html)
  $("##{removal_button}").click ->
    doRemoveAccountAction()
  $("#account_remove").submit ->
    doRemoveAccountAction()

doRemoveAccountAction = ->
  # Actually do the POST and such
  animateLoad()
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  username = $("#username").val()
  password = $("#password").val()
  code = if $("#code").exists() then $("#code").val() else false
  args = "action=removeaccount&username=#{username}&password=#{password}&code=#{code}"
  $.post(apiUrlString,args,'json')
  .done (result) ->
    if result.status is true
      $("#remove_message").text("Your account has been successfully deleted.")
      # On success, wipe cookies
      $.each $.cookie(), (k,v) ->
        $.removeCookie(k,{ path: '/' })
      delay 3000,->
        window.location.href = window.totpParams.home
      stopLoad()
    else
      $("#remove_message").text("There was an error removing your account. Please try again.")
      console.error("Got an error-result: ",result.error)
      console.warn(apiUrlString + "?" + args,result)
      stopLoadError()
  .fail (result,status) ->
    $("#remove_message")
    .text(result.error)
    .addClass("error")
    $("totp_code").val("")
    console.error("Ajax Failure",apiUrlString + "?" + args,result,status)
    stopLoadError()

###########
# Async user creation
###########


noSubmit = ->
  event.preventDefault()
  event.returnValue = false

doAsyncLogin = (uri = apiUri.targetApi, respectRelativePath = true) ->
  noSubmit()
  if respectRelativePath
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + uri
  else
    apiUrlString = uri
  username = $("#username").val()
  password = $("#password").val()
  pass64 = Base64.encodeURI(password)
  args = "action=dologin&username=#{username}&password=#{pass64}&b64=true"
  # Submit and check the login request
  false

doAsyncCreate = ->
  recaptchaResponse = grecaptcha.getResponse()
  recaptchaTest = if typeof recaptchaResponse is "object" then recaptchaResponse.success isnt true else isNull(recaptchaResponse)
  if recaptchaTest
    # Bad CAPTCHA
    $("#createUser_submit").before("<p id='createUser_fail' class='alert bg-danger'>Sorry, your CAPTCHA was incorrect. Please try again.</p>")
    grecaptcha.reset()
    return false
  $("#createUser_fail").remove()
  # Submit the user creation
  console.info "Successfully called back the recaptcha response", recaptchaResponse
  if typeof recaptchaResponse is "string"
    $("#g-recaptcha-response").val recaptchaResponse
  true


###########
# Password Reset
###########



resetPassword = ->
  ###
  # Reset the user password
  ###
  # Remove the password field and replace the login button, rebind
  # events
  $("#password").remove()
  $("label[for='password']").remove()
  $("#reset-password-icon").remove()
  $(".alert").remove()
  $("#form_create_new_account").remove()
  $(".tooltip").remove()
  pane_messages = "reset-user-messages"
  unless $("##{pane_messages}").exists()
    $("#login").before("<div id='#{pane_messages}'></div>")
  $("##{pane_messages}")
  .removeClass("alert-danger alert-info")
  .addClass("alert alert-warning")
  .text("Once your password has been reset, your old password will be invalid.")
  url = apiUri.o
  ajaxLanding = apiUri.targetApi
  apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding
  checkButton = """
  <button class="btn btn-warning" id="check-login">Start Reset</button>
  """

  $("#login_button").replaceWith(checkButton)
  # Set up the bindings
  args = "action=startpasswordreset"
  multiOptionBinding = (pargs = args) ->
    $(".reset-pass-button")
    .unbind()
    .click ->
      totpValue = $("#totp").val()
      if totpValue?
        pargs += "&totp=#{totpValue}"
      method = $(this).attr("data-method")
      resetFormSubmit(pargs,method)
      false
    false
  # The wrapper function
  resetFormSubmit = (args, method) ->
    user = $("#username").val()
    unless args?
      args = "action=startpasswordreset&username=#{user}"
    animateLoad()
    $.get(apiUrlString,args,"json")
    .done (result) ->
      if result.status is false
        # Do stuff based on the action
        if isNull(result.human_error)
          # Make it REALLY not there, in case it's an empty string
          result.human_error = undefined
        console.log("Got requested action #{result.action}",result)
        console.log("Requested","#{apiUrlString}?#{args}")
        $("#username").prop("disabled",true)
        switch result.action
          when "GET_TOTP"
            # Replace and rebind form to get the TOTP value
            # If the user canSMS, then present that as a button option
            usedSms = false
            html = """
            <legend>Two-Factor Authentication</legend>
            <p><code>#{user}</code> has two-factor authentication enabled.</p>
            <div id='start-reset-process' class="totp">
              <div class="form-group">
                <label for="totp">Authentication Code:</label>
                <input type="number" class="form-control" id="totp" name="totp"/>
              </div>
            </div>
            <button class='reset-pass-button btn btn-danger' data-method='email'>
              Verify By Email
            </button>
            """
            if result.canSMS
              sms_id = "reset-user-sms-totp"
              text_html = "<button class='btn btn-primary' id='#{sms_id}'>Text Code</button>"
              $("#start-reset-process").after(text_html)
              $("##{sms_id}").click ->
                # Attempt to send the TOTP
                animateLoad()
                smsArgs = "action=sendtotptext&user=#{user}"
                sms_totp = $.get(apiUrlString,smsArgs,'json')
                console.log("Sending message ...",apiUrlString+"?"+args)
                sms_totp.done (result) ->
                  if result.status is true
                    # Alert the user
                    $("##{pane_messages}")
                    .text("Your code has been sent to your registered number.")
                    .removeClass("alert-warning alert-danger")
                    .addClass("alert-info")
                    usedSms = true
                    newButton = """
                    <button class="reset-pass-button btn btn-danger" data-method="email">
                      Verify by SMS
                    </button>
                    """
                    $("##{sms_id}").replaceWith(newButton)
                    multiOptionBinding(args)
                  else
                    #Place a notice in pane_messages
                    $("##{pane_messages}")
                    .addClass("alert-danger")
                    .text(result.human_error)
                    console.error(result.error)
                sms_totp.fail (result,status) ->
                  $("##{pane_messages}")
                  .addClass("alert-danger")
                  .text("There was a problem sending your text. Please try again.")
                  console.error("AJAX failure trying to send TOTP text",apiUrlString + "?" + args)
                  console.error("Returns:",result,status)
                sms_totp.always ->
                  stopLoad()
            $("#login")
            .replaceWith(html)
            .unbind()
            .submit ->
              noSubmit()
              doTotpSubmission()
            multiOptionBinding(args)
            return false
          when "NEED_METHOD"
            # Draw a button to send a text AND button to email
            html = "<p>Resetting password for <code>#{user}</code></p>"
            if result.canSMS and usedSms isnt true
              # Show an option to get a text reset password
              html = "<button class='reset-pass-button btn btn-danger' data-method='sms'>Verify by SMS</button>"
              false
            html += """
            <button class='reset-pass-button btn btn-danger' data-method='email'>
              Verify by Email
            </button>
            """
            $("#login").replaceWith(html)
            multiOptionBinding(args)
            return false
          when "BAD_USER"
            # Bad user
            $("##{pane_messages}")
            .addClass("alert-danger")
            .text("Sorry, that user doesn't exist.")
            $("#username")
            .prop("disabled",false)
            .val("")
            return false
          else
            text = result.human_error ? "There was a problem resetting your password. Please try again"
            $("##{pane_messages}")
            .addClass("alert-danger")
            .removeClass("alert-info alert-warning")
            .text(text)
            console.error("Illegal state!")
            console.warn(result)
            return false
      ## End all the bad results.
      else
        # Otherwise, it's good, and an email has been sent
        console.log("Got a good result.")
        console.log(result)
        $(".form-group").remove()
        doManualEntry = ->
          # Initiating manual entry
          altEntry = """
          <legend>Verify Reset</legend>
          <div class="form-group">
            <label for="verify">Verification Token:</label>
            <input type="text" class="form-control" id="verify" name="verify" />
          </div>
          <div class="form-group">
            <label for="key">Key:</label>
            <input type="text" class="form-control" id="key" name="key" />
          </div>
          <input type="hidden" id="username" name="username" value="#{user}" />
          <button class="btn btn-success" id="verify-now">Verify Now</button>
          """
          $("#login")
          .html(altEntry)
          .unbind()
          .submit ->
            noSubmit()
            finishPasswordResetHandler()
          $("#verify-now").click ->
            finishPasswordResetHandler()
        # Method check
        if method is "email" or not method?
          $("##{pane_messages}")
          .removeClass("alert-warning alert-danger")
          .addClass("alert-info")
          .text("Check your email for your reset link. Once you've clicked that, your password will be reset.")
          altEntryButton = "<button class='btn btn-default' id='manual-input'>Manually Input Verification</button>"
          $("#check-login").replaceWith(altEntryButton)
          $("#manual-input").click ->
            doManualEntry()
        if method is "sms"
          doManualEntry()
      stopLoad()
      false
    .fail (result,status) ->
      stopLoadError()
      $("##{pane_messages}")
      .removeClass("alert-info alert-warning")
      .addClass("alert-danger")
      .text("We couldn't process the password reset. Please try again.")
      false
  # End the major wrpaper function
  # Bind the clicks
  $("#login")
  .unbind()
  .submit ->
    noSubmit()
    resetFormSubmit()
  $("#check-login")
  .unbind()
  .click ->
    noSubmit()
    resetFormSubmit()


finishPasswordResetHandler = ->
  ###
  # Read the URL params, then do the async call
  #
  #
  ###
  verify = ""
  key = ""
  if $("input#verify").exists()
    verify = $("input#verify").val().trim()
    key = $("input#key").val().trim()
    username = $("input#username").val()
  else
    # Check the globals
    verify = window.resetParams.verify
    key = window.resetParams.key
    username = window.resetParams.user
    if isNull(verify)
      # Last-ditch -- if one isn't there, none are
      verify = apiUri.o.param("verify")
      key = apiUri.o.param("key")
      username = apiUri.o.param("user")
    html = """
    <h1>Password Reset Confirmation</h1>
    <div id='login'></div>
    """
    $("body").append(html)
  if isNull(verify) or isNull(key)
    if $(".alert").exists()
      $(".alert").remove()
    html = """
    <div class="alert alert-danger">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      <strong>Yikes!</strong> We need both the verification token and key to continue resetting your password.
    </div>
    """
    $("#login").before(html)
    $(".alert").alert()
    return false
  # We have what we need, post it
  args = "action=finishpasswordreset&key=#{key}&verify=#{verify}&username=#{username}"
  $.post(apiUri.apiTarget, args, "json")
  .done (result) ->
    unless result.verification_data?
      result.verification_data = true
    unless result.status and result.verification_data
      if $(".alert").exists()
        $(".alert").remove()
      if result.error is "Invalid credentials - Invalid reset tokens"
        result.human_error += "<br/><br/>Remember, your reset link is only good for <strong>one</strong> reset. If you've already used that link, you'll need to generate another"
      html = """
      <div class="alert alert-danger">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <strong>There was a problem resetting your password.</strong> #{result.human_error} We suggest <a href="#{apiUri.urlString}" class="alert-link">going back</a> and trying again.
      </div>
      """
      $("#login").before(html)
      $(".alert").alert()
      console.error "Problem resetting password! Server said #{result.error}"
      console.warn result
      return false
    # It worked! Show them the new password.
    html = """
    <div class="alert alert-success">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      <strong>Your password has been successfully reset</strong> Your new password is <input type="text" value="#{result.new_password}" class="form-control form-inline code" readonly />. Write this down! You will NOT be able to generate or see this password again.<br/><br/>When you're done, <a href="#{apiUri.urlString}" class="alert-link">return to the login page</a> and log in with your new password.
    </div>
    """
    $("#login").replaceWith(html)
    $(".alert").alert()
    false
  .fail (result) ->
    html = """
    <div class="alert alert-danger">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      <strong>Yikes!</strong> We had a problem checking the server. Try again later.
    </div>
    """
    $("#login").before(html)
    $(".alert").alert()
    console.error("Couldn't communicate with server! Tried to contact","#{apiUri.apiTarget}?#{args}")
    false
  .always ->
    $(".do-refresh-page").click ->
      document.location.reload(true)
  false

###########
# Password Changing
###########



beginChangePassword = ->
  cookie = "#{window.totpParams.domain}_user"
  username = $.cookie(cookie)
  changePasswordForm = """
  <form class='change-password-form form-horizontal'>
    <fieldset>
      <legend>Change Password</legend>
      <div class="form-group">
        <label for="old-password" class="col-sm-2 control-label">Old Password</label>
        <div class="col-sm-4">
          <input type="password" class="form-control old-password" id="old-password" placeholder="Old Password" required="required"/>
        </div>
      </div>
      <div class="new-password-group">
        <div class="form-group">
          <label for="new-password" class="col-sm-2 control-label">New Password</label>
          <div class="col-sm-4 has-feedback">
            <input type="password" class="form-control new-password" id="new-password" placeholder="New Password" required="required"/>
            <span id="feedback-status-1"></span>
          </div>
        </div>
        <div class="form-group">
          <label for="new-password-confirm" class="col-sm-2 control-label">Confirm New Password</label>
          <div class="col-sm-4 has-feedback">
            <input type="password" class="form-control new-password" id="new-password-confirm" placeholder="Confirm New Password" required="required"/>
            <span id="feedback-status-2"></span>
          </div>
        </div>
      </div>
      <div id="password_security" class="pull-right col-sm-5 password-reqs hidden-xs"></div>
      <button id="do-change-password" class="btn btn-primary col-sm-offset-2" disabled>Change Password for<br/> #{username}</button>
    </fieldset>
  </form>
  """
  $("#account_settings").after changePasswordForm
  loadJS(window.totpParams.relative+"js/zxcvbn/zxcvbn.min.js")
  checkFirstPassword = ->
    try
      checkPasswordLive("#do-change-password", "#new-password", "#new-password-confirm")
    catch e
      console.error "Couldn't check password requirements! #{e.message}"
      console.warn e.stack
  $("#new-password")
  .keyup ->
    checkFirstPassword()
  .change ->
    checkFirstPassword()
  $("#new-password-confirm")
  .change ->
    checkMatchPassword("#do-change-password", "#new-password", "#new-password-confirm")
  .keyup ->
    checkMatchPassword("#do-change-password", "#new-password", "#new-password-confirm")
  $(".change-password-form input")
  .blur ->
    checkFirstPassword()
  # Bind the actual setter
  $("#do-change-password").click ->
    $(this).prop("disabled",true)
    # Submit it to the async target
    args = "action=changepassword&old_password=#{encodeURIComponent($("#old-password").val())}&new_password=#{encodeURIComponent($("#new-password").val())}&username=#{encodeURIComponent(username)}"
    $.post apiUri.apiTarget, args, "json"
    .done (result) ->
      if result.status is false or result.action isnt "changepassword"
        if result.action isnt "changepassword"
          result.error = "mismatched mode result"
          result.human_error = "The server gave a nonsensical response. Your original password is still valid."
        unless result.human_error?
          result.human_error = "The server had an unexpected error"
        errorHtml = """
  <div class="alert alert-danger center-block fade in" role="alert">
    <strong>Couldn't update password</strong> #{result.human_error}
  </div>
        """
        $("#do-change-password").before(errorHtml)
        $("#do-change-password").prop("disabled",false)
        console.error "Couldn't update password! Server said #{result.error}"
        console.warn result
        return false
      # It worked
      successHtml = """
  <div class="alert alert-success center-block fade in" role="alert">
    <strong>Password Changed</strong> Your password has been successfully updated. <a class="alert-link" id="refresh-page" style="cursor:pointer">Click here to refresh now</a> - you may have to log back in, using your new password.
  </div>
      """
      $(".change-password-form").replaceWith(successHtml)
      $("#refresh-page").click ->
        document.location.reload(true)
      false
    .fail (result, status) ->
      errorHtml = """
<div class="alert alert-danger center-block fade in" role="alert">
  <strong>Couldn't update password</strong> There was a problem communicating with the server. Please try again later.
</div>
      """
      $("#do-change-password").replaceWith(errorHtml)
      console.error "AJAX failure to change password!"
      console.warn "Got", result, status
  false


finishChangePassword = ->
  false


$ ->
  needStylesheetImport = true
  $("link[rel='stylesheet']").each ->
    if $(this).attr("href").search "bootstrap.min.css" isnt -1
      needStylesheetImport = false
      return false
  if needStylesheetImport
    bootstrapCSS = """
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" />
    """
    $("head").append bootstrapCSS
  if not window.passwords.submitSelector?
    selector = "#createUser_submit"
  else
    selector = window.passwords.submitSelector
  if $("#password.create").exists()
    loadJS(window.totpParams.relative+"js/zxcvbn/zxcvbn.min.js")
    $("#password.create")
    .keyup ->
      checkPasswordLive()
    .change ->
      checkPasswordLive()
    $("#password2")
    .change ->
      checkMatchPassword()
    .keyup ->
      checkMatchPassword()
    $("input")
    .addClass("form-control")
    .parent().addClass("form-inline")
    .blur ->
      checkPasswordLive()
    $("#password")
    .after("<span id='feedback-status-1'></span>")
    .parent().removeClass("form-inline")
    .parent().addClass("has-feedback")
    .parent().addClass("form-horizontal")
    $("#password2")
    .after("<span id='feedback-status-2'></span>")
    .parent().removeClass("form-inline")
    .parent().addClass("has-feedback")
    .parent().addClass("form-horizontal")
  $("#totp_submit").submit ->
    doTOTPSubmit()
  $("#verify_totp_button").click ->
    doTOTPSubmit()
  $("#totp_start").submit ->
    makeTOTP()
  $("#add_totp_button").click ->
    makeTOTP()
  $("#totp_remove").submit ->
    doTOTPRemove()
  $("#remove_totp_button").click ->
    doTOTPRemove()
  $("#alternate_verification_prompt").click ->
    giveAltVerificationOptions()
    return false
  $("#verify_phone").submit ->
    verifyPhone()
  $("#verify_phone_button").click ->
    verifyPhone();
  $("#verify_later").click ->
    window.location.href = window.totpParams.home
  $("#totp_help").click ->
    showInstructions()
  $("#showAdvancedOptions").click ->
    domain = $(this).attr('data-domain')
    has2fa = if $(this).attr("data-user-tfa") is 'true' then true else false
    showAdvancedOptions(domain,has2fa)
  $(".do-password-reset").click ->
    resetPassword()
    false
  try
    # Use the CDN out of an abundance of caution
    loadJS "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js", ->
      try
        if apiUri.o.param("showhelp")? then showInstructions()
      catch e
        delay 300, ->
          if apiUri.o.param("showhelp")? then showInstructions()
      $(".do-password-reset").unbind()
      try
        $("#reset-password-icon").tooltip()
      catch e
        console.warn("Couldn't tooltip the forgotten password icon!")
      $(".do-password-reset")
      .click ->
        resetPassword()
        false
      try
        $(".alert").alert()
      catch e
        console.warn("Couldn't bind alert!")
  catch e
    console.log("Couldn't tooltip icon!")
  try
    if apiUri.o.param("showhelp")? then showInstructions()
  catch e
    delay 300, ->
      if apiUri.o.param("showhelp")? then showInstructions()
  try
    if window.checkPasswordReset is true
      finishPasswordResetHandler()
  catch e
    console.error("Couldn't check password reset state! #{e.message}")
  $("#next.continue").click ->
    window.location.href = window.totpParams.home
  # Load stylesheets
  $("<link/>",{
    rel:"stylesheet"
    type:"text/css"
    media:"screen"
    href:window.totpParams.combinedStylesheetPath
    }).appendTo("head")
