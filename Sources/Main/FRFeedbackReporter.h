/*
 * Copyright 2008-2017, Torsten Curdt
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

#import <Cocoa/Cocoa.h>

// ARC is requried.
#if !__has_feature(objc_arc)
#error FeedbackReporter requires compiling with ARC
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol FRFeedbackReporterDelegate <NSObject>

@optional

// To add custom items to the HTTP POST beyond the default items (see FRConstants.h),
// implement this delegate method to return whatever other key/values pairs you want.
- (nullable NSDictionary*) customParametersForFeedbackReport;

// By default, reports include the entirety of the preferences.
// If you want to remove some items, for anonymity/privacy reasons, implement this delegate method.
- (NSMutableDictionary*) anonymizePreferencesForFeedbackReport:(NSMutableDictionary *)preferences;

// By default, reports are sent to the URL in the Info.plist key PLIST_KEY_TARGETURL.
// If you want to send them elsewhere, implement this delegate method to return an http or https URL.
- (NSString *) targetUrlForFeedbackReport;

// By default, the report UI uses the Info.plist key CFBundleExecutable as the application's name.
// If you want to show something else, implement this delegate method.
- (NSString *) feedbackDisplayName;

@end


@interface FRFeedbackReporter : NSObject

// Returns the singleton FRFeedbackReporter, creating it if necessary. Does not perform any checks or other real work.
+ (FRFeedbackReporter *)sharedReporter;

// Gets/sets the delegate.
@property (readwrite, weak, nonatomic, nullable) id<FRFeedbackReporterDelegate> delegate;

// Displays the feedback user interface allowing the user to provide general feedback. Returns YES if it was able to display the UI, NO otherwise.
- (BOOL) reportFeedback;

// Searches the disk for crash logs, and displays the feedback user interface if there are crash logs newer than since the last check. Updates the 'last crash check date' (DEFAULTS_KEY_LASTCRASHCHECKDATE) in user defaults. Returns YES if it was able to display the UI, NO otherwise.
- (BOOL) reportIfCrash;

// Displays the feedback user interface for the given exception. Do not pass nil. Returns YES if it was able to display the UI, NO otherwise.
- (BOOL) reportException:(NSException *)exception;

@end

NS_ASSUME_NONNULL_END
