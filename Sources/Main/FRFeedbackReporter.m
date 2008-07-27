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
#import "SystemDiscovery.h"
#import "NSException+Callstack.h"
#import "Uploader.h"
#import "Constants.h"

#import <uuid/uuid.h>



@implementation FRFeedbackReporter


static FRFeedbackReporter *sharedReporter = nil;

+ (FRFeedbackReporter *)sharedReporter
{
	if (sharedReporter == nil)
		sharedReporter = [[[self class] alloc] init];
	return sharedReporter;
}

NSString* user = nil;

- (void) setUser:(NSString*)pUser
{
    user = pUser;
}

- (int) reportFeedback
{
    FeedbackController *controller = [[FeedbackController alloc] init];
    [controller setUser:user];
    [controller showWindow:self];
    return 0;
}

- (int) reportIfCrash
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

- (int) reportException:(NSException *)exception
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

- (int) reportSystemStatistics
{
    // TODO make configurable

    NSTimeInterval statisticsInterval = 7*24*60*60; // once a week

    int ret = -1;

	NSDate* now = [[NSDate alloc] init];

    NSDate *lastStatisticsDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTSTATISTICSDATE];
    NSDate *nextStatisticsDate = [lastStatisticsDate addTimeInterval:statisticsInterval];
    
    if (lastStatisticsDate == nil || [now earlierDate:nextStatisticsDate] == nextStatisticsDate) {
        
        NSString *uuid = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_UUID];

        if (uuid == nil) {
            if (lastStatisticsDate != nil) {
                NSLog(@"UUID is missing");
            }
            
            uuid_t buffer;
            
            uuid_generate(buffer);

            char str[36];

            uuid_unparse_upper(buffer, str);
            
            uuid = [NSString stringWithFormat:@"%s", str];

            NSLog(@"Generated UUID %@", uuid);
            
            [[NSUserDefaults standardUserDefaults] setValue: uuid
                                                     forKey: KEY_UUID];

        }

        SystemDiscovery *discovery = [[SystemDiscovery alloc] init];
        
        NSDictionary *system = [discovery discover];
        
        [discovery release];

        NSLog(@"Reporting system statistics for %@ (%@)", uuid, [system description]);

        // TODO async upload
        Uploader *uploader = [[Uploader alloc] initWithTarget:@"" delegate:nil];
        
        [uploader post:system];
        
        [uploader release];
    }

    [now release];

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTSTATISTICSDATE];

    return ret;
}


// deprected

+ (int) reportFeedback
{
    return [[FRFeedbackReporter sharedReporter] reportFeedback];
}

+ (int) reportIfCrash
{
    return [[FRFeedbackReporter sharedReporter] reportIfCrash];
}

+ (int) reportException:(NSException *)exception
{
    return [[FRFeedbackReporter sharedReporter] reportException:exception];
}

+ (int) reportSystemStatistics
{
    return [[FRFeedbackReporter sharedReporter] reportSystemStatistics];
}

+ (void) setUser:(NSString*)pUser
{
    [[FRFeedbackReporter sharedReporter] setUser: pUser];
}

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
