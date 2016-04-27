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
  if localStorage?
    console.info "Saving backup of debug log"
    try
      logHistory = JSON.stringify window._debug
    catch
      console.error "Unable to backup debug log!"
    localStorage.debugLog = logHistory
  false

window.enableDebugLogging = enableDebugLogging


disableDebugLogging = ->
  if localStorage?.debugLog?
    delete localStorage.debugLog
  if typeof window.sysLog is "function"
    console.log = sysLog
    console.info = sysInfo
    console.warn = sysWarn
    console.error = sysError
  false


window.disableDebugLogging = disableDebugLogging


reportDebugLog = ->
  if window._debug?
    disableDebugLogging()
    console.info "Your log history:", _debug
  false

window.reportDebugLog = reportDebugLog


$ ->
  window.debugLoggingEnabled = false
  if localStorage?.debugLog?
    enableDebugLogging()
