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


$ ->
  $(".coord-input").keyup ->
    checkCoordinateSanity()
