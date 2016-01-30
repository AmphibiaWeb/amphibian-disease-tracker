<?php

if (!class_exists('DBHelper')) {
    require_once dirname(__FILE__).'/db/DBHelper.php';
}
if (!class_exists('Stronghash')) {
    require_once dirname(__FILE__).'/stronghash/php-stronghash.php';
}
if (!class_exists('Xml')) {
    require_once dirname(__FILE__).'/xml/xml.php';
}
if (!class_exists('Wysiwyg')) {
    require_once dirname(__FILE__).'/wysiwyg/wysiwyg.php';
    # Non-classed old things for project compatibility
    include dirname(__FILE__).'/wysiwyg/classic-wysiwyg.php';
}


if(!function_exists("returnAjax")) {
    function returnAjax($data) {
    /***
     * Return the data as a JSON object
     *
     * @param array $data
     *
     ***/
    if(!is_array($data)) $data=array($data);
    $data["execution_time"] = elapsed();
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
    header('Content-type: application/json');
    $json = json_encode($data,JSON_FORCE_OBJECT);
    $replace_array = array("&quot;","&#34;");
    print str_replace($replace_array,"\\\"",$json);
    exit();
    }
}

if(!function_exists('elapsed'))
  {
    function elapsed($start_time = null)
    {
      /***
       * Return the duration since the start time in
       * milliseconds.
       * If no start time is provided, it'll try to use the global
       * variable $start_script_timer
       *
       * @param float $start_time in unix epoch. See http://us1.php.net/microtime
       ***/

      if(!is_numeric($start_time))
        {
          global $start_script_timer;
          if(is_numeric($start_script_timer)) $start_time = $start_script_timer;
          else return false;
        }
      return 1000*(microtime_float() - (float)$start_time);
    }
  }


if (!function_exists('microtime_float')) {
    function microtime_float()
    {
        if (version_compare(phpversion(), '5.0.0', '<')) {
            list($usec, $sec) = explode(' ', microtime());

            return ((float) $usec + (float) $sec);
        } else {
            return microtime(true);
        }
    }
}

if (!function_exists('dirListPHP')) {
    function dirListPHP($directory, $filter = null, $extension = false, $debug = false)
    {
        $results = array();
        $handler = @opendir($directory);
        if ($handler === false) {
            return false;
        }
        while ($file = readdir($handler)) {
            if ($file != '.' && $file != '..') {
                if ($filter != null) {
                    if ($extension !== false) {
                        $parts = explode('.', basename($file));
                        $size = sizeof($parts);
                        $ext_file = array_pop($parts);
                        $filename = implode('.', $parts);
                        if ($debug) {
                            echo "Looking at extension '$extension' and '$ext_file' for $file and $filename\n";
                        }
                        if ($ext_file == $extension) {
                            if (empty($filter)) {
                                $results[] = $file;
                            } elseif (strpos(strtolower($filename), strtolower($filter)) !== false) {
                                $results[] = $file;
                            }
                        }
                    } elseif (strpos(strtolower($file), strtolower($filter)) !== false) {
                        $results[] = $file;
                        if ($debug) {
                            echo "No extension used\n";
                        }
                    }
                } else {
                    $results[] = $file;
                    if ($debug) {
                        echo "No filter used \n";
                    }
                }
            }
        }
        closedir($handler);

        return $results;
    }
}

if (!function_exists('array_find')) {
    function array_find($needle, $haystack, $search_keys = false, $strict = false)
    {
        if (!is_array($haystack)) {
            return false;
        }
        foreach ($haystack as $key => $value) {
            $what = ($search_keys) ? $key : $value;
            if ($strict) {
                if ($value == $needle) {
                    return $key;
                }
            } elseif (@strpos($what, $needle) !== false) {
                return $key;
            }
        }

        return false;
    }
}
if (!function_exists('encode64')) {
    function encode64($data)
    {
        return base64_encode($data);
    }
    function decode64($data)
    {
        # This is STRICT decoding
      if (@base64_encode(@base64_decode($data, true)) == $data) {
          return urldecode(@base64_decode($data));
      }

        return false;
    }
}

if (!function_exists('smart_decode64')) {
    function smart_decode64($data, $clean_this = true)
    {
        /*
       * Take in a base 64 object, decode it. Pass back an array
       * if it's a JSON, and sanitize the elements in any case.
       */
      if (is_null($data)) {
          return;
      } // in case emptyness of data is meaningful
      $r = urldecode(base64_decode($data));
        if ($r === false) {
            return false;
        }
        $jd = json_decode($r, true);
        $working = is_null($jd) ? $r : $jd;
        if ($clean_this) {
            try {
                // clean
              if (is_array($working)) {
                  $prepped_data = loopSanitizeArray($working);
              } else {
                  $prepped_data = DBHelper::staticSanitize($working);
              }
            } catch (Exception $e) {
                // Something broke, probably an invalid data format.
              return false;
            }
        } else {
            $prepped_data = $working;
        }

        return $prepped_data;
    }

    function loopSanitizeArray($array)
    {
        if (is_array($array)) {
            $new_array = array();
            foreach ($array as $k => $v) {
                $ck = DBHelper::staticSanitize($k);
                if (is_array($v)) {
                    $cv = loopSanitizeArray($v);
                } else {
                    $cv = DBHelper::staticSanitize($v);
                }
                $new_array[$ck] = $cv;
            }
        } else {
            $new_array = $array;
        }

        return $new_array;
    }
}

if (!function_exists('strbool')) {
    function strbool($bool)
    {
        // returns the string of a boolean as 'true' or 'false'.
      if (is_string($bool)) {
          $bool = boolstr($bool);
      } // if a string is passed, convert it to a bool
      if (is_bool($bool)) {
          return $bool ? 'true' : 'false';
      } else {
          return 'non_bool';
      }
    }
    function boolstr($string)
    {
        // returns the boolean of a string 'true' or 'false'
      if (is_bool($string)) {
          return $string;
      }
        if (is_string($string)) {
            if (preg_match('/[0-1]/', $string)) {
                return intval($string) == 1 ? true : false;
            }

            return strtolower($string) === 'true' ? true : false;
        }
        if (preg_match('/[0-1]/', $string)) {
            return $string == 1 ? true : false;
        }

        return false;
    }
}

if (!function_exists('shuffle_assoc')) {
    function shuffle_assoc(&$array)
    {
        $keys = array_keys($array);

        shuffle($keys);

        foreach ($keys as $key) {
            $new[$key] = $array[$key];
        }

        $array = $new;

        return true;
    }
}

if (!function_exists('displayDebug')) {
    function displayDebug($string, $background = true)
    {
        # alias
        return debugDisplay($string, $background);
    }
    function debugDisplay($string, $background = true)
    {
        if (is_array($string)) {
            foreach ($string as $k => $el) {
                if (is_bool($el)) {
                    $string[$k] = '(bool) '.strbool($el);
                }
            }
            $string = print_r($string, true);
        }
        $string = str_replace('&', '&amp;', $string);
        $string = str_replace('<', '&lt;', $string);
        $string = str_replace('>', '&gt;', $string);
        if(!$background) return $string;
        return "<pre style='background:white;color:black;'>".$string.'</pre>';
    }
}

if (!function_exists('do_post_request')) {
    function do_post_request($url, $data, $optional_headers = null)
    {
        /***
         * Do a POST request
         *
         * @param string $url the destination URL
         * @param array $data The paramter as key/value pairs
         * @return response object
         ***/
        $bareUrl = $url;
        $url = urlencode($url);
        $params = array('http' => array(
            'method' => 'POST',
            'content' => http_build_query($data),
            'header'  => 'Content-type: application/x-www-form-urlencoded',
        ));
        if ($optional_headers !== null) {
            $params['http']['header'] = $optional_headers;
        }
        $ctx = stream_context_create($params);
        # If url handlers are set,t his whole next part can be file_get_contents($url,false,$ctx)
        try {
            ini_set("default_socket_timeout",3);
            $response = file_get_contents($bareUrl,false,$ctx);
            if(empty($response) || $response === false) throw new Exception("No Response from file_get_contents");
        } catch (Exception $e) {
            ini_set("allow_url_fopen", true);
            $fp = @fopen($bareUrl, 'rb', false, $ctx);
            if (!$fp) {
                if(function_exists("http_post_fields")) {
                    $response = http_post_fields($bareUrl, $data);
                    if($response === false || empty($response)) throw new Exception("Could not POST to $bareUrl");
                    return $response;
                }
                else if (function_exists("curl_init")) {
                    # Last-ditch: CURL
                    $ch = curl_init( $bareUrl );
                    curl_setopt( $ch, CURLOPT_POST, 1);
                    curl_setopt( $ch, CURLOPT_POSTFIELDS, http_build_query($data));
                    curl_setopt( $ch, CURLOPT_FOLLOWLOCATION, 1);
                    curl_setopt( $ch, CURLOPT_HEADER, 0);
                    curl_setopt( $ch, CURLOPT_RETURNTRANSFER, 1);

                    $response = curl_exec( $ch );
                    if($response === false || empty($response)) throw new Exception("CURL failure: ".curl_error($ch));
                    return $response;
                }
                else throw new Exception("Problem POSTing to  $bareUrl");
            }
            $response = @stream_get_contents($fp);
            if ($response === false) {
                throw new Exception("Problem reading data from $bareUrl");
            }
        }
        return $response;
    }    
}

if (!function_exists('deEscape')) {
    function deEscape($input)
    {
        $find = array(
            "&#39;",
            "&#34;",
            "&#95;",
            "&#37;"
        );
        $replace = array(
            "'",
            "\"",
            "_",
            "%"
        );
        $input = str_replace($find, $replace, $input);
        return htmlspecialchars_decode(html_entity_decode(urldecode($input)));
    }
}

if (!function_exists('curPageURL')) {
    function curPageURL()
    {
        $pageURL = 'http';
        if ($_SERVER['HTTPS'] == 'on') {
            $pageURL .= 's';
        }
        $pageURL .= '://';
        if ($_SERVER['SERVER_PORT'] != '80') {
            $pageURL .= $_SERVER['SERVER_NAME'].':'.$_SERVER['SERVER_PORT'].$_SERVER['REQUEST_URI'];
        } else {
            $pageURL .= $_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
        }
        require_once dirname(__FILE__).'/db/DBHelper.php';

        return DBHelper::cleanInput($pageURL);
    }
}

if (!function_exists('appendQuery')) {
    function appendQuery($query)
    {
        $url = curPageURL();
        $url = str_replace('&', '&amp;', $url);
        if (strpos($url, '?') !== false) {
            $url .= '&amp;'.$query;
        } else {
            $url .= '?'.$query;
        }

        return $url;
    }
}
