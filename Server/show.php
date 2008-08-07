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

echo "Found $submission";

?>
