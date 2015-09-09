<?php
   ob_start( 'ob_gzhandler' ); // handles headers
/*
 * Sample page to show the whole kit n' kaboodle in action.
 */
if($_REQUEST['t']=='hash')
  {
    // decode the JSON
    require_once('core/core.php');
    $l=openDB();
    $r=mysqli_query($l,"SELECT password FROM `userdata` WHERE username='".sanitize($_POST['user'])."'");
    $hba=mysqli_fetch_array($r);
    $hb=$hba[0];
    $a=json_decode($hb,true);
    print_r($a);
    require_once('handlers/login_functions.php');
    $h=new Stronghash();
    $u=new UserFunctions();
    // user validation
    echo "<pre> LookupUser results -- ";
    print_r($u->lookupUser($_POST['user'],$_POST['pw_base'],true));
    echo "\n VerifyHash results --";
    print_r($h->verifyHash($_POST['pw_base'],$a,null,null,null,true));
    echo "</pre>";
  }
$debug = true;
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Sample Page for Userhandler</title>
  </head>
  <body>
    <?php
       // ob_start( 'ob_gzhandler' ); // handles headers
       /*
       * Sample page to show the whole kit n' kaboodle in action.
       */
       if($_REQUEST['t']=='hash')
       {
       // decode the JSON
       require_once('handlers/db_hook.inc');
       $l=openDB();
       $r=mysqli_query($l,"SELECT password FROM `userdata` WHERE username='".sanitize($_POST['user'])."'");
       $hba=mysqli_fetch_array($r);
       $hb=$hba[0];
       $a=json_decode($hb,true);
       print_r($a);
       require_once('stronghash/php-stronghash.php');
       require_once('handlers/login_functions.php');
       $h=new Stronghash();
       $u=new UserFunctions();
       // user validation
       echo "<pre> LookupUser results -- ";
       print_r($u->lookupUser($_POST['user'],$_POST['pw_base'],true));
    echo "\n VerifyHash results --";
    print_r($h->verifyHash($_POST['pw_base'],$a,null,null,null,true));
    echo "</pre>";
}

?>
    <article>
      <?php
         require_once('login.php');
         echo $login_output;
         ?>
      <div>
        <h3>Test Hash</h3>
        <p>You can check to ensure the proper functioning of the hashing here. Please note these passwords in the next field are plaintext.</p>
        <form action='?t=hash' method='post'>
          <input type='email' name='user' placeholder='username'/><br/>
          <input type='text' name='pw_base' placeholder='pass'/><br/>
          <input type='submit'/>
        </form>
      </div>
      <div>
        <h3>Test Safe Write</h3>
        <p>You can check to ensure the proper functioning of the writing to the user database here..</p>
        <?php
           try
         {
           $u = new UserFunctions();
           if($u->validateUser()) {
             $select="<select name='col'>";
             foreach($db_cols as $col=>$type)
               {
                 if($col!='username' && $col!='password' && $col!='auth_key')
                   {
                     $select.="<option value='$col'>$col</option>";
                   }
               }
             $select.="</select>";
        ?>
        <form action='?t=write' method='post'>
          <input type='text' name='data' placeholder='Data to save'/><br/>
          <?php echo $select; ?><br/>
          <input type='submit'/>
        </form>
        <?php
           }
           else echo "Please log in above to test this.";
         } catch(Exception $e) {
    echo "You've not logged in. Please log in above to test this.";
  }
if($_REQUEST['t']=='write')
  {
    echo displayDebug($u->writeToUser($_POST['data'],$_POST['col']));
  }
           ?>
      </div>
      <div>
        <h3>Show User Data</h3>
<?php
try {
           if($u->validateUser()) {
        ?>
        <form action='?t=show' method='post'>
          <p>User: <?php echo $_COOKIE[$cookieuser]; ?></p>
          <input type='password' name='pw' placeholder='password'/><br/>
          <input type='submit'/>
        </form>
        <?php
           }
           else echo "Please log in above to test this.";
} catch(Exception $e) {
  echo "You've not logged in. Please log in above to test this.";
}
           if($_REQUEST['t']=='show')
             {
               echo displayDebug($u->lookupUser($_COOKIE[$cookieuser],$_POST['pw']));
             }
           ?>
      </div>
    </article>
  </body>
</html>
