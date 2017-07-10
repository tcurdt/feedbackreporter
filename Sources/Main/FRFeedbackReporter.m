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

#import "FRFeedbackReporter.h"
#import "FRFeedbackController.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "NSException+Callstack.h"
#import "FRUploader.h"
#import "FRApplication.h"
#import "FRConstants.h"
#import "FRLocalizedString.h"

// Private interface.
@interface FRFeedbackReporter()
@property (readwrite, strong, nonatomic) FRFeedbackController* feedbackController;
@end

@implementation FRFeedbackReporter

#pragma mark Construction

+ (FRFeedbackReporter *)sharedReporter
{
    static FRFeedbackReporter *sharedReporter = nil;

    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{ sharedReporter = [[[self class] alloc] init]; });

    return sharedReporter;
}

#pragma mark Destruction

- (void) dealloc
{
    [_feedbackController release];
    
    [super dealloc];
}

#pragma mark Variable Accessors

- (FRFeedbackController*) feedbackController
{
    if (_feedbackController == nil) {
        _feedbackController = [[FRFeedbackController alloc] init];
    }
    
    return _feedbackController;
}

#pragma mark Reports

- (BOOL) reportFeedback
{
    FRFeedbackController *controller = [self feedbackController];

    @synchronized (controller) {
    
        if ([controller isShown]) {
            NSLog(@"Controller already shown");
            return NO;
        }
        
        [controller reset];

        NSString * applicationName = nil;
        id<FRFeedbackReporterDelegate> strongDelegate = [self delegate];
        if ([strongDelegate respondsToSelector:@selector(feedbackDisplayName)]) {
            applicationName = [strongDelegate feedbackDisplayName];
        }
        else {
            applicationName = [FRApplication applicationName];
        }

        [controller setHeading:[NSString stringWithFormat:
            FRLocalizedString(@"Got a problem with %@?", nil),
            applicationName]];
        
        [controller setSubheading:FRLocalizedString(@"Send feedback", nil)];

        [controller setType:FR_FEEDBACK];

        [controller setDelegate:strongDelegate];

        [controller showWindow:self];

    }
    
    return YES;
}

- (BOOL) reportIfCrash
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY_LASTCRASHCHECKDATE];
    
    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastCrashCheckDate];

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: DEFAULTS_KEY_LASTCRASHCHECKDATE];
    
    if (lastCrashCheckDate && [crashFiles count] > 0) {
        // NSLog(@"Found new crash files");

        FRFeedbackController *controller = [self feedbackController];

        @synchronized (controller) {
        
            if ([controller isShown]) {
                NSLog(@"Controller already shown");
                return NO;
            }

            [controller reset];

            NSString * applicationName = nil;
            id<FRFeedbackReporterDelegate> strongDelegate = [self delegate];
            if ([strongDelegate respondsToSelector:@selector(feedbackDisplayName)]) {
               applicationName = [strongDelegate feedbackDisplayName];
            }
            else {
               applicationName = [FRApplication applicationName];
            }
           
            [controller setHeading:[NSString stringWithFormat:
                FRLocalizedString(@"%@ has recently crashed!", nil),
                applicationName]];
            
            [controller setSubheading:FRLocalizedString(@"Send crash report", nil)];
            
            [controller setType:FR_CRASH];

            [controller setDelegate:strongDelegate];

            [controller showWindow:self];

        }
        
        return YES;

    }
    
    return NO;
}

- (BOOL) reportException:(NSException *)exception
{
    FRFeedbackController *controller = [self feedbackController];

    @synchronized (controller) {

        if ([controller isShown]) {
            NSLog(@"Controller already shown");
            return NO;
        }

        [controller reset];
       
        NSString * applicationName = nil;
        id<FRFeedbackReporterDelegate> strongDelegate = [self delegate];
        if ([strongDelegate respondsToSelector:@selector(feedbackDisplayName)]) {
            applicationName = [strongDelegate feedbackDisplayName];
        }
        else {
            applicationName = [FRApplication applicationName];
        }

      
        [controller setHeading:[NSString stringWithFormat:
            FRLocalizedString(@"%@ has encountered an exception!", nil),
            applicationName]];
        
        [controller setSubheading:FRLocalizedString(@"Send crash report", nil)];

        NSString* callStack = [exception my_callStack];
        [controller setException:[NSString stringWithFormat: @"%@\n\n%@\n\n%@",
                                    [exception name],
                                    [exception reason],
                                    callStack ? callStack : @""]];

        [controller setType:FR_EXCEPTION];

        [controller setDelegate:strongDelegate];

        [controller showWindow:self];

    }
    
    return YES;
}

@end
