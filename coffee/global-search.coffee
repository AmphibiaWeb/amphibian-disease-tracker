###
#
###


checkCoordinateSanity = ->
  isGood = true
  bounds =
    n: $("#north-coordinate").val()
    w: $("#west-coordinate").val()
    s: $("#south-coordinate").val()
    e: $("#east-coordinate").val()
  # Check that north is north, west is west
  unless bounds.n > bounds.s
    isGood = false
    $(".lat-input").parent().addClass "has-error"
  unless bounds.e > bounds.w
    isGood = false
    $(".lng-input").parent().addClass "has-error"
  unless isGood
    $(".do-search").attr "disabled", "disabled"
    return false
  $(".coord-input").parent().removeClass "has-error"
  $(".do-search").removeAttr "disabled"
  true


getSearchObject = ->
  bounds =
    n: $("#north-coordinate").val()
    w: $("#west-coordinate").val()
    s: $("#south-coordinate").val()
    e: $("#east-coordinate").val()
  search =
    sampled_species:
      data: $("#taxa-input").val()
    bounding_box_n:
      data: bounds.n
      search_type: "<="
    bounding_box_e:
      data: bounds.e
      search_type: "<="
    bounding_box_w:
      data: bounds.w
      search_type: ">="
    bounding_box_s:
      data: bounds.s
      search_type: ">="
  diseaseStatus = $(p$("#disease-status").selectedItem).attr "data-search"
  if diseaseStatus isnt "*"
    search.disease_positive =
      data: 0
      search_type: if diseaseStatus.toBool() then ">" else "="
  morbidityStatus = $(p$("#morbidity-status").selectedItem).attr "data-search"
  if morbidityStatus isnt "*"
    search.disease_morbidity =
      data: 0
      search_type: if morbidityStatus.toBool() then ">" else "="
  search


doSearch = (search = getSearchObject(), goDeep = false) ->
  ###
  #
  ###
  startLoad()
  data = jsonTo64 search
  args = "perform=advanced_project_search&q=#{data}"
  $.post "#{uri.urlString}admin-api.php", args, "json"
  .done (result) ->
    console.info "Adv. search result", result
    if result.status isnt true
      console.error result.error
      stopLoadError "There was a problem fetching the results"
      return false
    results = Object.toArray result.result
    if results.length is 0
      console.warn "No results"
      stopLoadError "No results"
      return false
    try
      boundingBox = [
        [search.bounding_box_n, search.bounding_box_w]
        [search.bounding_box_n, search.bounding_box_e]
        [search.bounding_box_s, search.bounding_box_e]
        [search.bounding_box_s, search.bounding_box_w]
        ]
      mapCenter = getMapCenter boundingBox
      p$("#global-data-map").latitude = mapCenter.lat
      p$("#global-data-map").longitude = mapCenter.lng
      zoom = getMapZoom boundingBox, "#global-data-map"
    catch e
      console.warn "Failed to rezoom/recenter map - #{e.message}"
      console.warn e.stack
    if goDeep
      # If we're going deep, we'll let the deep take care of the rest
      doDeepSearch(results)
      return false
    totalSamples = 0
    posSamples = 0
    totalSpecies = new Array()
    layers = new Array()
    for project in results
      totalSamples += project.disease_samples
      posSamples += project.disease_positive
      spArr = project.sampled_species.split(",")
      for species in spArr
        species = species.trim()
        unless species in totalSpecies
          totalSpecies.push species
      # Visualize it
      # See
      # https://docs.cartodb.com/cartodb-platform/cartodb-js/getting-started/#creating-visualizations-at-runtime
      table = project.carto_id.table
      unless isNull table
        layer =
          sql: "SELECT * FROM #{table}"
        layers.push layer
    speciesCount = totalSpecies.length
    console.info "Projects containing your search returned #{totalSamples} (#{posSamples} positive) among #{speciesCount} species"
    $("#post-map-subtitle").text "Viewing projects containing #{totalSamples} samples (#{posSamples} positive) among #{speciesCount} species"  
    # Render the vis
    try
      createRawCartoMap layers
    catch e
      console.error "Couldn't create map! #{e.message}"
      console.warn e.stack
    stopLoad()
    false
  .fail (result, status) ->
    console.error result, status
    stopLoadError "Server error, couldn't perform search"
  false


doDeepSearch = (shallowResults) ->
  ###
  # Follows up on doSearch() to then look at the shallow matches and
  # do a Carto query
  ###
  toastStatusMessage "Deep search not yet implemented"
  stopLoad()
  false


$ ->
  $(".coord-input").keyup ->
    checkCoordinateSanity()
  $(".do-search").click ->
    ok = checkCoordinateSanity()
    unless ok
      toastStatusMessage "Please check your coordinates"
      return false
    deep = $(this).attr("data-deep").toBool()
    doSearch(getSearchObject(), deep)
    false
