<?php

/***
 * Handle admin-specific requests
 ***/
#$debug = true;


if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('AdminAPI is running in debug mode!');
}

try {
    ini_set('post_max_size', '500M');
    ini_set('upload_max_filesize', '500M');
} catch (Exception $e) {
}

$print_login_state = false;
require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
# This is a public API
header('Access-Control-Allow-Origin: *');

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

require_once dirname(__FILE__).'/admin/async_login_handler.php';

# Declaring this makes Aldo slow
# $udb = new DBHelper($default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols);

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

$admin_req = isset($_REQUEST['perform']) ? strtolower($_REQUEST['perform']) : null;

if ($admin_req == null && isset($_REQUEST["action"])) {
    $admin_req = strtolower($_REQUEST["action"]);
}

$login_status = getLoginState($get);

if ($as_include !== true) {
    if ($login_status['status'] !== true) {
        if ($admin_req == 'list') {
            returnAjax(listProjects());
        }
        if ($admin_req == "advanced_project_search") {
            returnAjax(advancedSearchProject($_REQUEST));
        }

        $login_status['error'] = 'Invalid user';
        $login_status['human_error'] = "You're not logged in as a valid user to do this. Please log in and try again.";
        returnAjax($login_status);
    }

    switch ($admin_req) {
        # Stuff
        case 'save':
            returnAjax(saveEntry($_REQUEST));
            break;
        case 'new':
            returnAjax(newEntry($_REQUEST));
            break;
        case 'delete':
            returnAjax(deleteEntry($_REQUEST));
            break;
        case 'list':
            returnAjax(listProjects(false));
            break;
        case 'sulist':
            returnAjax(suListProjects(false));
            break;
        case 'get':
            returnAjax(readProjectData($_REQUEST));
            break;
        case 'edit_access':
        case 'editaccess':
            $link = $_REQUEST['project'];
            $deltas = smart_decode64($_REQUEST['deltas']);
            returnAjax(editAccess($link, $deltas));
            break;
        case 'mint_data':
        case 'mint':
            $link = $_REQUEST['link'];
            $file = $_REQUEST['file'];
            $title64 = $_REQUEST['title'];
            $title = decode64($title64);
            if (empty($link) || empty($title)) {
                returnAjax(array(
                    'status' => false,
                    'error' => 'BAD_PARAMETERS',
                ));
            }
            $addToExpedition = isset($_REQUEST['expedition']) ? boolstr($_REQUEST['expedition']) : false;
            returnAjax(mintBcid($link, $file, $title, $addToExpedition));
            break;
        case 'create_expedition':
            $link = $_REQUEST['link'];
            $title64 = $_REQUEST['title'];
            $public = boolstr($_REQUEST['public']);
            $title = decode64($title64);
            if (empty($link) || empty($title)) {
                returnAjax(array(
                    'status' => false,
                    'error' => 'BAD_PARAMETERS',
                ));
            }
            $associate = boolstr($_REQUEST['bind_datasets']);
            returnAjax(mintExpedition($link, $title, $public, $associate));
            break;
        case 'associate_expedition':
            $link = $_REQUEST['link'];
            $bcid = isset($_REQUEST['bcid']) ? $_REQUEST['bcid'] : null;
            returnAjax(associateBcidsWithExpeditions($link, null, $bcid));
            break;
        case 'validate':
          //$data = $_REQUEST["data"];
            $datasrc = $_REQUEST['datasrc'];
            $link = isset($_REQUEST['link']) ? $_REQUEST['link'] : $_REQUEST['project'];
            $cookies = $_REQUEST['auth'];
            $continue = empty($cookies) ? false : true;
            returnAjax(validateDataset($datasrc, $link, $cookies, $continue));
            break;
        case 'check_access':
            returnAjax(authorizedProjectAccess($_REQUEST));
            break;
        case 'su_manipulate_user':
            returnAjax(superuserEditUser($_REQUEST));
            break;
        case "update_profile":
            returnAjax(updateOwnProfile($_REQUEST));
            break;
        case "write_profile_image":
            returnAjax(saveProfileImage($_REQUEST));
            break;
        case 'advanced_project_search':
            returnAjax(advancedSearchProject($_REQUEST));
            break;
        case "invite":
            returnAjax(inviteUser($_REQUEST));
            break;
        case "notify":
            $subject = empty($_REQUEST["subject"]) ? null : $_REQUEST["subject"];
            $body = empty($_REQUEST["body"]) ? null : $_REQUEST["body"];
            returnAjax(notifyUsers($_REQUEST["project"], $subject, $body));
            break;
        default:
            $defaultResponse = getLoginState($_REQUEST, true);
            $defaultResponse["requested"] = $admin_req;
            returnAjax($defaultResponse);
    }
}

function inviteUser($get)
{
    # Is the invite target valid?
    $destination = deEscape($get["invitee"]);
    if (!preg_match('/^(?:[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$/im', $destination)) {
        return array(
            "status" => false,
            "action" => "INVITE_USER",
            "error" => "INVALID_EMAIL",
            "target" => $destination,
          );
    }
    # Go through the process
    $u = new UserFunctions($login_status["detail"]["dblink"], 'dblink');
    # Does the invite target exist as a user?
    $userExists = $u->isEntry($destination, $u->userColumn);
    if ($userExists !== false) {
        return array(
          "status" => false,
              "error" => "ALREADY_REGISTERED",
              "target" => $destination,
              "action" => "INVITE_USER",
          );
    }
    require_once dirname(__FILE__).'/admin/PHPMailer/PHPMailerAutoload.php';
    require_once dirname(__FILE__).'/admin/CONFIG.php';
    global $is_smtp,$mail_host,$mail_user,$mail_password,$is_pop3;
    $mail = new PHPMailer();
    if ($is_smtp) {
        $mail->isSMTP();
        $mail->SMTPAuth = true;
        $mail->Host = $mail_host;
        $mail->Username = $mail_user;
        $mail->Password = $mail_password;
        $mail->SMTPSecure = 'tls';
        $mail->Port = 587;
    }
    if ($is_pop3) {
        $mail->isPOP3();
    } # Need to expand this
    $mail->From = $u->getUsername();
    $mail->FromName = $u->getShortUrl().' on behalf of '.$u->getName();
    $mail->isHTML(true);
    $mail->addAddress($destination);
    $mail->Subject = "[".$u->getShortUrl()."] Invitation to Collaborate";
    $body = "<h1>You've been invited to join a research project!</h1><p>You've been invited to join ".$u->getShortUrl()." by ".$u->getName()." (".$u->getUsername().").</p><p>Visit <a href='https://amphibiandisease.org/admin-login.php?q=create'>https://amphibiandisease.org/admin-login.php?q=create</a> to create a new user and get going!</p>";
    $mail->Body = $body;
    $success = $mail->send();
    if ($success) {
        return array(
            "status" => $success,
            "action" => "INVITE_USER",
            "invited" => $destination,
        );
    } else {
        return array(
            "status" => $success,
            "action" => "INVITE_USER",
            "invited" => $destination,
            "error" => "MAIL_SEND_FAIL",
            "error_detail" => $mail->ErrorInfo,
        );
    }
}


function notifyUsers($projectId, $subject = "Default Message", $body = "Default Body", $superusers = false)
{
    /***
     * Wrapper to handle notifying users of changes.
     ***/
    require_once dirname(__FILE__).'/admin/PHPMailer/PHPMailerAutoload.php';
    require_once dirname(__FILE__).'/admin/CONFIG.php';
    global $is_smtp,$mail_host,$mail_user,$mail_password,$is_pop3, $db;
    $mail = new PHPMailer();
    if ($is_smtp) {
        $mail->isSMTP();
        $mail->SMTPAuth = true;
        $mail->Host = $mail_host;
        $mail->Username = $mail_user;
        $mail->Password = $mail_password;
        $mail->SMTPSecure = 'tls';
        $mail->Port = 587;
    }
    if ($is_pop3) {
        $mail->isPOP3();
    } # Need to expand this
    $mail->From = "blackhole@amphibiandisease.org";
    $mail->FromName = "Amphibian Disease Webserver";
    $mail->isHTML(true);
    # Look up the project
    $query = "SELECT `author`, `author_data`, `access_data`, `technical_contact_email` FROM `disease_tracking_data` WHERE `project_id` = '".$db->sanitize($projectId)."'";
    $userList = array();
    $r = mysqli_query($db->getLink(), $query);
    $row = mysqli_fetch_assoc($r);
    # Find recipients
    if ($row["technical_contact_email"] !== null) {
        $userList[] = $row["technical_contact_email"];
    }
    $authorData = json_decode($row["author_data"], true);
    $authorEmail = $authorData["contact_email"];
    $userList[] = $authorEmail;
    $accessors = explode(",", $row["access_data"]);
    foreach ($accessors as $accessString) {
        $parts = explode(":", $accessString);
        $uid = $parts[0];
        $query = "SELECT `username` FROM `userdata` WHERE `dblink`='".$uid."'";
        $r = mysqli_query($db->getLink(), $query);
        $row = mysqli_fetch_row($r);
        $email = $row[0];
        if ($email !== null && $email != $authorEmail) {
            $userList[] = $email;
        }
    }

    # Add superusers
    $query = "SELECT `username` FROM `userdata` WHERE `su_flag` IS TRUE";
    $r = mysqli_query($db->getLink(), $query);
    while ($row = mysqli_fetch_row($r)) {
        $userList[] = $row[0];
    }
    # Add everyone to the mail object
    foreach ($userList as $destination) {
        $mail->addAddress($destination);
    }
    $mail->Subject = "[Server Notice] ".$subject;
    $htmlBody = "<html><head><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/></head><body>".$body."</body></html>";
    $mail->Body = $htmlBody;
    $success = $mail->send();
    #$success = false;
    if ($success) {
        return array(
            "status" => $success,
            "action" => "NOTIFY_USER",
            "notified" => $userList,
        );
    } else {
        return array(
            "status" => $success,
            "action" => "NOTIFY_USER",
            "notified" => $userList,
            "error" => "MAIL_SEND_FAIL",
            "error_detail" => $mail->ErrorInfo,
            "body" => $body,
            "subject" => $subject,
            // "accessors" => $accessors,
            // "author"=> $authorData,
        );
    }
}


function saveEntry($get)
{
    /***
     * Save updates to a project
     *
     * @param data a base 64-encoded JSON string of the data to insert
     ***/

    $data64 = $get['data'];
    $enc = strtr($data64, '-_', '+/');
    $enc = chunk_split(preg_replace('!\015\012|\015|\012!', '', $enc));
    $enc = str_replace(' ', '+', $enc);
    $data_string = base64_decode($enc);
    $data = json_decode($data_string, true);
    if (!isset($data['project_id']) || !isset($data['id'])) {
        # The required attribute is missing
        $details = array(
                          'original_data' => $data64,
                          'decoded_data' => $data_string,
                          'data_array' => $data,
                          'message' => 'POST data attribute "project_id" or "id" is missing',
                          );

        return array(
        'status' => false,
        'error' => 'BAD_PARAMETERS',
        'detail' => $details,
        'human_error' => 'The request to the server was malformed. Please try again.',
      );
    }
    global $db, $login_status;
    $uid = $login_status['detail']['uid'];
    $project = $data['project_id'];
    $id = $data['id'];
    if (!$db->isEntry($id)) {
        return array(
            'status' => false,
            'error' => 'INVALID_PROJECT',
            'human_error' => 'No project exists at database row #'.$id,
        );
    }
    $search = array('id' => $id);
    $projectServerDataRow = $db->getQueryResults($search);
    $projectServer = $projectServerDataRow[0];
    if ($projectServer['project_id'] != $project) {
        return array(
            'status' => false,
            'error' => 'MISMATCHED_PROJECT_IDENTIFIERS',
            'human_error' => 'The project at row #'.$id." doesn't match the provided project number (provided: '".$project."'; expected '".$projectServer['project_id']."')",
        );
    }
    $authorizedStatus = checkProjectAuthorized($projectServer, $uid);
    if (!$authorizedStatus['can_edit']) {
        return array(
            'status' => false,
            'error' => 'UNAUTHORIZED',
            'human_error' => 'You have insufficient privileges to edit project #'.$project,
        );
    }
    # Remove some read-only attributes
    $ref = array(
        'project_id' => $project,
    );
    unset($data['project_id']); # Obvious
    unset($data['project_obj_id']); # ARK
    if (strlen($data['dataset_arks']) < strlen($projectServer['dataset_arks'])) {
        # It can only grow, not shrink
        # Check formatting
        unset($data['dataset_arks']);
    }
    unset($data['id']); # Obvious
    unset($data['access_data']); # Handled seperately

    try {
        $result = $db->updateEntry($data, $ref);
    } catch (Exception $e) {
        return array(
            'status' => false,
            'error' => $e->getMessage(),
            'humman_error' => 'Database error saving',
            'data' => $data,
            'ref' => $ref,
        );
    }
    if ($result !== true) {
        return array(
            'status' => false,
            'error' => $result,
            'human_error' => 'Database error saving',
            'data' => $data,
            'ref' => $ref,
        );
    }

    return array(
        'status' => true,
        'data' => $data,
        'project' => readProjectData($project, true),
    );
}

function newEntry($get)
{
    /***
   * Create a new entry
   *
   *
   * @param data a base 64-encoded JSON string of the data to insert
   ***/
    global $login_status;
    $isUnrestricted = toBool($login_status["unrestricted"]);
    if (!$isUnrestricted) {
        return array(
            "status" => false,
            "error" => "RESTRICTED_USER_UNAUTHORIZED",
            "human_error" => "Your account is still restricted. Please unrestrict your account before trying to create a project.",
        );
    }
    $data64 = $get['data'];
    $enc = strtr($data64, '-_', '+/');
    $enc = chunk_split(preg_replace('!\015\012|\015|\012!', '', $enc));
    $enc = str_replace(' ', '+', $enc);
    $data_string = base64_decode($enc);
    $data = json_decode($data_string, true);
  # Add the perform key
  global $db;
    try {
        $result = $db->addItem($data);
    } catch (Exception $e) {
        return array('status' => false, 'error' => $e->getMessage(), 'humman_error' => 'Database error saving', 'data' => $data, 'ref' => $result, 'perform' => 'new');
    }
    if ($result !== true) {
        return array('status' => false, 'error' => $result, 'human_error' => 'Database error saving', 'data' => $data, 'ref' => $result, 'perform' => 'new');
    }

    return array('status' => true, 'perform' => 'new', 'data' => $data);
}

function deleteEntry($get)
{
    /***
     * Delete a project entry described by the ID parameter
     *
     * @param $get["id"] The DB id to delete
     ***/
    global $db, $login_status;
    $uid = $login_status['detail']['uid'];
    $id = $get['id'];
    if (!$db->isEntry($id)) {
        return array(
            'status' => false,
            'error' => 'INVALID_PROJECT',
            'human_error' => 'No project exists at database row #'.$id,
        );
    }
    $search = array('id' => $id);
    $project = $db->getQueryResults($search);
    $authorizedStatus = checkProjectAuthorized($project, $uid);
    if (!$authorizedStatus['can_edit']) {
        return array(
            'status' => false,
            'error' => 'UNAUTHORIZED',
            'human_error' => 'You have insufficient privileges to delete project #'.$project['project_id'],
        );
    }
    $result = $db->deleteRow($id, 'id');
    if ($result['status'] === false) {
        $result['human_error'] = "Failed to delete item '$id' from the database";
    }

    return $result;
}

function editAccess($link, $deltas)
{
    /***
     *
     ***/
    global $db, $login_status,$default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols;
    try {
        $udb = new DBHelper($default_user_database, $default_sql_user, $default_sql_password, $sql_url, $default_user_table, $db_cols);
        $uid = $login_status['detail']['uid'];
        $pid = $db->sanitize($link);

        if (!$db->isEntry($pid, 'project_id', true)) {
            return array(
                'status' => false,
                'error' => 'INVALID_PROJECT',
                'human_error' => 'No project #'.$pid.' exists',
            );
        }
        $search = array('project_id' => $pid);
        $projectList = $db->getQueryResults($search, '*', 'AND', false, true);
        $project = $projectList[0];
        $originalAccess = $project['access_data'];
        $authorizedStatus = checkProjectAuthorized($project, $uid);
        if (!$authorizedStatus['can_edit']) {
            return array(
                'status' => false,
                'error' => 'UNAUTHORIZED',
                'human_error' => 'You have insufficient privileges to change user permissions on project #'.$pid,
            );
        }
        if (!is_array($deltas)) {
            return array(
                'status' => false,
                'error' => 'BAD_DELTAS',
                'human_error' => 'Your permission changes were malformed. Please correct them and try again.',
            );
        }
        $additions = $deltas['add'];
        $removals = $deltas['delete'];
        $changes = $deltas['changes'];
        $editList = $authorizedStatus['editors'];
        $viewList = $authorizedStatus['viewers'];
        $authorList = array($project['author']);
        $totalList = array_merge($editList, $viewList, $authorList);
        $notices = array();
        $operations = array();

        # Add users
        foreach ($additions as $newUid) {
            if (!$udb->isEntry($newUid, 'dblink')) {
                $notices[] = 'User '.$user['uid']." doesn't exist";
                continue;
            }

            if (in_array($newUid, $totalList)) {
                $notices[] = "$newUid is already given project permissions";
                continue;
            }
            $viewList[] = $newUid;
            $operations[] = "Succesfully added $newUid as a viewer";
        }

        # Remove users
        foreach ($removals as $user) {
            # Remove user from list after looping through each
            if (!is_array($user)) {
                $notices[] = "Couldn't remove user, permissions object malformed";
                continue;
            }
            if (!$udb->isEntry($user['uid'], 'dblink')) {
                $notices[] = 'User '.$user['uid']." doesn't exist";
                continue;
            }

            $currentRole = strtolower($user['currentRole']);
            if ($currentRole == 'edit') {
                $observeList = 'editList';
            } elseif ($currentRole == 'read') {
                $observeList = 'viewList';
            } elseif ($currentRole == 'authorList') {
                # Check the lists for other author thing
                $observeList = 'authorList';
                continue;
            } else {
                $notices[] = "Unrecognized current role '".strotupper($currentRole)."'";
                continue;
            }
            $key = array_find($user['uid'], ${$observeList});
            if ($key === false) {
                $notices[] = 'Invalid current role for '.$user['uid'];
                continue;
            }
            $orig = ${$observeList};
            unset(${$observeList}[$key]);
            $operations[] = 'User '.$user['uid']." removed from role '".strtoupper($currentRole)."' in ".$observeList;
        }

        # Changes to existing users
        foreach ($changes as $user) {
            if (!is_array($user)) {
                $notices[] = "Couldn't change permissions, permissions object malformed";
                continue;
            }
            if (!$udb->isEntry($user['uid'], 'dblink')) {
                $notices[] = 'User '.$user['uid']." doesn't exist";
                continue;
            }
            if (empty($user['currentRole']) || empty($user['newRole']) || empty($user['uid'])) {
                $notices[] = "Couldn't change permissions, missing one of newRole, uid, or currentRole for user";
                continue;
            }
            # Match the roles
            $newRole = strtolower($user['newRole']);
            $currentRole = strtolower($user['currentRole']);
            if ($newRole == $currentRole) {
                $notices[] = 'User '.$user['uid']." already has permissions '".strtoupper($currentRole)."'";
                continue;
            }
            if ($currentRole == 'edit') {
                $observeList = 'editList';
            } elseif ($currentRole == 'read') {
                $observeList = 'viewList';
            } elseif ($currentRole == 'authorList') {
                $observeList = 'authorList';
            } else {
                $notices[] = "Unrecognized current role '".strtoupper($currentRole)."'";
                continue;
            }
            if ($newRole == 'edit') {
                $addToList = 'editList';
            } elseif ($newRole == 'read') {
                $addToList = 'viewList';
            } elseif ($newRole == 'authorList' || $newRole == "author") {
                # $addToList = 'authorList';
                $addToList = 'editList';
            } else {
                $notices[] = "Unrecognized new role '".strtoupper($newRole)."'";
                continue;
            }
            $useAuthorQuery = false;
            if ($newRole == 'edit' || $newRole == 'read' || $newRole == "author") {
                $key = array_find($user['uid'], ${$observeList});
                if ($key === false) {
                    $notices[] = 'Invalid current role for '.$user['uid'];
                    continue;
                }
                if ($observeList == 'authorList') {
                    # Someone else must be set as the author
                } else {
                    unset(${$observeList}[$key]);
                }
                array_push(${$addToList}, $user['uid']);
                $operations[] = 'Removed '.$user['uid']." from $observeList and added to $addToList";
                if ($newRole == 'author') {
                    # Need to do fanciness
                    $useAuthorQuery = true;
                    $authorQuery = 'UPDATE `'.$db->getTable()."` SET `author`='".$user['uid']."' WHERE `project_id`='".$pid."'";
                    $db->closeLink();
                    $r = mysqli_query($db->getLink(), $authorQuery);
                    if ($r !== true) {
                        throw(new Exception(mysqli_error($db->getLink())));
                    }
                    $operations[] = "Changed project author to ".$user['uid'];
                }
            } else {
                $notices[] = 'Invalid role assignment for user '.$user['uid'];
            }
        }
        # Write the new lists back out
        $newList = array();
        $editListTracker =array();
        $readListTracker = array();
        foreach ($editList as $user) {
            if (array_key_exists($user, $editListTracker)) {
                continue;
            }
            $newList[] = $user.':EDIT';
            $editListTracker[$user] = true;
        }
        foreach ($viewList as $user) {
            if (array_key_exists($user, $readListTracker)) {
                continue;
            }
            $newList[] = $user.':READ';
            $readListTracker[$user] = true;
        }
        $newListString = implode(',', $newList);
        $newListString = $db->sanitize($newListString);
        $newEntry = array(
            'access_data' => $newListString,
        );
        $lookup = array(
            'project_id' => $pid,
        );
        $db->closeLink();
        $query = 'UPDATE `'.$db->getTable()."` SET `access_data`='".$newListString."' WHERE `project_id`='".$pid."'";

        $r = mysqli_query($db->getLink(), $query);
        if ($r !== true) {
            throw(new Exception(mysqli_error($db->getLink())));
        }
        $projectList = $db->getQueryResults($search, 'access_data', 'AND', false, true);
        $project = $projectList[0];

        return array(
            'status' => true,
            'operations_status' => $operations,
            'notices' => $notices,
            'new_access_list' => $newList,
            'deltas' => $deltas,
            'new_access_saved' => $newListString,
            // "new_access_entry" => $project["access_data"],
            // "original" => $originalAccess,
            // "search" => $search,
            // "query" => $query,
            'project_id' => $pid,
        );
    } catch (Exception $e) {
        return array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'Server error processing access changes',
        );
    }
}

function listProjects($unauthenticated = true)
{
    /***
     * List accessible projects to the user.
     *
     * @param bool $unauthenticated -> Check for authorized projects
     * to the user if false. Default true.
     ***/
    global $db, $login_status;
    $query = 'SELECT `project_id`,`project_title`, `carto_id`, `author_data`, `sample_raw_data` FROM '.$db->getTable().' WHERE `public` IS TRUE';
    $l = $db->openDB();
    $r = mysqli_query($l, $query);
    $authorizedProjects = array();
    $editableProjects = array();
    $authoredProjects = array();
    $publicProjects = array();
    $queries = array();
    $queries[] = $query;
    $checkedPermissions = array();
    $cartoTableList = array();
    while ($row = mysqli_fetch_row($r)) {
        $authorizedProjects[$row[0]] = $row[1];
        $publicProjects[] = $row[0];
        try {
            $cartoJson = json_decode(deEscape($row[2]), true);
            $authorJson = json_decode(deEscape($row[3]), true);
            $cartoTable = $cartoJson["table"];
            $creation = $authorJson["entry_date"];
            $cartoTableList[$row[0]] = array(
                "table" => $cartoTable,
                "creation" => $creation,
                "has_data" => !empty($row[4]),
            );
        } catch (Exception $e) {
        }
    }
    if (!$unauthenticated) {
        try {
            $uid = $login_status['detail']['uid'];
        } catch (Exception $e) {
            $queries[] = 'UNAUTHORIZED';
        }
        if (!empty($uid)) {
            $searchedAuthorized = true;
            $query = 'SELECT `project_id`,`project_title`,`author`, `carto_id`, `author_data`, `sample_raw_data` FROM `'.$db->getTable()."` WHERE (`access_data` LIKE '%".$uid."%' OR `author`='$uid')";
            $queries[] = $query;
            $r = mysqli_query($l, $query);
            while ($row = mysqli_fetch_row($r)) {
                $pid = $row[0];
                if (empty($pid)) {
                    continue;
                }
                # All results here are authorized projects
                $authorizedProjects[$pid] = $row[1];
                try {
                    $cartoJson = json_decode(deEscape($row[3]), true);
                    $authorJson = json_decode(deEscape($row[4]), true);
                    $cartoTable = $cartoJson["table"];
                    $creation = $authorJson["entry_date"];
                    $cartoTableList[$row[0]] = array(
                        "table" => $cartoTable,
                        "creation" => $creation,
                        "has_data" => !empty($row[5]),
                    );
                } catch (Exception $e) {
                }
                if ($row[2] == $uid) {
                    $authoredProjects[] = $pid;
                    $editableProjects[] = $pid;
                } else {
                    # Check permissions
                    $access = checkProjectIdAuthorized($pid);
                    $accessCopy = $access;
                    unset($accessCopy["detail"]);
                    $checkedPermissions[$pid] = $accessCopy;
                    $isEditor = $access["detailed_authorization"]["can_edit"];
                    $isViewer = $access["detailed_authorization"]["can_view"];
                    if ($isEditor === true) {
                        $editableProjects[] = $pid;
                    }
                }
            }
        } else {
            $searchedAuthorized = false;
        }
    }

    $result = array(
        'status' => true,
        'projects' => $authorizedProjects,
        'public_projects' => $publicProjects,
        'authored_projects' => $authoredProjects,
        'editable_projects' => $editableProjects,
        'check_authentication' => !$unauthenticated,
        "carto_table_map" => $cartoTableList,
        "checked_authorized_projects" => $searchedAuthorized,
        #"permissions" => $checkedPermissions,
    );

    return $result;
}

function suListProjects()
{
    global $db, $login_status;
    $suFlag = $login_status['detail']['userdata']['su_flag'];
    $isSu = boolstr($suFlag);
    if ($isSu !== true) {
        return array(
            'status' => false,
            'error' => 'INVALID_PERMISSIONS',
            'human_error' => "Sorry, you don't have permissions to do that.",
        );
    }
    # Get a list of all the projects
    $query = 'SELECT `project_id`,`project_title`, `public` FROM '.$db->getTable();
    try {
        $l = $db->openDB();
        $r = mysqli_query($l, $query);
        $projectList = array();
        while ($row = mysqli_fetch_row($r)) {
            $details = array(
                'title' => $row[1],
                'public' => boolstr($row[2]),
            );
            $projectList[$row[0]] = $details;
        }

        return array(
            'status' => boolstr($suFlag),
            'projects' => $projectList,
        );
    } catch (Exception $e) {
        return array(
            'status' => false,
            'error' => 'SERVER_ERROR',
            'human_error' => 'The server returned an error: '.$e->message(),
        );
    }
}


function checkProjectIdAuthorized($projectId, $simple = false)
{
    /***
     *
     *
     * @return array. If $simple = true, @return bool
     ***/
    $access = array("project"=>$projectId);
    try {
        $accessResult = authorizedProjectAccess($access);
    } catch (Exception $e) {
        $accessResult = array(
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "Bad access result; defaulting no access",
        );
    }
    return $simple ? $accessResult["status"] : $accessResult;
}

function checkProjectAuthorized($projectData, $uid)
{
    /***
     * Helper function for checking authorization
     ***/
    global $login_status;
    $currentUser = $login_status['detail']['uid'];
    if ($uid == $currentUser) {
        $suFlag = $login_status['detail']['userdata']['su_flag'];
        $isSu = boolstr($suFlag);
    } else {
        $isSu = false;
    }
    $isAuthor = $projectData['author'] == $uid;
    $isPublic = boolstr($projectData['public']);
    $accessList = explode(',', $projectData['access_data']);
    $editList = array();
    $viewList = array();
    foreach ($accessList as $viewer) {
        $permissions = explode(':', $viewer);
        $user = $permissions[0];
        $access = $permissions[1];
        if ($access == 'READ') {
            $viewList[] = $user;
        }
        if ($access == 'EDIT') {
            $editList[] = $user;
        }
        # Any other access value, including nullish, gives no permissions
    }
    $isEditor = in_array($uid, $editList);
    $isViewer = in_array($uid, $viewList);
    if ($isSu === true) {
        # Superuser is everything!
        if (!$isEditor) {
            $editList[] = $uid;
        }
        $isAuthor = true;
        $isEditor = true;
    }
    $response = array(
        'can_edit' => $isAuthor || $isEditor,
        'can_view' => $isAuthor || $isEditor || $isViewer || $isPublic,
        'is_author' => $isAuthor,
        'editors' => $editList,
        'viewers' => $viewList,
        'check' => array(
            'current_user' => $currentUser,
            'checked_user' => $uid,
            'is_checked' => $uid == $currentUser,
            'is_su' => $isSu,
        ),
        "raw_access" => $projectData['access_data'],
        "parsed_access" => $accessList,
    );

    return $response;
}

function authorizedProjectAccess($get)
{
    global $db, $login_status;
    $userProject = $get['project'];
    $db->invalidateLink();
    $project = $db->sanitize($userProject);
    $projectExists = $db->isEntry($project, 'project_id', true);
    if (!$projectExists) {
        return array(
            'status' => false,
            'error' => 'INVALID_PROJECT',
            'human_error' => "This project doesn't exist. Please check your project ID.",
            'project_id' => $project,
            "provided" => $get,
            "read" => $userProject,
        );
    }
    $uid = $login_status['detail']['uid'];
    $projectDataList = $db->getQueryResults(array("project_id"=>$project), "*", "AND", false, true);
    $projectData = $projectDataList[0];
    $authorizedStatus = checkProjectAuthorized($projectData, $uid);
    $status = $authorizedStatus['can_view'];
    $results = array(
        'status' => $status,
        'project' => $project,
        'detailed_authorization' => $authorizedStatus,
    );
    if ($status === true) {
        $results['detail'] = readProjectData($project, true);
    }

    return $results;
}

function readProjectData($get, $precleaned = false, $debug = false)
{
    /***
     *
     ***/
    global $db, $login_status;
    if ($precleaned) {
        $project = $get;
    } else {
        $project = $db->sanitize($get['project']);
    }
    $userdata = $login_status['detail'];
    unset($userdata['source']);
    unset($userdata['iv']);
    unset($userdata['userdata']['random_seed']);
    unset($userdata['userdata']['special_1']);
    unset($userdata['userdata']['special_2']);
    unset($userdata['userdata']['su_flag']);
    unset($userdata['userdata']['admin_flag']);
    # Base response
    $response = array(
        'status' => false,
        'error' => 'UNPROCESSED_READ',
        'human_error' => 'Server error handling project read',
        'project' => array(
            'project_id' => $project,
            'public' => false,
        ),
        'user' => array(
            'user' => $login_status['detail']['userdata']['dblink'],
            'has_edit_permissions' => false,
            'has_view_permissions' => false,
            'is_author' => false,
        ),

    );
    if ($debug) {
        $response['debug'] = array();
    }
    # Actual projecting
    $query = 'SELECT * FROM '.$db->getTable()." WHERE `project_id`='".$project."'";
    if ($debug) {
        $response['debug']['query'] = $query;
    }
    $l = $db->openDB();
    $r = mysqli_query($l, $query);
    $row = mysqli_fetch_assoc($r);
    # First check the user auth
    $uid = $userdata['uid'];
    if ($debug) {
        $pc = array(
            'checked_id' => $uid,
            'checked_data' => $row,
            'performed_query' => $query,
        );
        $response['debug']['permissions'] = $pc;
    }
    $permission = checkProjectAuthorized($row, $uid);
    if ($permission['can_view'] !== true) {
        $response['human_error'] = 'You are not authorized to view this project';
        $response['error'] = 'ACCESS_AUTHORIZATION_FAILED';
        $response['details'] = $permission;

        return $response;
    }
    # It's good, so set permissions
    $response['user']['has_edit_permissions'] = $permission['can_edit'];
    $response['user']['has_view_permissions'] = $permission['can_view'];
    $response['user']['is_author'] = $permission['is_author'];
    # Rewrite the users to be more practical
    $u = new UserFunctions($row['author'], 'dblink');
    $detail = $u->getUser($row['author']);
    $accessData = array(
        'editors' => array(),
        'viewers' => array(),
        'total' => array(),
        'editors_list' => array(),
        'viewers_list' => array(),
        'author' => $u->getUsername(),
        'composite' => array(),
        'raw' => $row['access_data'],
    );
    # Add the author to the lists
    $accessData['editors_list'][] = $u->getUsername();
    $accessData['total'][] = $u->getUsername();
    $accessData['editors'][] = $u->getHardlink();
    $accessData['composite'][$u->getUsername()] = $u->getHardlink();
    # Editors
    foreach ($permission['editors'] as $editor) {
        # Get the editor data
        $u = new UserFunctions($editor, 'dblink');
        $detail = $u->getUser($editor);
        $editor = array(
            'email' => $u->getUsername(),
            'user_id' => $u->getHardlink(),
        );
        $accessData['editors'][] = $editor;
        $accessData['editors_list'][] = $u->getUsername();
        $accessData['total'][] = $u->getUsername();
        $accessData['composite'][$u->getUsername()] = $editor;
    }
    foreach ($permission['viewers'] as $viewer) {
        # Get the viewer data
        $u = new UserFunctions($viewer, 'dblink');
        $detail = $u->getUser($viewer);
        $viewer = array(
            'email' => $u->getUsername(),
            'user_id' => $u->getHardlink(),
        );
        $accessData['viewers'][] = $viewer;
        $accessData['viewers_list'][] = $u->getUsername();
        $accessData['composite'][$u->getUsername()] = $viewer;
        if (!in_array($accessData['total'], $u->getUsername())) {
            $accessData['total'][] = $u->getUsername();
        }
    }
    sort($accessData['total']);
    # Replace the dumb permissions
    $row['access_data'] = $accessData;
    # Append it
    $row['public'] = boolstr($row['public']);
    $row['includes_anura'] = boolstr($row['includes_anura']);
    $row['includes_caudata'] = boolstr($row['includes_caudata']);
    $row['includes_gymnophiona'] = boolstr($row['includes_gymnophiona']);
    $response['project'] = $row;
    # Do we want to flag if the current user is a superuser?
    # Return it!
    $response['status'] = true;
    $response['error'] = null;
    $response['human_error'] = null;
    $response['project_id'] = $project;
    $response['project_id_raw'] = $get['project'];

    return $response;
}



function mintBcid($projectLink, $datasetRelativeUri = null, $datasetTitle, $addToExpedition = false, $fimsAuthCookiesAsString = null)
{
    /***
     *
     * Mint a BCID for a dataset (originally, a BCID for a project).
     *
     * Sample response:
     *
     *{"projectCode":"AMPHIB","validationXml":"https:\/\/raw.githubusercontent.com\/biocodellc\/biocode-fims\/master\/Documents\/AmphibianDisease\/amphibiandisease.xml","projectId":"26","datasetTitle":"Amphibian Disease"},
     *
     * See
     * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
     *
     * Resolve the ark with https://n2t.net/
     *
     * @param string $datasetRelativeUri -> the relative URI (to root)
     *   of a dataset. If this file doesn't exist, assume it's a
     *   project identifier.
     * @param string $datasetTitle -> title of the dataset
     * @param array $addToExpedition -> If an array, add to the expedition
     *   in key "expedition", or the the saved expedition for the
     *   project in key "project_id"
     * @param string $fimsAuthCookie -> the formatted cookie string to
     *   place in a POST header
     * @return array
     ***/
     global $db;
    $fimsDefaultHeaders = array(
          'Content-type: application/x-www-form-urlencoded',
          'Accept: application/json',
          'User-Agent: amphibian disease portal',
          );
    # FIMS probably already does this, but let's be a good net citizen.
    $datasetRelativeUri = $db->sanitize($datasetRelativeUri);
    $datasetTitle = $db->sanitize($datasetTitle);
    $projectLink = $db->sanitize($projectLink);
    $dataFileName = array_pop(explode('/', $datasetRelativeUri));
    $dataNameArray = explode('.', $dataFileName);
    array_pop($dataNameArray);
    $dataFileIdentifier = implode('.', $dataNameArray);
    $datasetCanonicalUri = 'https://amphibiandisease.org/project.php?id='.$projectLink.'#dataset:'.$dataFileIdentifier;
    # Is the dataset a file, or a project identifier?
    $notices = array();
    $filePath = dirname(__FILE__).'/'.$datasetRelativeUri;
    if (strpos($datasetRelativeUri, '.') === false || !file_exists($filePath)) {
        # No file extension == no file
        # Prevent legacy things from breaking
        $datasetCanonicalUri = 'https://amphibiandisease.org/project.php?id='.$projectLink;
        if (empty($datasetTitle)) {
            $datasetTitle = $datasetRelativeUri;
        }
        $notices[] = array(
          "message" => "Bad file",
          "has_extension" => strpos($datasetRelativeUri, '.') !== false,
          "file_exists" => file_exists($filePath),
          "provided_relative_uri" => $datasetRelativeUri,
          "computed_path" => $filePath,
        );
    }
    $fimsMintUrl = 'http://www.biscicol.org/biocode-fims/rest/bcids';
    # http://biscicol.org/biocode-fims/rest/fims.wadl#idp752895712
    $fimsMintData = array(
        'webAddress' => $datasetCanonicalUri,
        'title' => $datasetTitle,
        'resourceType' => 'http://purl.org/dc/dcmitype/Dataset',
    );
    try {
        if (empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsAuthUrl = 'http://www.biscicol.org/biocode-fims/rest/authenticationService/login';
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = 'amphibiaweb'; # AmphibianDisease
            $fimsAuthData = array(
                'username' => $fimsUserCredential,
                'password' => $fimsPassCredential,
            );
            # Post the login
            $params = array('http' => array(
                'method' => 'POST',
                'content' => http_build_query($fimsAuthData),
                'header' =>   implode("\r\n", array(
                    'Content-type: application/x-www-form-urlencoded',
                    'Accept: application/json',
                    'User-Agent: amphibian disease portal',
                ))."\r\n",
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            if ($rawResponse === false) {
                throw(new Exception("Fatal FIMS communication error 001 (No Response)"));
            }
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = '';
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1].';';
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if (empty($loginResponse['url'])) {
                throw(new Exception('Invalid Login Response E001'));
            }
        } else {
            $loginResponse = 'NO_LOGIN_CREDENTIALS_PROVIDED';
            $cookiesString = $fimsAuthCookiesAsString;
            $params = array(
                'http' => array(
                    'method' => 'POST',
                ),
            );
        }
        # Post the args
        $headers = implode("\r\n", array(
            'Content-type: application/x-www-form-urlencoded',
            'Accept: application/json',
            'User-Agent: amphibian disease portal',
            'Cookie: '.$cookiesString,
        ))."\r\n";
        $params['http']['header'] = $headers;
        $params['http']['content'] = http_build_query($fimsMintData);
        $ctx = stream_context_create($params);
        $rawResponse = file_get_contents($fimsMintUrl, false, $ctx);
        if ($rawResponse === false) {
            throw(new Exception("Fatal FIMS communication error 002 (No Response)"));
        }
        $resp = json_decode($rawResponse, true);
        # Get the ID in the result
        /***
         * Example result:
         {"login_response":{"url":"http:\/\/www.biscicol.org\/index.jsp"},"mint_response":{"identifier":"ark:\/21547\/AKQ2"},"response_headers":{"0":"HTTP\/1.1 200 OK","1":"X-FRAME-OPTIONS: DENY","2":"Set-Cookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;Path=\/;HttpOnly","3":"Expires: Thu, 01 Jan 1970 00:00:00 GMT","4":"Content-Type: application\/json","5":"Content-Length: 44","6":"Server: Jetty(9.2.6.v20141205)"},"cookies":{"JSESSIONID":"vvt1703eq52ub0jazasfu87h"},"post_headers":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n","post_params":{"http":{"method":"POST","content":"webAddress=https%3A%2F%2Famphibiandisease.org%2Fproject.php%3Fid%3Dfoobar&title=test&resourceType=http%3A%2F%2Fpurl.org%2Fdc%2Fdcmitype%2FDataset","header":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n"}},"execution_time":2675.9889125824}
        ***/
        $identifier = $resp['identifier'];
        if (empty($identifier)) {
            throw(new Exception('Invalid identifier in response'));
        }
        $response = array(
            'status' => true,
            'ark' => $identifier,
            'project_permalink' => $datasetCanonicalUri,
            'project_title' => $datasetTitle,
            'file_path' => $filePath,
            'provided' => array(
                'project_id' => $projectLink,
                'data_uri' => $datasetRelativeUri,
                'data_title' => $datasetTitle,
                'data_parts' => array(
                    'data_file_name' => $dataFileName,
                    'data_file_identifier' => $dataFileIdentifier,
                ),
            ),
            'responses' => array(
                'login_response' => array(
                    'response' => $loginResponse,
                    'cookies' => $cookiesString,
                ),
                'mint_response' => $resp,
            ),

        );
        if ($addToExpedition === true) {
            $response['responses']['association'] = associateBcidsWithExpeditions($projectLink, $cookiesString, $identifier);
        }

        return $response;
    } catch (Exception $e) {
        return array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem communicating with the FIMS project. Please try again later.',
            "raw_response" => $rawResponse,
            "action" => "mintBcid",
        );
    }
}

function associateBcidsWithExpeditions($projectLink, $fimsAuthCookiesAsString = null, $bcidToAssociate = null)
{
    /***
     * Finds the list of `dataset_arks` associated with the project,
     * and associate each of them with this expedition
     *
     * @param string $projectLink -> the project ID
     ***/
    global $db;

    $fimsAssociateUrl = 'http://www.biscicol.org/biocode-fims/rest/expeditions/associate';
    $projectLink = $db->sanitize($projectLink);
    if (empty($projectLink)) {
        returnAjax(array(
            'status' => false,
            'error' => 'BAD_PARAMETERS',
        ));
    }
    $associationData = array(
        'projectId' => 26,
        'expeditionCode' => $projectLink,
    );

    # Get all the arks
    $arkArray = array();
    if (empty($bcidToAssociate)) {
        $search = array('project_id' => $projectLink);
        $cols = array('dataset_arks');
        $results = $db->getQueryResults($search, $cols, 'AND', false, true);
        $row = $results[0];
        $data = explode(',', $row['dataset_arks']);
        foreach ($data as $arkPair) {
            $arkData = explode('::', $arkPair);
            $ark = $arkData[0];
            $arkArray[] = $ark;
        }
    } else {
        $arkArray[] = $bcidToAssociate;
    }
    try {
        if (empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = 'amphibiaweb'; # AmphibianDisease
            $fimsAuthUrl = 'http://www.biscicol.org/biocode-fims/rest/authenticationService/login';
            $fimsAuthData = array(
                'username' => $fimsUserCredential,
                'password' => $fimsPassCredential,
            );
            # Post the login
            $params = array('http' => array(
                'method' => 'POST',
                'content' => http_build_query($fimsAuthData),
                'header' => implode("\r\n", array(
                    'Content-type: application/x-www-form-urlencoded',
                    'Accept: application/json',
                    'User-Agent: amphibian disease portal',
                ))."\r\n",
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            if ($rawResponse === false) {
                throw(new Exception("Fatal FIMS communication error 003 (No Response)"));
            }
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = '';
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1].';';
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if (empty($loginResponse['url'])) {
                throw(new Exception('Invalid Login Response E002'));
            }
        } else {
            $loginResponse = 'NO_LOGIN_CREDENTIALS_PROVIDED';
            $cookiesString = $fimsAuthCookiesAsString;
            $params = array(
                'http' => array(
                    'method' => 'POST',
                ),
            );
        }
        # Post the args
        $headers = implode("\r\n", array(
            'Content-type: application/x-www-form-urlencoded',
            'Accept: application/json',
            'User-Agent: amphibian disease portal',
            'Cookie: '.$cookiesString,
        ))."\r\n";
        $params['http']['header'] = $headers;

        $associateResponses = array();
        $associateResponsesRaw = array();
        foreach ($arkArray as $bcid) {
            $tempAssociationData = $associationData;
            $tempAssociationData['bcid'] = $bcid;
            $params['http']['content'] = http_build_query($tempAssociationData);
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAssociateUrl, false, $ctx);
            if ($rawResponse === false) {
                throw(new Exception("Fatal FIMS communication error 004 (No Response)"));
            }
            $resp = json_decode($rawResponse, true);
            $associateResponses[] = $resp;
            if (empty($resp)) {
                # Get a header from CURL
                $ch = curl_init($fimsAssociateUrl);
                curl_setopt($ch, CURLOPT_POST, 1);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $tempAssociationData);
                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
                curl_setopt($ch, CURLOPT_COOKIE, $cookiesString);
                $httpHeader = array(
                    'Content-type: application/x-www-form-urlencoded',
                    'Accept: application/json',
                );
                curl_setopt($ch, CURLOPT_HTTPHEADER, $httpHeader);
                curl_setopt($ch, CURLOPT_HEADER, 1);
                $rawResponse = curl_exec($ch);
                curl_close($ch);
                $rawResponse = array('response' => $rawResponse);
                $rawResponse['detail_params'] = array(
                    'post_fields' => $tempAssociationData,
                    'http_headers' => $httpHeader,
                );
            }
            $associateResponsesRaw[] = $rawResponse;
        }

        return array(
            'status' => true,
            'responses' => $associateResponses,
            'raw_responses' => $associateResponsesRaw,
            'arks_associated' => $arkArray,
        );
    } catch (Exception $e) {
        return array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem communicating with the FIMS project. Please try again later.',
            "raw_response" => $rawResponse,
            "action" => "associateBcidWithExpedition",
        );
    }
}

function mintExpedition($projectLink, $projectTitle, $publicProject = false, $associateDatasets = false, $fimsAuthCookiesAsString = null)
{
    /***
     *
     *
     *
     *{"projectCode":"AMPHIB","validationXml":"https:\/\/raw.githubusercontent.com\/biocodellc\/biocode-fims\/master\/Documents\/AmphibianDisease\/amphibiandisease.xml","projectId":"26","projectTitle":"Amphibian Disease"},
     *
     * See
     * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
     *
     * Resolve the ark with https://n2t.net/
     *
     * See
     * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/55
     *
     * @param string $projectLink -> the project link to associate
     *   with this expedition. It does not yet need to exist in the
     *   database.
     * @param string $projectTitle -> The project title
     * @param boolean $publicProject -> Is the project a public one?
     * @param boolean $associateDatasets -> If the project exists,
     *   then the database column "datasets" is checked for values to
     *   associate with the expedition
     * @param string $fimsAuthCookie -> the formatted cookie string to
     *   place in a POST header
     * @return array
     ***/
    global $db;
    ini_set("error_log", "./admin-api-fims.log");
    $fimsDefaultHeaders = array(
        'Content-type: application/x-www-form-urlencoded',
        'Accept: application/json',
        'User-Agent: amphibian disease portal',
        );
    # Does the project exist?
    $projectLink = $db->sanitize($projectLink);
    $projectUri = 'https://amphibiandisease.org/project.php?id='.$projectLink;
    $fimsMintUrl = 'http://www.biscicol.org/biocode-fims/rest/expeditions';
    # http://biscicol.org/biocode-fims/rest/fims.wadl#idp752991232
    $fimsMintData = array(
        'projectId' => 26, # From FIMS site
        'webAddress' => $projectUri, # Well, we want this but it isn't part of the spec at this time
        'expeditionCode' => $projectLink,
        'expeditionTitle' => $projectTitle,
        'public' => boolstr($publicProject),
    );
    try {
        if (empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = 'amphibiaweb'; # AmphibianDisease
            $fimsAuthUrl = 'http://www.biscicol.org/biocode-fims/rest/authenticationService/login';
            $fimsAuthData = array(
                'username' => $fimsUserCredential,
                'password' => $fimsPassCredential,
            );
            # Post the login
            $postData = http_build_query($fimsAuthData);
            $params = array('http' => array(
                'method' => 'POST',
                'content' => $postData,
                'header' => implode("\r\n", $fimsDefaultHeaders)."\r\n",
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            if ($rawResponse === false) {
                error_log("POST login failed!! Sent post:\n\tTarget URL:\t".$fimsAuthUrl."\n\tParameters:\t".print_r($params, true)."\n\tFull Context:\t".print_r($ctx, True)."\n\nResponse: ".print_r($rawResponse, true));
                throw(new Exception("Fatal FIMS communication error 005 (No Response)"));
            }
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = '';
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1].';';
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if (empty($loginResponse['url'])) {
                throw(new Exception('Invalid Login Response E003'));
            }
        } else {
            $loginResponse = 'NO_LOGIN_CREDENTIALS_PROVIDED';
            $cookiesString = $fimsAuthCookiesAsString;
            $params = array(
                'http' => array(
                    'method' => 'POST',
                ),
            );
        }
        # Post the args
        $headers = $fimsDefaultHeaders;
        $headers[] = 'Cookie: '.$cookiesString;
        $header = implode("\r\n", $headers)."\r\n";
        $params['http']['header'] = $header;
        $params['http']['content'] = http_build_query($fimsMintData);
        $ctx = stream_context_create($params);
        $rawResponse = file_get_contents($fimsMintUrl, false, $ctx);
        $resp = null;
        if ($rawResponse === false) {
            $errorOut = true;
            $error = error_get_last();
            try {
                $errorMessageRaw = print_r(error_get_last(), true);
                $errorMessage = json_encode(error_get_last());
                error_log("POST mint failed!! \nError: $errorMessageRaw \nSent post:\n\tTarget URL:\t".$fimsMintUrl."\n\tParameters:\t".print_r($params, true)."\n\tFull Context:\t".print_r($ctx, True)."\n\nResponse: ".print_r($rawResponse, true));
                if (empty($errorMessage)) {
                    throw(new Exception("BadEncode"));
                }
            } catch (Exception $e) {
                $errorMessage = $errorMessageRaw;
            }
            if (strpos($error["message"], "400 Bad Request") !== false) {
                # Try looking it up -- might already exist
                global $fimsPassword;
                $fimsPassCredential = $fimsPassword;
                $fimsUserCredential = 'amphibiaweb'; # AmphibianDisease
                $fimsAuthUrl = 'http://www.biscicol.org/biocode-fims/rest/authenticationService/login';
                $fimsAuthData = array(
                    'username' => $fimsUserCredential,
                    'password' => $fimsPassCredential,
                );
                # Post the login
                $postData = http_build_query($fimsAuthData);
                $params = array('http' => array(
                    'method' => 'POST',
                    'content' => $postData,
                    'header' => implode("\r\n", $fimsDefaultHeaders)."\r\n",
                ));
                $ctx = stream_context_create($params);
                $rawReauthResponse = file_get_contents($fimsAuthUrl, false, $ctx);
                if ($rawReauthResponse === false) {
                    error_log("POST reauth failed!! Sent post:\n\tTarget URL:\t".$fimsAuthUrl."\n\tParameters:\t".print_r($params, true)."\n\tFull Context:\t".print_r($ctx, True)."\n\nResponse: ".print_r($rawReauthResponse, true));
                    throw(new Exception("Fatal FIMS communication error 009 (No Response)"));
                }
                $loginHeaders = $http_response_header;
                $cookies = array();
                $cookiesString = '';
                foreach ($http_response_header as $hdr) {
                    if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                        $cookiesString .= $matches[1].';';
                        parse_str($matches[1], $tmp);
                        $cookies += $tmp;
                    }
                }
                $loginResponse = json_decode($rawReauthResponse, true);
                if (empty($loginResponse['url'])) {
                    error_log("POST login failed (009)!! Sent post:\n\tTarget URL:\t".$fimsAuthUrl."\n\tParameters:\t".print_r($params, true)."\n\tFull Context:\t".print_r($ctx, True)."\n\nResponse: ".print_r($rawRawResponse, true));
                    throw(new Exception('Invalid Login Response E093'));
                }
                # Try to fetch the expedition
                # http://www.biscicol.org/apidocs/?url=http://www.biscicol.org/apidocs/current/service.json#!/Expeditions/getExpedition
                $target = "http://www.biscicol.org/biocode-fims/rest/projects/".$fimsMintData["projectId"]."/expeditions/".$projectLink;
                $headers = array(
                    "Accept: application/json",
                );
                $ch = curl_init($target);
                curl_setopt($ch, CURLOPT_HTTPGET, 1);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                curl_setopt($ch, CURLOPT_SAFE_UPLOAD, false); // required as of PHP 5.6.0
                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
                curl_setopt($ch, CURLOPT_COOKIE, $cookiesString);
                curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                curl_setopt($ch, CURLOPT_HEADER, 1);
                $rawResponse2 = curl_exec($ch);
                $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
                $http_response_header = substr($rawResponse2, 0, $header_size);
                $body = substr($rawResponse2, $header_size);
                curl_close($ch);
                if ($body !== false) {
                    $resp = json_decode($body, true);
                    $rawResponse = array(
                        "original_mint_response" => $rawResponse,
                        "detail_response" => $body,
                        "detail_decoded" => $resp,
                        "target" => $target,
                    );
                    if (!empty($resp)) {
                        $errorOut = false;
                        if ($resp["usrMessage"] == "You are not a member of this private project") {
                            $includeHeaderDetails = true;
                        } else {
                            $includeHeaderDetails = false;
                        }
                    } else {
                        $includeHeaderDetails = true;
                    }
                    if ($includeHeaderDetails) {
                        $rawResponse["response_header"] = $http_response_header;
                        $rawResponse["response_header_login"] = $loginHeaders;
                        $rawResponse["response_login"] = $loginResponse;
                        $rawResponse["cookies_sent_with_lookup"] = $cookiesString;
                    }
                } else {
                    $rawResponse = array(
                        "did_lookup" => true,
                        "target" => $target,
                        "original_response" => $rawResponse,
                        "detail_response" => $rawResponse2,
                        "header" => $params,
                        "error" => error_get_last(),
                    );
                }
            }
            if ($errorOut) {
                # Try getting a list
                $target = "http://www.biscicol.org/biocode-fims/rest/expeditions/admin/list/".$fimsMintData["projectId"];
                $headers = $fimsDefaultHeaders;
                $headers[] = 'Cookie: '.$cookiesString;
                $header = implode("\r\n", $headers)."\r\n";
                $params['http']['header'] = $header;
                $params["http"]["method"] = "GET";
                unset($params["http"]["content"]);
                $ctx = stream_context_create($params);
                $rawResponse2 = file_get_contents($target, false, $ctx);
                $resp = json_decode($rawResponse2, true);
                $rawResponse = array(
                    "original_response" => $rawResponse,
                    "list_response" => $rawResponse2,
                    "list_decoded" => $resp,
                );
                if ($rawResponse2 === false) {
                    $rawResponse["error"] = error_get_last();
                } else {
                    $rawResponse = array_merge($resp, $rawResponse);
                }
                throw(new Exception("Fatal FIMS communication error 006 (No Response) [".$errorMessage."] ".json_encode($rawResponse)));
            }
        }
        if (empty($resp)) {
            $resp = json_decode($rawResponse, true);
        }
        # Get the ID in the result
        /***
         * Example result:
         {"login_response":{"url":"http:\/\/www.biscicol.org\/index.jsp"},"mint_response":{"identifier":"ark:\/21547\/AKQ2"},"response_headers":{"0":"HTTP\/1.1 200 OK","1":"X-FRAME-OPTIONS: DENY","2":"Set-Cookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;Path=\/;HttpOnly","3":"Expires: Thu, 01 Jan 1970 00:00:00 GMT","4":"Content-Type: application\/json","5":"Content-Length: 44","6":"Server: Jetty(9.2.6.v20141205)"},"cookies":{"JSESSIONID":"vvt1703eq52ub0jazasfu87h"},"post_headers":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n","post_params":{"http":{"method":"POST","content":"webAddress=https%3A%2F%2Famphibiandisease.org%2Fproject.php%3Fid%3Dfoobar&title=test&resourceType=http%3A%2F%2Fpurl.org%2Fdc%2Fdcmitype%2FDataset","header":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n"}},"execution_time":2675.9889125824}
        ***/
        $identifier = $resp['expeditionBcid'];
        if (empty($identifier)) {
            throw(new Exception('Invalid identifier in response'));
        }
        $response = array(
            'status' => true,
            'ark' => $identifier,
            'project_permalink' => $projectUri,
            'project_title' => $projectTitle,
            'fims_expedition_id' => $resp['expeditionId'],
            'responses' => array(
                'login_response' => array(
                    'response' => $loginResponse,
                    'cookies' => $cookiesString,
                ),
                'expedition_response' => $resp,
            ),

        );
        if ($associateDatasets === true) {
            $response['responses']['association'] = associateBcidsWithExpeditions($projectLink, $cookiesString);
        }

        return $response;
    } catch (Exception $e) {
        unset($params["http"]["content"]);
        return array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem communicating with the FIMS project. Please try again later.',
            'response' => $resp,
            "raw_response" => $rawResponse,
            "action" => "mintExpedition",
            "params_headers" => $params,
        );
    }
}

function validateDataset($dataPath, $projectLink, $fimsAuthCookiesAsString = null, $continue = false)
{
    try {
        $fimsValidateUrl = 'http://www.biscicol.org/biocode-fims/rest/validate';
        # See
        # http://biscicol.org/biocode-fims/rest/fims.wadl#idp1379817744
        # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html#validate-dataset
        if ($continue == true) {
            $fimsStatusUrl = $fimsValidateUrl.'/status';
            $fimsContinueUrl = $fimsValidateUrl.'/continue';
            $params = array('http' => array(
                'method' => 'GET',
                'header' => implode("\r\n", array(
                    'Content-type: application/x-www-form-urlencoded',
                    'Accept: application/json',
                    'User-Agent: amphibian disease portal',
                ))."\r\n",
            ));
            $params['http']['header'] .= "Cookie: ".$cookiesString."\r\n";
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsStatusUrl, false, $ctx);
            if ($rawResponse === false) {
                throw(new Exception("Fatal FIMS communication error 007 (No Response)"));
            }
            $rawResponse2 = file_get_contents($fimsContinueUrl, false, $ctx);
            $resp = json_decode($rawResponse, true);
            $resp2 = json_decode($rawResponse2, true);

            return array(
                'status' => true,
                'responses' => array(
                    'status' => $resp,
                    'continue' => $resp2,
                ),
                'cookies' => $cookiesString,
            );
        }
        # $data = smart_decode64($dataset, false);
        $datasrc = decode64($dataPath);
        $file = realpath($datasrc);
        if (!file_exists($file)) {
            return array(
                'status' => false,
                'error' => 'INVALID_FILE_PATH',
                'human_error' => "Sorry, we couldn't validate your uploaded file",
                'provided' => array(
                    'path' => $datasrc,
                    'computed_path' => $file,
                ),
            );
        }
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, $file);
        finfo_close($finfo);
        if (empty($mime) || $mime == 'application/zip') {
            # Just the fallback that is based purely on extension
            # Only used when finfo can't find a mime type
            try {
                include_once dirname(__FILE__).'/helpers/js-dragdrop/manual_mime.php';
                $mime = mime_type($file);
            } catch (Exception $e) {
                $mime_error = $e->getMessage();
                $mime = null;
            }
        }
        # https://secure.php.net/manual/en/function.curl-file-create.php
        $dataUploadObj = curl_file_create($file, $mime);
        # Remove the invalid "fims_extra" data
        // foreach($data as $k=>$row) {
        //     unset($row["fimsExtra"]);
        //     $data[$k] = $row;
        // }

        # The POST object
        $fimsValidateData = array(
            'dataset' => $dataUploadObj,
            'projectId' => 26,
            'expeditionCode' => $projectLink,
        );

        # Login
        if (empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = 'amphibiaweb'; # AmphibianDisease
            $fimsAuthUrl = 'http://www.biscicol.org/biocode-fims/rest/authenticationService/login';
            $fimsAuthData = array(
                'username' => $fimsUserCredential,
                'password' => $fimsPassCredential,
            );
            # Post the login
            $params = array('http' => array(
                'method' => 'POST',
                'content' => http_build_query($fimsAuthData),
                'header' =>  implode("\r\n", array(
                    'Content-type: application/x-www-form-urlencoded',
                    'Accept: application/json',
                    'User-Agent: amphibian disease portal',
                ))."\r\n",
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            if ($rawResponse === false) {
                throw(new Exception("Fatal FIMS communication error 008 (No Response)"));
            }
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = '';
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1].';';
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if (empty($loginResponse['url'])) {
                throw(new Exception('Invalid Login Response E004'));
            }
        } else {
            $loginResponse = 'NO_LOGIN_CREDENTIALS_PROVIDED';
            $cookiesString = $fimsAuthCookiesAsString;
            $params = array(
                'http' => array(
                    'method' => 'POST',
                ),
            );
        }
        # Post the args
        $headers = array();
        $headers[] = 'Content-type: multipart/form-data';
        $headers[] = 'Accept: application/json';
        $headers[] = 'User-Agent: amphibian disease portal';
        $params = array(
            'http' => array(
                'method' => 'POST',
                'header' => $headers,
                'content' => http_build_query($fimsValidateData),
            ),
        );
        # https://fims.readthedocs.org/en/latest/amphibian_disease_example.html#validate-dataset
        $ch = curl_init($fimsValidateUrl);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_SAFE_UPLOAD, false); // required as of PHP 5.6.0
        # Also auto sets header to "multipart/form-data"
        # Must be an array for file uploads
        curl_setopt($ch, CURLOPT_POSTFIELDS, $fimsValidateData);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($ch, CURLOPT_COOKIE, $cookiesString);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        #curl_setopt($ch, CURLOPT_USERAGENT, "amphibian disease portal");
        #curl_setopt( $ch, CURLOPT_HEADER, 1);
        $rawResponse = curl_exec($ch);
        curl_close($ch);
        $resp = json_decode($rawResponse, true);
        $status = true;
        $validateStatus = true;
        # Check the response for errors
        try {
            if (isset($resp['done']['worksheets'][0]['Samples'])) {
                $hasError = !empty($resp['done']['worksheets'][0]['Samples']['errors']);
                $hasWarning = !empty($resp['done']['worksheets'][0]['Samples']['warnings']);
            } else {
                $hasError = false;
                $hasWarning = false;
            }
        } catch (Exception $e) {
            $hasError = false;
            $hasWarning = false;
        }
        if (empty($resp) || !isset($resp['done']['worksheets'][0])) {
            $validateStatus = 'FIMS_SERVER_DOWN';
        } elseif ($hasError) {
            $mainError = $resp['done']['worksheets'][0]['Samples']['errors'][0];
            $meK = key($mainError);
            $errorMessage = $meK.': '.$mainError[$meK][0];
            if (!empty($mainError[0][0])) {
                $errorMessage .= $mainError[0][0];
            }
            $validateStatus = array(
                'status' => false,
                'error' => $errorMessage,
                'main_error' => $mainError,
                'errors' => $resp['done']['worksheets'][0]['Samples']['errors'],
                'warnings' => $resp['done']['worksheets'][0]['Samples']['warnings'],
            );
        }
        # Make the response
        $response = array(
            'status' => $status,
            'validate_status' => $validateStatus,
            'responses' => array(
                'login_response' => array(
                    'response' => $loginResponse,
                    'cookies' => $cookiesString,
                ),
                'validate_response' => $resp,
                'raw_response' => $rawResponse,
                'validate_has_error' => $hasError,
            ),
            'post_params' => array(
                'file_sent' => $dataUploadObj,
                'header_params' => $params,
            ),
            'data' => array(
              //"user_provided_data" => $dataset,
                //"fims_passed_data" => $data,
                'data_sent' => $fimsValidateData,
                'data_mime' => array(
                    'mime' => $mime,
                    'mime_error' => $mime_error,
                ),
            ),
        );

        return $response;
    } catch (Exception $e) {
        return array(
            'status' => true,
            'validate_status' => 'FIMS_SERVER_DOWN',
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem communicating with the FIMS project. Please try again later.',
        );
    }
}


function superuserEditUser($get)
{
    /***
     *
     * $get is the $_REQUEST superglobal.
     * Expects keys:
     *
     * @param string user -> The dblink/hardlink of the target user
     * @param string change_type -> The type of change to
     * enact. Available: delete | reset
     *
     ***/
    global $login_status,$default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols;
    $udb = new DBHelper($default_user_database, $default_sql_user, $default_sql_password, $sql_url, $default_user_table, $db_cols);
    $uid = $login_status['detail']['uid'];
    # is caller an SU or admin?
    $suFlag = $login_status['detail']['userdata']['su_flag'];
    $isSu = boolstr($suFlag);
    $adminFlag = $login_status['detail']['userdata']['admin_flag'];
    $isAdmin = boolstr($adminFlag);
    if (!($isSu || $isAdmin)) {
        return array(
            "status" => false,
            "error" => "INVALID_USER_PERMISSIONS",
            "human_error" => "You do not have enough permission to perform this action",
        );
    }
    # Check the target
    $target = $get["user"];
    if (empty($target)) {
        return array(
            "status" => false,
            "error" => "INVALID_TARGET_NO_USER_PROVIDED",
            "human_error" => "You must provide argument 'user'",
        );
    }
    # Do they exist?
    if (!$udb->isEntry($target, 'dblink')) {
        return array(
            "status" => false,
            "error" => "INVALID_TARGET_DOES_NOT_EXIST",
            "human_error" => "The requested user does not exist",
        );
    }
    $uf = new UserFunctions($target, "dblink");
    $userData = $uf->getUser($target);
    try {
        # Is the target an SU or admin?
        $suFlag = $userData['userdata']['su_flag'];
        $targetIsSu = boolstr($suFlag);
        if ($targetIsSu) {
            return array(
                "status" => false,
                "error" => "INVALID_TARGET_IS_SU",
                "human_error" => "You can not edit Superusers through this interface. Please contact your system administrator",
            );
        }
        $adminFlag = $userData['userdata']['admin_flag'];
        $targetIsAdmin = boolstr($adminFlag);
        if ($targetIsAdmin && !$isSu) {
            return array(
                "status" => false,
                "error" => "INVALID_TARGET_ADMIN_VS_ADMIN",
                "human_error" => "Sorry, only Superusers can edit adminstrators"
            );
        }
        # Permission check complete.
        $editAction = strtolower($get["change_type"]);
        if (empty($editAction)) {
            return array(
                "status" => false,
                "error" => "INVALID_CHANGE_TYPE_EMPTY",
                "human_error" => "You must provide an argument 'change_type'"
            );
        }
        switch ($editAction) {
            case "delete":
                $dryRun = $uf->forceDeleteCurrentUser();
                $targetUid = $dryRun["target_user"];
                if ($targetUid != $target) {
                    # Should never happen
                    return array(
                        "status" => false,
                        "error" => "MISMATCHED_TARGETS",
                        "human_error" => "The system encountered an error confirming target for deletion",
                        "obj_target" => $targetUid,
                        "post_target" => $target,
                    );
                }
                return $uf->forceDeleteCurrentUser(true);
                break;
            case "reset":
                return array(
                    "status" => false,
                    "error" => "Incomplete"
                );
                break;
            default:
                return array(
                    "status" => false,
                    "error" => "INVALID_CHANGE_TYPE",
                    "human_error" => "We didn't recognize this change type",
                    "change_type_provided" => $editAction,
                );
        }
    } catch (Exception $e) {
        return array(
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "Application error",
            "args" => $get,
        );
    }
}




function updateOwnProfile($get, $col = "public_profile")
{
    /***
     * Update the self-profile of a user
     *
     *
     *
     ***/
    # Verify the JSON integrity of the file
    $structuredData = smart_decode64($get["data"]);
    if (!is_array($structuredData)) {
        $raw = base64_decode($get["data"]);
        $structuredData = json_decode($raw, true);
    }
    //check nullness objectness etc
    if (!is_array($structuredData)) {
        return array(
            "status" => false,
            "error" => "BAD_DATA",
            "human_error" => "Provided data should be a Base-64 representation of a JSON object.",
            "provided" => $get,
        );
    }
    # Check required keys
    $requiredKeys = array(
        "place",
        "social",
        "privacy",
        "profile",
    );
    foreach ($requiredKeys as $key) {
        if (!array_key_exists($key, $structuredData)) {
            return array(
                "status" => false,
                "error" => "MISSING_REQUIRED_KEY",
                "human_error" => "Required key '$key' cannot be found in the posted dataset",
                "provided" => $get,
            );
        }
    }
    $jsonOptions = JSON_NUMERIC_CHECK | JSON_HEX_QUOT | JSON_HEX_APOS;
    $data = json_encode($structuredData, $jsonOptions);
    $u = new UserFunctions();
    # We'll use writeToUser and use default cookie-based validation.
    #return $structuredData;
    $writeResult = $u->writeToUser($data, $col);
    $rStatus = $writeResult["status"];
    if (!is_bool($rStatus)) {
        $rStatus = false;
    }
    $response = array(
        "status" => $rStatus,
        "write_response" => $writeResult,
        "provided" => array(
            "raw" => $get["data"],
            "decoded" => $structuredData
        ),
    );
    return $response;
}


function saveProfileImage($get)
{
    /***
     * For a given image, set it as the profile picture for a user.
     ***/
    # We don't need to clean the decoded data since we're checking for existence
    $data = smart_decode64($get["data"], false);
    $imagePath = $data["profile_image_path"];
    # Verify file exists
    if (!file_exists($imagePath)) {
        return array(
            "status" => false,
            "error" => "Invalid path",
            "args" => $get,
            "parsed" => $data,
            "canonical_path" => realpath($imagePath),
        );
    }
    $u = new UserFunctions();
    return $u->setImageAsUserPicture($imagePath);
}

function sendUserMessage($get)
{
    return false;
}

function getConversationWithUser($get)
{
    return false;
}

function getTotalConversationsSummary($get)
{
    return false;
}


function advancedSearchProject($get)
{
    /***
     * Searches a project.
     *
     * The project should have data for bounds and, optionally,
     * taxa. When searched, the project should be entirely contained
     * within the bounds.
     ***/
    global $db;
    $searchParams = smart_decode64($get["q"], false);
    $search = array();
    $response = array(
        "notices" => array(),
    );
    foreach ($searchParams as $col=>$searchQuery) {
        if (checkColumnExists($col, false)) {
            if ($searchQuery["data"] != "*") {
                $searchQuery["data"] = $db->sanitize($searchQuery["data"]);
                $search[$col] = $searchQuery;
            }
        } else {
            $response["notices"][] = "'$col' is an invalid column and was ignored.";
        }
    }
    $response["search"] =$searchParams;
    $response['status'] = true;
    # The API hit returns data from these columns
    $returnCols = array(
        "public",
        "project_id",
        "disease",
        "project_title",
        "bounding_box_n",
        "bounding_box_e",
        "bounding_box_w",
        "bounding_box_s",
        "disease_morbidity",
        "disease_mortality",
        "disease_samples",
        "disease_positive",
        "includes_anura",
        "includes_caudata",
        "includes_gymnophiona",
        "sampled_species",
        "carto_id",
    );
    # For numerical comparisons, we have to allow a type specification
    $allowedSearchTypes = array(
        "<",
        ">",
        "<=",
        ">=",
        "=",
    );
    $loose = isset($get["loose"]) ? toBool($get["loose"]) : true;
    $boolean_type = "AND";
    $where_arr = array();
    foreach ($search as $col => $searchQuery) {
        $crit = $searchQuery["data"];
        $validSearchType = empty($searchQuery["search_type"]) ? true : in_array($searchQuery["search_type"], $allowedSearchTypes);
        if (!empty($searchQuery["search_type"]) && !$validSearchType) {
            $response["notices"][] = "'".$searchQuery["search_type"]."' isn't a valid search type";
        }
        if ($validSearchType && !is_numeric($crit) && !empty($searchQuery["search_type"])) {
            $response["notices"][] = "Search types may only be specified for numeric data ('".$searchQuery["search_type"]."' tried to be specified for '$crit')";
        }
        if (!$validSearchType || !is_numeric($crit)) {
            $where_arr[] = $loose ? 'LOWER(`'.$col."`) LIKE '%".$crit."%'" : '`'.$col."`='".$crit."'";
        } else {
            # The query is numeric AND we have a search type specified
            $where_arr[] = "`".$col."` ".$searchQuery["search_type"]." ".$crit;
        }
    }
    $where = '('.implode(' '.strtoupper($boolean_type).' ', $where_arr).')';
    $query = "SELECT ".implode(",", $returnCols)." FROM `".$db->getTable()."` WHERE $where";
    $response["query"] = $query;
    $db->invalidateLink();
    $r = mysqli_query($db->getLink(), $query);
    if ($r === false) {
        $response["status"] = false;
        $response["error"] = mysqli_error($db->getLink());
        $response["query"] = $query;
        returnAjax($response);
    }
    $queryResult = array();
    $baseRows = mysqli_num_rows($r);
    $boolCols = array(
        "public",
        "includes_anura",
        "includes_caudata",
        "includes_gymnophiona",
    );

    while ($row = mysqli_fetch_assoc($r)) {
        # Authenticate the project against the user
        if (checkProjectIdAuthorized($row["project_id"], true)) {
            # Clean up data types
            foreach ($row as $col=>$val) {
                if (is_numeric($val)) {
                    if (in_array($col, $boolCols)) {
                        $row[$col] = toBool($val);
                    } else {
                        $row[$col] = floatval($val);
                    }
                }
                if ($col == "carto_id") {
                    $cartoObj = json_decode($val);
                    if (!is_array($cartoObj)) {
                        $cartoObj = $val;
                    } else {
                        foreach ($cartoObj as $k=>$v) {
                            $nk = str_replace("&#95;", "_", $k);
                            try {
                                unset($cartoObj[$k]);
                            } catch (Exception $e) {
                                $response["notices"][] = $e->getMessage();
                            }
                            $cartoObj[$nk] = $v;
                        }
                    }
                    $row[$col] = $cartoObj;
                }
            }
            if (!empty($row["project_id"])) {
                $queryResult[] = $row;
            }
        }
    }
    $response['result'] = $queryResult;
    $response['count'] = sizeof($response['result']);
    $response['base_count'] = $baseRows;
    returnAjax($response);
}


function advancedSearchProjectContains($get)
{
    /***
     * Similar to advancedSearchProject, but rather than requiring the
     * whole project is contained in the bounds, there only has to be
     * a nonzero amount of area of a project contained within bounds.
     ***/
    global $db;
    $searchParams = smart_decode64($get["q"], false);
    $search = array();
    $response = array(
        "notices" => array(),
    );
    foreach ($searchParams as $col=>$searchQuery) {
        if (checkColumnExists($col, false)) {
            if ($searchQuery["data"] != "*") {
                $searchQuery["data"] = $db->sanitize($searchQuery["data"]);
                $search[$col] = $searchQuery;
            }
        } else {
            $response["notices"][] = "'$col' is an invalid column and was ignored.";
        }
    }
    $response["search"] =$searchParams;
    $response['status'] = true;
    # The API hit returns data from these columns
    $returnCols = array(
        "public",
        "project_id",
        "disease",
        "project_title",
        "bounding_box_n",
        "bounding_box_e",
        "bounding_box_w",
        "bounding_box_s",
        "disease_morbidity",
        "disease_mortality",
        "disease_samples",
        "disease_positive",
        "includes_anura",
        "includes_caudata",
        "includes_gymnophiona",
        "sampled_species",
        "carto_id",
    );
    # For numerical comparisons, we have to allow a type specification
    $allowedSearchTypes = array(
        "<",
        ">",
        "<=",
        ">=",
        "=",
    );
    $loose = isset($get["loose"]) ? toBool($get["loose"]) : true;
    $boolean_type = "AND";
    $where_arr = array();
    foreach ($search as $col => $searchQuery) {
        $crit = $searchQuery["data"];
        $validSearchType = empty($searchQuery["search_type"]) ? true : in_array($searchQuery["search_type"], $allowedSearchTypes);
        if (!empty($searchQuery["search_type"]) && !$validSearchType) {
            $response["notices"][] = "'".$searchQuery["search_type"]."' isn't a valid search type";
        }
        if ($validSearchType && !is_numeric($crit)) {
            $response["notices"][] = "Search types may only be specified for numeric data ('".$searchQuery["search_type"]."' tried to be specified for '$crit')";
        }
        if (!$validSearchType || !is_numeric($crit)) {
            $where_arr[] = $loose ? 'LOWER(`'.$col."`) LIKE '%".$crit."%'" : '`'.$col."`='".$crit."'";
        } else {
            # The query is numeric AND we have a search type specified
            $where_arr[] = "`".$col."` ".$searchQuery["search_type"]." ".$crit;
        }
    }
    $where = '('.implode(' '.strtoupper($boolean_type).' ', $where_arr).')';
    $query = "SELECT ".implode(",", $returnCols)." FROM `".$db->getTable()."` WHERE $where";
    $response["query"] = $query;
    $db->invalidateLink();
    $r = mysqli_query($db->getLink(), $query);
    if ($r === false) {
        $response["status"] = false;
        $response["error"] = mysqli_error($db->getLink());
        $response["query"] = $query;
        returnAjax($response);
    }
    $queryResult = array();
    $baseRows = mysqli_num_rows($r);
    $boolCols = array(
        "public",
        "includes_anura",
        "includes_caudata",
        "includes_gymnophiona",
    );

    while ($row = mysqli_fetch_assoc($r)) {
        # Authenticate the project against the user
        if (checkProjectIdAuthorized($row["project_id"], true)) {
            # Clean up data types
            foreach ($row as $col=>$val) {
                if (is_numeric($val)) {
                    if (in_array($col, $boolCols)) {
                        $row[$col] = toBool($val);
                    } else {
                        $row[$col] = floatval($val);
                    }
                }
                if ($col == "carto_id") {
                    $cartoObj = json_decode($val);
                    if (!is_array($cartoObj)) {
                        $cartoObj = $val;
                    } else {
                        foreach ($cartoObj as $k=>$v) {
                            $nk = str_replace("&#95;", "_", $k);
                            try {
                                unset($cartoObj[$k]);
                            } catch (Exception $e) {
                                $response["notices"][] = $e->getMessage();
                            }
                            $cartoObj[$nk] = $v;
                        }
                    }
                    $row[$col] = $cartoObj;
                }
            }
            $queryResult[] = $row;
        }
    }
    $response['result'] = $queryResult;
    $response['count'] = sizeof($response['result']);
    $response['base_count'] = $baseRows;
    returnAjax($response);
}


function checkColumnExists($column_list, $userReturn = true, $detailReturn = false)
{
    /***
     * Check if a comma-seperated list of columns exists in the
     * database.
     * @param string $column_list (comma-sep)
     * @return array
     ***/
    if (empty($column_list)) {
        return true;
    }
    global $db;
    $cols = $db->getCols();
    foreach (explode(',', $column_list) as $column) {
        if (!array_key_exists($column, $cols)) {
            if ($userReturn || $detailReturn) {
                $response = array('status' => false, 'error' => 'Invalid column. If it exists, it may be an illegal lookup column.', 'human_error' => "Sorry, you specified a lookup criterion that doesn't exist. Please try again.", 'columns' => $column_list, 'bad_column' => $column);
                if ($userReturn) {
                    returnAjax($response);
                }
                return $response;
            } else {
                return false;
            }
        }
    }
    if ($userReturn) {
        returnAjax(array('status' => true));
    } else {
        return true;
    }
}
