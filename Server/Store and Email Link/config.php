<?php

# destination directory needs to be writable by web server
$feedback_dir = '/home/tcurdt/feedback/';

# fields that get stored as files
$feedback_files = array(
    'type',
    'version',
    'comment',
    'email',
    'exception',
    'system',
    'console',
    'crashes',
    'preferences',
    'shell',
    // add custom fields here
    );

# create directories for unknown projects automatically
$create_project_dirs = true;

# hard limits
$feedback_max_files = 20;
$feedback_max_project = 20;

?>
