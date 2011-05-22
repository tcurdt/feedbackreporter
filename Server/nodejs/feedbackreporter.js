// npm install formidable
// npm install node-uuid

var path = "/var/nodejs/feedbackreporter/feedback",
    port = 3000;

var http = require("http"),
    url = require("url"),
    fs = require("fs"),
    qs = require("querystring"),
    uuid = require('node-uuid'),
    formidable = require('formidable');

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
