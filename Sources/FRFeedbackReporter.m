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

#import "FRFeedbackReporter.h"
#import "FeedbackController.h"
#import "CrashLogFinder.h"

static NSString *KEY_LASTCRASHCHECKDATE = @"FRFeedbackReporter.lastCrashCheckDate";

@implementation FRFeedbackReporter

+ (void) reportAsUser:(NSString*)user
{
    FeedbackController *controller = [[FeedbackController alloc] initWithUser:user];

    [controller showWindow:self];
}

+ (void) reportCrashAsUser:(NSString*)user
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTCRASHCHECKDATE];
    
    if (lastCrashCheckDate != nil) {
        NSArray *crashFiles = [CrashLogFinder findCrashLogsBefore:lastCrashCheckDate];
        
        if ([crashFiles count] > 0) {
            NSLog(@"found new crash files");

            NSString *comment = NSLocalizedString(@"The application crashed after I...", nil);

            FeedbackController *controller = [[FeedbackController alloc] initWithUser:user comment:comment];

            [controller showWindow:self];

        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTCRASHCHECKDATE];

}

@end
