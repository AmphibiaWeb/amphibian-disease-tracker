<?php

/***
 * Core hooks to use for database management
 * Uses MySQLi as the main interface
 ***/

class DBHelper
{
    public function __construct($database, $user, $pw, $url = 'localhost', $table = null, $cols = null)
    {
        /***
     * @param string $database the database to connect to
     * @param string $user the username for the SQL database
     * @param string $pw the password for $user in $database
     * @param string $url the URL of the SQL server
     * @param string $table the default table
     * @param array $cols the column information. Note that it must be
     * specified here in the constructor!!
     ***/
    $this->db = $database;
        $this->SQLuser = $user;
        $this->pw = $pw;
        $this->url = $url;
        $this->table = $table;
        if (is_array($cols)) {
            $this->setCols($cols);
        }
    }

    public function getDB()
    {
        if (empty($this->db)) {
            throw(new Exception('No database set.'));
        }

        return $this->db;
    }

    protected function setDB($db)
    {
        $this->db = $db;
    }

    public function getTable()
    {
        if (empty($this->table)) {
            #empty chairs?
        throw(new Exception('No table has been defined for this object.'));
        }

        return $this->table;
    }

    public function setTable($table)
    {
        $this->table = $this->sanitize($table);
    }

    private function getSQLUser()
    {
        if (empty($this->SQLuser)) {
            throw(new Exception('No user has been defined for this object.'));
        }

        return $this->SQLuser;
    }

    protected function setSQLUser($user)
    {
        $this->SQLuser = $user;
    }

    private function getSQLPW()
    {
        if (empty($this->pw)) {
            throw(new Exception('No password has been defined for this object'));
        }

        return $this->pw;
    }

    protected function setSQLPW($pw)
    {
        $this->pw = $pw;
    }

    private function getSQLURL()
    {
        if (empty($this->url)) {
            $this->url = 'localhost';
        }

        return $this->url;
    }

    private function setLink($link) {
        $this->link = $link;
    }

    public function getLink() {
        if(empty($this->link)) {
            $this->openDB();
        }
        return $this->link;
    }

    private function invalidateLink() {
        $this->setLink(null);
        return $this->openDB();
    }
    public function closeLink() {
        $r = mysqli_close($this->getLink());
        $this->setLink(null);
        return $r;
    }
    protected function setSQLURL($url)
    {
        $this->url = $url;
    }

    protected function setCols($cols, $dirty_columns = true)
    {
        if (!is_array($cols)) {
            if (empty($cols)) {
                throw(new Exception('No column data provided'));
            } else {
                throw(new Exception('Invalid column data type (needs array)'));
            }
        }
        $shadow = array();
        foreach ($cols as $col => $type) {
            $col = $this->sanitize($col, $dirty_columns);
            $shadow[$col] = $type;
        }
        $this->cols = $shadow;
    }

    public function getCols()
    {
        if (!is_array($this->cols)) {
            throw(new Exception('Invalid columns'));
        }

        return $this->cols;
    }

    protected function testSettings($table = null, $detail = false)
    {

        if (!empty($table)) {
            $this->setTable($table);
        }
        if (mysqli_query($this->getLink(), 'SELECT * FROM `'.$this->getTable().'` LIMIT 1') === false) {
            return $this->createTable($detail);
        }

        return true;
    }

    private function createTable($detail = false)
    {
        /***
     * @return bool
     ***/
    $query = 'CREATE TABLE `'.$this->getTable().'` (id int(10) NOT NULL auto_increment';
        foreach ($this->getCols() as $col => $type) {
            $query .= ', '.$this->sanitize($col, true).' '.$type;
        }
        $query .= ',PRIMARY KEY (id),UNIQUE id (id),KEY id_2 (id))';
        $error = false;

        $r = mysqli_query($this->getLink(), $query);
        if ($r !== false) {
            $query2 = 'INSERT INTO `'.$this->getTable().'` VALUES()';
            $r2 = mysqli_query($this->getLink(), $query2);
            if ($r2 === false) {
                $error = mysqli_error($this->getLink());
            }
        } else {
            $error = mysqli_error($this->getLink());
        }
        if ($detail) {
            return array('status' => $r && $r2,'create' => $query,'insert' => $query2,'error' => $error);
        }

        return $r && $r2;
    }

    public static function cleanInput($input, $strip_html = true)
    {
        $search = array(
      '@<script[^>]*?>.*?</script>@si',   // Strip out javascript
      '@<style[^>]*?>.*?</style>@siU',    // Strip style tags properly
      '@<![\s\S]*?--[ \t\n\r]*>@',         // Strip multi-line comments
    );
        if ($strip_html) {
            $search[] = '@<[\/\!]*?[^<>]*?>@si'; // Strip out HTML tags
        }
        $output = preg_replace($search, '', $input);
        # Replace HTML brackets for anything that slipped through
        $output = str_replace("<", "&#60;", $output);
        $output = str_replace(">", "&#62;", $output);
        return $output;
    }

    protected static function mysql_escape_mimic($inp)
    {
        if (is_array($inp)) {
            return array_map(__METHOD__, $inp);
        }
        if (!empty($inp) && is_string($inp)) {
            return str_replace(array('\\', "\0", "\n", "\r", "'", '"', "\x1a"), array('\\\\', '\\0', '\\n', '\\r', "\\'", '\\"', '\\Z'), $inp);
        }

        return $inp;
    }

    public function sanitize($input, $dirty_entities = false)
    {
        # Emails get mutilated here -- let's check that first
    $preg = "/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
        if (preg_match($preg, $input) === 1) {
            # It's an email, let's escape it and be done with it
            $output = mysqli_real_escape_string($this->getLink(), $input);
            return $output;
        }
        if (is_array($input)) {
            foreach ($input as $var => $val) {
                $output[$var] = $this->sanitize($val, $dirty_entities);
            }
        } else {
            if (get_magic_quotes_gpc()) {
                $input = stripslashes($input);
            }
            # We want JSON to pass through unscathed, just be escaped
            if (!$dirty_entities && json_encode(json_decode($input,true)) != $input) {
                $input = htmlentities(self::cleanInput($input));
                $input = str_replace('_', '&#95;', $input); // Fix _ potential wildcard
            $input = str_replace('%', '&#37;', $input); // Fix % potential wildcard
            $input = str_replace("'", '&#39;', $input);
                $input = str_replace('"', '&#34;', $input);
            }
            $output = mysqli_real_escape_string($this->getLink(), $input);
        }

        return $output;
    }

    public static function staticSanitize($input, $strip_html = true)
    {
        # Emails get mutilated here -- let's check that first
    $preg = "/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
        if (is_array($input)) {
            foreach ($input as $var => $val) {
                $output[$var] = self::staticSanitize($val);
            }
        } else {
            if (preg_match($preg, $input) === 1) {
                # It's an email, let's escape it and be done with it
          $output = self::mysql_escape_mimic($input);

                return $output;
            }
            if (get_magic_quotes_gpc()) {
                $input = stripslashes($input);
            }
            $input = htmlentities(self::cleanInput($input, $strip_html));
            $input = str_replace('_', '&#95;', $input); // Fix _ potential wildcard
        $input = str_replace('%', '&#37;', $input); // Fix % potential wildcard
        $input = str_replace("'", '&#39;', $input);
            $input = str_replace('"', '&#34;', $input);
            $output = self::mysql_escape_mimic($input);
        }

        return $output;
    }

    public function openDB()
    {
        /***
     * @return mysqli_resource
     ***/
    if ($l = mysqli_connect($this->getSQLURL(), $this->getSQLUser(), $this->getSQLPW())) {
        if (mysqli_select_db($l, $this->getDB())) {
            $this->setLink($l);
            return $l;
        }
    }
        throw(new Exception('Could not connect to database.'));
    }

    protected function getFirstRow($query)
    {

        try {
            $result = mysqli_query($this->getLink(), $query);
            if ($result) {
                $row = mysqli_fetch_assoc($result);
            } else {
                $row = false;
            }

            return $row;
        } catch (Exception $e) {
            return false;
        }
    }

    public function isEntry($item, $field_name = null, $precleaned = false, $test = false) {
        return $this->is_entry($item, $field_name, $precleaned, $test);
    }

    public function is_entry($item, $field_name = null, $precleaned = false, $test = false)
    {
        if ($field_name == null) {
            $field_name = 'id';
        }
        if ($precleaned !== true) {
            $item = $this->sanitize($item);
            $field_name = $this->sanitize($field_name);
        }

        if (false) {
            #is_numeric($item))

            $item_string = $item;
        } else {
            $item_string = "'$item'";
        }
        $query = 'SELECT * FROM `'.$this->getTable()."` WHERE `$field_name`=".$item_string;
        try {
            $result = mysqli_query($this->getLink(), $query);
            if ($result === false) {
                if ($test) {
                    return array('status' => false,'query' => $query,'error' => 'false result');
                }

                return false;
            }
            $row = mysqli_fetch_row($result);
            mysqli_close($this->getLink());
            if ($test) {
                return array('query' => $query,'row' => $row);
            }
            if (!empty($row[0])) {
                return true;
            } else {
                return false;
            }
        } catch (Exception $e) {
            if ($test) {
                return array('status' => 'exception thrown','error' => $e->getMessage());
            }

            return false;
        }
    }

    public function lookupItem($item, $field_name = null, $throw = false, $precleaned = false)
    {
        if (empty($field_name)) {
            $field_name = 'id';
        }
        if ($precleaned !== true) {
            $item = $this->sanitize($item);
            $field_name = $this->sanitize($field_name);
        }


        $query = 'SELECT * FROM `'.$this->getTable()."` WHERE `$field_name`='$item'";
        $result = mysqli_query($this->getLink(), $query);
        if ($result === false && $throw === true) {
            throw(new Exception('MySQL error - '.mysqli_error($this->getLink())));
        }

        return $result;
    }

    public function getLastRowNumber()
    {
        /***
     * Return the highest id of the database. Thus, this includes deleted items.
     *
     * @return int
     ***/

        $query = 'SELECT * FROM `'.$this->getTable().'` ORDER BY id DESC LIMIT 1';
        $result = mysqli_query($this->getLink(), $query);
        $rows = mysqli_fetch_row($result);

        return $rows[0];
    }

    public function deleteRow($value, $field_name, $throw = false)
    {
        /***
     * Deletes a row
     *
     * @param string $value match for $field_name = $value
     * @param string $field_name column name
     * @return array with result in "status"; if true, rows affected in "rows"; if false, error in "error"
     ***/
    $value = $this->sanitize($value);
        $field_name = $this->sanitize($field_name);

        mysqli_query($this->getLink(), 'BEGIN');
        $query = 'DELETE FROM `'.$this->getTable()."` WHERE `$field_name`='$value'";
        if (mysqli_query($this->getLink(), $query)) {
            mysqli_query($this->getLink(), 'COMMIT');

            return array('status' => true,'rows' => mysqli_affected_rows($this->getLink()));
        } else {
            $r = mysqli_query($this->getLink(), 'ROLLBACK');
            if ($throw === true) {
                throw(new Exception('Failed to delete row.'));
            }

            return array('status' => false,'rollback_status' => $r,'error' => mysqli_error($this->getLink()));
        }
    }

    public function addItem($value_arr, $field_arr = null, $test = false, $precleaned = false)
    {
        /***
     *
     * @param array $value_arr
     * @param array $field_arr
     ***/
    $querystring = 'INSERT INTO `'.$this->getTable().'` VALUES (';
        if (empty($field_arr)) {
            $temp = array();
            foreach ($value_arr as $k => $v) {
                if(!$precleaned) $k = $this->sanitize($k, true); # Keys can be picky
                if(!$precleaned) $v = $this->sanitize($v);
                $field_arr[] = $k;
                $temp[] = $v;
            }
            $value_arr = $temp;
        } else if (!$precleaned) {
            # Sanitize it all
            $field_arr = $this->sanitize($field_arr, true);
            $value_arr = $this->sanitize($value_arr);
        }
        if (sizeof($field_arr) == sizeof($value_arr)) {
            $i = 0;
            $valstring = '';
            $item = $this->lookupItem('1');
            if ($item !== false) {
                $source = mysqli_fetch_assoc($item);
            }
        // Create blank, correctly sized entry
        while ($i < sizeof($source)) {
            $valstring .= "''";
            if ($i < sizeof($source) - 1) {
                $valstring .= ',';
            }
            ++$i;
        }
            $querystring .= "$valstring)";
            if ($test) {
                $retval = $querystring;
            } else {

                mysqli_query($this->getLink(), 'BEGIN');
                if (mysqli_query($this->getLink(), $querystring) === false) {
                    $error = mysqli_error($this->getLink());
                    $r = mysqli_query($this->getLink(), 'ROLLBACK');

                    return array(false,'rollback_status' => $r,'error' => $error,'query' => $querystring);
                }
            }
            $querystring = 'UPDATE `'.$this->getTable().'` SET ';
            $i = 0;
            $equatestring = '';
            foreach ($field_arr as $field) {
                if (!empty($field) && !empty($value_arr[$i])) {
                    $equatestring .= "`$field`='".$value_arr[$i]."',";
                    ++$i;
                } else {
                    $i++;
                }
            }
            $equatestring = substr($equatestring, 0, -1); // remove trailing comma
        $querystring .= "$equatestring WHERE id='";
            if ($test) {
                $row = $this->getLastRowNumber() + 1;
                $querystring .= "$row'";
            } else {
                $querystring .= mysqli_insert_id($this->getLink())."'";
            }
            if ($test) {
                $retval .= ' !!And!! '.$querystring;

                return $retval;
            } else {
                $res2 = mysqli_query($this->getLink(), $querystring);
                if ($res2 !== false) {
                    $r = mysqli_query($this->getLink(), 'COMMIT');

                    return $r;
                } else {
                    $error = mysqli_error($this->getLink());
                    $r = mysqli_query($this->getLink(), 'ROLLBACK');

                    return array(false,'rollback_status' => $r,'result' => $res2,'error' => $error,'query' => $querystring);
                }
            }
        } else {
            return false;
        }
    }
    
    

    public function getQueryResults($search, $cols = '*', $boolean_type = 'AND', $loose = false, $precleaned = false, $order_by = false, $debug_query = false) {
        $this->invalidateLink();
        $result = $this->doQuery($search, $cols, $boolean_type, $loose, $precleaned, $order_by);
        $response = array();
        while($row = mysqli_fetch_assoc($result)) {
            $response[] = $row;
        }
        if(empty($response) && $debug_query) {
            $debug = $this->doQuery($search, $cols, $boolean_type, $loose, $precleaned, $order_by, true);
            $debug["result"] = $result;
            return $debug;
        }
        return $response;
    }
    
    
    
    
    public function doQuery($search, $cols = '*', $boolean_type = 'AND', $loose = false, $precleaned = false, $order_by = false, $debug_query = false)
    {
        /***
   * Do a query.
   *
   * @param $search
   * @param $cols
   * @param $boolean_type
   * @param $loose
   * @param $precleaned
   * @param $order_by
   * @param $debug_query
   ***/
  if (!is_array($search)) {
      if ($debug_query === true) {
          return array('status' => false,'debug' => true,'error' => 'Bad search array','search' => $search,'is_array' => is_array($search));
      }

      return false;
  }
        if ($precleaned !== true) {
            foreach ($search as $col => $crit) {
                $search[$this->sanitize($col)] = $this->sanitize($crit);
            }
            if (is_array($cols)) {
                foreach ($cols as $k => $column) {
                    $cols[$k] = $this->sanitize($column);
                }
            } else {
                $cols = $this->sanitize($cols);
            }
        }
        if ($cols != '*') {
            $col_selector = is_array($cols) ? '`'.implode('`,`', $cols).'`' : '`'.$cols.'`';
        } else {
            $col_selector = $cols;
        }
        if (strtolower($boolean_type) != 'and' && strtolower($boolean_type) != 'or') {
            if ($debug_query === true) {
                return array('status' => false,'debug' => true,'error' => 'Bad boolean type','provided_type' => $boolean_type);
            }

            return false;
        }
        $where_arr = array();
        foreach ($search as $col => $crit) {
            $where_arr[] = $loose ? 'LOWER(`'.$col."`) LIKE '%".$crit."%'" : '`'.$col."`='".$crit."'";
        }
        $where = '('.implode(' '.strtoupper($boolean_type).' ', $where_arr).')';
        $query = "SELECT $col_selector FROM `".$this->getTable()."` WHERE $where";
        if ($order_by !== false) {
            $ordering = explode(',', $order_by);
            $order = ' ORDER BY '.'`'.implode('`,`', $ordering).'`';
            $query .= $order;
        }
        if ($debug_query === true) {
            return array('status' => false,'debug' => true,'query' => $query,'col_selector' => $col_selector,'boolean_type' => $boolean_type,'ordering' => $order);
        }

        $r = mysqli_query($this->getLink(), $query);

        return $r === false ? mysqli_error($this->getLink()) : $r;
    }

    public function doSoundex($search, $cols = '*', $precleaned = false, $order_by = false)
    {
        if (!is_array($search)) {
            return false;
        }
        if (sizeof($search) > 1) {
            return false;
        }
        if ($precleaned !== true) {
            foreach ($search as $col => $crit) {
                $search[$this->sanitize($col)] = $this->sanitize($crit);
            }
            if (is_array($cols)) {
                foreach ($cols as $k => $column) {
                    $cols[$k] = $this->sanitize($column);
                }
            } else {
                $cols = $this->sanitize($cols);
            }
        }
        if ($cols != '*') {
            $col_selector = is_array($cols) ? '`'.implode('`,`', $cols).'`' : '`'.$cols.'`';
        } else {
            $col_selector = $cols;
        }
        $column = key($search);
        $crit = $search[$column];
        $query = "SELECT $col_selector FROM `".$this->getTable()."` WHERE (STRCMP(SUBSTR(SOUNDEX($column),1,LENGTH(SOUNDEX('$crit'))),SOUNDEX('$crit'))=0 OR `$column` LIKE '%$crit%')";
        if ($order_by !== false) {
            $ordering = explode(',', $order_by);
            $order = ' ORDER BY '.'`'.implode('`,`', $ordering).'`';
            $query .= $order;
        }

        $r = mysqli_query($this->getLink(), $query);

        return $r === false ? mysqli_error($this->getLink()) : $r;
    }

    public function updateEntry($value, $unq_id, $field_name = null, $precleaned = false)
    {
        /***
     *
     * @param string|array $value new value to fill $field_name, or column=>value pairs
     * @param array $unq_id a 1-element array of col=>val to designate the matching criteria
     * @param string|array $field_name column(s) to be updated
     * @param bool $precleaned if the input elements have been presanitized
     ***/
    if (!is_array($unq_id)) {
        throw(new Exception('Invalid argument for unq_id'));
    }
        $column = key($unq_id);
        $uval = current($unq_id);

        if (!$this->is_entry($uval, $column, $precleaned)) {
            throw(new Exception("No item '$uval' exists for column '$column' in ".$this->getTable()));
        }

        if (!empty($field_name)) {
            $values = array();
            if (is_array($field_name)) {
                foreach ($field_name as $key) {
                    # Map each field name onto the value of the current value item
                $item = current($value);
                    $key = $precleaned ? mysqli_real_escape_string($this->getLink(), $key) : $this->sanitize($key);
                    $values[$key] = $precleaned ? mysqli_real_escape_string($this->getLink(), $item) : $this->sanitize($item);
                    next($value);
                }
            } else {
                # $field_name isn't an array. Let's make sure $value isn't either
            if (!is_array($value)) {
                $key = $precleaned ? mysqli_real_escape_string($this->getLink(), $field_name) : $this->sanitize($field_name);
                $values[$key] = $precleaned ? mysqli_real_escape_string($this->getLink(), $value) : $this->sanitize($value);
            } else {
                # Mismatched types
                throw(new Exception("Mismatched types for \$value and \$field_name"));
            }
            }
        } elseif (empty($field_name)) {
            # Make sure that $value is an array
        if (is_array($value) && is_string(key($value))) {
            $values = array();
            foreach ($value as $key => $value) {
                $key = $precleaned ? mysqli_real_escape_string($this->getLink(), $key) : $this->sanitize($key);
                $key = str_replace('&#95;', '_', $key);
                $values[$key] = $precleaned ? mysqli_real_escape_string($this->getLink(), $value) : $this->sanitize($value);
            }
        } else {
            throw(new Exception("No column found for \$value"));
        }
        }

        $sets = array();
        foreach ($values as $col => $val) {
            $sets[] = "`$col`=\"$val\"";
        }
        $set_string = implode(',', $sets);
        $query = 'UPDATE `'.$this->getTable()."` SET $set_string WHERE `$column`='$uval'";
        mysqli_query($this->getLink(), 'BEGIN');
        $r = mysqli_query($this->getLink(), $query);
        if ($r !== false) {
            mysqli_query($this->getLink(), 'COMMIT');

            return true;
        } else {
            $error = mysqli_error($this->getLink())." - for $query";
            mysqli_query($this->getLink(), 'ROLLBACK');

            return $error;
        }
    }


    public function columnExists($columnName) {
        /***
         * Check if the specified column exists
         *
         * @returns bool
         ***/


        $result = mysqli_query($this->getLink(), "SHOW COLUMNS FROM `".$this->getTable()."` LIKE '".$columnName."'");
        return (mysqli_num_rows($result)) ? TRUE : FALSE;
    }

    protected function addColumn($columnName, $columnType = null) {
        /***
         * Add a new column. DATA MUST BE SANITIZED BEFORE CALLING!
         *
         * @param array|string $columnName - if an array, array of
         * type "name" => "type"; otherwise, column name.
         *
         * @param string $columnType - The type of data in the
         * column. May be blank if $columnName is an array.
         *
         * @returns array
         ***/
        if(is_array($columnName)) {
            $columnType = current($columnName);
            $columnName = key($columnName);
        }
        if($this->columnExists($columnName)) {
            # Already exists
            return array(
                "status" => false,
                "error" => "COLUMN_EXISTS",
                "human_error" => "Column already exists",
            );
        }
        # Create it!
        $query = "ALTER TABLE `" . $this->getTable() . "` ADD " . $columnName . " " . $columnType;

        $r = mysqli_query($this->getLink(), $query);
        if($r === false) {
            return array(
                "status" => $r,
                "error" => mysqli_error($this->getLink(), $r),
            );
        }
        return array(
            "status" => true,
        );
    }
}
