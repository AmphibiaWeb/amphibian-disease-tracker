<?php 
$svg = basename($_REQUEST['name']);
if(strpos($svg,"svgz")===FALSE)
  {
    ob_start ("ob_gzhandler");
    if (file_exists($svg)) 
      {
	$fp = fopen($svg, 'rb');
	header('Access-Control-Allow-Origin: *');
	header("Content-type:image/svg+xml");
	header("Vary: Accept");
	header ("cache-control: must-revalidate");
	$offset = 7 * 60 * 60;
	$expire = "expires: " . gmdate ("D, d M Y H:i:s", time() + $offset) . " GMT";
	header ($expire);
	header("Content-encoding:gzip");
	fpassthru($fp);
	fclose($fp);
      }
    else {
      echo "404 - SVG File Not found";
    }
    ob_end_flush();
  }
else
  {
    if(file_exists($svg))
      {
	$fp = fopen($svg, 'rb');
	header('Access-Control-Allow-Origin: *');
	header("Content-type:image/svg+xml");
	header("Vary: Accept");
	header ("cache-control: must-revalidate");
	$offset = 7 * 60 * 60;
	$expire = "expires: " . gmdate ("D, d M Y H:i:s", time() + $offset) . " GMT";
	header ($expire);
	header("Content-encoding:gzip");
	fpassthru($fp);
	fclose($fp);
      }
    else {
      echo "404 - SVG File Not found";
    }
  }
?>
