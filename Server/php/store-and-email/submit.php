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

include 'config.php';
include 'errorlog.php';

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

function uniq()
{
    return date('Y-m-d\\TH:i:s-') . md5(getmypid().uniqid(rand()).$_SERVER[‘SERVER_NAME’]);
}

$project_raw = $_GET['project'];
$project = preg_replace('/[^(0-9A-Za-z)]*/', '', $project_raw);

if ($project != $project_raw) {
    echo "ERR 007\n";
    echo "project name mismatch";
    exit;    
}

$project_dir = $feedback_dir . $project . '/';

if(!is_dir($project_dir)) {
    // no project directory
    
    if (!$create_project_dirs) {
        // no project directory (and not configured to create one)
        echo "ERR 002\n";
        echo "no such project";
        exit;        
    }
    
    if (count(dirs($feedback_dir)) > $feedback_max_project) {
        // too many projects
        echo "ERR 009\n";
        echo "too many projects";
        exit;                
    }
    
    // create project dir
    if (!mkdir($project_dir)) {
        // failed to create project directory
        echo "ERR 008\n";
        echo "could not create project dir";
        exit;
    }
}

$submission_dir = $project_dir . uniq() . '/';

if (!mkdir($submission_dir)) {
    // failed to create submission directory
    echo "ERR 003\n";
    echo "failed to create submission directory";
    exit;
}

foreach($feedback_files as $file) {
   
   $dest = $submission_dir . '/' . $file;
   
   $fh = fopen($dest, "w");
   
   if (!$fh) {
       // failed to create file
       echo "ERR 004 $file\n";
       echo "failed to create file";
       continue;
   }

   fwrite($fh, $_POST[$file]);
   
   fclose($fh);
   
   echo "OK 004 $file\n";
}

if (count($_FILES) > $feedback_max_files) {
    // too many files submitted
    echo "ERR 005\n";
    echo "too many files";
    exit;
}


$i = 0;
foreach($_FILES as $file) {
    
    $dest = $submission_dir . "file-$i";
    
    if(!move_uploaded_file($file['tmp_name'], $dest)){
        // failed to move uploaded file
        echo 'ERR 006 ' . $file['error'] . "\n";
        echo "failed to move file";
    } else {
        echo 'OK 006 ' . $file['name'] . "\n";
    }
    
    chmod($dest, 0644);
}

?>
