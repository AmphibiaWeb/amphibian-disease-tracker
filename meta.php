<?php

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
     * Return the data as a JSON object
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

function getUserFileModTime($get = array())
{
    $a = array("defaulted" => false);
    if(!empty($get["file"])) {
        $file = $get["file"];
        if(!file_exists($file)) {
            return "INVALID_FILE";
        }
    }
    else {
        $file = "js/c.min.js";
        $a["defaulted"] = true;
    }    
    $a = array(
        "last_mod" => filemtime($file),
        "file" => $file,
    );    
    return $a;
}

function doUploadImage()
{
    if (empty($_FILES)) {
        return array('status' => false,'error' => 'No files provided','human_error' => 'Please provide a file to upload');
    }
    $temp = $_FILES['file']['tmp_name'];
    $savePath = dirname(__FILE__).'/user_photos/';
    $file = $_FILES['file']['name'];
    $extension = array_pop(explode('.', $file));
    $newFilePath = md5($file).'.'.$extension;
    $fileWritePath = $savePath.$newFilePath;

    return array('status' => move_uploaded_file($temp, $fileWritePath),'original_file' => $file,'wrote_file' => $newFilePath,'full_path' => $fileWritePath);
}

if (isset($_SERVER['QUERY_STRING'])) {
    parse_str($_SERVER['QUERY_STRING'], $_REQUEST);
}
$do = isset($_REQUEST['do']) ? strtolower($_REQUEST['do']) : null;

switch ($do) {
case 'get_last_mod':
    returnAjax(getUserFileModTime());
    break;
case 'upload_image':
    returnAjax(doUploadImage());
    break;
default:
    $default_answer = array(
        'status' => false, 
        'error' => 'Invalid action', 
        'human_error' => 'No valid action was supplied.',
        "provided_args" => $_REQUEST,
        "requested_action" => $do,
    );
    # doUploadImage()
    returnAjax($default_answer);
}
