// npm install formidable
// npm install node-uuid
// npm install prowl
// {
//   "system":"LANGUAGE = en\nCPU_64BIT = YES\nCPU_COUNT = 2\nCPU_SPEED = 2500\nCPU_TYPE = Intel Core 2 Duo (Penryn)\nRAM_SIZE = 4096\nMACHINE_MODEL = MacBookPro4,1\nOS_VERSION = 10.6.7 (Build 10J869)\n",
//   "crashes":"crashes",
//   "preferences":"{\n    \"FRFeedbackReporter.lastCrashCheckDate\" = 2011-05-27 02:46:41 +0200;\n    \"FRFeedbackReporter.lastSubmissionDate\" = 2011-05-22 17:41:40 +0200;\n    \"FRFeedbackReporter.sender\" = \"tcurdt@vafer.org\";\n    NSNavBrowserPreferedColumnContentWidth = 186;\n    NSNavLastRootDirectory = \"~/Development/uif2iso4mac\";\n    NSNavPanelExpandedSizeForOpenMode = \"{518, 400}\";\n    NSNavSidebarWidth = 120;\n    \"NSWindow Frame SUUpdateAlertFrame\" = \"437 363 566 395 0 0 1440 878 \";\n    SUCheckAtStartup = 0;\n    SUEnableAutomaticChecks = 0;\n    SULastCheckTime = 2011-05-27 02:46:52 +0200;\n    U2IF4InstallationId = \"C4BD8C26-5988-4365-BBA1-BEB69A126126\";\n    WebKitDefaultFontSize = 11;\n    WebKitStandardFont = \"Lucida Grande\";\n}",
//   "shell":"shell",
//   "email":"tcurdt at bla.de",
//   "version":"1.4.1 (d0ed0fc7fce00131c19c6f49fd6ff6aff05e8a54)",
//   "type":"feedback",
//   "console":"2011-05-27 02:46:52 +0200: Adding parameters to sparkle check\n",
//   "comment":"test"
// }

var path = "/var/nodejs/feedbackreporter/feedback",
    notify = false,
    port = 3000;

var http = require("http"),
    url = require("url"),
    fs = require("fs"),
    qs = require("querystring"),
    uuid = require('node-uuid'),
    formidable = require('formidable'),
    Prowl = require('prowl').Prowl,
    prowl = new Prowl('prowl-api-key-goes-here');

function sanitize(s) {
  if (s == null) {
    return "null";
  }
  return s.toLowerCase().substr(0, 64).replace(/[^a-zA-Z0-9]+/g, "");
}

function lead(n) {
  if (n < 9) {
    return "0" + n;
  }
  return "" + n;
}

http.createServer(function(request, response) {
  if (request.method == 'POST') {

    var project = sanitize(url.parse(request.url, true).query['project']);

    new formidable.IncomingForm().parse(request, function(err, fields, files) {

      var now = new Date(),
          filename = now.getFullYear() + "-" + lead(now.getMonth()) + "-" + lead(now.getDay()) + "-" + uuid() + ".json";

      fs.writeFile(path + "/" + project + "/" + filename, JSON.stringify(fields), function(err) {
        if(err) {
          console.log(project + ": failed to save report (" + err + ")");

          response.writeHead(200, {"Content-Type": "text/html"});
          response.write("ERR 001");
          response.end();
        } else {
          console.log(project + ": received crash report " + filename);

          if (notify) {
            prowl.add({
              priority: Prowl.NORMAL,
              application: project,
              event: fields['type'] + ' for ' + fields['version'],
              description: fields['comment']
            }, function(status) {
              if (status != 200) {
                console.log(project + ": failed to send prowl notification");
              }
            });
          }

          response.writeHead(200, {"Content-Type": "text/html"});
          response.write("OK 004");
          response.end();
        }
      });
    });
  } else {
    response.writeHead(404, {"Content-Type": "text/html"});
    response.write("Not Found");
    response.end();
  }
}).listen(port);

console.log('listening on http://localhost:' + port);
