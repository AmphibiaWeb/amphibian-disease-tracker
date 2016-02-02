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

validateFimsData = (dataObject, callback = null) ->
  ###
  #
  #
  # @param Object dataObject -> object with at least one key, "data",
  #  containing the parsed data to be validated by FIMS
  # @param function callback -> callback function
  ###
  console.info "Validating", dataObject.data
  fimsPostTarget = ""
  # Format the JSON for FIMS
  # Post the object over to FIMS
  # When we're successful, run the dependent callback
  if typeof callback is "function"
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
  unless window.validataionMeta?.validatedTaxons?
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
  if taxonObj in window.validationMeta.validatedTaxons
    console.info "Already validated taxon, skipping revalidation", taxonObj
    doCallback(taxonObj)
    return false
  # POST the data over to AWeb
  # Success! Save validated taxon, and run callback
  window.validationMeta.validatedTaxons.push taxonObj
  doCallback(taxonObj)
  return false
  # On fail, notify the user that the taxon wasn't actually validated
  # with a BSAlert, rather than toast
  prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
  prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
  bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
  console.warn "Warning: Couldn't validated #{prettyTaxon} with AmphibiaWeb"
  false
