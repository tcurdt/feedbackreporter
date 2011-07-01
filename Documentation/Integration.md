# Integration into your projects

## Call out into the framework

Once you got the framework embedded into you application the actual
integration is really easy. Just include the header file and a few class
methods become available.

    [[FRFeedbackReporter sharedReporter] reportFeedback];
    [[FRFeedbackReporter sharedReporter] reportIfCrash];


Method `reportIfCash` should preferably be called just after your application
has started. A good place is `applicationDidFinishLaunching` of the
application controller. It checks whether there has been a crash or hang
report since the last run. If so, it presents the user the feedback dialog. If
there wasn't it moves on quietly.

Method `reportFeedback` is usually called from a "Feedback" menu item in your
"Help" menu. This way users can send feedback at any time using the same
mechanism.

You can set a delegate and...

      ...
      [[FRFeedbackReporter sharedReporter] setDelegate:self];
    }

pass in arbitrary data on the submission e.g. like license information,

    - (NSDictionary*) customParametersForFeedbackReport
    {
      NSMutableDictionary *dict = [NSMutableDictionary dictionary];
      ...
      return dict;
    }

there is a hook to anonymize the preference information

    - (NSMutableDictionary*) anonymizePreferencesForFeedbackReport:(NSMutableDictionary *)preferences
    {
      ...
      return preferences;
    }

and you can change/set the target for the feedback report

    - (NSString *) targetUrlForFeedbackReport
    {
      return "http://somewhere.com/"
    }

## Catch uncaught exceptions

FeedbackReporter can also catch uncaught exceptions and pop up whenever they
happen. All you have to do is to specify a new principal class in the
project's `Info.plist`.

    <key>Principal class</key>
    <string>FRExceptionReportingApplication</string>

## Specify the target in your projects Info.plist

The framework needs to know where to post the information to. The target needs
to be specified in the application's `Info.plist`. Note: the %@ will get
expanded to your application's name. If you don't want this URL to be
guessable it can also be hard coded to whatever you like. The `project`
parameter must just match the directory on the server.

    <key>FRFeedbackReporter.targetURL</key>
    <string>http://yourdomain.com/feedback/submit.php?project=%@</string>

## Gather custom information from a shell script

In case your application needs more details from the user's system than what
is provided by the FeedbackReporter framework you can include a shell script
called `FRFeedbackReporter.sh` into your application bundle. It will be called
whenever the feedback dialog comes up and the stdout and stderr output gets
included in the `shell` pane.

    #!/bin/sh
    ls -la ~/Library/Something

Please check the [documentation][1] for more how to receive the data on the
server.

[1]: https://github.com/tcurdt/feedbackreporter/blob/master/Documentation/Server.md
