<?php

function errorlog($type, $info, $file, $row)
{
   global $feedback_dir;
   if ($fh = fopen($feedback_dir . "php.log", "a")) {
      @fwrite($handle, date("Y-m-d H:i:s") . " --> $type: $info FILE: $file -  Row $row\r\n" );
      @fclose($handle);
   }
}

set_error_handler("errorlog");
?>