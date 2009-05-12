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

$project_raw = $_GET['project'];
$project = preg_replace('/[^(0-9A-Za-z)]*/', '', $project_raw);

$submission_raw = $_GET['submission'];
$submission = preg_replace('/[^(0-9A-Za-z\-\:)]*/', '', $submission_raw);

$submission_dir = $feedback_dir . $project . '/' . $submission;

if(!is_dir($submission_dir)) {
    // no submission directory
    header("HTTP/1.1 404 Not Found"); 
    print("<html><body>HTTP 404 - Not Found</body></html>");
    exit;
}
?><!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
	<head>
		<title>Feedback Report - <?php echo "$submission"; ?></title>
		<style type="text/css" media="screen">
pre {
    white-space: pre-wrap;       /* css-3 */
    white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
    white-space: -pre-wrap;      /* Opera 4-6 */
    white-space: -o-pre-wrap;    /* Opera 7 */
    word-wrap: break-word;       /* Internet Explorer 5.5+ */
    margin: 0;
    padding: 0;
}
div {
	border: 1px solid;    
	background-color: #ccc;
	margin: 5px;
	padding: 5px;
}

#comment {
	width: 500px;
}
#email {
	width: 250px;
}	
#system {
	width: 500px;
}	
#version {
	width: 500px;
}	
#console {
	width: 1000px;
}	
#crashlog {
	width: 1000px;
}	
#exception {
	width: 500px;
}	
#preferences {
	width: 500px;
}	
#shell {
	width: 500px;
}	
		</style>
	</head>
<body>

<div id="version"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/version')); ?></pre></div>
<div id="email"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/email')); ?></pre></div>
<div id="system"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/system')); ?></pre></div>
<div id="comment"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/comment')); ?></pre></div>
<div id="console"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/console')); ?></pre></div>
<div id="crashlog"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/crashes')); ?></pre></div>
<div id="exception"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/exception')); ?></pre></div>
<div id="preferences"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/preferences')); ?></pre></div>
<div id="shell"><pre><?php print htmlspecialchars(file_get_contents($submission_dir . '/shell')); ?></pre></div>

</body>
</html>