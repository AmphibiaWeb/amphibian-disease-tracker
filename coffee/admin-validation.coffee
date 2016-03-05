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

validateFimsData = (dataObject, callback = null) ->
  ###
  #
  #
  # @param Object dataObject -> object with at least one key, "data",
  #  containing the parsed data to be validated by FIMS
  # @param function callback -> callback function
  ###
  console.info "FIMS Validating", dataObject.data
  $("#data-validation").removeAttr "indeterminate"
  rowCount = Object.size dataObject.data
  p$("#data-validation").max = rowCount
  # Set an animation timer
  timerPerRow = 30
  validatorTimeout = null
  animateProgress = ->
    val = p$("#data-validation").value
    if val >= rowCount
      # Stop the animation
      return false
    ++val
    p$("#data-validation").value = val
    validatorTimeout = delay timerPerRow, ->
      animateProgress()
  # Format the JSON for FIMS
  data = jsonTo64 dataObject.data
  src = post64 dataObject.dataSrc
  args = "perform=validate&data=#{data}&datasrc=#{src}"
  # Post the object over to FIMS
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "FIMS validate result", result
    unless result.status is true
      stopLoadError "There was a problem with your dataset"
      error = result.human_error ? result.error ? "There was a problem with your dataset, but we couldn't understand what FIMS said. Please manually examine your data, correct it, and try again."
      bsAlert error, "danger"
      clearTimeout validatorTimeout
      return false
    p$("#data-validation").value = Object.size dataObject.data
    clearTimeout validatorTimeout
    # When we're successful, run the dependent callback
    if typeof callback is "function"
      callback(dataObject)
  .error (result, status) ->
    clearTimeout validatorTimeout
    stopLoadError "There was a problem validating your data, please try again later"
    false
  false


mintBcid = (projectId, title, callback) ->
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
  args = "perform=mint&link=#{projectId}&title=#{post64(title)}"
  $.post adminParams.apiTarget, args, "json"
  .done (result) ->
    console.log "Got", result
    unless result.status
      stopLoadError result.human_error
      console.error result.error
      return false
    resultObj = result
  .error (result, status) ->
    resultObj.ark = null
    false
  .always ->
    console.info "mintBcid is calling back", resultObj
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
    taxon =
      genus: row.genus
      species: row.specificEpithet
      subspecies: row.infraspecificEpithet
      clade: row.cladeSampled
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
  toastStatusMessage "Validating #{taxa.length} uniqe #{grammar}"
  console.info "Replacement tracker", taxaPerRow
  $("#taxa-validation").removeAttr "indeterminate"
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
      p$("#taxa-validation").value = key
      key++
      if key < taxonArray.length
        if key %% 50 is 0
          toastStatusMessage "Validating taxa #{key} of #{taxonArray.length} ..."
        taxonValidatorLoop(taxonArray, key)
      else
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
      window.validationMeta.validatedTaxons.push taxonObj
    else
      taxonObj.invalid = true
    taxonObj.response = result
    doCallback(taxonObj)
    return false
  .error (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false
