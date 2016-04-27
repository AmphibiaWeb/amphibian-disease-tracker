###
#
###

enableDebugLogging = ->
  ###
  # Overwrite console logs with custom events
  ###
  window._debug = new Array()
  sysConsole = console
  sysLog = console.log
  sysInfo = console.info
  sysWarn = console.warn
  sysError = console.error
  console.log = (args...) ->
    messageObject =
      callType: "log"
      arguments: args
    _debug.push messageObject
    sysLog args
  console.info = (args...) ->
    messageObject =
      callType: "info"
      arguments: args
    _debug.push messageObject
    sysInfo args
  console.warn = (args...) ->
    messageObject =
      callType: "warn"
      arguments: args
    _debug.push messageObject
    sysWarn args
  console.error = (args...) ->
    messageObject =
      callType: "error"
      arguments: args
    _debug.push messageObject
    sysError args
  false

window.enableDebugLogging = enableDebugLogging
