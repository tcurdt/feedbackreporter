/*
 * Copyright 2008-2012, Torsten Curdt
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
#import <FeedbackReporter/FRFeedbackReporter.h>

@interface AppController : NSObject <FRFeedbackReporterDelegate> {
@private
	IBOutlet NSWindow* window; // strong reference, needed for GC
}

- (IBAction) buttonFeedback:(id)sender;
- (IBAction) buttonException:(id)sender;
- (IBAction) buttonExceptionInThread:(id)sender;
- (IBAction) buttonExceptionInDispatchQueue:(id)sender;
- (IBAction) buttonCrash:(id)sender;

@end
