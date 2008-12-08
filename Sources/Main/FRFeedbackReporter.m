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
#import "FRFeedbackController.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "NSException+Callstack.h"
#import "FRUploader.h"
#import "FRApplication.h"
#import "FRConstants.h"

#import <uuid/uuid.h>

@implementation FRFeedbackReporter

#pragma mark Construction

static FRFeedbackReporter *sharedReporter = nil;

+ (FRFeedbackReporter *)sharedReporter
{
	if (sharedReporter == nil) {
		sharedReporter = [[[self class] alloc] init];
    }

	return sharedReporter;
}

#pragma mark Destruction

- (void) dealloc
{
    [feedbackController release];
    
    [super dealloc];
}

#pragma mark Variable Accessors

- (FRFeedbackController*) feedbackController
{
    if (feedbackController == nil) {
        feedbackController = [[FRFeedbackController alloc] init];
    }
    
    return feedbackController;
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id) pDelegate
{
	delegate = pDelegate;
}


#pragma mark Reports

- (BOOL) reportFeedback
{
    FRFeedbackController *controller = [self feedbackController];

    if ([controller isShown]) {
        NSLog(@"Controller already shown");
        return NO;
    }
    
    [controller reset];

    [controller setMessage:[NSString stringWithFormat:
        FRLocalizedString(@"Got a problem with %@?", nil),
        [FRApplication applicationName]]];
    
    [controller setDelegate:delegate];
    
    [controller showWindow:self];
    
    return YES;
}

- (BOOL) reportIfCrash
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTCRASHCHECKDATE];
    
    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastCrashCheckDate];

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTCRASHCHECKDATE];
    
    if ([crashFiles count] > 0) {
        NSLog(@"Found new crash files");

        FRFeedbackController *controller = [self feedbackController];
        
        if ([controller isShown]) {
            NSLog(@"Controller already shown");
            return NO;
        }

        [controller reset];

        [controller setMessage:[NSString stringWithFormat:
            FRLocalizedString(@"%@ has recently crashed!", nil),
            [FRApplication applicationName]]];

        [controller setDelegate:delegate];

        [controller showWindow:self];

        return YES;

    }
    
    return NO;
}

- (BOOL) reportException:(NSException *)exception
{
    FRFeedbackController *controller = [self feedbackController];

    if ([controller isShown]) {
        NSLog(@"Controller already shown");
        return NO;
    }

    [controller reset];
    
    [controller setMessage:[NSString stringWithFormat:
        FRLocalizedString(@"%@ has encountered an exception!", nil),
        [FRApplication applicationName]]];

    [controller setException:[NSString stringWithFormat: @"%@\n\n%@\n\n%@",
                                [exception name],
                                [exception reason],
                                [exception my_callStack] ?:@""]];

    [controller setDelegate:delegate];

    [controller showWindow:self];
    
    return YES;
}

/*
- (BOOL) reportSystemStatistics
{
    // TODO make configurable

    NSTimeInterval statisticsInterval = 7*24*60*60; // once a week

    BOOL ret = NO;

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
        
        ret = YES;
    }

    [now release];

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTSTATISTICSDATE];

    return ret;
}
*/

@end
