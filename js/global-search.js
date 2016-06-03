
/*
 *
 */
var checkCoordinateSanity;

checkCoordinateSanity = function() {
  var bounds, isGood;
  isGood = true;
  bounds = {
    n: $("#north-coordinate").val(),
    w: $("#west-coordinate").val(),
    s: $("#south-coordinate").val(),
    e: $("#east-coordinate").val()
  };
  if (!(bounds.n > bounds.s)) {
    isGood = false;
    $(".lat-input").parent().addClass("has-error");
  }
  if (!(bounds.e > bounds.w)) {
    isGood = false;
    $(".lng-input").parent().addClass("has-error");
  }
  if (!isGood) {
    return false;
  }
  $(".coord-input").parent().removeClass("has-error");
  return false;
};

$(function() {
  return $(".coord-input").keyup(function() {
    return checkCoordinateSanity();
  });
});

//# sourceMappingURL=maps/global-search.js.map
