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
#import "NSException+Callstack.h"

static NSString *KEY_LASTCRASHCHECKDATE = @"FRFeedbackReporter.lastCrashCheckDate";

@implementation FRFeedbackReporter

static NSString* user = nil;

+ (void) setUser:(NSString*)pUser
{
    user = pUser;
}

+ (int) reportFeedback
{
    FeedbackController *controller = [[FeedbackController alloc] init];

    [controller setUser:user];

    int ret = [controller runModal];
    
    [controller release];
    
    return ret;
}

+ (int) reportIfCrash
{
    int ret = NSCancelButton;
    
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTCRASHCHECKDATE];
    
    if (lastCrashCheckDate != nil) {
        NSArray *crashFiles = [CrashLogFinder findCrashLogsBefore:lastCrashCheckDate];
        
        if ([crashFiles count] > 0) {
            NSLog(@"Found new crash files");

            FeedbackController *controller = [[FeedbackController alloc] init];

            [controller setUser:user];
            [controller setComment:NSLocalizedString(@"The application crashed after I...", nil)];

            ret = [controller runModal];
            
            [controller release];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTCRASHCHECKDATE];

    return ret;
}

+ (int) reportException:(NSException *)exception
{
    FeedbackController *controller = [[FeedbackController alloc] init];

    [controller setUser:user];

    [controller setComment:NSLocalizedString(@"Uncought exception", nil)];


    NSString *s = [NSString stringWithFormat: @"%@\n\n%@\n\n%@",
                             [exception name],
                             [exception reason],
                             [exception my_callStack] ?:@""];

    [controller setException:s];

    int ret = [controller runModal];
    
    [controller release];

    return ret;
}



// deprected

+ (void) reportAsUser:(NSString*)user
{
    [self setUser:user];
    [self reportFeedback];
}

+ (void) reportCrashAsUser:(NSString*)user
{
    [self setUser:user];
    [self reportIfCrash];
}

@end
