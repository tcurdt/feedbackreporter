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

#import "AppController.h"
#import <FeedbackReporter/FRFeedbackReporter.h>

// Private interface.
@interface AppController()
@property (readwrite, strong, nonatomic) IBOutlet NSWindow* window;
@end


@implementation AppController

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    assert(aNotification);
    
    // Set some random defaults key to some random value, to test anonymizePreferencesForFeedbackReport:.
    [[NSUserDefaults standardUserDefaults] setObject:@"unicode test: 💩 مرحبا 你好 שלום"
                                              forKey:@"somePrivateKey"];

    // Log some text to be sure we can retrieve it later.
    NSLog(@"applicationDidFinishLaunching - add unicode text in console: 💩 مرحبا 你好 שלום");

    FRFeedbackReporter * sharedReporter = [FRFeedbackReporter sharedReporter];
    [sharedReporter setDelegate:self];

    NSLog(@"applicationDidFinishLaunching - checking for crash...");
    [sharedReporter reportIfCrash];
}

#pragma mark - FRFeedbackReporterDelegate

- (nullable NSDictionary *) customParametersForFeedbackReport
{
    NSDictionary *dict = @{@"user" : @"tcurdt",
                           @"license" : @"1234-1234-1234-1234"};

    return dict;
}

- (NSDictionary*)anonymizePreferencesForFeedbackReport:(NSDictionary*)preferences
{
	assert(preferences);
    
    NSMutableDictionary* newPreferences = [preferences mutableCopy];
    [newPreferences removeObjectForKey:@"somePrivateKey"];
    
    return newPreferences;
}

- (NSString *) feedbackDisplayName
{
   return @"Test App";
}

#if 0
- (NSURL *)targetURLForFeedbackReport
{
    NSString *targetUrlFormat = @"https://myserver.com/submit.php?project=%@&version=%@";
    NSString *project = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
    return [NSURL URLWithString:[NSString stringWithFormat:targetUrlFormat, project, version]];
}
#endif

#pragma mark -

- (IBAction) buttonFeedback:(id)sender
{
    NSLog(@"button - unicode: ❄☠️");
    [[FRFeedbackReporter sharedReporter] reportFeedback];
}

- (IBAction) buttonException:(id)sender
{
    NSLog(@"exception on main thread - unicode: ❄☠️");
    [NSException raise:@"TestException-MainThread" format:@"Something went wrong (☃💩 attack?)"];
}

- (void) threadWithException:(id)argument
{
    (void)argument;
    
    @autoreleasepool {
        NSLog(@"exception on NSThread - unicode: ❄☠️");
        [NSException raise:@"TestException-NSThread" format:@"Something went wrong (☃💩 attack?)"];
    }
}

- (IBAction) buttonExceptionInThread:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadWithException:) toTarget:self withObject:nil];
}

- (IBAction) buttonExceptionInDispatchQueue:(id)sender
{
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1);
    dispatch_after(popTime, queue, ^{
        @autoreleasepool {
            NSLog(@"exception on dispatch queue - unicode: ❄☠️");
            [NSException raise:@"TestException-DispatchQueue" format:@"Something went wrong (☃💩 attack?)"];
        }
    });
}

- (IBAction) buttonCrash:(id)sender
{
    NSLog(@"crash - unicode: ❄☠️");
    volatile char *c = 0;
    *c = 0;
}

@end
