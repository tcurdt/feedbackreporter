<?php

$feedback_dir = '/home/tcurdt/feedback/';

$feedback_files = array('email');

$feedback_max_files = 20;

// --------------------------------------

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