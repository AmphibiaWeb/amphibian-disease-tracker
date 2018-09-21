<?php

if (isset($_SERVER['QUERY_STRING'])) {
    parse_str($_SERVER['QUERY_STRING'], $_REQUEST);
}

if (!function_exists('file_get_contents_curl')) {
    # cURL replacement for file_get_contents
    # https://gist.github.com/tigerhawkvok/794a725436ae0b29db3ab17812828818
    function file_get_contents_curl($url) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_AUTOREFERER, TRUE);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);

        # Actual fetch
        $data = curl_exec($ch);
        curl_close($ch);

        return $data;
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

$start_script_timer = microtime_float();

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


if (!function_exists("returnAjax")) {
    function returnAjax($data)
    {
        /***
         * Return the data as a JSON object
         *
         * @param array $data
         *
         ***/
        if (!is_array($data)) {
            $data=array($data);
        }
        $data["execution_time"] = elapsed();
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        header('Content-type: application/json');
        $json = json_encode($data, JSON_FORCE_OBJECT);
        $replace_array = array("&quot;","&#34;");
        print str_replace($replace_array, "\\\"", $json);
        exit();
    }
}

if (!function_exists('elapsed')) {
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

      if (!is_numeric($start_time)) {
          global $start_script_timer;
          if (is_numeric($start_script_timer)) {
              $start_time = $start_script_timer;
          } else {
              return false;
          }
      }
        return 1000*(microtime_float() - (float)$start_time);
    }
}

if (!function_exists('curl_file_create')) {
    function curl_file_create($filename, $mimetype = '', $postname = '')
    {
        return "@$filename;filename="
            . ($postname ?: basename($filename))
            . ($mimetype ? ";type=$mimetype" : '');
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
    function toBool($str)
    {
        return boolstr($str);
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

if (!function_exists("get_final_url")) {
    #  https://stackoverflow.com/questions/3799134/how-to-get-final-url-after-following-http-redirections-in-pure-php#
    function get_redirect_url($url) {
        /**
         * get_redirect_url()
         * Gets the address that the provided URL redirects to,
         * or FALSE if there's no redirect.
         *
         * @param string $url
         * @return string
         */
        $redirect_url = null;

        $url_parts = @parse_url($url);
        if (!$url_parts) return false;
        if (!isset($url_parts['host'])) return false; //can't process relative URLs
        if (!isset($url_parts['path'])) $url_parts['path'] = '/';

        $sock = fsockopen($url_parts['host'], (isset($url_parts['port']) ? (int)$url_parts['port'] : 80), $errno, $errstr, 30);
        if (!$sock) return false;

        $request = "HEAD " . $url_parts['path'] . (isset($url_parts['query']) ? '?'.$url_parts['query'] : '') . " HTTP/1.1\r\n";
        $request .= 'Host: ' . $url_parts['host'] . "\r\n";
        $request .= "Connection: Close\r\n\r\n";
        fwrite($sock, $request);
        $response = '';
        while(!feof($sock)) $response .= fread($sock, 8192);
        fclose($sock);

        if (preg_match('/^Location: (.+?)$/m', $response, $matches)){
            if ( substr($matches[1], 0, 1) == "/" )
                return $url_parts['scheme'] . "://" . $url_parts['host'] . trim($matches[1]);
            else
                return trim($matches[1]);

        } else {
            return false;
        }

    }


        function get_all_redirects($url){
            /**
             * get_all_redirects()
             * Follows and collects all redirects, in order, for the given URL.
             *
             * @param string $url
             * @return array
             */
            $redirects = array();
            while ($newurl = get_redirect_url($url)){
                if (in_array($newurl, $redirects)){
                    break;
                }
                $redirects[] = $newurl;
                $url = $newurl;
            }
            return $redirects;
        }


        function get_final_url($url){
    /**
     * get_final_url()
     * Gets the address that the URL ultimately leads to.
     * Returns $url itself if it isn't a redirect.
     *
     * @param string $url
     * @return string
     */
            $redirects = get_all_redirects($url);
            if (count($redirects)>0){
                return array_pop($redirects);
            } else {
                return $url;
            }
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
        if (!$background) {
            return $string;
        }
        return "<pre style='background:white;color:black;'>".$string.'</pre>';
    }
}

if (!function_exists('do_post_request')) {
    function do_post_request($url, $data, $method = "POST", $optional_headers = null)
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
            'method' => $method,
            'content' => is_array($data) ? http_build_query($data) : $data,
            'header'  => 'Content-type: application/x-www-form-urlencoded',
        ));
        if ($optional_headers !== null) {
            $params['http']['header'] = $optional_headers;
        }
        $ctx = stream_context_create($params);
        # If url handlers are set,t his whole next part can be file_get_contents($url,false,$ctx)
        try {
            ini_set("default_socket_timeout", 3);
            ini_set("allow_url_fopen", true);
            $response = file_get_contents($bareUrl, false, $ctx);
            if (empty($response) || $response === false) {
                throw new Exception("No Response from file_get_contents");
            }
        } catch (Exception $e) {
            ini_set("allow_url_fopen", true);
            $fp = @fopen($bareUrl, 'rb', false, $ctx);
            if (!$fp) {
                if (function_exists("http_post_fields")) {
                    $response = http_post_fields($bareUrl, $data);
                    if ($response === false || empty($response)) {
                        throw new Exception("Could not POST to $bareUrl");
                    }
                    return $response;
                } elseif (function_exists("curl_init")) {
                    # Last-ditch: CURL
                    $ch = curl_init($bareUrl);
                    if ($method == "POST") {
                        curl_setopt($ch, CURLOPT_POST, 1);
                    }
                    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
                    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
                    curl_setopt($ch, CURLOPT_HEADER, 0);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

                    $response = curl_exec($ch);
                    if ($response === false || empty($response)) {
                        throw new Exception("CURL failure: ".curl_error($ch));
                    }
                    return $response;
                } else {
                    throw new Exception("Problem POSTing to  $bareUrl");
                }
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
            "&amp;#",
            "&#39;",
            "&#34;",
            "&#95;",
            "&#37;"
        );
        $replace = array(
            "&#",
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


if (!function_exists("get_include_contents")) {
    function get_include_contents($filename)
    {
        if (is_file($filename)) {
            ob_start();
            include $filename;
            return ob_get_clean();
        }
        return false;
    }
}

if (!class_exists("ImageFunctions")) {
    class ImageFunctions
    {
        /***
     * Image parser library. Taken and adapted from many sources over
     * a number of years.
     *
     * It can be used in several ways:
     *
     * As an object:
     * create a new ImageFunctions object, with the path to an image
     * file as its argument, eg,
     *
     * $i = new ImageFunctions("path/to/foo.jpg");
     *
     * Then reizeImage can be called on the object
     * $i->resizeImage("path/to/output.jpg",MAX_WIDTH,MAX_HEIGHT);
     *
     * There are a number of static methods, as well.
     *
     * ImageFunctions::randomRotate(MIN_ROTATION_DEGRESS,MAX_ROTATION_DEGREES)
     * will randomly rotate an image in CSS
     *
     * ImageFunctions::staticResizeImage("path/to/foo.jpg","path/to/output.jpg",MAX_WIDTH,MAX_HEIGHT);
     *
     * ImageFunctions::randomImage("path/to/dir", EXTENSION);
     * returns a random image matching EXTENSION from a given directory
     *
     *
     ***/

    public function __construct($imgUrl = null)
    {
        $this->img = $imgUrl;
    }

        private static function notfound()
        {
            throw new Exception('Not Found Exception');
        }

        public static function randomRotate($min, $max)
        {
            /***
         * Return a random CSS rotation transformation, in the
         * positive or negative direction. If the random angle is
         * odd, the direction is negative; otherwise, the direction
         * is positive.
         *
         * @param float $min The minimum rotation in degrees
         * @param float $max The maximum rotation in degrees
         *
         * @return string CSS to be applied to the image, with
         *   appropriate vendor prefixes.
         ***/
        $angle = rand($min, $max);
            if (rand(0, 100) % 2) {
                $angle = '-'.$angle;
            }

            return 'transform:rotate('.$angle.'deg);-moz-transform:rotate('.$angle.'deg);-webkit-transform:rotate('.$angle.'deg);';
        }

        public static function randomImage($dir = 'assets/images', $extension = 'jpg')
        {
            /***
         * Fetch a random image from a directory
         *
         * @param string $dir A direcotry path
         * @param string $extension An extension to filter with (as
         *   dirListPHP's filter parameter)
         *
         * @return bool|string A path to a random image matching those
         *   criteria, or false if no matching items found.
         ***/
        $images = dirListPHP($dir, '.'.$extension);
            if ($images === false) {
                return false;
            }
            $item = rand(0, count($images) - 1);

            return $dir.'/'.$images[$item];
        }


        protected function getImage($imgFile)
        {
            if (function_exists(get_magic_quotes_gpc) && get_magic_quotes_gpc()) {
                $image = stripslashes($this->img);
            } else {
                $image = $this->img;
            }
            return $image;
        }

        public function setImage($imagePath)
        {
            if (function_exists(get_magic_quotes_gpc) && get_magic_quotes_gpc()) {
                $image = stripslashes($imagePath);
            } else {
                $image = $imagePath;
            }
            $this->img = $image;
        }

        public function imageExists()
        {
            $image = $this->getImage();

            if (strrchr($image, '/')) {
                $filename = substr(strrchr($image, '/'), 1); # remove folder references
            } else {
                $filename = $image;
            }

            return file_exists($image);
        }

        public function getImageDimensions()
        {
            $image = $this->getImage();

            if (strrchr($image, '/')) {
                $filename = substr(strrchr($image, '/'), 1); # remove folder references
            } else {
                $filename = $image;
            }

            if (!file_exists($image)) {
                return array('status' => false,'error' => 'File does not exist','image_path' => $image);
            }

            $size = getimagesize($image);
            $width = $size[0];
            $height = $size[1];
            return array(
            "width" => $width,
            "height" => $height,
        );
        }

        public function getWidth()
        {
            $size = $this->getImageDimensions();
            return $size["width"];
        }

        public function getHeight()
        {
            $size = $this->getImageDimensions();
            return $size["height"];
        }

        public static function staticResizeImage($imgfile, $output, $max_width = null, $max_height = null)
        {
            /***
         * Resize an image to parameters.
         *
         * @param string $imgfile The path to the image file
         * @param string $output The path where the output will be
         *   saved.
         * @param int $max_width The maximum width of the resize, in
         *   pixels (aspect ratio will be maintained)
         * @param int $max_height The maximum height of the resize, in
         *   pixels (aspect ratio will be maintained)
         *
         * @return array An array containing:
         *  status: boolean
         *  error: Explanation (only if error)
         *  image_file: Original path (only if error)
         *  ouput: Path to resized image
         *  dimensions: Human-friendly new dimensions
         ***/
        if (!is_numeric($max_height)) {
            $max_height = 1000;
        }
            if (!is_numeric($max_width)) {
                $max_width = 2000;
            }
            if (function_exists(get_magic_quotes_gpc) && get_magic_quotes_gpc()) {
                $image = stripslashes($imgfile);
            } else {
                $image = $imgfile;
            }

            if (strrchr($image, '/')) {
                $filename = substr(strrchr($image, '/'), 1); # remove folder references
            } else {
                $filename = $image;
            }

            if (!file_exists($image)) {
                return array('status' => false,'error' => 'File does not exist','image_path' => $image);
            }

            $size = getimagesize($image);
            $width = $size[0];
            $height = $size[1];
            if ($width == 0) {
                return array('status' => false, 'error' => 'Unable to compute image dimensions','image_path' => $image);
            }
        # get the ratio needed
        $x_ratio = $max_width / $width;
            $y_ratio = $max_height / $height;

        # if image already meets criteria, load current values in
        # if not, use ratios to load new size info
        if (($width <= $max_width) && ($height <= $max_height)) {
            $tn_width = $width;
            $tn_height = $height;
        } elseif (($x_ratio * $height) < $max_height) {
            $tn_height = ceil($x_ratio * $height);
            $tn_width = $max_width;
        } else {
            $tn_width = ceil($y_ratio * $width);
            $tn_height = $max_height;
        }

            $resized = 'cache/'.$tn_width.'x'.$tn_height.'-'.$filename;
            $imageModified = @filemtime($image);
            $thumbModified = @filemtime($resized);

        # read image
        $ext = strtolower(substr(strrchr($image, '.'), 1)); # get the file extension
        switch ($ext) {
        case 'jpg':     # jpg
            $src = imagecreatefromjpeg($image) or self::notfound();
            break;
        case 'png':     # png
            $src = imagecreatefrompng($image) or self::notfound();
            break;
        case 'gif':     # gif
            $src = imagecreatefromgif($image) or self::notfound();
            break;
        case 'bmp':     # bmp
            $src = imagecreatefromwbmp($image) or self::notfound();
            break;
        case 'webp':     # webp
            $src = imagecreatefromwebp($image) or self::notfound();
            break;
        default:
            self::notfound();
        }

        # set up canvas
        $dst = imagecreatetruecolor($tn_width, $tn_height);

            if (function_exists("imageantialias")) {
                imageantialias($dst, true);
            }
        # copy resized image to new canvas
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $tn_width, $tn_height, $width, $height);

        # send the header and new image
        if ($ext == 'jpg') {
            $status = imagejpeg($dst, $output, 75);
        } elseif ($ext == 'png') {
            $status = imagepng($dst, $output, 9);
        } elseif ($ext == 'gif') {
            $status = imagegif($dst, $output);
        } elseif ($ext == 'bmp') {
            $status = imagewbmp($dst, $output);
        } elseif ($ext == 'webp') {
            $status = imagewebp($dst, $output);
        } else {
            return array('status' => false,'error' => 'Illegal extension','image_path' => $image, 'extension' => $ext);
        }

        # clear out the resources
        imagedestroy($src);
            imagedestroy($dst);

            return array('status' => $status, 'output' => $output, 'output_size' => "$tn_width X $tn_height");
        }

        public function resizeImage($output, $max_width = null, $max_height = null)
        {
            /***
         * Resize an image to parameters.
         *
         * @param string $output The path where the output will be
         *   saved.
         * @param int $max_width The maximum width of the resize, in
         *   pixels (aspect ratio will be maintained)
         * @param int $max_height The maximum height of the resize, in
         *   pixels (aspect ratio will be maintained)
         *
         * @return array An array containing:
         *  status: boolean
         *  error: Explanation (only if error)
         *  image_file: Original path (only if error)
         *  ouput: Path to resized image
         *  dimensions: Human-friendly new dimensions
         ***/
        if (!is_numeric($max_height)) {
            $max_height = 1000;
        }
            if (!is_numeric($max_width)) {
                $max_width = 2000;
            }

            $image = $this->getImage();

            if (strrchr($image, '/')) {
                $filename = substr(strrchr($image, '/'), 1); # remove folder references
            } else {
                $filename = $image;
            }

            if (!file_exists($image)) {
                return array('status' => false,'error' => 'File does not exist','image_path' => $image);
            }

            $size = getimagesize($image);
            $width = $size[0];
            $height = $size[1];
            if ($width == 0) {
                return array('status' => false, 'error' => 'Unable to compute image dimensions','image_path' => $image);
            }
        # get the ratio needed
        $x_ratio = $max_width / $width;
            $y_ratio = $max_height / $height;

        # if image already meets criteria, load current values in
        # if not, use ratios to load new size info
        if (($width <= $max_width) && ($height <= $max_height)) {
            $tn_width = $width;
            $tn_height = $height;
        } elseif (($x_ratio * $height) < $max_height) {
            $tn_height = ceil($x_ratio * $height);
            $tn_width = $max_width;
        } else {
            $tn_width = ceil($y_ratio * $width);
            $tn_height = $max_height;
        }

            $resized = 'cache/'.$tn_width.'x'.$tn_height.'-'.$filename;
            $imageModified = @filemtime($image);
            $thumbModified = @filemtime($resized);

        # read image
        $ext = strtolower(substr(strrchr($image, '.'), 1)); # get the file extension
        switch ($ext) {
        case 'jpg':     # jpg
            $src = imagecreatefromjpeg($image) or self::notfound();
            break;
        case 'png':     # png
            $src = imagecreatefrompng($image) or self::notfound();
            break;
        case 'gif':     # gif
            $src = imagecreatefromgif($image) or self::notfound();
            break;
        case 'bmp':     # bmp
            $src = imagecreatefromwbmp($image) or self::notfound();
            break;
        case 'webp':     # webp
            $src = imagecreatefromwebp($image) or self::notfound();
            break;
        default:
            self::notfound();
        }

        # set up canvas
        $dst = imagecreatetruecolor($tn_width, $tn_height);

            if (function_exists("imageantialias")) {
                imageantialias($dst, true);
            }

        # copy resized image to new canvas
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $tn_width, $tn_height, $width, $height);

        # send the header and new image
        if ($ext == 'jpg') {
            $status = imagejpeg($dst, $output, 75);
        } elseif ($ext == 'png') {
            $status = imagepng($dst, $output, 9);
        } elseif ($ext == 'gif') {
            $status = imagegif($dst, $output);
        } elseif ($ext == 'bmp') {
            $status = imagewbmp($dst, $output);
        } elseif ($ext == 'webp') {
            $status = imagewebp($dst, $output);
        } else {
            return array('status' => false,'error' => 'Illegal extension','image_path' => $image, 'extension' => $ext);
        }

        # clear out the resources
        imagedestroy($src);
            imagedestroy($dst);

            return array('status' => $status, 'output' => $output, 'output_size' => "$tn_width X $tn_height");
        }
    }
}
