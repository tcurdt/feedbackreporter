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

#define FILE_SHELLSCRIPT       @"FRFeedbackReporter"

#define KEY_LASTCRASHCHECKDATE @"FRFeedbackReporter.lastCrashCheckDate"
#define KEY_LASTSTATISTICSDATE @"FRFeedbackReporter.lastStatisticsDate"
#define KEY_LASTSUBMISSIONDATE @"FRFeedbackReporter.lastSubmissionDate"
#define KEY_SENDEREMAIL        @"FRFeedbackReporter.sender"
#define KEY_TARGETURL          @"FRFeedbackReporter.targetURL"
#define KEY_UUID               @"FRFeedbackReporter.uuid"
#define KEY_LOGHOURS           @"FRFeedbackReporter.logHours"
//	The default e-mail address to select in case there is no selection saved in 
//	the preferences. The options are 'anonymous' and 'firstEmail'. If nothing
//	is specified, 'anonymous' is selected.
#define KEY_DEFAULTSENDER      @"FRFeedbackReporter.defaultSender"
//	The number of characters a console log is truncated to. If not specified,
//	no truncation takes place.
#define KEY_MAXCONSOLELOGSIZE  @"FRFeedbackReporter.maxConsoleLogSize"

#define POST_KEY_TYPE          @"type"
#define POST_KEY_EMAIL         @"email"
#define POST_KEY_VERSION       @"version"
#define POST_KEY_COMMENT       @"comment"
#define POST_KEY_SYSTEM        @"system"
#define POST_KEY_CONSOLE       @"console"
#define POST_KEY_CRASHES       @"crashes"
#define POST_KEY_SHELL         @"shell"
#define POST_KEY_PREFERENCES   @"preferences"
#define POST_KEY_EXCEPTION     @"exception"

