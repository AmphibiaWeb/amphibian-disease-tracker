<?php
error_reporting(-1);
ini_set("display_errors", 1);
ini_set('error_reporting', -1);
error_log("handle_misc_edits is running in debug mode!");
?>
<!doctype html>
<html>
  <head>
    <title>
      PHP Core tests
    </title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"/>
    <style type="text/css">
    .panel, .alert{ max-width: 80%; }
    code { white-space: pre-wrap; }
    </style>
  </head>
  <body>
      <div class='page-header'><h1>PHP Core tests</h1></div>
    <?php
       require_once("../core.php");
       echo "All is well in load-land.<br/>";
?>
<p>Beginning tests</p>
<?php
# Markdown
echo "<section class='panel panel-primary center-block'><div class='panel-heading'>Markdown Tests</div>";
echo "Raw input:<br/><br/>";
$text = "Here is some **Markdown** text that I *really* want to parse. What about [b]Classic options[/b]? How about greek? [grk]npLl[/grk]";
echo "<code class='center-block text-center'>$text</code><br/>";
$html = Wysiwyg::toHtml($text);
echo "<div class='alert alert-success center-block'>$html<br/><code>".displayDebug($html,false)."</code></div>";
echo "<br/>This de-parses as: <div class='alert alert-success center-block'><code>" . Wysiwyg::fromHtml($html) . "</code></div>";
echo "Full detail: <code>".displayDebug(Wysiwyg::toHtml($text,true),false).displayDebug(Wysiwyg::fromHtml($html,true),false)."</code>";
echo "</section>";
       ?>
  </body>
</html>
