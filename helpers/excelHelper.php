<?php

// ini_set("error_log","/usr/local/web/amphibian_disease/error-admin.log");
// ini_set("display_errors",1);
// ini_set("log_errors",1);
// error_reporting(E_ALL);

require_once dirname(__FILE__).'/../phpexcel/Classes/PHPExcel.php';

# We require the functions living in core.php
require_once dirname(__FILE__).'/../core/core.php';

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
    $replace_array = array('&quot;', '&#34;');
    echo str_replace($replace_array, '\\"', $json);
    exit();
}

# Based on this answer:
# http://stackoverflow.com/a/3895965/1877527

ini_set("memory_limit","512M");

function excelToPhp($filePath)
{
    $objWriter = PHPExcel_IOFactory::createWriter($objPHPExcel, 'CSV');
    $objWriter->save($filePath);
}

# From this gist: https://gist.github.com/calvinchoy/5821235
/*
  |--------------------------------------------------------------------------
  | Excel To Array
  |--------------------------------------------------------------------------
  | Helper function to convert excel sheet to key value array
  | Input: path to excel file, set wether excel first row are headers
  | Dependencies: PHPExcel.php include needed
*/
function excelToArray($filePath, $header = true, $sheets = null)
{
    //Create excel reader after determining the file type
    $inputFileName = $filePath;
    /*  Identify the type of $inputFileName  **/
    $inputFileType = PHPExcel_IOFactory::identify($inputFileName);
    /*  Create a new Reader of the type that has been identified  **/
    $objReader = PHPExcel_IOFactory::createReader($inputFileType);
    /* Set read type to read cell data only **/
    $objReader->setReadDataOnly(true);
    if (!empty($sheets)) {
        # See
        # https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/phpexcel/Documentation/markdown/ReadingSpreadsheetFiles/05-Reader-Options.md#reading-only-named-worksheets-from-a-file
        $objReader->setLoadSheetsOnly($sheets);
    }
    /*  Load $inputFileName to a PHPExcel Object  **/
    $objPHPExcel = $objReader->load($inputFileName);
    $sheetNames = $objPHPExcel->getSheetNames();
    if (!in_array($sheets, $sheetNames, true)) {
        # If the sheet doesn't exist, just read the first one
        $objReader = PHPExcel_IOFactory::createReader($inputFileType);
        $objReader->setReadDataOnly(true);
        $objPHPExcel = $objReader->load($inputFileName);
    }
    # Get worksheet and built array with first row as header
    $objWorksheet = $objPHPExcel->getActiveSheet();

    //excel with first row header, use header as key
    if ($header) {
        $highestRow = $objWorksheet->getHighestRow();
        $highestColumn = $objWorksheet->getHighestColumn();
        $headingsArray = $objWorksheet->rangeToArray('A1:'.$highestColumn.'1', null, true, true, true);
        $headingsArray = $headingsArray[1];

        $r = -1;
        $namedDataArray = array();
        for ($row = 2; $row <= $highestRow; ++$row) {
            $dataRow = $objWorksheet->rangeToArray('A'.$row.':'.$highestColumn.$row, null, true, true, true);
            if ((isset($dataRow[$row]['A'])) && ($dataRow[$row]['A'] > '')) {
                ++$r;
                foreach ($headingsArray as $columnKey => $columnHeading) {
                    $columnHeading = trim($columnHeading);
                    $namedDataArray[$r][$columnHeading] = $dataRow[$row][$columnKey];
                }
            }
        }
    } else {
        //excel sheet with no header
        $namedDataArray = $objWorksheet->toArray(null, true, true, true);
    }

    return $namedDataArray;
}

/********
 * Actual handler
 ********/
if (isset($_SERVER['QUERY_STRING'])) {
    parse_str($_SERVER['QUERY_STRING'], $_REQUEST);
}
$do = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : 'NO_PROVIDED_ACTION';

# Check the cases ....

switch ($do) {
case 'parse':
    $validatedPath = dirname(__FILE__).'/'.$_REQUEST['path'];
    if (!file_exists($validatedPath)) {
        returnAjax(array(
            'status' => false,
            'error' => "Non-existant file '".$validatedPath."'",
            'paths' => array(
                'requested_path' => $_REQUEST['path'],
                'validated_path' => $validatedPath,
            ),
            'human_error' => 'There was a problem validating your file. Please try again.',
        ));
    }
    $header = isset($_REQUEST['has_header']) ? boolstr($_REQUEST['has_header']) : true;
    $sheets = $_REQUEST['sheets'];
    $sheets_arr = explode(',', $sheets);
    if (sizeof($sheets_arr) > 1) {
        # PHPExcel only wants array for many sheets
        $sheets = $sheets_arr;
    }
    try {
        returnAjax(array(
            'status' => true,
            'data' => excelToArray($validatedPath, $header, $sheets),
            'path' => array(
                'requested_path' => $_REQUEST['path'],
                'validated_path' => $validatedPath,
            ),
        ));
    } catch (Exception $e) {
        returnAjax(array(
            'status' => false,
            'error' => $e->getMessage(),
        ));
    }
    break;
default:
    returnAjax(array(
        'status' => false,
        'error' => "Invalid action (got '$do')",
        'args' => $_REQUEST,
        'human_error' => "The server recieved an instruction it didn't understand. Please try again.",
    ));
}
