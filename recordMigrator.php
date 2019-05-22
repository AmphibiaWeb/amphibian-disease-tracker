<?php



/*****************
 * Setup
 *****************/

#$show_debug = true;

if ($show_debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('RecordMigrator is running in debug mode!');
}

require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';

$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

$flatTable = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, "records_list");

$print_login_state = false;
require_once dirname(__FILE__).'/admin/async_login_handler.php';

$udb = new DBHelper($default_user_database, $default_sql_user, $default_sql_password, $sql_url, $default_user_table, $db_cols);
$login_status = getLoginState($get);

$start_script_timer = microtime_float();

$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);

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


/*******************************
 * Write a migrator
 *
 * See
 * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/215
 *******************************/

$synonymizeCountries = array(
    "Việt Nam" => "Vietnam",
    "United States of America" => "United States",
    "Монгол улс" => "Mongolia",
    "ශ්‍රී ලංකාව இலங்கை" => "Sri Lanka",
    "ປະເທດລາວ" => "Laos",
    "မြန်မာ" => "Myanmar",
    "Burma (Myanmar)" => "Myanmar",
    "Burma" => "Myanmar",
    "ព្រះរាជាណាចក្រ​កម្ពុជា" => "Cambodia",
    "中国" => "China",
    "Svizzera" => "Switzerland",
    "Schweiz, Suisse, Svizzera, Svizra" => "Switzerland",
    "Қазақстан" => "Kazakhstan",
    "Perú" => "Peru",
    "پاکستان‎" => "Pakistan",
    "Кыргызстан" => "Kyrgyzstan",
);


$recordsUpdated = 0;
$projectsUpdated = 0;
$badRows = array();
$projectsInspected = array();
$projectsAgeingList = array();
$projectsNoData = 0;
try {
    # Get DB columns
    $cols = $flatTable->getCols();
} catch (Exception $e) {
    $cols = array();
    $badRows[] = array(
        "message" => "Unable to get columns, initializing empty",
        "error" => $e->getMessage(),
    );
}

$newDbEntries = array();
$newCols = array();

## Begin project loop

# Look up distinct projects
$query = "SELECT `project_id`, `carto_id`, `modified` FROM `".$db->getTable()."` WHERE `project_id`!='' AND `project_id` IS NOT NULL";
$projectLookupQuery = $query;
$db->invalidateLink();
$result = mysqli_query($db->getLink(), $query);

$flatProjects = "SELECT DISTINCT project_id FROM `".$flatTable->getTable()."`";

$fpResult = mysqli_query($flatTable->getLink(), $flatProjects);
$flatRecordsProjects = array();
while ($flatRow = mysqli_fetch_row($fpResult)) {
    $flatRecordsProjects[] = $flatRow[0];
}



$rowsProcessed = 0;
$rowsProcessedWithGeocode = 0;
$geocodeInspected = 0;
$geocodeAttempted = 0;
$geocodeFailed = 0;
$goodDetail = array();
$useGeocoder = "GOOGLE";
$dupsRemoved = 0;
# Loop over each project ...
while ($projectRow = mysqli_fetch_row($result)) {
    $project = $projectRow[0];
    $projectsInspected[] = $project;
    $cartoid = $projectRow[1];
    $carto = json_decode(deEscape($cartoid), true);

    if (empty($carto["table"])) {
        $projectsNoData++;
        continue;
    }

    # Only projects with data can be in the flat table, so it's fine
    # to check here
    $flatKey = array_find($project, $flatRecordsProjects);
    if ($flatKey !== false) {
        unset($flatRecordsProjects[$flatKey]);
    }


    $modified = floatval($projectRow[2]);
    $ageingReason = "NATURAL";
    # Check the modified time in the project....
    # ... compared to flat table modified time
    $resultData = $flatTable->getQueryResults(array("project"=>$project), array("project","modified","reverse_geocoded","country"));
    $projectAgeing = $resultData[0]["modified"];
    foreach ($resultData as $testRow) {
        $geocodeTest = $testRow["reverse_geocoded"];
        $isArrayish = $testRow["country"] == "Array" || is_array($testRow["country"]) || is_array(json_decode($testRow["country"], true));
        $country = $testRow["country"];
        if (empty($geocodeTest) || empty($country) || $isArrayish) {
            break;
        }
    }
    if (empty($projectAgeing) || !is_numeric($projectAgeing)) {
        $ageingReason = "INVALID_AGE_VALUE";
        $badRows[] = array(
            "message" => "bad project ageing",
            "got" => $projectAgeing,
            "project" => $project,
            "will-use" => 0,
            "vals" => array(
                "empty" => empty($projectAgeing),
                "numeric" => is_numeric($projectAgeing),
                "float" => floatval($projectAgeing),
            ),
        );
        $projectAgeing = 0;
    } elseif (empty($geocodeTest) || empty($country) || $isArrayish) {
        # No geocoded results
        $ageingReason = "BAD_REVERSE_GEOCODE";
        if (empty($geocodeTest)) {
            $ageingReason .= "_FLAGGED_FAILED";
        } elseif (empty($country)) {
            $ageingReason .= "_NULL_COUNTRY";
        } elseif ($isArrayish) {
            $ageingReason .= "_BAD_DECODE";
        }
        $badRows[] = array(
            "message" => "No reverse geocode data for project",
            "got" => array(
                "reverse_geocoded" => $geocodeTest,
                "country" => $country,
            ),
            "project" => $project,
        );
        # Force an update
        $projectAgeing = 0;
    } else {
        $projectAgeing = floatval($projectAgeing);
    }
    $projectsAgeingList[] = array(
        "project" => $project,
        "ageing-value" => $projectAgeing,
        "data-last-modified" => $modified,
        "needs-ageing-update" => $projectAgeing < $modified,
        "ageing-reason" => $ageingReason,
    );
    # If the flat table is older...
    if ($projectAgeing < $modified && !toBool($_REQUEST["dedup"])) {
        $opts = array(
            'http' => array(
                'method' => 'GET',
                #'request_fulluri' => true,
                'ignore_errors' => true,
                'timeout' => 3.5, # Seconds
                "header" => "User-Agent: PHP/5.5 (Debian; x64); AmphibianDiseasePortal (+https://amphibiandisease.org; appid: amphibiandiseaseportal)\r\n" .
                  "Origin: https://amphibiandisease.org",
            ),
        );
        $context = stream_context_create($opts);
        $gMapsApiKey = "AIzaSyCkFBPtFAuZZmfxCgWVLY-8klRR6Dz4aeM";
        # ...pull the data from CartoDB
        if (empty($newDbEntries[$project])) {
            $newDbEntries[$project] = array();
        }
        $statements = array();

        $statements[] = "SELECT *, ST_asGeoJson(the_geom) FROM ".$carto["table"]."";
        $cartoPostUrl = 'https://'.$cartodb_username.'.cartodb.com/api/v2/sql';
        $cartoArgSuffix = '&api_key='.$cartodb_api_key;
        $responses = array();
        $parsed_responses = array();
        $urls = array();
        ini_set('allow_url_fopen', true);
        try {
            set_time_limit(0);
        } catch (Exception $e) {
            $length = 30 * sizeof($statements);
            set_time_limit($length);
        }
        foreach ($statements as $statement) {
            $statement = trim($statement);
            if (empty($statement)) {
                continue;
            }
            $cartoArgs = 'q='.urlencode($statement).$cartoArgSuffix;
            $cartoFullUrl = $cartoPostUrl.'?'.$cartoArgs;
            $urls[] = $cartoFullUrl;
            # Default get_contents
            $response = file_get_contents($cartoFullUrl, false, $context);
            $responses[] = $response;
            $decoded = json_decode($response, true);
            if (!empty($decoded["error"])) {
                $decoded["query"] = $statement;
                $decoded["encoded_query"] = urlencode($statement);
                $decoded["table"] = $carto["table"];
                $decoded["project_id"] = $project;
                $badRows[] = array(
                    "message" => "CartoDB query error",
                    "project" => $project,
                    "error" => $decoded["error"],
                );
                continue;
            }
            $parsed_responses[] = $decoded;
        }
        if (sizeof($parsed_responses) === 0) {
            continue;
        }
        $projectDataTime = microtime_float();
        $goodInfo = array(
            "project" => $project,
            "modified" => $modified,
            "flat-modified" => $projectAgeing,
            "flat-update-time" => $projectDataTime,
        );
        # Remove current project entries from flat table
        // $deleteStatus = $flatTable->deleteRow(array("project"=>$project));
        // if($deleteStatus["status"] === false) {
        //     $badRows[] = array(
        //         "message" => "Couldn't delete entries from flat table",
        //         "error" => $deleteStatus,
        //     );
        // } else {
        //     $goodInfo["deletion-status"] = $deleteStatus;
        // }
        $rows = 0;
        $refRow = null;
        foreach ($parsed_responses as $projectResponse) {
            foreach ($projectResponse["rows"] as $row) {
                if (!empty($row["error"])) {
                    $badRows[] = array(
                        "error" => "CartoDB error",
                        "project" => $project,
                        "row" => $row,
                    );
                    continue;
                }
                $row["project_id"] = $project;
                /*****************************
                 * Begin Reverse Geocode Blob
                 *****************************/
                $flagUpdate = false;
                $testKey = empty($row["fieldnumber"]) ? "sampleid" : "fieldnumber";
                $item = $flatTable->getQueryResults(array("project"=>$project, $testKey => $row[$testKey]), array("modified","reverse_geocoded","country","st_asgeojson","geocode_provider"));
                if (sizeof($item) === 1) {
                    # If the item is unique ...
                    $isArrayish = $item[0]["country"] == "Array" || is_array($item[0]["country"]) || is_array(json_decode($item[0]["country"], true));
                    if ($isArrayish) {
                        # Test it
                        try {
                            $testArray = json_decode($item[0]["country"], true);
                            if (is_array($testArray)) {
                                # Try to reconstruct it first
                                foreach ($testArray as $i => $component) {
                                    if (is_array($component)) {
                                        $types = $component["types"];
                                        if (in_array("country", $types)) {
                                            $item[0]["country"] = $component["long_name"];
                                            $item[0]["reverse_geocoded"] = true;
                                            $isArrayish = false;
                                            break;
                                        }
                                    } else {
                                        try {
                                            $types = $component["types"];
                                        } catch (Exception $e) {
                                            $types = $e->getMessage();
                                        }
                                        try {
                                            $badRows[] = array(
                                                "error" => "WARN: bad reparse array",
                                                "address" => $address,
                                                "component" => $component,
                                                "component_decode" => json_decode($component, true),
                                                "component_double" => json_decode(json_encode($component), true),
                                                "component_level" => $i,
                                                "types" => $types,
                                            );
                                        } catch (Exception $e) {
                                            $badRows[] = array(
                                                "error" => "WARN: bad reparse array exception ",
                                                "address" => $address,
                                                "component" => $component,
                                                "exception" => $e->getMessage(),
                                                "types" => $types,
                                            );
                                        }
                                    }
                                }
                            }
                        } catch (Exception $e) {
                            # Do nothing
                            $badRows[] = array(
                            "error" => "WARN: bad reparse array parent exception ",
                                    "address" => $address,
                                    "component" => $component,
                                    "exception" => $e->getMessage(),
                                    "types" => $types,
                                    );
                        }
                    }
                    if ($item[0]["reverse_geocoded"] === true &&
                        !empty($item[0]["country"]) &&
                        !$isArrayish) {
                        # There is a well-formatted country. Skip the geocode.
                        $row["reverse_geocoded"] = true;
                        $row["country"] = $item[0]["country"];
                        $row["st_asgeojson"] = $item[0]["st_asgeojson"];
                        $row["geocode_provider"] = empty($item[0]["geocode_provider"]) ? "GOOGLE" : $item[0]["geocode_provider"];
                        $flagUpdate = true;
                    } else {
                        $row["reverse_geocoded"] = false;
                    }
                } else {
                    $row["reverse_geocoded"] = false;
                }
                $geocodeInspected++;

                try {
                    # Don't geocode again if we don't have to
                    # We don't just want to continue above, because we
                    # might have other updates that are needed to be done
                    if ($row["reverse_geocoded"] !== true) {
                        $address = null;
                        if (empty($address)) {
                            # Reverse geocode datapoints
                            # https://developers.google.com/maps/documentation/geocoding/intro#ReverseGeocoding
                            require_once "geophp/geoPHP.inc";
                            if (empty($row["st_asgeojson"])) {
                                $geom = geoPHP::load($row["the_geom"], "wkb");
                            } else {
                                # We have the GeoJSON output
                                $geom = geoPHP::load($row["st_asgeojson"], "json");
                            }
                            $decimalLatLngGJ = $geom->out("json");
                            # Build it ourselves
                            $decimalLatLngArr = json_decode($decimalLatLngGJ, true);
                            $decimalLatLng = $decimalLatLngArr["coordinates"];
                            # CartoDB swaps the order
                            $lat = $decimalLatLng[1];
                            $lng = $decimalLatLng[0];
                            if (!empty($lat) && !empty($lng)) {
                                try {
                                    if ($useGeocoder == "GOOGLE") {
                                        try {
                                            # Use the API
                                            $reverseGeocoder = new GoogleGeocode();
                                            $address = $reverseGeocoder->write($geom, "array");
                                            $method = "geophp";
                                            #if(!is_array($address)) $address = json_decode($address, true);
                                        } catch (Exception $e) {
                                            $method = "api_endpoint_google";
                                            $gMapsEndpoint = "https://maps.googleapis.com/maps/api/geocode/json";
                                            $args = array();
                                            $args["latlng"] = $lat.",".$lng;
                                            $args["key"] = $gMapsApiKeyUnrestricted;
                                            $args["result_type"] = "country";
                                            $gMapsFullUrl = $gMapsEndpoint . "?" . http_build_query($args);
                                            $geocodeResponse = file_get_contents($gMapsFullUrl, false, $context);
                                            $addressBase = json_decode($geocodeResponse, true);
                                            # The library already returns this
                                            # https://github.com/phayes/geoPHP/blob/master/lib/adapters/GoogleGeocode.class.php#L107
                                            $address = $addressBase["results"][0]["address_components"];
                                        }


                                        $row["reverse_geocoded"] = true;
                                        if (is_array($address)) {
                                            foreach ($address as $partLevel => $part) {
                                                if (!is_array($part)) {
                                                    try {
                                                        $part = (array) $part;
                                                    } catch (Exception $e) {
                                                        # Leave it as is
                                                    }
                                                }
                                                if (is_array($part)) {
                                                    $types = $part["types"];
                                                    if (in_array("country", $types)) {
                                                        $row["country"] = $part["long_name"];
                                                        break;
                                                    }
                                                } else {
                                                    $badRows[] = array(
                                                        "error" => "WARN: bad array",
                                                        "address" => $address,
                                                        "part" => $part,
                                                        "part_level" => $partLevel,
                                                    );
                                                    # fallbacK??????
                                                }
                                            }
                                        }
                                        if (empty($row["country"])) {
                                            if ($addressBase["status"] == "OVER_QUERY_LIMIT" || $addressBase["status"] == "REQUEST_DENIED") {
                                                # Try an alternate geocoder
                                                $useGeocoder = "OSM";
                                            } elseif ($addressBase["status"] == "ZERO_RESULTS") {
                                                $row["country"] = "NO_GEOCODE_AVAILABLE_ZERO_RESULTS";
                                                $row["reverse_geocoded"] = true;
                                            } else {
                                                $row["country"] = json_encode($address);
                                                $row["reverse_geocoded"] = false;
                                                $geocodeFailed++;
                                                $badRows[] = array(
                                                    "response" => $geocodeResponse,
                                                    "address" => $address,
                                                    "row" => $rowsProcessed,
                                                    "project" => $project,
                                                    "method" => $method,
                                                );
                                            }
                                        }
                                    }
                                    if ($useGeocoder == "OSM") {
                                        # https://wiki.openstreetmap.org/wiki/Nominatim#Reverse_Geocoding
                                        $method = "api_endpoint_osm";
                                        $args = array();
                                        $args["lat"] = $lat;
                                        $args["lon"] = $lng;
                                        $args["format"] = "json";
                                        $args["addressdetails"] = 1;
                                        $oMapsEndpoint = "https://nominatim.openstreetmap.org/reverse";
                                        $oMapsFullUrl = $oMapsEndpoint . "?" . http_build_query($args);
                                        $geocodeResponse = file_get_contents($oMapsFullUrl, false, $context);
                                        $address = json_decode($geocodeResponse, true);
                                        $address = $address["address"];
                                        $row["country"] = $address["country"];
                                        $row["reverse_geocoded"] = true;
                                        if (empty($row["country"])) {
                                            $OVER_LIMIT_OSM = "<html>\n<head>\n<title>Bandwidth limit exceeded</title>\n</head>\n<body>\n<h1>Bandwidth limit exceeded</h1>\n\n<p>You have been temporarily blocked because you have been overusing OSM's geocoding service or because you have not provided sufficient identification of your application. This block will be automatically lifted after a while. Please take the time and adapt your scripts to reduce the number of requests and make sure that you send a valid UserAgent or Referer.</p>\n\n<p>For more information, consult the <a href=\"https://operations.osmfoundation.org/policies/nominatim/\">usage policy</a> for the OSM Nominatim server.\n</body>\n</head>\n";
                                            if ($geocodeResponse === false || $geocodeResponse == $OVER_LIMIT_OSM) {
                                                $useGeocoder = "HERE";
                                            } else {
                                                $geocodeFailed++;
                                                $badRows[] = array(
                                                        "response" => $geocodeResponse,
                                                        "address" => $address,
                                                        "row" => $rowsProcessed,
                                                        "project" => $project,
                                                        "method" => $method,
                                                        "latlng" => $decimalLatLng,
                                                        "url" => $oMapsFullUrl,
                                                    );
                                                $row["reverse_geocoded"] = false;
                                            }
                                        }
                                    }
                                    if ($useGeocoder == "HERE") {
                                        # https://developer.here.com/signup/geocoding
                                        # https://developer.here.com/rest-apis/documentation/geocoder/topics/request-first-reverse-geocode.html
                                        $method = "api_endpoint_heremaps";
                                        $args = array();
                                        $args["app_id"] = $hereAppId;
                                        $args["app_code"] = $hereAppCode;
                                        $args["mode"] = "retrieveAreas";
                                        $args["gen"] = 9;
                                        $args["prox"] = "$lat,$lng,100";
                                        $args["lat"] = $lat;
                                        $args["lng"] = $lng;
                                        $args["format"] = "json";
                                        $args["addressdetails"] = 1;
                                        $hMapsEndpoint = "https://reverse.geocoder.cit.api.here.com/6.2/reversegeocode.xml";
                                        $hMapsFullUrl = $hMapsEndpoint . "?" . http_build_query($args);
                                        $xmlResponse = file_get_contents($hMapsFullUrl, false, $context);
                                        # This is an XML response
                                        try {
                                            $xml = new Xml();
                                            $xml->setXml($xmlResponse);
                                            $address = $xml->getTagContents("Address");
                                            $xml->setXml($address);
                                            $country = $xml->getTagContents("Country");
                                            $additionalList = $xml->getAllTagContents("AdditionalData");
                                            $keys = $xml->getTagAttributes("AdditionalData", "key");
                                            $adKey = -1;
                                            foreach ($keys as $k=>$v) {
                                                if ($v["key"] == "CountryName") {
                                                    $adKey = $k;
                                                    break;
                                                }
                                            }
                                            if ($adKey >= 0 && array_key_exists($adKey, $additionalList)) {
                                                $country = $additionalList[$adKey];
                                            }
                                            $row["country"] = $country;
                                            if (empty($row["country"])) {
                                                throw new Exception("badcountry");
                                            }
                                        } catch (Exception $e) {
                                            $xmlResponse = str_replace(array("\n", "\r", "\t"), '', $xmlResponse);
                                            $xmlResponse = trim(str_replace('"', "'", $xmlResponse));
                                            $simpleXml = simplexml_load_string($xmlResponse);
                                            $geocodeResponse = json_encode($simpleXml);
                                            $address = json_decode($geocodeResponse, true);
                                            $address = $address["result"]["location"]["address"];
                                            $row["country"] = $address["country"];
                                        }
                                        $row["reverse_geocoded"] = true;
                                        if (empty($row["country"])) {
                                            $row["country"] = "FLAG_MANUAL";
                                            $badRows[] = array(
                                                "message" => "Unable to reverse geocode (all services failed)",
                                                "xml" => $xmlResponse,
                                                "address" => $address,
                                                "latlng" => $decimalLatLng,
                                                "url" => $hMapsFullUrl,
                                                "row" => $row,
                                                "service" => $useGeocoder,
                                            );
                                            $row["reverse_geocoded"] = false;
                                        }
                                    }
                                    $geocodeAttempted++;
                                } catch (Exception $e) {
                                    $row["country"] = null;
                                    $badRows[] = array(
                                        "message" => "Unable to reverse geocode (all services)",
                                        "error" => $e->getMessage(),
                                        "wkb" => $row["the_geom"],
                                        "latlng" => $decimalLatLng,
                                        "row" => $row,
                                        "service" => $useGeocoder,
                                    );
                                }
                            }
                        }
                    }
                } catch (Exception $e) {
                    $row["country"] = null;
                    $badRows[] = array(
                        "message" => "Unable to reverse geocode",
                        "error" => $e->getMessage(),
                        "wkb" => $row["the_geom"],
                        "latlng" => $decimalLatLng,
                        "row" => $row,
                    );
                }
                if (!empty($row["country"])) {
                    $row["geocode_provider"] = $useGeocoder;
                    $row["reverse_geocoded"] = true;
                }
                /*****************************
                 * End Reverse Geocode Blob
                 *****************************/
                # Unpack fimsExtra
                $fimsExtraEncoded = $row["fimsextra"];
                $fimsExtra = json_decode($fimsExtraEncoded, true);
                if (sizeof($fimsExtra) > 0) {
                    foreach ($fimsExtra as $bonusCol => $bonusData) {
                        if (is_array($bonusData)) {
                            $bonusData = json_encode($bonusData);
                        }
                        $row[$bonusCol] = $bonusData;
                    }
                }

                # Remove redundant rows
                unset($row["fimsextra"]);
                unset($row["id"]);

                # Add updated unix time column
                $row["modified"] = $projectDataTime;
                $row["project"] = $project;

                # Add rows to $newDbEntries
                $newDbEntries[$project][] = $row;
                # Add columns not in $cols to $newCols, and append to $cols
                foreach ($row as $refCol => $colData) {
                    # Lookup col type
                    $colDataType = null;
                    foreach ($db->getCols() as $colName => $colType) {
                        if (strtolower($colName) == strtolower($refCol)) {
                            $colDataType = $colType;
                            $refCol = $colName;
                            break;
                        } elseif ($refCol == "modified") {
                            $colDataType = "decimal(32))";
                            break;
                        } else {
                            $colDataType = "text";
                        }
                    }
                    if (empty($colDataType)) {
                        $colDataType = "text";
                    }
                    # Put col in cols
                    if (!array_key_exists($refCol, $cols)) {
                        $newCols[$refCol] = $colDataType;
                        $cols[$refCol] = $colDataType;
                    }
                }

                $rows++;
                $rowsProcessed++;
                if ($row["reverse_geocoded"]) {
                    $rowsProcessedWithGeocode++;
                }
            }
        }
        $goodDetail[] = $goodInfo;
        $projectsUpdated++;
    } else {
        # The records are up to date -- just run a dedup
        $query = "SELECT count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project'";
        $countResult = mysqli_query($flatTable->getLink(), $query);
        $row = mysqli_fetch_row($countResult);
        $projectTotal = $row[0];
        # Check mandatory col 1 of 2
        $col = "sampleid";
        $query = "SELECT DISTINCT `$col`, count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' GROUP BY `$col` HAVING count > 1";
        #
        $countResult = mysqli_query($flatTable->getLink(), $query);
        $rowCount = mysqli_num_rows($countResult);
        if ($rowCount === 1) {
            # Check the other mandatory col
            $col = "fieldnumber";
            $query = "SELECT DISTINCT `$col`, count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' GROUP BY `$col` HAVING count > 1";
            $countResult = mysqli_query($flatTable->getLink(), $query);
            $rowCount = mysqli_num_rows($countResult);
            if ($rowCount === 0) {
                # This project has no dups -- if the col was blank, the
                # count would be the same as the project total
                continue; # Next project
            }
        } elseif ($rowCount === 0) {
            # This project has no dups -- if the col was blank, the
            # count would be the same as the project total
            continue; # Next project
        }
        while ($row = mysqli_fetch_assoc($countResult)) {
            # Check the row for dups
            if ($row["count"] < $projectTotal) {
                $i = 0;
                $query = "SELECT id FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' AND `$col`='".$row[$col]."'";
                $subResult = mysqli_query($flatTable->getLink(), $query);
                $numDups = mysqli_num_rows($subResult);
                while ($subrow = mysqli_fetch_row($subResult)) {
                    $i++;
                    if ($i == $numDups) {
                        continue;
                    } # Don't remove the last copy
                    # Remove the dups
                    $removeId = $subrow[0];
                    $query = "DELETE FROM `".$flatTable->getTable()."` WHERE `id`=$removeId AND `project_id`='$project'";
                    $removalResult = mysqli_query($flatTable->getLink(), $query);
                    $dupsRemoved++;
                }
            } else {
                # The unique cols aren't actually unique.
                # Be conservative.
            }
        }
    }
}
## End project loop

# Remove any flat record projects that don't have a corresponding main
# project anymore
$removedProjects = array();
$removedProjectsFailed = array();
foreach ($flatRecordsProjects as $removeProject) {
    # Test
    if (empty($removeProject)) {
        continue;
    }
    $removeQuery = "DELETE FROM `".$flatTable->getTable()."` WHERE `project_id`='".$removeProject."'";
    $r = mysqli_query($flatTable->getLink(), $removeQuery);
    if ($r !== false) {
        $removedProjects[] = $removeProject;
    } else {
        $removedProjectsFailed[] = $removeProject;
    }
}


unset($newCols["id"]);

foreach ($newCols as $newColumn => $dataType) {
    # Add a column to the flat table
    $cleanColumn = $flatTable->sanitize($newColumn);
    $result = $flatTable->addColumn($cleanColumn, $dataType);
    if ($result["status"] !== true) {
        $badRows[] = array(
            "error" => $result,
            "message" => "Unable to add column",
            "column" => array(
                "name" => array(
                    "sanitized" => $cleanColumn,
                    "raw" => $newColumn,
                ),
                "type" => $dataType,
                "totals" => array(
                    "tracked" => $newCols,
                    "internal" => $flatTable->getCols(),
                ),
            ),
        );
    }
}

$goodRows = 0;
$skipId = array();
$dedupProjects = array();
foreach ($newDbEntries as $projectId => $data) {
    try {
        foreach ($data as $row) {
            $ref = array(
                "id" => $row["id"],
            );
            // if(in_array($ref["id"], $skipId)) continue;
            // $match = array(
            //     "project" => $row["project"],
            //     "sampleid" => $row["sampleid"],
            //     "fieldnumber" => $row["fieldnumber"],
            // );
            // $matches = $flatTable->getQueryResults($match, array("id"));
            // if(sizeof($matches) > 1) {
            //     # Houston, we have duplicates
            //     foreach($matches as $id) {
            //         $id = $id["id"];
            //         if($id == $ref["id"]) continue;
            //         $skipId[] = $id;
            //         $query = "DELETE FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' `id`=".$id;
            //         $result = mysqli_query($flatTable->getLink(), $query);
            //         if($result !== true) {
            //             $badRows[] = array(
            //                 "error" => "Couldn't delete duplicate rows",
            //                 "message" => mysqli_error($flatTable->getLink()),
            //                 "duplicate_ids" => $matches,
            //                 "match_criteria" => $match,
            //                 "query" => $query,
            //             );
            //         }
            //     }
            // }
            unset($row["id"]);
            if (array_key_exists($row["country"], $synonymizeCountries)) {
                $row["country"] = $synonymizeCountries[$row["country"]];
            }
            if ($flagUpdate !== true) {
                # Add a new row to the flat table
                # Carto has already handled santization
                if (!in_array($row["project"], $dedupProjects)) {
                    $dedupProjects[] = $row["project"];
                }
                $result = $flatTable->addItem($row, null, false, true);
                if ($result !== true) {
                    $badRow = array(
                        "error" => "Couldn't add row to database",
                        "project" => $projectId,
                        "result" => $result,
                        "row" => $row,
                    );
                    $badRows[] = $badRow;
                    continue;
                } else {
                    $goodRows++;
                }
                $recordsUpdated++;
            } else {
                # Do an update
                # Carto has already handled santization
                $result = $flatTable->updateEntry($row, $ref, null, true);
                if ($result !== true) {
                    $badRow = array(
                        "error" => "Couldn't update row in database",
                        "project" => $projectId,
                        "result" => $result,
                        "ref" => $ref,
                        "row" => $row,
                    );
                    $badRows[] = $badRow;
                    continue;
                } else {
                    $goodRows++;
                }
                $recordsUpdated++;
            }
        }
    } catch (Exception $e) {
        $badRow = array(
            "message" => "Couldn't update records for project",
            "error" => $e->getMessage(),
            "project" => $projectId,
        );
        $badRows[] = $badRow;
        continue;
    }
}

foreach ($dedupProjects as $project) {
    $query = "SELECT count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project'";
    $countResult = mysqli_query($flatTable->getLink(), $query);
    $row = mysqli_fetch_row($countResult);
    $projectTotal = $row[0];
    # Check mandatory col 1 of 2
    $col = "sampleid";
    $query = "SELECT DISTINCT `$col`, count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' GROUP BY `$col` HAVING count > 1";
    #
    $countResult = mysqli_query($flatTable->getLink(), $query);
    $rowCount = mysqli_num_rows($countResult);
    if ($rowCount === 1) {
        # Check the other mandatory col
        $col = "fieldnumber";
        $query = "SELECT DISTINCT `$col`, count(*) as count FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' GROUP BY `$col` HAVING count > 1";
        $countResult = mysqli_query($flatTable->getLink(), $query);
        $rowCount = mysqli_num_rows($countResult);
        if ($rowCount === 0) {
            # This project has no dups -- if the col was blank, the
            # count would be the same as the project total
            continue; # Next project
        }
    } elseif ($rowCount === 0) {
        # This project has no dups -- if the col was blank, the
        # count would be the same as the project total
        continue; # Next project
    }
    while ($row = mysqli_fetch_assoc($countResult)) {
        # Check the row for dups
        if ($row["count"] < $projectTotal) {
            $i = 0;
            $query = "SELECT id FROM `".$flatTable->getTable()."` WHERE `project_id`='$project' AND `$col`='".$row[$col]."'";
            $subResult = mysqli_query($flatTable->getLink(), $query);
            $numDups = mysqli_num_rows($subResult);
            while ($subrow = mysqli_fetch_row($subResult)) {
                $i++;
                if ($i == $numDups) {
                    continue;
                } # Don't remove the last copy
                # Remove the dups
                $removeId = $subrow[0];
                $query = "DELETE FROM `".$flatTable->getTable()."` WHERE `id`=$removeId AND `project_id`='$project'";
                $removalResult = mysqli_query($flatTable->getLink(), $query);
                $dupsRemoved++;
            }
        } else {
            # The unique cols aren't actually unique.
            # Be conservative.
        }
    }
}

$response = array(
    "rows-marked-modified" => $rowsProcessed,
    "records-updated" => $recordsUpdated,
    "dups-removed" => $dupsRemoved,
    "geocode" => array(
        "rows-geocoded-modified" => $rowsProcessedWithGeocode,
        "geocode-attempted" => $geocodeAttempted,
        "geocode-inspected" => $geocodeInspected,
    ),
    "columns-added" => $newCols,
    "projects" => array(
        "projects-removed" => array(
            "attempted" => sizeof($removedProjects) + sizeof($removedProjectsFailed),
            "succeeded" => $removedProjects,
            "failed" => $removedProjectsFailed,
        ),
        "projects-updated" => $projectsUpdated,
        "projects-inspected" => $projectsInspected,
        "projects-no-data" => $projectsNoData,
        "projects-ageing-list" => $projectsAgeingList,
    ),
    "rows" => array(
        "good-count" => $goodRows,
        "good-detail" => $goodDetail,
        "bad-count" => sizeof($badRows),
        "bad-detail" => $badRows,
    ),
    "total-entries" => mysqli_num_rows(mysqli_query($flatTable->getLink(), "SELECT * FROM `".$flatTable->getTable()."`")),
);


returnAjax($response);
