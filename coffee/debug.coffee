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
    catch
      window._debug = new Array()
  else
    window._debug = new Array()
  sysConsole = console
  window.sysLog = console.log
  window.sysInfo = console.info
  window.sysWarn = console.warn
  window.sysError = console.error
  console.log = (args...) ->
    messageObject =
      callType: "log"
      arguments: args
    _debug.push messageObject
    sysLog args...
  console.info = (args...) ->
    messageObject =
      callType: "info"
      arguments: args
    _debug.push messageObject
    sysInfo args...
  console.warn = (args...) ->
    messageObject =
      callType: "warn"
      arguments: args
    _debug.push messageObject
    sysWarn args...
  console.error = (args...) ->
    messageObject =
      callType: "error"
      arguments: args
    _debug.push messageObject
    sysError args...
  # Page navigation event
  $(window).on "popstate", ->
    if localStorage?
      logHistory = JSON.stringify _debug
      localStorage.debugLog = logHistory
    false
  window.debugLoggingEnabled = true
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
    console.info "Your log history:", _debug
  false

window.reportDebugLog = reportDebugLog


$ ->
  window.debugLoggingEnabled = false
  if localStorage?.debugLog?
    enableDebugLogging()
