<?php

# Simply redirect to the login url

require_once(dirname(__FILE__).'/CONFIG.php');

if(empty($baseurl))
{
    $baseurl = 'http';
    if ($_SERVER["HTTPS"] == "on") {$baseurl .= "s";}
    $baseurl .= "://";
    $baseurl.=$_SERVER['HTTP_HOST'];
}

$base_long = str_replace("http://","",strtolower($baseurl));
$base_long = str_replace("https://","",strtolower($base_long));

$canonicalUrl = $baseurl . "/" . str_replace($relative_path,"",$working_subdirectory) . $login_url;

header("Refresh: 0; url=$canonicalUrl");

?>