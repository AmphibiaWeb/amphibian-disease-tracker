###
# Debug log helper.
# Assumes Bootstrap styles/js are included (as well as a bunch of my
# standard stuff)
#
# Displayed elements are from the Polymer project
###

enableDebugLogging = ->
  ###
  # Overwrite console logs with custom events
  ###
  if window.debugLoggingEnabled
    return false
  if localStorage?.debugLog?
    try
      logHistory = JSON.parse localStorage.debugLog
      window._debug = logHistory
      console.info "Restored log history to local object"
    catch
      console.warn "Unable to restore log history"
      window._debug = new Array()
  else
    window._debug = new Array()
  window.sysConsole = console
  window.sysLog = console.log
  window.sysInfo = console.info
  window.sysWarn = console.warn
  window.sysError = console.error
  window.sysDebug = console.debug
  console.debug = (args...) ->
    messageObject =
      callType: "debug"
      arguments: args
    _debug.push messageObject
    sysDebug.apply console, arguments
    backupDebugLog true
  console.log = (args...) ->
    messageObject =
      callType: "log"
      arguments: args
    _debug.push messageObject
    sysLog.apply console, arguments
    backupDebugLog true
  console.info = (args...) ->
    messageObject =
      callType: "info"
      arguments: args
    _debug.push messageObject
    sysInfo.apply console, arguments
    backupDebugLog true
  console.warn = (args...) ->
    messageObject =
      callType: "warn"
      arguments: args
    _debug.push messageObject
    sysWarn.apply console, arguments
    backupDebugLog true
  console.error = (args...) ->
    messageObject =
      callType: "error"
      arguments: args
    _debug.push messageObject
    sysError.apply console, arguments
    backupDebugLog true
  # Page navigation event
  $(window).on "popstate", (ev) ->
    console.log "Navigation event"
    false
  $(window).unload (ev) ->
    console.log "unload event"
    false
  $("#debug-reporter").remove()
  html =  """
  <paper-fab id="debug-reporter" icon="icons:send" data-toggle="tooltip" title="Send Debug Report" elevation="5">
  </paper-fab>
  """
  $("body").append html
  css = """
  <style type="text/css">
    #debug-reporter {
      background: #F44336;
      color: #fff!important;
      position: fixed;
      right: 1rem;
      bottom: 1rem;
      cursor: pointer;
    }
  </style>
  """
  $("#debug-reporter").before css
  $("#debug-reporter").click ->
    reportDebugLog()
  window.debugLoggingEnabled = true
  try
    p$(".debug-enable-context").disabled = true
  backupDebugLog()
  false


backupDebugLog = (suppressMessage = false)->
  ###
  # Saves the debug log to local storage
  ###
  if localStorage? and window._debug?
    unless suppressMessage
      console.info "Saving backup of debug log"
    try
      logHistory = JSON.stringify window._debug
      localStorage.debugLog = logHistory
    catch e
      sysError.apply console, ["Unable to backup debug log! #{e.message}", window._debug]
  false

window.enableDebugLogging = enableDebugLogging


disableDebugLogging = ->
  ###
  # Disable debug logging and replace bindings for system calls.
  ###
  if localStorage?.debugLog?
    delete localStorage.debugLog
    delete _debug
  if typeof window.sysLog is "function"
    console.log = sysLog
    console.info = sysInfo
    console.warn = sysWarn
    console.error = sysError
    console.debug = sysDebug
  $("#debug-reporter").remove()
  window.debugLoggingEnabled = false
  try
    p$(".debug-disable-context").disabled = true
  false


window.disableDebugLogging = disableDebugLogging


reportDebugLog = ->
  ###
  # Render the modal dialog to enable sending reports
  ###
  if window._debug?
    # disableDebugLogging()
    backupDebugLog()
    console.info "Opening debug reporter"
    # Show an email dialog
    getModalContents = ->
      modalContents = """
          <div>
            <p>Copy the text below</p>
            <textarea readonly rows="10" class="form-control">
              #{localStorage.debugLog}
            </textarea>
            <br/><br/>
            <p>And email it to <a href="mailto:support@velociraptorsystems.com?subject=Debug%20Log">support@velociraptorsystems.com</a></p>
          </div>
      """
      modalContents
    html = """
    <paper-dialog modal id="report-bug-modal">
      <h2>Bug Report</h2>
      <paper-dialog-scrollable>
        #{getModalContents()}
      </paper-dialog-scrollable>
      <div class="buttons">
        <paper-button dialog-dismiss>Close</paper-button>
      </div>
    </paper-dialog-modal>
    """
    $("#report-bug-modal").remove()
    $("body").append html
    try
      safariDialogHelper("#report-bug-modal")
    catch e
      console.warn "Warning -- couldn't use safariDialogHelper to open. Some browsers may have an issue seeing this alert. (#{e.message})"
      console.debug e.stack
      try
        try
          p$("#report-bug-modal").open()
        catch e1
          console.warn "Couldn't use p$ to show modal, trying direct ... (#{e1.message})"
          document.querySelector("#report-bug-modal").open()
        visibleTestTime = 3000
        delay visibleTestTime, ->
          if not $("#report-bug-modal").isVisible()
            errObj = ->
              this.message = "Modal failed visibility test at #{visibleTestTime}ms"
              this.name = "InvisibleModalError"
            throw errObj
      catch e2
        console.error "Unable to show bug report modal! #{e2.message}"
        console.warn e2.stack
        try
          bsAlert getModalContents()
        catch e3
          console.error "Couldn't show fallback bsAlert! #{e3.message}"
          console.warn e3.stack
          try
            startLoad()
            stopLoadError "Unable to show bug report modal!"
          catch e4
            console.error "Couldn't alert user to the problem! #{e4.message}"
            console.warn e3.stack
  false

window.reportDebugLog = reportDebugLog













###
# This file should be modular. Set up helper functions.
#
# This should NEVER overwrite the real versions, so we'll do these
# checks on a delay (except the delay helper)
###

unless typeof delay is "function"
  delay = (ms,f) -> setTimeout(f,ms)

delay 100, ->
  # $.isVisible()
  unless typeof jQuery?.fn?.isVisible is "function"
    jQuery.fn.isVisible = ->
      jQuery(this).is(":visible") and jQuery(this).css("visibility") isnt "hidden"
  # $.exists()
  unless typeof jQuery?.fn?.exists is "function"
    jQuery.fn.exists = -> jQuery(this).length > 0
  # Polymer selector
  unless typeof p$ is "function"
    p$ = (selector) ->
      # Try to get an object the Polymer way, then if it fails,
      # do jQuery
      try
        $$(selector)[0]
      catch
        $(selector).get(0)
  # isNull
  unless typeof isNull is "function"
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
  # Hanging bootstrap alert
  unless typeof bsAlert is "function"
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
      css = """
      <style type="text/css">
        .hanging-alert {
          position: fixed;
          top: 0;
          width: 50%;
          margin: 0;
          left: 25%;
          z-index: 5999;
        }
      </style>
      """
      $(selector).before css
      bindClicks()
      mapNewWindows()
      false
    ## Children of bsAlert
    # openTab
    unless typeof openTab is "function"
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
    # mapNewWindows
    unless typeof mapNewWindows is "function"
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
    # bindClicks
    unless typeof bindClicks is "function"
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
        false
  unless typeof Function.debounce is "function"
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
      func = this
      delayed = ->
        func.apply(func, args) unless execAsap
        #console.info("Debounce applied")
      try
        if core.debouncers[key]?
          timeout = core.debouncers[key]
      if timeout?
        try
          clearTimeout(timeout)
        catch e
          # just do nothing
      if execAsap
        func.apply(obj, args)
        console.log("Executed #{key} immediately")
        return false
      if key?
        #console.log "Debouncing '#{key}' for #{threshold} ms"
        core.debouncers[key] = delay threshold, ->
          delayed()
      else
        #console.log "Delaying '#{key}' for #{threshold} ms"
        window.debounce_timer = delay threshold, ->
          delayed()








##############################
# Setup events
##############################
window.debugScriptSetup = false
$ ->
  do bootstrapDebugSetup = ->
    window.debugScriptSetup = true
    if localStorage?.debugLog?
      window.debugLoggingEnabled = true
      enableDebugLogging()
    else
      window.debugLoggingEnabled = false

  do setupContext = (count = 0) ->
    unless Polymer?.RenderStatus?._ready
      if Polymer?
        if count > 20
          waited = count * 500
          console.warn "Fake it till you make it -- after waiting #{waited}ms, we're going to pretend Polymer is ready"
          try
            Polymer.RenderStatus._ready = true
      else
        if count > 20
          # Insert Polymer components
          try
            console.warn "Inserting Polymer components into DOM"
            preurl = "https://cdn.rawgit.com/download/polymer-cdn/1.5.0/lib"
            html = """
            <script src="#{preurl}/webcomponentsjs/webcomponents-lite.min.js"></script>
            <link rel="import" href="#{preurl}/polymer/polymer.html"/>
            <link rel="import" href="#{preurl}/paper-spinner/paper-spinner.html"/>
            <link rel="import" href="#{preurl}/paper-menu/paper-menu.html"/>
            <link rel="import" href="#{preurl}/paper-material/paper-material.html"/>
            <link rel="import" href="#{preurl}/paper-dialog/paper-dialog.html"/>
            <link rel="import" href="#{preurl}/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
            <link rel="import" href="#{preurl}/paper-button/paper-button.html"/>
            <link rel="import" href="#{preurl}/paper-icon-button/paper-icon-button.html"/>
            <link rel="import" href="#{preurl}/paper-fab/paper-fab.html"/>
            <link rel="import" href="#{preurl}/paper-item/paper-item.html"/>
            <link rel="import" href="#{preurl}/iron-icons/iron-icons.html"/>
            <link rel="import" href="#{preurl}/iron-icons/image-icons.html"/>
            <link rel="import" href="#{preurl}/iron-icons/social-icons.html"/>
            <link rel="import" href="#{preurl}/iron-icons/editor-icons.html"/>
            <link rel="import" href="#{preurl}/neon-animation/neon-animation.html"/>
            </
            """
            $("head").append html
            count = -2
          catch e
            console.error "Unable to insert Polymer into DOM (#{e.message})"
      console.warn "Delaying context until Polymer.RenderStatus is ready"
      delay 500, ->
        count++
        setupContext(count)
      return false
    console.info "Setting up context events"
    $("paper-icon-button[icon='icons:bug-report']").contextmenu (event) ->
      doShowBugReportContext.debounce null, null, null, this, event
      false
    # Types of elements that are allowed to be bug reports
    allowedBugReportElements = [
      "paper-button"
      "button"
      ]
    for tagType in allowedBugReportElements
      # If the element has a child that is contains a bug-report icon,
      # enable this feature.
      $(tagType).find("[icon='icons:bug-report']").parents(tagType).contextmenu (event) ->
        doShowBugReportContext.debounce null, null, null, this, event
        false
    # The helper function
    doShowBugReportContext = (clickedElement, event) ->
      event.preventDefault()
      console.info "Showing bug report context menu"
      html = """
      <paper-material class="bug-report-context-wrapper" style="top:#{event.pageY}px;left:#{event.pageX}px;position:absolute">
        <paper-menu class=context-menu">
          <paper-item class="debug-enable-context" data-fn="enableDebugLogging">
            Enable debug reporting
          </paper-item>
          <paper-item class="debug-disable-context" data-fn="disableDebugLogging">
            Disable debug reporting
          </paper-item>
        </paper-menu>
      </paper-material>
      """
      $(".bug-report-context-wrapper").remove()
      $("body").append html
      inFn = (el) ->
        $(clickedElement).addClass "iron-selected"
        false
      outFn = (el) ->
        $(clickedElement).removeClass "iron-selected"
        false
      $(".bug-report-context-wrapper paper-item")
      .hover inFn, outFn
      .click ->
        fn = $(clickedElement).attr "data-fn"
        # window[fn]()
        false
      $(".debug-enable-context").click ->
        enableDebugLogging()
      $(".debug-disable-context").click ->
        disableDebugLogging()
      if window.debugLoggingEnabled
        try
          p$(".debug-enable-context").disabled = true
      else
        try
          p$(".debug-disable-context").disabled = true
      delay 5000, ->
        $(".bug-report-context-wrapper").remove()
  window.setupDebugContext = ->
    console.log "**** Debug Context Events Enabled ***"
    bootstrapDebugSetup()
    setupContext()
    true
  try
    setupDebugContext()
