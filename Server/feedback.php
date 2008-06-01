<?php
/*
 * Copyright 2008, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# destination directory needs to be writable by web server
$feedback_dir = '/path/to/feedback/';

# fields that get stored as files
$feedback_files = array('user', 'version', 'comment', 'email', 'exception', 'system', 'console', 'crashes', 'preferences', 'shell');

// --------------------------------------
$feedback_max_files = 20;

function uniq()
{
    return date('Y-m-d\\TH:i:s-') . md5(getmypid().uniqid(rand()).$_SERVER[‘SERVER_NAME’]);
}

function dirs($dir)
{
    $fh = opendir($dir);

    while($entryName = readdir($fh)) {
        if ($entryName{0} != '.') {
	        $dirArray[$entryName] = $entryName;            
        }
    }

    closedir($fh);
    
    return $dirArray;
}

$projects = dirs($feedback_dir);

if (!$projects[$_GET['project']]) {
    echo "ERR 001\n";
    exit;
}

$project_dir  = $feedback_dir . $projects[$_GET['project']] . '/';

if(!is_dir($project_dir)) {
    echo "ERR 002\n";
    exit;    
}

$submission_dir = $project_dir . uniq() . '/';

if (!mkdir($submission_dir)) {
    echo "ERR 003\n";
    exit;
}

foreach($feedback_files as $file) {
   
   $dest = $submission_dir . '/' . $file;
   
   $fh = fopen($dest, "w");
   
   if (!$fh) {
       echo "ERR 004 $file\n";
       continue;
   }

   fwrite($fh, $_POST[$file]);
   
   fclose($fh);
   
   echo "OK 004 $file\n";
}

if (count($_FILES) > $feedback_max_files) {
    echo "ERR 005\n";
    exit;
}


$i = 0;
foreach($_FILES as $file) {
    
    $dest = $submission_dir . "file-$i";
    
    if(!move_uploaded_file($file['tmp_name'], $dest)){
        echo 'ERR 006 ' . $file['error'] . "\n";
    } else {
        echo 'OK 006 ' . $file['name'] . "\n";
    }
    
    @chmod($dest, 0644);
}

?>
