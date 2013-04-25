/*
 * Copyright 2008-2011, Torsten Curdt
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

//  Filename of the script in the resource bundle to execute (optional)
#define FILE_SHELLSCRIPT                @"FRFeedbackReporter"

//  URL where to POST the result to (required)
#define PLIST_KEY_TARGETURL             @"FRFeedbackReporter.targetURL"

//  Truncates the console log to not send more than x hours into the past. (optinal)
#define PLIST_KEY_LOGHOURS              @"FRFeedbackReporter.logHours"

//  The default e-mail address to select in case there is no selection saved in
//  the preferences. The options are 'anonymous' and 'firstEmail'. If nothing
//  is specified, 'anonymous' is selected. (optional)
#define PLIST_KEY_DEFAULTSENDER         @"FRFeedbackReporter.defaultSender"

//  The number of characters a console log is truncated to. If not specified,
//  no truncation takes place. (optional)
#define PLIST_KEY_MAXCONSOLELOGSIZE     @"FRFeedbackReporter.maxConsoleLogSize"

//  Set the value of this key to 'YES' to present a checkbox where the user
//  can switch on and off the sending of details information. If not specified,
//  defaults to 'NO', hence no checkbox is shown.
//  If the user checks off the 'send details' option, just the e-mail address,
//  the comment, the type of report, and the application version are transmitted
//  to the server. (optional)
#define PLIST_KEY_SENDDETAILSISOPTIONAL @"FRFeedbackReporter.sendDetailsIsOptional"

// If set to 'YES' the application will exit after an exception has been caught
#define PLIST_KEY_EXITAFTEREXCEPTION    @"FRFeedbackReporter.exitAfterException"

// Keys store in the user defaults
#define DEFAULTS_KEY_LASTCRASHCHECKDATE @"FRFeedbackReporter.lastCrashCheckDate"
#define DEFAULTS_KEY_LASTSUBMISSIONDATE @"FRFeedbackReporter.lastSubmissionDate"
#define DEFAULTS_KEY_SENDEREMAIL        @"FRFeedbackReporter.sender"


// POST fields filled by default
#define POST_KEY_TYPE           @"type"
#define POST_KEY_EMAIL          @"email"
#define POST_KEY_MESSAGE        @"comment"
#define POST_KEY_SYSTEM         @"system"
#define POST_KEY_CONSOLE        @"console"
#define POST_KEY_CRASHES        @"crashes"
#define POST_KEY_SHELL          @"shell"
#define POST_KEY_PREFERENCES    @"preferences"
#define POST_KEY_EXCEPTION      @"exception"
#define POST_KEY_VERSION_LONG   @"version_long"   // Corresponds to CFBundleLongVersionString. Discouraged.
#define POST_KEY_VERSION_SHORT  @"version_short"  // Corresponds to CFBundleShortVersionString.
#define POST_KEY_VERSION_BUNDLE @"version_bundle" // Corresponds to CFBundleVersion.
#define POST_KEY_VERSION        @"version"        // A combination of the above 3.

// Exception parsing
#define EXCEPTION_STACK_SKIP    2
#define EXCEPTION_STACK_LIMIT   100
