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
    return false
  $(".coord-input").parent().removeClass "has-error"
  false


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


doSearch = ->
  ###
  #
  ###
  data = jsonTo64 getSearchObject()
  args = "action=advanced_project_search&q=#{data}"
  $.post "#{uri.urlString}api.php", args, "json"
  .done (result) ->
    console.info "Adv. search result", result
    stopLoad()
    false
  .fail (result, status) ->
    console.error result, status
    stopLoadError "Server error, couldn't perform search"
  false


$ ->
  $(".coord-input").keyup ->
    checkCoordinateSanity()
