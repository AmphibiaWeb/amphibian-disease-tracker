<?php
function curPageURL() {
  $pageURL = 'http';
  if ($_SERVER["HTTPS"] == "on") {$pageURL .= "s";}
  $pageURL .= "://";
  if ($_SERVER["SERVER_PORT"] != "80") {
    $pageURL .= $_SERVER["SERVER_NAME"].":".$_SERVER["SERVER_PORT"].$_SERVER["REQUEST_URI"];
  } else {
    $pageURL .= $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
  }
  return $pageURL;
}

function appendQuery($query,$entities=true) {
  $url = curPageURL();
  if($entities)$url=str_replace("&","&amp;",$url);
  $amp= $entities ? "&amp;":"&";
  if(strpos($url,"?")!==FALSE) $url .= $amp . $query;
  else $url .= "?" . $query;
  return $url;
}

function strbool($bool)
{
  // returns the string of a boolean as 'true' or 'false'.
  if(is_string($bool)) $bool=boolstr($bool); // if a string is passed, convert it to a bool
  if(is_bool($bool)) return $bool ? 'true' : 'false';
  else return false;
}
function boolstr($string)
{
  // returns the boolean of a string 'true' or 'false'
  if(is_string($string)) return strtolower($string)==='true' ? true:false;
  else if(is_bool($string)) return $string;
  else if(preg_match("/[0-1]/",$string)) return $string==1 ? true:false;
  else return false;
}

function dispSVG($resource,$alt=NULL,$width=NULL,$height=NULL,$id=NULL,$class=NULL,$return=false)
{
  require_once('modular/browser.inc');
  //object width
  $ostyle=" ";
  if(is_numeric($width)) $ostyle .= "width='$width" . "px'";
  if(is_numeric($height)) $ostyle .= " height='$height" . "px'";

  //CSS width
  $cstyle = (is_numeric($width) || is_numeric($height)) ? " style='":"";
  if(is_numeric($width)) $cstyle .="width:$width" . "px;";
  if(is_numeric($height)) $cstyle .="height:$height" . "px;";
  if($cstyle!="") $cstyle .="' ";

  //identifiers
  if($id!=NULL) $ido="id='$id'";
  if($class!=NULL) $classo="class='$class'";

  // Check directory for gzip-svg.php
  $subdir = dirname($resource);
  if(file_exists($subdir . "/gzip-svg.php"))
    {
      $resource_old=$resource;
      $resource = $subdir . "/gzip-svg.php?name=" . basename($resource);
    }
  else $resource_old=$resource;

  // Detect browsers.  IE falls back to Google's code, and FireFox falls back to <object> implementation.
  if(browser_detection('browser')=='moz' && browser_detection('number')<17)
    {
      $out="<object data='$resource' type='image/svg+xml' $ostyle $ido $classo>\n$alt\n</object>";
      if(!$return) 
        {
          echo $out;
          return true;
        }
      else return $out;
    }
  if(browser_detection('browser')=='ie')
    {
      if(browser_detection('number')<9)
        {
          // Check for a png
          $pngfile = substr($resource_old, 0, -4) . ".png";
          if(file_exists($pngfile))
            {
              // With a png, display that rather than call resource overhead for Flash display
              $out= "<img src='$pngfile' alt='$alt' $cstyle  $ido $classo/>";
              if(!$return) 
                {
                  echo $out;
                  return true;
                }
              else return $out;
            }
          else
            {
              // Fallback to Flash SVG display.
              if(!is_numeric($width)) 
                {
                  $ostyle .=" width='100px'"; // IE requires a width and height. If not specified, default to 100x100.
                  $width=100;
                }
              if(!is_numeric($height)) $ostyle .= " height='$width" . "px'";
              $out= "<object data='$resource' type='image/svg+xml' $ostyle $ido $classo>";
              if(browser_detection('number')>=8) $out.= $alt;
              $out.= "</object>";
              if(!$return) 
                {
                  echo $out;
                  return true;
                }
              else return $out;
            }
        }
      else 
        {
          $out= "<img src='$resource' alt='$alt' $cstyle  $ido $classo/>";
          if(!$return) 
            {
              echo $out;
              return true;
            }
          else return $out;
        }
    }
  else // if browser detection fails, fall back to most common resource inclusion.
    {
      $out= "<img src='$resource' alt='$alt' $cstyle  $ido $classo/>";
      if(!$return) 
        {
          echo $out;
          return true;
        }
      else return $out;
    }
}
function do_post_request($url, $data, $optional_headers = null)
{
  $params = array('http' => array(
				  'method' => 'POST',
				  'content' => $data
				  ));
  if ($optional_headers !== null) {
    $params['http']['header'] = $optional_headers;
  }
  $ctx = stream_context_create($params);
  $fp = @fopen($url, 'rb', false, $ctx);
  if (!$fp) {
    throw new Exception("Problem with $url, $php_errormsg");
  }
  $response = @stream_get_contents($fp);
  if ($response === false) {
    throw new Exception("Problem reading data from $url, $php_errormsg");
  }
  return $response;
}
?>