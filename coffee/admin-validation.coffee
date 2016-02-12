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
  console.info "Doing nested validation"
  timer = Date.now()
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
  fimsPostTarget = ""
  # Format the JSON for FIMS
  # Post the object over to FIMS
  # Get back an ARK
  # When we're successful, run the dependent callback
  if typeof callback is "function"
    callback(dataObject)
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
          dataObject.data[row].specificEpithet = result.specificEpithet
          unless result.infraspecificEpithet?
            result.infraspecificEpithet = ""
          dataObject.data[row].infraspecificEpithet = result.infraspecificEpithet
      catch e
        console.warn "Problem replacing rows! #{e.message}"
        console.warn e.stack
      taxonArray[key] = result
      key++
      if key < taxonArray.length
        if key %% 50 is 0
          toastStatusMessage "Validating taxa #{key} of #{taxonArray.length} ..."
        taxonValidatorLoop(taxonArray, key)
      else
        dataObject.validated_taxa  = taxonArray
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
  .fail (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false
