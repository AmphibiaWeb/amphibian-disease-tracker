<?php 
# vulcanized-header wilil use the variable vulcanized to deal with
# this
$includePath = dirname(__FILE__) . "/vulcanized-div-and-dom-module.html";
# We want to get contents so quotes and such are properly escaped
$vulcanized = file_get_contents($includePath);
?>
