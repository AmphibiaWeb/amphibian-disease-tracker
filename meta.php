<?php

/***
 * Helper Handler for handling things like uploads, file time stamps,
 * and other non-mission/api critical tasks.
 *
 * @author Philip Kahn | https://github.com/tigerhawkvok
 * @copyright (c) 2015 Velociraptor Systems LLC
 * @license MIT / GPL-3 dual-license
 ***/

ini_set('post_max_size', '10M');
ini_set('upload_max_filesize', '10M');

# We require the functions living in core.php
require_once dirname(__FILE__).'/core/core.php';

$start_script_timer = microtime_float();

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

        return 1000 * (microtime_float() - (float) $start_time);
    }
}

function returnAjax($data)
{
    /***
     * Return the data as a JSON object. This function, when called,
     * will exit the script.
     *
     * @param array $data
     *
     ***/
    if (!is_array($data)) {
        $data = array($data);
    }
    $data['execution_time'] = elapsed();
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
    header('Content-type: application/json');
    $json = json_encode($data, JSON_FORCE_OBJECT);
    $replace_array = array('&quot;','&#34;');
    print str_replace($replace_array, '\\"', $json);
    exit();
}


function getRelativePath($fullPath)
{
    /***
     * Get relative descendant path. Useful for cleaning up full paths
     * of the server filesystem into something more web friendly.
     *
     * @param fullPath the full path to a file, that is in a
     * descendant directory of this one.
     ***/

    return str_replace(dirname(__FILE__).'/', '', $fullPath);
}

# Manual mime type checker from
# https://gist.github.com/Erutan409/8e774dfb2b343fe78b14#file-mimetype-php
include_once("manual_mime.php");


function handleUpload()
{
    /***
     * Determine the type of file upload handler that needs to be
     * used, then pass things along accordingly.
     ***/
    if (empty($_FILES)) {
        return array('status' => false,'error' => 'No files provided','human_error' => 'Please provide a file to upload');
    }
    $temp = $_FILES['file']['tmp_name'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $temp);
    finfo_close($finfo);
    $file = $_FILES['file']['name'];
    $mime_error = "";
    if(empty($mime)) {
        # Just the fallback that is based purely on extension
        # Only used when finfo can't find a mime type
        try {
            $mime = mime_type($file);
        } catch (Exception $e) {
            $mime_error = $e->getMessage();
            $mime = null;
        }
    }
    # Look at the MIME prefix
    $mime_types = explode('/', $mime);
    $mime_class = $mime_types[0];

    # Now, call the actual uploader function based on the mime class
    # (eg, image/, audio/, video/ ... )
    switch ($mime_class) {
    case 'image':
        return doUploadImage($mime);
        break;
    case 'audio':
        return doUploadAudio($mime);
        break;
    case 'video':
        return doUploadVideo($mime);
        break;
    default:
        # return array('status' => false,'error' => "Unrecognized MIME type '".$mime."' for file '".$file."' (".$mime_error.")", 'human_error' => 'Unsupported file format', "dumb_type"=>mime_type($file));
        $temp = $_FILES['file']['tmp_name'];
        $uploadPath = $_REQUEST['uploadpath'];
        $savePath = dirname(__FILE__).'/'.$uploadPath;
        if (!file_exists($savePath)) {
            return array(
                'status' => false,
                'error' => "Bad path '$savePath'",
                'human_error' => 'There is a server misconfiguration preventing your file from being uploaded',
            );
        }
        $file = $_FILES['file']['name'];
        $exploded = explode('.', $file);
        $extension = array_pop($exploded);
        $fileName = md5($file.microtime_float());
        $newFilePath = $fileName.'.'.$extension;
        $fileWritePath = $savePath.$newFilePath;
        # We want to suppress the warning on move_uploaded_file, or else
        # it'll return an invalid JSON response
        #error_reporting(0); # Disable this for debugging
        $status = move_uploaded_file($temp, $fileWritePath);
        $uploadStatus = array('status' => $status,'original_file' => $file,'wrote_file' => $newFilePath,'full_path' => getRelativePath($fileWritePath), "dumb_type"=>mime_type($file));
        return $uploadStatus;
    }
}

function doUploadVideo($passed_mime = null)
{
    /***
     *
     * Video upload handler. Right now, just basic upload handling.
     *
     * @todo Thumbnail generation to return for the client argument thumb_path
     *
     * It takes one optional function argument
     *
     * @param passed_mime The mime type of the file (to be passed to client)
     ***/
    if (empty($_FILES)) {
        return array('status' => false,'error' => 'No files provided','human_error' => 'Please provide a file to upload');
    }
    $temp = $_FILES['file']['tmp_name'];
    $uploadPath = $_REQUEST['uploadpath'];
    $savePath = dirname(__FILE__).'/'.$uploadPath;
    if (!file_exists($savePath)) {
        return array(
            'status' => false,
            'error' => "Bad path '$savePath'",
            'human_error' => 'There is a server misconfiguration preventing your file from being uploaded',
        );
    }
    $file = $_FILES['file']['name'];
    $exploded = explode('.', $file);
    $extension = array_pop($exploded);
    $fileName = md5($file.microtime_float());
    $newFilePath = $fileName.'.'.$extension;
    $fileWritePath = $savePath.$newFilePath;
    # We want to suppress the warning on move_uploaded_file, or else
    # it'll return an invalid JSON response
    #error_reporting(0); # Disable this for debugging
    $status = move_uploaded_file($temp, $fileWritePath);
    $uploadStatus = array('status' => $status,'original_file' => $file,'wrote_file' => $newFilePath,'full_path' => getRelativePath($fileWritePath));
    /***********
     * NEED THUMBNAIL GENERATION HERE
     * All indications are it needs something like FFMPEG, but it is
     * build-specific:
     * http://ffmpeg-php.sourceforge.net/
     *
     * Something like
     *
     * shell_exec("ffmpeg -i $VIDEO_PATH -deinterlace -an -ss 1 -t
     *   00:00:01 -r 1 -y -vcodec mjpeg -f mjpeg $THUMBNAIL_PATH 2>&1");
     *
     * *should* work, but it's a bit dicey to run a direct shell
     * command ...
     *
     * https://github.com/buggedcom/phpvideotoolkit-v2
     * may provide a solution but the docs are long and I've not read
     * through them yet.
     ***********/
    $uploadStatus['thumb_path'] = '';
    $uploadStatus['mime_provided'] = $passed_mime;
    # $uploadStatus["s3"] = copyToS3($fileWritePath, $newFilePath);
    $uploadStatus["wrote_thumb"] = "";
    return $uploadStatus;
}

function doUploadAudio($passed_mime = null)
{
    /***
     *
     * Audio file upload handling.
     * Largely basic uploading, but also returns a Glyphicon music
     * icon as a thumbnail icon.
     *
     * It takes one optional function argument
     *
     * @param passed_mime The mime type of the file (to be passed to client)
     ***/
    if (empty($_FILES)) {
        return array('status' => false,'error' => 'No files provided','human_error' => 'Please provide a file to upload');
    }
    $temp = $_FILES['file']['tmp_name'];
    $uploadPath = $_REQUEST['uploadpath'];
    $savePath = dirname(__FILE__).'/'.$uploadPath;
    if (!file_exists($savePath)) {
        return array(
            'status' => false,
            'error' => "Bad path '$savePath'",
            'human_error' => 'There is a server misconfiguration preventing your file from being uploaded',
        );
    }
    $file = $_FILES['file']['name'];
    $exploded = explode('.', $file);
    $extension = array_pop($exploded);
    $fileName = md5($file.microtime_float());
    $newFilePath = $fileName.'.'.$extension;
    $fileWritePath = $savePath.$newFilePath;
    # We want to suppress the warning on move_uploaded_file, or else
    # it'll return an invalid JSON response
    #error_reporting(0); # Disable this for debugging
    $status = move_uploaded_file($temp, $fileWritePath);
    $uploadStatus = array('status' => $status,'original_file' => $file,'wrote_file' => $newFilePath,'full_path' => getRelativePath($fileWritePath));
    # Provide a link to a static thumbnail path
    $uploadStatus['thumb_path'] = 'assets/glyphicons-18-music.png';
    $uploadStatus['mime_provided'] = $passed_mime;
    # $uploadStatus["s3"] = copyToS3($fileWritePath, $newFilePath);
    $uploadStatus["wrote_thumb"] = 'assets/glyphicons-18-music.png';
    return $uploadStatus;
}

function doUploadImage($passed_mime = null)
{
    /***
     * Works with the default $_FILES object and handles image
     * uploads.
     *
     * It then creates a thumbnail for easy display.
     *
     * It takes one optional function argument
     *
     * @param passed_mime The mime type of the file (to be passed to client)
     *
     * It has the following optional parameters, that should be
     * provided in the POST / GET request:
     *
     *
     * @param uploadpath the path, relative to this file, to save the
     * uploaded images. Should end in a trailing slash.
     *
     * @param thumb_width the maximum width of a thumbnail. (Aspect
     * ratio will be maintained)
     *
     * @param thumb_height the maximum height of a thumbnail (Aspect
     * ratio will be maintained)
     ***/
    if (empty($_FILES)) {
        return array('status' => false,'error' => 'No files provided','human_error' => 'Please provide a file to upload');
    }
    $temp = $_FILES['file']['tmp_name'];
    $uploadPath = $_REQUEST['uploadpath'];
    $savePath = dirname(__FILE__).'/'.$uploadPath;
    if (!file_exists($savePath)) {
        return array(
            'status' => false,
            'error' => "Bad path '$savePath'",
            'human_error' => 'There is a server misconfiguration preventing your file from being uploaded',
        );
    }
    $file = $_FILES['file']['name'];
    $exploded = explode('.', $file);
    $extension = array_pop($exploded);
    $fileName = md5($file.microtime_float());
    $newFilePath = $fileName.'.'.$extension;
    $fileWritePath = $savePath.$newFilePath;
    # We want to suppress the warning on move_uploaded_file, or else
    # it'll return an invalid JSON response
    #error_reporting(0); # Disable this for debugging
    $status = move_uploaded_file($temp, $fileWritePath);
    $uploadStatus = array('status' => $status,'original_file' => $file,'wrote_file' => $newFilePath,'full_path' => getRelativePath($fileWritePath));
    if (!$status) {
        # We bugged out on completing the upload. Return this status.
        # Formal mime type:
        # https://secure.php.net/manual/en/fileinfo.constants.php
        $finfo = finfo_open(FILEINFO_MIME);
        $mime = finfo_file($finfo, $temp);
        finfo_close($finfo);
        # Return the "real" path for debugging
        $uploadStatus["error"] = "Could not move uploaded file to destination ( Destination directory: ".realpath($savePath).")";
        $uploadStatus["mime"] = "Formal mime: '".$mime."'";
        $uploadStatus["human_error"] = "There was a problem saving your file to the server";
        return $uploadStatus;
    }
    # $uploadStatus["s3"] = copyToS3($fileWritePath, $newFilePath);
    # OK, create the thumbs.
    if (intval($_REQUEST['thumb_width']) > 0) {
        $thumb_max_width = intval($_REQUEST['thumb_width']);
    } else {
        $thumb_max_width = 640;
    }
    if (intval($_REQUEST['thumb_height']) > 0) {
        $thumb_max_height = intval($_REQUEST['thumb_height']);
    } else {
        $thumb_max_height = 480;
    }
    $fileThumb = $savePath.$fileName.'-thumb.'.$extension;
    $resizeStatus = ImageFunctions::staticResizeImage($fileWritePath, $fileThumb, $thumb_max_width, $thumb_max_height);
    $resizeStatus["s3"] = copyToS3($resizeStatus['output'], $fileName.'-thumb.'.$extension);
    $resizeStatus['output'] = getRelativePath($resizeStatus['output']);
    $uploadStatus['resize_status'] = $resizeStatus;
    $uploadStatus['thumb_path'] = $resizeStatus['output'];
    $uploadStatus["wrote_thumb"] = str_replace("uploaded/","",$resizeStatus["output"]);
    $uploadStatus['mime_provided'] = $passed_mime;
    return $uploadStatus;
}

/***************
 * Actual script
 ***************/

if (isset($_SERVER['QUERY_STRING'])) {
    parse_str($_SERVER['QUERY_STRING'], $_REQUEST);
}
$do = isset($_REQUEST['do']) ? strtolower($_REQUEST['do']) : null;

# Check the cases ....

switch ($do) {
# Extend other switches in here as cases ...
case 'upload_file':
    returnAjax(handleUpload());
    break;
case 'upload_image':
    returnAjax(doUploadImage());
    break;
default:
    $default_answer = array('status' => false, 'error' => 'Invalid action', 'human_error' => 'No valid action was supplied.');
    # doUploadImage()
    returnAjax($default_answer);
}
