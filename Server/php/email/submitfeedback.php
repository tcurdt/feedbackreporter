<?php
/*
  This is a script for mailing a report as posted by FeedbackReporter 
  https://github.com/tcurdt/feedbackreporter
  
  It formats the output into a fairly readable HTML document. It should also
  be readable by an XML parser (after you remove the email headers). But you
  will have to decode the html entities after you read each section.
*/

function supportedApplications()
{
  // add the names of apps you are supporting here
  $apps[] = 'My Awesome App';
  $apps[] = 'My Other Awesome App';
  
  return $apps;
}


// this will check the title against multiple apps you may be supporting
function isSupportedApp($appName)
{
  return in_array($appName, supportedApplications());
}


// this will check the userAgent against multiple apps you may be supporting
function isSupportedAgent($userAgent)
{
  $userAgent = urldecode($userAgent);
  
  foreach (supportedApplications() as $appName)
    if (strncasecmp($userAgent, $appName, strlen($appName)) == 0)
      return true;
  
  return false;
}


// a dictionary of post keys to readable titles, if a key is not in this list the title will be the same as the key
// add your custom keys
function humanReadableTitles()
{
  $titles['email']       = 'Email';
  $titles['comment']     = 'Comment';
  $titles['crashes']     = 'Crash Report';
  $titles['system']      = 'System Information';
  $titles['preferences'] = 'Preferences';
  $titles['console']     = 'Console Output';
  $titles['exception']   = 'Exception';
  $titles['shell']       = 'Shell';
  
  return $titles;
}


// change the output order of the keys
function orderedKeys($postedData)
{
  // all the keys posted to this report
  $postedKeys = array_keys($postedData);
  
  // each possible FeedbackReporter key in the report
  // add any custom keys your app posts
  // order them as you want to view them
  // take a look at $postedData['type'] if you want to reorder based on the report type
  $keys[] = 'email';
  $keys[] = 'comment';
  $keys[] = 'crashes';
  $keys[] = 'system';
  $keys[] = 'preferences';
  $keys[] = 'console';
  $keys[] = 'exception';
  $keys[] = 'shell';
  
  
  // remove any posted keys you don't want in the report
  $ignoreKeys[] = 'type';
  $ignoreKeys[] = 'version';
  $ignoreKeys[] = 'application';  // custom key
  
  $postedKeys = array_values(array_diff($postedKeys, $ignoreKeys));
  
  
  // add any keys posted in this report that are not in the above list to the end (useful while testing)
  $unknownKeys = array_diff($postedKeys, $keys);
  foreach ($unknownKeys as $key)
    $keys[] = $key;
  
  
  // remove any keys from $keys that have no data (this just makes the report cleaner)
  $emptyKeys = array();
  foreach ($postedKeys as $key)
    if (empty($postedData[$key]))
      $emptyKeys[] = $key;
  $keys = array_values(array_diff($keys, $emptyKeys));
  
  
  return $keys;
}


// change the css to customize the look
function beginningOfReportWithTitle($reportTitle)
{
  $reportTitle = htmlspecialchars($reportTitle);
  return 
"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\">
<html>
<head>
  <title>{$reportTitle}</title>
  <style type=\"text/css\">
    body {
      font-family: \"Lucida Grande\", sans-serif;
      font-size: 75%;
    }
    .content {
      padding-bottom: 2em;
      padding-left: 1em;
      margin-left: 2em;
      background-color: #f7f7f7;
      white-space: pre;
      width: 100%;
    }
    code {
      font: 10pt Monaco, mono;
    }
    .navBar {
      padding-top: 2em;
      padding-bottom: 2em;
      margin-left: 2em;
    }
  </style>
</head>
<body>
<div id=\"FeedbackReporter\">
<h1>{$reportTitle}</h1>";
}


function bodyOfReport($postedData)
{
  $keys   = orderedKeys($postedData);
  $titles = humanReadableTitles();
  
  // build the navigation bar that will be placed between each section of the report
  $navigationBarArray = array();
  foreach ($keys as $key) {
    $title = $titles[$key];
    if (empty($title))
      $title = $key;
    $title = htmlspecialchars($title);
    $navigationBarArray[] = "<a href=\"#{$title}\">{$title}</a>";
  }
  $navigationBar = "<div class=\"navBar\">".implode(' | ', $navigationBarArray)."</div>";
  
  // build up each section to create the body of the report
  $body = '';
  foreach ($keys as $key) {
    $title = $titles[$key];
    if (empty($title))
      $title = $key;
    $title   = htmlspecialchars($title);
    $content = htmlspecialchars($postedData[$key]);
    $body   .= "\n<div id=\"{$title}\">\n<h2>{$title}:</h2>\n<div class=\"content\">\n<code>{$content}</code>\n</div>\n</div>\n{$navigationBar}\n";
  }
  
  return $body;
}


function endOfReport()
{
  return "</div>\n</body>\n</html>";
}


// an ounce of prevention...
function cleanerString($input)
{
  if (empty($input))
    return '';
  
  $badStuph = array('to:', 'cc:', 'bcc:', 'from:', 'return-path:', 'content-type:', 'mime-version:', 'multipart-mixed:', 'content-transfer-encoding:');
  
  // if any bad things are found don't use the input at all (as there may be other unknown bad things)
  foreach ($badStuph as $badThing)
    if (stripos($input, $badThing) !== false)
      return 'Found bad things';
  
  // these aren't technically bad things by themselves, but clean them up for good measure
  $input = str_replace(array("\r", "\n", "%0a", "%0d"), ' ', $input);
  return trim($input);
}


function createTitle($appName, $type, $fromAddress)
{
  $type = $type;
  $title = 'Crash Report';
  
  if ($type == 'feedback') {
    $title = 'Feedback Report';
  } elseif ($type == 'exception') {
    $title = 'Exception Report';
  }
  
  $fromAddress = cleanerString($fromAddress);
  if (empty($fromAddress)) {
    $fromAddress = 'Anonymous';
  }
  
  $title .= " from {$fromAddress} for {$appName}";
  
  return $title;
}


// Don't put user submitted email addresses in the From or Return-Path headers,
// if your mail server is down it will bounce back to that address.
// A malicious person could send spam that way.
// Better to use an account at a seperate email provider so you won't miss a report.
function sendReport($subject, $message)
{
  $to       = 'your.main.report.address@your.domain';
  $from     = 'backup.address@some.other.domain';
  $headers  = "From: {$from}\r\n";
  $headers .= "Return-Path: {$from}\r\n";
  $headers .= "MIME-Version: 1.0\r\n";
  $headers .= "Content-Type: text/html; charset=\"utf-8\"\r\n";
  
  if (empty($message))
    $message = 'There is no message';
  
  $subject = cleanerString($subject);
  if (empty($subject))
    $subject = 'There is no subject';
  
  return mail($to, $subject, $message, $headers);
}



// START

// I'm ignoring the $_GET data, instead I post a custom key called 'application' from the app
if (($_SERVER['REQUEST_METHOD'] == 'POST') && isSupportedAgent($_SERVER['HTTP_USER_AGENT']) && isSupportedApp($_POST['application'])) {
  $title  = createTitle($_POST['application'], $_POST['type'], $_POST['email']);
  $report = beginningOfReportWithTitle($title).bodyOfReport($_POST).endOfReport();
  if (!(sendReport($title, $report))) {
    // don't send detailed error reports on the production server
    // echo 'error with sendReport';
    sendReport('Failed sending crash report', 'sendReport() failed');
  }
  // this is to cause the app to not close the feedback report window (good for testing, make sure to comment this out when copying to the production server)
  // echo 'Testing';
} else {
  // not a proper feedback request
  // always send a message of some sort so you can see what a bot is up to
  if (count($_REQUEST)) {
    foreach($_REQUEST as $key=>$value)
      $keyValues[] = "{$key} = {$value}";
    $message = implode(' | ', $keyValues);
    sendReport('Failed crash report attempt', cleanerString($message));
  } else {
    sendReport('Failed crash report attempt', 'Someone just visiting or a bot fishing');
  }
  
  // send them somewhere usefull
  header('Location: http://your.domain');
}

?>