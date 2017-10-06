###
# Split-out coffeescript file for data validation.
# This file contains async validation code to check entries.
#
# This is included in ./js/admin.js via ./Gruntfile.coffee
#
# For administrative functions for project creation, editing, or
# viewing, check ./coffee/admin.coffee, ./coffee/admin-editor.coffee,
# and ./coffee/admin-viewer.coffee (respectively).
#
# @path ./coffee/admin-validation.coffee
# @author Philip Kahn
###

unless typeof window.validationMeta is "object"
  window.validationMeta = new Object()



validateData = (dataObject, callback = null) ->
  ###
  #
  ###
  _adp.validationDataObject = dataObject
  console.info "Doing nested validation"
  timer = Date.now()
  renderValidateProgress()
  validateFimsData dataObject, ->
    validateTaxonData dataObject, ->
      # When we're successful, run the dependent callback
      elapsed = Date.now() - timer
      console.info "Validation took #{elapsed}ms", dataObject
      cleanupToasts()
      toastStatusMessage "Your dataset has been successfully validated"
      if typeof callback is "function"
        callback(dataObject)
      else
        console.warn "validateData had no defined callback!"
        console.info "Got back", dataObject
  false



stopLoadBarsError = (currentTimeout, message) ->
  unless $("#validator-progress-container:visible").exists()
    ex = ->
      this.message = "Loading bars aren't visible!"
      this.name = "BadLoadState"
    throw new ex()
  if typeof currentTimeout is "string" and isNull message
    message = currentTimeout
  try
    clearTimeout currentTimeout
  $("#validator-progress-container paper-progress[indeterminate]")
  .addClass "error-progress"
  .removeAttr "indeterminate"
  others = $("#validator-progress-container paper-progress:not([indeterminate])")
  for el in others
    try
      if p$(el).value isnt p$(el).max
        $(el).addClass "error-progress"
        $(el).find("#primaryProgress").css "background", "#F44336"
  if message?
    bsAlert "<strong>Data Validation Error</strong>: #{message}", "danger"
    stopLoadError null, "There was a problem validating your data"
  try
    $("#cancel-new-upload").remove()
  false


delayFimsRecheck = (originalResponse, callback) ->
  cookies = encodeURIComponent originalResponse.responses.login_response.cookies
  args = "perform=validate&auth=#{cookies}"
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Server said", result
    if typeof callback is "function"
      callback()
    else
      console.warn "Warning: delayed recheck had no callback"
  .fail (result, status) ->
    console.error "#{status}: Couldn't check status on FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadBarsError null, "There was a problem validating your data, please try again later"
  false


validateFimsData = (dataObject, callback = null) ->
  ###
  #
  #
  # @param Object dataObject -> object with at least one key, "data",
  #  containing the parsed data to be validated by FIMS
  # @param function callback -> callback function
  ###
  unless typeof _adp?.fims?.expedition?.expeditionId is "number"
    if _adp.hasRunMintCallback is true
      console.error "Couldn't run validateFimsData(); called itself back recursively. There may be a problem with the server. "
      stopLoadBarsError null, "Couldn't generate an ARK for your data, please try again later (couldn't communicate with the FIMS server)"
      _adp.hasRunMintCallback = false
      return false
    _adp.hasRunMintCallback = false
    console.warn "Haven't minted expedition yet! Minting that first"
    mintExpedition _adp.projectId, p$("#project-title").value, ->
      _adp.hasRunMintCallback = true
      validateFimsData(dataObject, callback)
    return false
  console.info "FIMS Validating", dataObject.data
  $("#data-validation").removeAttr "indeterminate"
  rowCount = Object.size dataObject.data
  try
    p$("#data-validation").max = rowCount * 2
  # Set an animation timer
  timerPerRow = 20
  validatorTimeout = null
  do animateProgress = ->
    try
      val = p$("#data-validation").value
    catch
      # Probably revalidating ...
      return false
    if val >= rowCount
      # Stop the animation
      clearTimeout validatorTimeout
      return false
    ++val
    try
      p$("#data-validation").value = val
    catch
      return false
    validatorTimeout = delay timerPerRow, ->
      animateProgress()
  # Format the JSON for FIMS
  data = jsonTo64 dataObject.data
  src = post64 dataObject.dataSrc
  args = "perform=validate&datasrc=#{src}&link=#{_adp.projectId}"
  # Post the object over to FIMS
  console.info "Posting ...", "#{uri.urlString}#{adminParams.apiTarget}?#{args}"
  _adp.currentAsyncJqxhr = $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
  .done (result) ->
    console.log "FIMS validate result", result
    unless result.status is true
      # Server crazieness
      stopLoadError "There was a problem talking to the server"
      error = result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
      bsAlert "<strong>Server Error:</strong> #{error}", "danger"
      stopLoadBarsError validatorTimeout
      return false
    statusTest = if result.validate_status?.status? then result.validate_status.status else result.validate_status
    fimsStatusProceedAnyway = [
      "FIMS_SERVER_DOWN"
      ]
    fimsErrorProceedAnyway = [
      "server error"
      ]
    permissibleError = false
    serverErrorMessageMain = ""
    try
      if Object.size(result.validate_status.errors) is 1
        for errorType, errorMessage of result.validate_status.errors[0]
          serverErrorMessageMain = errorMessage
          if typeof serverErrorMessageMain is "object"
            serverErrorMessageMain = errorMessage[0]
          break
        permissibleError = serverErrorMessageMain.toLowerCase() in fimsErrorProceedAnyway
    errorStatus =
      statusesOK: fimsStatusProceedAnyway
      errorsOK: fimsErrorProceedAnyway
      message: serverErrorMessageMain
      permissible: permissibleError
      errorSize: Object.size(result.validate_status.errors)

    if result.validate_status in fimsStatusProceedAnyway or permissibleError
      toastStatusMessage "Validation server is down, proceeding ..."
      bsAlert "<strong>FIMS error</strong>: The validation server is down, we're trying to finish up anyway.", "warning"
    else if statusTest isnt true
      # Bad validation
      overrideShowErrors = false
      console.error "Bad validation", errorStatus
      stopLoadError "There was a problem with your dataset"
      error = "<code>#{result.validate_status.error}</code>" ? result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
      if error.length > 255
        overrideShowErrors = true
        error = error.substr(0, 255) + "[...] and more."
      bsAlert "<strong>FIMS reported an error validating your data:</strong> #{error}", "danger"
      stopLoadBarsError validatorTimeout
      # Show all other errors, if there
      errors = result.validate_status.errors
      if Object.size(errors) > 1 or overrideShowErrors
        html = """
        <div class="error-block" id="validation-error-block">
          <p><strong>Your dataset had errors</strong>. Here's a summary:</p>
          <table class="table-responsive table-striped table-condensed table table-bordered table-hover" >
            <thead>
              <tr>
                <th>Error Type</th>
                <th>Error Message</th>
              </tr>
            </thhead>
            <tbody>
        """
        for key, errorType of errors
          for errorClass, errorMessages of errorType
            errorList = "<ul>"
            for k, message of errorMessages
              # Format the message
              message = message.stripHtml(true)
              if /\[(?:((?:"(\w+)"((, )?))*?))\]/m.test(message)
                # Wrap the column names
                message = message.replace /"(\w+)"/mg, "<code>$1</code>"
              errorList += "<li>#{message}</li>"
            errorList += "</ul>"
            html += """
            <tr>
              <td><strong>#{errorClass.stripHtml(true)}</strong></td>
              <td>#{errorList}</td>
            </tr>
            """
        html += """
            </tbody>
          </table>
        </div>
        """
        $("#validator-progress-container").append html
        $("#validator-progress-container").get(0).scrollIntoView()
      return false
    try
      p$("#data-validation").value = p$("#data-validation").max
      clearTimeout validatorTimeout
    # When we're successful, run the dependent callback
    if typeof callback is "function"
      callback(dataObject)
  .fail (result, status) ->
    clearTimeout validatorTimeout
    console.error "#{status}: Couldn't upload to FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadBarsError null, "There was a problem validating your data, please try again later"
    false
  false


mintBcid = (projectId, datasetUri = dataFileParams?.filePath, title, callback) ->
  ###
  #
  # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
  #
  # Resolve the ARK with
  # https://n2t.net/
  ###
  if typeof callback isnt "function"
    console.warn "mintBcid() requires a callback function"
    return false
  resultObj = new Object()
  addToExp = _adp?.fims?.expedition?.ark?

  args = "perform=mint&link=#{projectId}&title=#{post64(title)}&file=#{datasetUri}&expedition=#{addToExp}"
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadBarsError null, result.human_error
      console.error result.error
      return false
    resultObj = result
  .fail (result, status) ->
    resultObj =
      ark: null
      error: status
      human_error: result.responseText
      status: false
    false
  .always ->
    console.info "mintBcid is calling back", resultObj
    callback(resultObj)
  false


mintExpedition = (projectId = _adp.projectId, title = p$("#project-title").value, callback) ->
  ###
  #
  # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
  #
  # Resolve the ARK with
  # https://n2t.net/
  ###
  if typeof callback isnt "function"
    console.warn "mintExpedition() requires a callback function"
    return false
  resultObj = new Object()
  try
    publicProject = p$("#data-encumbrance-toggle").checked
  catch
    try
      publicProject = p$("#public").checked
  unless typeof publicProject is "boolean"
    publicProject = false
  args = "perform=create_expedition&link=#{projectId}&title=#{post64(title)}&public=#{publicProject}"
  _adp.currentAsyncJqxhr = $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Expedition got", result
    unless result.status
      errorJsonEscaped = result.error.replace /^.*\[(.*)\]$/img, "$1"
      errorJson = errorJsonEscaped.unescape()
      try
        errorParsed = JSON.parse errorJson
        message = errorParsed.message.trim()
        lastError = message.replace /^([a-z_]+\(.*\):\s*)?((.*?(?::|!)\s*)*(.*))/img, "$4"
        wholeError = message.replace /^([a-z_]+\(.*\):\s*)?((.*?(?::|!)\s*)*(.*))/img, "$2"
        alertError = if isNull(lastError) then wholeError else lastError
      catch
        alertError = "UNREADABLE_FIMS_ERROR"
      result.human_error += """" Server said: <code>#{alertError}</code> """
      try
        stopLoadBarsError null, result.human_error
      catch
        stopLoadError result.human_error
      console.error result.error, "#{adminParams.apiTarget}?#{args}"
      return false
    resultObj = result
    unless _adp?.fims?
      unless _adp?
        window._adp = new Object()
      _adp.fims = new Object()
    _adp.fims.expedition =
      permalink: result.project_permalink
      ark: unless typeof result.ark is "object" then result.ark else result.ark.identifier
      expeditionId: result.fims_expedition_id
      fimsRawResponse: result.responses.expedition_response
  .fail (result, status) ->
    resultObj.ark = null
    false
  .always ->
    console.info "mintExpedition is calling back", resultObj
    callback(resultObj)
  false


validateTaxonData = (dataObject, callback = null) ->
  ###
  #
  ###
  data = dataObject.data
  taxa = new Array()
  taxaPerRow = new Object()
  for n, row of data
    species = row.specificEpithet ? row.specificepithet
    ssp = row.infraspecificEpithet ? row.infraspecificepithet
    clade = row.cladeSampled ? row.cladesampled
    taxon =
      genus: row.genus
      species: species
      subspecies: ssp
      clade: clade
    unless taxa.containsObject taxon
      taxa.push taxon
    taxaString = "#{taxon.genus} #{taxon.species}"
    unless isNull taxon.subspecies
      taxaString += " #{taxon.subspecies}"
    unless taxaPerRow[taxaString]?
      taxaPerRow[taxaString] = new Array()
    taxaPerRow[taxaString].push n
  console.info "Found #{taxa.length} unique taxa:", taxa
  grammar = if taxa.length > 1 then "taxa" else "taxon"
  length = Object.toArray(data).length
  toastStatusMessage "Validating #{taxa.length} unique #{grammar} from #{length} rows ..."
  console.info "Replacement tracker", taxaPerRow
  $("#taxa-validation").removeAttr "indeterminate"
  try
    p$("#taxa-validation").max = taxa.length
  do taxonValidatorLoop = (taxonArray = taxa, key = 0) ->
    taxaString = "#{taxonArray[key].genus} #{taxonArray[key].species}"
    unless isNull taxonArray[key].subspecies
      taxaString += " #{taxonArray[key].subspecies}"
    validateAWebTaxon taxonArray[key], (result) ->
      if result.invalid is true
        cleanupToasts()
        specificEpithetRegex = /^([a-zA-Z]+) +[a-zA-Z\. ]+$/im
        match = specificEpithetRegex.exec(taxonArray[key].species)
        sspMatch = specificEpithetRegex.exec(taxonArray[key].subspecies)
        if match? or sspMatch?
          which = if match? then "species" else "subspecies"
          extraMessage = """
          (We noticed your #{which} looks like the full species name. <a href="https://tdwg.github.io/dwc/terms/index.htm#specificEpithet" class="alert-link newwindow" data-newtab="true">Double check the definition <span class="glyphicon glyphicon-new-window"></span></a> and your entry &#8212; that may help!)
          """
        else
          extraMessage = "Please correct taxonomy issues and try uploading again. If you're confused by this message, please check <a href='https://amphibian-disease-tracker.readthedocs.io/en/latest/APIs/#validating-updating-taxa' data-newtab='true' class='newwindow alert-link'>our documentation  <span class='glyphicon glyphicon-new-window'></span></a>."
        message = result.response.human_error ? result.response.error ? "Unknown error."
        stopLoadError message
        message = result.response.human_error_html ? message
        console.error result.response.error
        taxaRow = taxaPerRow[taxaString].slice 0
        n = 0
        for row in taxaRow
          row++
          taxaRow[n] = row
          n++
        if taxaRow.length > 5
          taxaRow = taxaRow.slice 0, 5
          taxaRow = taxaRow.toString() + "..."
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. #{message} The error occured while we were checking taxon <span class='sciname'>\"#{taxaString}\"</span>, which occurs at rows #{taxaRow}. We stopped validation at that point. #{extraMessage}"
        bsAlert(message)
        removeDataFile()
        stopLoadBarsError()
        return false
      try
        replaceRows = taxaPerRow[taxaString]
        console.info "Replacing rows @ #{taxaString}", replaceRows, taxonArray[key]
        # Replace entries
        for row in replaceRows
          dataObject.data[row].genus = result.genus
          dataObject.data[row].specificEpithet = result.species
          unless result.subspecies?
            result.subspecies = ""
          dataObject.data[row].infraspecificEpithet = result.subspecies
          dataObject.data[row].originalTaxa = taxaString
      catch e
        console.warn "Problem replacing rows! #{e.message}"
        console.warn e.stack
      taxonArray[key] = result
      try
        p$("#taxa-validation").value = key
      key++
      if key < taxonArray.length
        if key %% 50 is 0
          toastStatusMessage "Validating taxa #{key} of #{taxonArray.length} ..."
        taxonValidatorLoop(taxonArray, key)
      else
        try
          p$("#taxa-validation").value = key
        dataObject.validated_taxa  = taxonArray
        console.info "Calling back!", dataObject
        callback(dataObject)
  false
