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
    stopLoadError "There was a problem validating your data"
  false


delayFimsRecheck = (originalResponse, callback) ->
  cookies = encodeURIComponent originalResponse.responses.login_response.cookies
  args = "perform=validate&auth=#{cookies}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Server said", result
    if typeof callback is "function"
      callback()
    else
      console.warn "Warning: delayed recheck had no callback"
  .fail (result, status) ->
    console.error "#{status}: Couldn't check status on FIMS server!"
    console.warn "Server said", result.responseText
    stopLoadError "There was a problem validating your data, please try again later"
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
      stopLoadError "Couldn't validate your data, please try again later"
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
  $.post "#{uri.urlString}#{adminParams.apiTarget}", args, "json"
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
    if result.validate_status is "FIMS_SERVER_DOWN"
      toastStatusMessage "Validation server is down, proceeding ..."
      bsAlert "<strong>FIMS error</strong>: The validation server is down, we're trying to finish up anyway.", "warning"
    else if statusTest isnt true
      # Bad validation
      overrideShowErrors = false
      stopLoadError "There was a problem with your dataset"
      error = result.validate_status.error ? result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
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
    stopLoadError "There was a problem validating your data, please try again later"
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
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadError result.human_error
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
  publicProject = p$("#data-encumbrance-toggle").checked
  unless typeof publicProject is "boolean"
    publicProject = false
  args = "perform=create_expedition&link=#{projectId}&title=#{post64(title)}&public=#{publicProject}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Expedition got", result
    unless result.status
      stopLoadError result.human_error
      console.error result.error
      return false
    resultObj = result
    unless _adp?.fims?
      unless _adp?
        window._adp = new Object()
      _adp.fims = new Object()
    _adp.fims.expedition =
      permalink: result.project_permalink
      ark: result.ark
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
        stopLoadError result.response.human_error
        console.error result.response.error
        message = "<strong>Taxonomy Error</strong>: There was a taxon error in your file. #{result.response.human_error} We stopped validation at that point. Please correct taxonomy issues and try uploading again."
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
  $.post "api.php", args, "json"
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
