<?php

/***
 * Basic WYSIWYG functionality. Left for backwards compatibility if
 * dropped into old things.
 ***/

function parseBlock($block,$sanitize=true,$strip=true,$paragraph=true)
{
  // check for base64, and decode it if passed
  $raise_error=false;
  $error_log="";
  if(base64_encode(base64_decode($block,true))==$block) $block=base64_decode($block);
  if(!is_string($block)) return array(false,'error'=>'A string wasn\'t provided.');
  if($sanitize)
    {
      # Requires DBHelper -- make sure it's included earlier!            
      $parsed=DBHelper::staticSanitize($block);
    }
  else $parsed=$block;
  /***
       Check paragraphs
  ***/
  // tags
  if($paragraph)
    {
      if(strpos($parsed,"<p>")===false) $parsed = "<p>" . $parsed;
      if(strpos($parsed,"</p>")===false) $parsed = $parsed . "</p>";
    }
  $parsed=urldecode($parsed);
  // possibly has a bug removing a line beginning with a single quote after a new line.
  $parsed = preg_replace('/((([\\\\nr]){2,}(?<=\\\\)(?<!n)[^\'"(])(?![\']))|([\n\r]{2,})/', '</p><p>', $parsed); // new paragraph parsing


  //pass fixes
  $parsed=stripslashes($parsed);
  $parsed=preg_replace('/&(?![A-Za-z0-9#]{1,7};)/','&amp;',$parsed); // replace standalone "&" with &amp;
  $parsed=preg_replace("/([^=])'([^\/>](?!(.{2,6}=)))/","$1&#39;$2",$parsed); // replace standalone single quotes
  // some characters
  $parsed=str_replace(" < "," &lt; ",$parsed);
  $parsed=str_replace(" > "," &gt; ",$parsed);
  $parsed=str_replace("--","&#8212;",$parsed);
  //Fix broken bits pasted from a word processor
  $parsed=str_replace("—","&#8212;",$parsed);
  $parsed=str_replace("","",$parsed);
  $parsed=str_replace("“","\"",$parsed);
  $parsed=str_replace("‹","-",$parsed);
  $parsed=str_replace("”","\"",$parsed);
  $parsed=str_replace("’","'",$parsed);
  $parsed=str_replace("‘","'",$parsed);
  $parsed=str_replace("…","...",$parsed);
  $parsed=str_replace("–","&#8212;",$parsed);



  /***
      Replace special tags. Only iterate over them if any exist.
  ***/
  //img
  if(strpos($parsed,"[img:")!==false)
    {
      $pos=strpos($parsed,"[img:");
      while($pos!==false)
        {
          $img_o="";
          $end=strpos($parsed,"]",$pos);
          if(substr($parsed,$pos-3,3)=="<p>")
            {
              $i_switch=true;
              $i_rep="<p>";
            }
          else if (substr($parsed,$pos-4,4)=="<p>\n")
            {
              $i_switch=true;
              $i_rep="<p>\n";
            }
          else
            {
              $i_switch=false;
              //$img_o.="<!-- 4 parse '" . substr($parsed,$pos-4,4) . "'-->";
            }
          $length=$end-$pos;
          $img=substr($parsed,$pos,$length);
          //echo "<pre>$img tag from $pos to $end</pre>";
          $img_e=explode(",",$img);
          if(sizeof($img_e<2)) return array(false,'error'=>'Fatal Error: Bad Image Syntax');
          $img_o.="<div class='img" . strtolower($img_e[1]); // alignment
          $img_o.="'>\n<img src='" . substr($img_e[0],5) . "'"; // src
          // parse comment
          if(sizeof($img_e)>3)
            {
              $i=0;
              foreach($img_e as $caption)
                {
                  if($i>2) $img_e[2].=",$caption";
                  $i++;
                }
            }
          if(!empty($img_e[2])) $img_o .= " alt='" . $img_e[2] . "'/>\n<p>" . $img_e[2] . "</p>";
          else $img_o .="/>";
          $img_o.="\n</div>";
          if($i_switch)
            {
              $img=$i_rep.$img;
              $img_o.="<p>";
            }
          $parsed=str_replace($img . "]",$img_o,$parsed);
          $pos=strpos($parsed,"[img:");
        }
    }

  //link
  if(strpos($parsed,"[link:")!==false)
    {
      $pos=strpos($parsed,"[link:");
      while($pos!==false)
        {
          $end=strpos($parsed,"]",$pos);
          $length=$end-$pos;
          $link=substr($parsed,$pos,$length);
          // kill embedded javascript
          $link=str_replace("javascript:","",strtolower($link));
          $link_e=explode(",",$link);
          if(sizeof($link_e)<2) $link_e=array($link,substr($link_e[0],6));
          $link_o="<a href='" . urlencode(substr($link_e[0],6)) . "'>" . $link_e[1] . "</a>";
          $parsed=str_replace($link . "]",$link_o,$parsed);
          $pos=strpos($parsed,"[link:");
        }
    }

  //u
  if(strpos($parsed,"[u]")!==false)
    {
      $pos=strpos($parsed,"[u]");
      while($pos!==false)
        {
          $end=strpos($parsed,"[/u]",$pos);
          if($end===false)
            {
              $short=trim(substr($parsed,$pos,25));
              $short_rep=trim(str_replace("[u]","[TagError]",$short));
              $parsed=str_replace($short,$short_rep,$parsed);
              $raise_error=true;
              $error_log.="<p>Unclosed tag found! Section begins as: '$short'. It has been replaced by '$short_rep'. It is strongly suggested you correct the problem and resave.</p>";
            }
          $length=$end-$pos;
          $uline=substr($parsed,$pos+3,$length-3);
          $uline_o="<span class='ul'>$uline</span>";
          $parsed=str_replace("[u]" . $uline . "[/u]",$uline_o,$parsed);
          $pos=strpos($parsed,"[u]");
        }
    }

  //b
  if(strpos($parsed,"[b]")!==false)
    {
      $pos=strpos($parsed,"[b]");
      while($pos!==false)
        {
          $end=strpos($parsed,"[/b]",$pos);
          if($end===false)
            {
              $short=trim(substr($parsed,$pos,25));
              $short_rep=trim(str_replace("[b]","[TagError]",$short));
              $parsed=str_replace($short,$short_rep,$parsed);
              $raise_error=true;
              $error_log.="<p>Unclosed tag found! Section begins as: '$short'. It has been replaced by '$short_rep'. It is strongly suggested you correct the problem and resave.</p>";
            }
          $length=$end-$pos;
          $bold=substr($parsed,$pos+3,$length-3);
          $bold_o="<strong>$bold</strong>";
          $parsed=str_replace("[b]" . $bold . "[/b]",$bold_o,$parsed);
          $pos=strpos($parsed,"[b]");
        }
    }

  //i
  if(strpos($parsed,"[i]")!==false)
    {
      $pos=strpos($parsed,"[i]");
      while($pos!==false)
        {
          $end=strpos($parsed,"[/i]",$pos);
          if($end===false)
            {
              $short=trim(substr($parsed,$pos,25));
              $short_rep=trim(str_replace("[i]","[TagError]",$short));
              $parsed=str_replace($short,$short_rep,$parsed);
              $raise_error=true;
              $error_log.="<p>Unclosed tag found! Section begins as: '$short'. It has been replaced by '$short_rep'. It is strongly suggested you correct the problem and resave.</p>";
            }
          $length=$end-$pos;
          $em=substr($parsed,$pos+3,$length-3);
          $em_o="<em>$em</em>";
          $parsed=str_replace("[i]" . $em . "[/i]",$em_o,$parsed);
          $pos=strpos($parsed,"[i]");
        }
    }

  //Greek Characters
  if(strpos($parsed,"[grk]")!==false)
    {
      $pos=strpos($parsed,"[grk]");
      while($pos!==false)
        {
          $end=strpos($parsed,"[/grk]",$pos);
          if($end===false)
            {
              $short=trim(substr($parsed,$pos,25));
              $short_rep=trim(str_replace("[grk]","[TagError]",$short));
              $parsed=str_replace($short,$short_rep,$parsed);
              $raise_error=true;
              $error_log.="<p>Unclosed tag found! Section begins as: '$short'. It has been replaced by '$short_rep'. It is strongly suggested you correct the problem and resave.</p>";
            }
          $length=$end-$pos;
          $grk=substr($parsed,$pos+5,$length-5);
          $grk_o="<span class='greek' lang='gr'>$grk</span>";
          $parsed=str_replace("[grk]" . $grk . "[/grk]",$grk_o,$parsed);
          $pos=strpos($parsed,"[grk]");
        }
    }

  /**
   * Lists
   * Lists are made with [list][/list], with - or * preceeded by
   * either a space or newline and followed by a space assumed to be
   * new list elements.
   */
  $exp=explode("[list]",$parsed);
  foreach($exp as $k=>$list)
    {
      if($k>0) { // always skip the first element
        if(strpos($list,"[/list]")===false)
          {
            $raise_error=true;
            $short=trim(substr($parsed,$pos,25));
            $list="[TagError]".$list;
            $error_log.="<p>Unclosed list found! Section begins as '$short'. It is strongly suggested you correct the problem and resave.</p>";
          }
        $list_e=explode("[/list]",$list,2); // only work with the content in the list
        $e = array_filter(preg_split('/([\n\r](-|\*)|( (-|\*) ))[ ]*/', $list_e[0])); // split at list item criteria
        $list_e[0]=implode("</li>\n<li>",$e)."</li></ul>"; // join as list elements, append list closure
        $list="<ul><li>".implode("\n",$list_e); // join the list halves
      }
      $exp[$k]=$list;
    }
  $parsed=implode("\n",$exp);


// replace emotion tag with HTML.
// The tag is self-closed, so fancy parsing isn't needed here.
  $exp=explode("[[emotion]]",$parsed);
  $parsed=implode("<span class='editor_replace_emotion'></span>",$exp);


  if(strpos(substr($parsed,-8),"</p>")===false && $paragraph) $parsed.="</p>";
  // database clean
  if(!$strip)$parsed=addslashes($parsed);
  if($raise_error) return array(true,'html'=>$parsed,'error_log'=>$error_log,'new_edit'=>deparseBlock($parsed));
  return $parsed;
}

function deparseBlock($block)
{
  $parsed=$block;
  // Un-replace fixes
  $parsed=stripslashes($parsed);
  $parsed=str_replace("</p><p>","\r\n\r",$parsed);
  $parsed=str_replace("<p>","",$parsed);
  $parsed=str_replace("</p>","",$parsed);

  $parsed=str_replace(" &lt; "," < ",$parsed);
  $parsed=str_replace(" &gt; "," > ",$parsed);
  $parsed=str_replace("&#8212;","--",$parsed);

  // must be replaced now in case there were overzealous earlier replacements ....
  $parsed=str_replace(array("&#39;","&#34;"),array("'","\""),$parsed);

  // retag
  if(strpos($parsed,"<div class='img")!==false)
    {
      $pos=strpos($parsed,"<div class='img");
      while($pos!==false)
        {
          $length=strpos($parsed,"</div>",$pos)+6-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[img:";
          $begin=$pos+15;
          $end=strpos($parsed,"'",$begin);
          $length=$end-$begin;
          $align=substr($parsed,$begin,$length);
          $begin=strpos($parsed,"src='",$begin)+5;
          $end=strpos($parsed,"'",$begin);
          $length=$end-$begin;
          $src=substr($parsed,$begin,$length);
          $tag.= $src . ",$align";
          if(strpos($parsed,"$src' alt='",$begin)!==false)
            {
              $begin=strpos($parsed,"alt='",$begin)+5;
              $end=strpos($parsed,"'",$begin);
              $length=$end-$begin;
              $tag.= "," . substr($parsed,$begin,$length);
            }
          $tag.="]";
          $parsed=str_replace($search,$tag,$parsed);
          $pos=strpos($parsed,"<div class='img");
        }
    }

  if(strpos($parsed,"<a href='")!==false)
    {
      $pos=strpos($parsed,"<a href='");
      while($pos!==false)
        {
          $length=strpos($parsed,"</a>",$pos)+4-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[link:";
          $md = "[";
          $begin=$pos+9;
          $end=strpos($parsed,"'",$begin);
          $length=$end-$begin;
          $href=substr($parsed,$begin,$length);
          $tag.=$href;
          $begin=strpos($parsed,"'>",$begin)+2;
          $end=strpos($parsed,"</a>",$begin);
          $length=$end-$begin;
          $text = substr($parsed,$begin,$length);
          $md .= $text."](".$href.")";
          $tag.="," . $text . "]";
          $parsed=str_replace($search,$md,$parsed);
          $pos=strpos($parsed,"<a href='");
        }
    }

  // style tags
  if(strpos($parsed,"<strong>")!==false)
    {
      $pos=strpos($parsed,"<strong>");
      while($pos!==false)
        {
          $end=strpos($parsed,"</strong>",$pos);
          $length=$end+9-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[b]";
          $md = "**";
          $begin=$pos+8;
          $length=$end-$begin;
          $text = substr($parsed,$begin,$length);
          $tag.=$text . "[/b]";
          $md .= $text."**";
          $parsed=str_replace($search,$md,$parsed);
          $pos=strpos($parsed,"<strong>");
        }
    }

  if(strpos($parsed,"<em>")!==false)
    {
      $pos=strpos($parsed,"<em>");
      while($pos!==false)
        {
          $end=strpos($parsed,"</em>",$pos);
          $length=$end+5-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[i]";
          $md = "*";
          $begin=$pos+4;
          $length=$end-$begin;
          $text = substr($parsed,$begin,$length);
          $tag.= $text . "[/i]";
          $md .= $text."*";
          $parsed=str_replace($search,$md,$parsed);
          $pos=strpos($parsed,"<em>");
        }
    }

  if(strpos($parsed,"<span class='ul'>")!==false)
    {
      $pos=strpos($parsed,"<span class='ul'>");
      while($pos!==false)
        {
          $end=strpos($parsed,"</span>",$pos);
          $length=$end+7-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[u]";
          $begin=$pos+17;
          $length=$end-$begin;
          $tag.=substr($parsed,$begin,$length) . "[/u]";
          $parsed=str_replace($search,$tag,$parsed);
          $pos=strpos($parsed,"<span class='ul'>");
        }
    }

  if(strpos($parsed,"<span class='greek' lang='gr'>")!==false)
    {
      $pos=strpos($parsed,"<span class='greek' lang='gr'>");
      while($pos!==false)
        {
          $end=strpos($parsed,"</span>",$pos);
          $length=$end+7-$pos;
          $search=substr($parsed,$pos,$length);
          $tag="[grk]";
          $begin=$pos+30;
          $length=$end-$begin;
          $tag.=substr($parsed,$begin,$length) . "[/grk]";
          $parsed=str_replace($search,$tag,$parsed);
          $pos=strpos($parsed,"<span class='greek' lang='gr'>");
        }
    }

  # Need to do more Markdown-style replacements ...
  
  $exp=explode("<ul>",$parsed);
  $parsed=implode("[list]\n",$exp);
  $exp=explode("<li>",$parsed);
  $parsed=implode("* ",$exp);
  $exp=explode("</ul>",$parsed);
  $parsed=implode("[/list]",$exp);
  $parsed=str_replace("</li>","",$parsed);

  return $parsed;

}


?>