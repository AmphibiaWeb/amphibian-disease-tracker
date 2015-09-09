<?php

/***
 * Library for dealing with images
 ***/

function notfound() {
    throw new Exception("Not Found Exception");
}

function randomRotate($min,$max) {
    $angle=rand($min,$max);
    if(rand(0,100)%2)$angle="-".$angle;
    echo "transform:rotate(".$angle."deg);-moz-transform:rotate(".$angle."deg);-webkit-transform:rotate(".$angle."deg);";
}

function randomImage($dir=null) {
    if($dir==null) $dir='assets/gallery';
    $images=dirListPHP($dir,'.jpg');
    if($images===false) return false;
    $item=rand(0,count($images)-1);
    return $dir . '/' . $images[$item];
}

function resizeImage($imgfile,$output,$max_width=NULL,$max_height=NULL)
{
    if(!is_numeric($max_height)) $max_height=1000;
    if(!is_numeric($max_width)) $max_width=2000;
    if (function_exists(get_magic_quotes_gpc) && get_magic_quotes_gpc())
    {
        $image = stripslashes( $imgfile );
    } else  $image = $imgfile;
    // if (isset($max_width)) { if($max_width < 2000) $max_width = $max_width; }
    // if (isset($max_height)) { if($max_height < 1000) $max_height = $max_height; }
	
    if (strrchr($image, '/')) {
        $filename = substr(strrchr($image, '/'), 1); // remove folder references
    } else {
        $filename = $image;
    }
  
    if(!file_exists($image)) return false;
  
    $size = getimagesize($image);
    $width = $size[0];
    $height = $size[1];
    if($width == 0 ) return false;
    // get the ratio needed
    $x_ratio = $max_width / $width;
    $y_ratio = $max_height / $height;
	
    // if image already meets criteria, load current values in
    // if not, use ratios to load new size info
    if (($width <= $max_width) && ($height <= $max_height) ) {
        $tn_width = $width;
        $tn_height = $height;
    } else if (($x_ratio * $height) < $max_height) {
        $tn_height = ceil($x_ratio * $height);
        $tn_width = $max_width;
    } else {
        $tn_width = ceil($y_ratio * $width);
        $tn_height = $max_height;
    }
	
    /* Caching additions by Trent Davies */
    // first check cache
    // cache must be world-readable
    $resized = 'cache/'.$tn_width.'x'.$tn_height.'-'.$filename;
    $imageModified = @filemtime($image);
    $thumbModified = @filemtime($resized);
	
	
    // read image
    $ext = strtolower(substr(strrchr($image, '.'), 1)); // get the file extension
    switch ($ext) { 
    case 'jpg':     // jpg
        $src = imagecreatefromjpeg($image) or notfound();
        break;
    case 'png':     // png
        $src = imagecreatefrompng($image) or notfound();
        break;
    case 'gif':     // gif
        $src = imagecreatefromgif($image) or notfound();
        break;
    default:
        notfound();
    }
	
    // set up canvas
    $dst = imagecreatetruecolor($tn_width,$tn_height);
	
    imageantialias ($dst, true);
	
    // copy resized image to new canvas
    imagecopyresampled ($dst, $src, 0, 0, 0, 0, $tn_width, $tn_height, $width, $height);
	
    /* Sharpening adddition by Mike Harding */
    // sharpen the image (only available in PHP5.1)
    /*if (function_exists("imageconvolution")) {
      $matrix = array(    array( -1, -1, -1 ),
      array( -1, 32, -1 ),
      array( -1, -1, -1 ) );
      $divisor = 24;
      $offset = 0;
	
      imageconvolution($dst, $matrix, $divisor, $offset);
      }*/
	
    // send the header and new image
    if($ext=='jpg')
    {
        imagejpeg($dst, $output, 90);
    }
    else if ($ext=='png')
    {
        imagepng($dst, $output, 90);
    }
    else if ($ext=='gif')
    {
        imagegif($dst, $output, 90);
    }
	
    // clear out the resources
    imagedestroy($src);
    imagedestroy($dst);
    return true;
}



?>