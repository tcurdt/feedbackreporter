/*
 * Copyright 2008-2012, Jens Alfke, Torsten Curdt
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

#import "FRExceptionReportingApplication.h"
#import "NSException+Callstack.h"
#import "FRFeedbackReporter.h"
#import <pthread.h>

@implementation FRExceptionReportingApplication

- (void) reportException:(NSException *)x
{
    [super reportException: x];
    
    @try {
        if (!pthread_main_np()) {
            [[FRFeedbackReporter sharedReporter] performSelectorOnMainThread:@selector(reportException:) withObject:x waitUntilDone:NO];
            [NSThread exit];
        }
        else {
            [[FRFeedbackReporter sharedReporter] reportException:x];
        }
    }
    @catch (NSException *exception) {

        if ([exception respondsToSelector:@selector(callStackSymbols)]) {
            NSLog(@"Problem within FeedbackReporter %@: %@  call stack:%@", [exception name], [exception  reason],[(id)exception callStackSymbols]);
        } else {
            NSLog(@"Problem within FeedbackReporter %@: %@  call stack:%@", [exception name], [exception  reason],[exception callStackReturnAddresses]);
        }

    }
    @finally {
    }
}


@end
