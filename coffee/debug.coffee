###
#
###

enableDebugLogging = ->
  ###
  # Overwrite console logs with custom events
  ###
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
  console.log = (args...) ->
    messageObject =
      callType: "log"
      arguments: args
    _debug.push messageObject
    sysLog.apply console, arguments
  console.info = (args...) ->
    messageObject =
      callType: "info"
      arguments: args
    _debug.push messageObject
    sysInfo.apply console, arguments
  console.warn = (args...) ->
    messageObject =
      callType: "warn"
      arguments: args
    _debug.push messageObject
    sysWarn.apply console, arguments
  console.error = (args...) ->
    messageObject =
      callType: "error"
      arguments: args
    _debug.push messageObject
    sysError console, arguments
  # Page navigation event
  $(window).on "popstate", (ev) ->
    sysConsole.log "Navigation event", ev
    backupDebugLog()
    false
  $(window).unload (ev) ->
    sysConsole.log "unload event", ev
    backupDebugLog()
    false
  window.debugLoggingEnabled = true
  false


backupDebugLog = ->
  if localStorage? and window._debug?
    console.info "Saving backup of debug log"
    try
      logHistory = JSON.stringify window._debug
      localStorage.debugLog = logHistory
    catch e
      console.error "Unable to backup debug log! #{e.message}", window._debug
  false

window.enableDebugLogging = enableDebugLogging


disableDebugLogging = ->
  if localStorage?.debugLog?
    delete localStorage.debugLog
    delete _debug
  if typeof window.sysLog is "function"
    console.log = sysLog
    console.info = sysInfo
    console.warn = sysWarn
    console.error = sysError
  false


window.disableDebugLogging = disableDebugLogging


reportDebugLog = ->
  if window._debug?
    # disableDebugLogging()
    backupDebugLog()
    logOutput = JSON.stringify _debug
    # console.info "Your log history:", _debug
    # Show an email dialog
    html = """
    <paper-dialog modal id="report-bug-modal">
      <h2>Bug Report</h2>
      <paper-dialog-scrollable>
        <div>
          <p>Copy the text below</p>
          <textarea readonly rows="10">
            #{localStorage.debugLog}
          </textarea>
          <p>And email it to <a href="mailto:support@velociraptorsystems.com?subject=Debug%20Log">support@velociraptorsystems.com</a></p>
        </div>
      </paper-dialog-scrollable>
      <div class="buttons">
        <paper-button>Close</paper-button>
      </div>
    </paper-dialog-modal>
    """
    $("#report-bug-modal").remove()
    $("body").append html
    p$("#report-bug-modal").open()
  false

window.reportDebugLog = reportDebugLog


$ ->
  window.debugLoggingEnabled = false
  if localStorage?.debugLog?
    enableDebugLogging()
