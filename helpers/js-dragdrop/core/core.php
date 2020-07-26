<?php

/***
 * Common Core Helper Functions
 *
 * @author Philip Kahn | https://github.com/tigerhawkvok
 * @copyright (c) 2006-2015 Velociraptor Systems LLC
 * @license MIT / GPL-3 dual-license
 ***/

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
        /***
         * Version independent timecode function
         ***/
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
        /***
         * Get a list of all the files in a given directory.
         *
         * @param $directory Mandatory. The directory to be crawled.
         * @param $filter A string to match files against. Only files
         *   matching the filter will be included.
         * @param $extension A string to match extensions against.
         * @param $debug Set as TRUE to get output on which files the
         *   script is finding.
         ***/
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

if (!function_exists('encode64')) {
    /***
       * Wrapper for the PHP functions, with strict encoding fixes on
       * the decode.
       ***/
    function encode64($data)
    {
        return base64_encode($data);
    }
    function decode64($data)
    {
        # This is STRICT decoding
        # Fix a bunch of random problems that can happen with PHP
        $enc = strtr($data, '-_', '+/');
        $enc = chunk_split(preg_replace('!\015\012|\015|\012!', '', $enc));
        $enc = str_replace(' ', '+', $enc);
        # Once we decode and re-encode, does it match?
      if (@base64_encode(@base64_decode($enc, true)) == $enc) {
          return urldecode(@base64_decode($data));
      }

        return false;
    }
}

if (!function_exists('strbool')) {
    function strbool($bool)
    {
        /***
         * Get the string value of a boolean value.
         * Therefore, (bool) true returns "true"
         *
         * @param boolean $bool
         * @return string
         ***/
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
        /***
         * Get the boolean value of "truthy" strings or ints.
         * Thus, "1", 1, "TRUE", and "true", all return (bool) true
         *
         * @param mixed $string A string (or 0/1) value to get the
         *   boolean of
         * @return bool
         ***/
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

      $params = array('http' => array(
        'method' => 'POST',
        'content' => http_build_query($data),
      ));
        if ($optional_headers !== null) {
            $params['http']['header'] = $optional_headers;
        }
        $ctx = stream_context_create($params);
      # If url handlers are set,t his whole next part can be file_get_contents($url,false,$ctx)
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
}

if (!function_exists('deEscape')) {
    function deEscape($input)
    {
        /***
         * Remove all escaping from a passed sequence.
         * Helpful for things that may need weird encoding for GET or
         * POST requests.
         *
         * @param string $input
         * @return string
         ***/
      return htmlspecialchars_decode(html_entity_decode(urldecode($input)));
    }
}

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

        imageantialias($dst, true);

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
        if (function_exists(get_magic_quotes_gpc) && get_magic_quotes_gpc()) {
            $image = stripslashes($this->img);
        } else {
            $image = $this->img;
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

        imageantialias($dst, true);

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
