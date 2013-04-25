# Receiving the information on the server

The framework is using a standard multi-part post request to upload the data
to the web server. It uses the target URL that is specified in the
`Info.plist`. Once on the server you can easily inject them into your bug
tracking/ticketing system or just zip them up and send them to you via email.

There are couple -mostly contributed- scripts that can receive the reports on
the server side.

 * a PHP script that sends you an email
 * a PHP script that just writes the data to disk and let's cron send the email
 * a PHP script that directly creates an issue in [Mantis][1]
 * a node.js app that stores the reports to disk as json and (optinally) sends a notification via [prowl][2]

...of course you can easily write your own backend. In the end it's just the
same as receiving a form POST submission.

Please check the various scripts/backends for how to configure them.

[1]: http://www.mantisbt.org/
[2]: http://www.prowlapp.com/