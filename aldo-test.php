<?php

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
    $json = json_encode($data, JSON_FORCE_OBJECT); #  | JSON_UNESCAPED_UNICODE
    $replace_array = array('&quot;','&#34;');
    print str_replace($replace_array, '\\"', $json);
    exit();
}


$response = array(
    "status" => true,
    "data" => "Simple test",
);


returnAjax($response);


?>