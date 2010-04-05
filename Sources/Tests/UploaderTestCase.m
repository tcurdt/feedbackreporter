/*
 * Copyright 2008-2010, Torsten Curdt
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

#import "UploaderTestCase.h"
#import "FRUploader.h"

@implementation UploaderTestCase

BOOL terminated;

- (void) testUpload
{
    NSLog(@"Uploading");

    FRUploader *uploader = [[FRUploader alloc] initWithTarget:@"http://vafer.org/feedback.php?project=TestCase" delegate:self];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"test" forKey:@"test"];

    [uploader postAndNotify:dict];

    terminated = NO;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while(!terminated) {
        if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:100000]]) {
            break;
        }
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    [pool drain];

    [dict release];
    
    NSLog(@"done");
}

- (void) uploaderStarted:(FRUploader*)uploader
{
    NSLog(@"Upload started");
}

- (void) uploaderFailed:(FRUploader*)uploader withError:(NSError*)error
{
    NSLog(@"Upload failed: %@", error);

    [uploader release];

    terminated = YES;
}

- (void) uploaderFinished:(FRUploader*)uploader
{
    NSLog(@"Upload finished");

    NSString *response = [uploader response];
    
    NSLog(@"response = %@", response);

    [uploader release];

    terminated = YES;
}



@end
