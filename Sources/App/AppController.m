/*
 * Copyright 2008-2013, Torsten Curdt
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

#import "AppController.h"
#import <FeedbackReporter/FRFeedbackReporter.h>

@implementation AppController

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    [[FRFeedbackReporter sharedReporter] setDelegate:self];

    NSLog(@"checking for crash");
    [[FRFeedbackReporter sharedReporter] reportIfCrash];
}

- (NSDictionary *) customParametersForFeedbackReport
{
    NSLog(@"adding custom parameters");

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:@"tcurdt"
             forKey:@"user"];

    [dict setObject:@"1234-1234-1234-1234"
             forKey:@"license"];

    return dict;
}

- (NSString *) feedbackDisplayName
{
   return @"Test App";
}

/*
- (NSString *)targetUrlForFeedbackReport
{
    NSString *targetUrlFormat = @"http://myserver.com/submit.php?project=%@&version=%@";
    NSString *project = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"];
    return [NSString stringWithFormat:targetUrlFormat, project, version];
}*/

- (IBAction) buttonFeedback:(id)sender
{
    NSLog(@"button");
    [[FRFeedbackReporter sharedReporter] reportFeedback];
}

- (IBAction) buttonException:(id)sender
{
    NSLog(@"exception on main thread - unicode: ❄");
    [NSException raise:@"TestException-MainThread" format:@"Something went wrong (☃ attack?)"];
}

- (void) threadWithException
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"exception on NSThread - unicode: ❄");
    [NSException raise:@"TestException-NSThread" format:@"Something went wrong (☃ attack?)"];
    [pool drain];
}

- (IBAction) buttonExceptionInThread:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadWithException) toTarget:self withObject:nil];
}

- (IBAction) buttonExceptionInDispatchQueue:(id)sender
{
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
	dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1);
	dispatch_after(popTime, queue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSLog(@"exception on dispatch queue - unicode: ❄");
		[NSException raise:@"TestException-DispatchQueue" format:@"Something went wrong (☃ attack?)"];
		[pool drain];
	});
	
	// leak queue.
#else
	NSBeep();
#endif
}

- (IBAction) buttonCrash:(id)sender
{
    NSLog(@"crash");
    char *c = 0;
    *c = 0;
}

@end
