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

#import "FRCommand.h"

// Private interface.
@interface FRCommand()
@property (readwrite, strong, nonatomic) NSTask *task;
@property (readwrite, copy, nonatomic) NSURL *fileURL;
@property (readwrite, copy, nonatomic) NSArray *args;
@property (readwrite, strong, nonatomic) NSMutableString *output;
@property (readwrite, strong, nonatomic) NSMutableString *error;
@property (readwrite, nonatomic) BOOL terminated;
@end


@implementation FRCommand

// Cover the superclass' designated initialiser
- (instancetype)init NS_UNAVAILABLE
{
    assert(0);
    return nil;
}

- (instancetype) initWithFileURL:(NSURL*)inFileURL args:(NSArray *)inArgs
{
    assert(inFileURL);
    assert(inArgs);

    self = [super init];
    if (self != nil) {
        _task = [[NSTask alloc] init];
        _args = [inArgs copy];
        _fileURL = [inFileURL copy];
        _error = nil;
        _output = nil;
        _terminated = NO;
    }
    
    return self;
}

-(void) appendDataFrom:(NSFileHandle*)fileHandle to:(NSMutableString*)string
{
    assert(fileHandle);
    assert(string);

    NSData *data = [fileHandle availableData];

    if ([data length] > 0) {

        // Initially try to read the file in using UTF8
        NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        if (s) {
            [string appendString:s];
            //NSLog(@"| %@", s);
        }
    }

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) outData: (NSNotification *) notification
{
    assert(notification);

    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:[self output]];

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    assert(notification);

    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:[self output]];

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated: (NSNotification *)notification
{
    assert(notification);

    (void)notification;

    // NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self setTerminated:YES];
}

- (int) execute
{
    NSString *path = [[self fileURL] path];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
        // executable not found, or not executable
        return -1;
    }

    NSTask* task = [self task];
    [task setLaunchPath:path];
    [task setArguments:[self args]];

    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];

    NSFileHandle *outFile = [outPipe fileHandleForReading];
    NSFileHandle *errFile = [errPipe fileHandleForReading];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(outData:)
                   name:NSFileHandleDataAvailableNotification
                 object:outFile];

    [center addObserver:self
               selector:@selector(errData:)
                   name:NSFileHandleDataAvailableNotification
                 object:errFile];

    [center addObserver:self
               selector:@selector(terminated:)
                   name:NSTaskDidTerminateNotification
                 object:task];

    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

    [task launch];

    while (![self terminated]) {
        @autoreleasepool {
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
                break;
            }
        }
    }

    [self appendDataFrom:outFile to:[self output]];
    [self appendDataFrom:errFile to:[self error]];

    int result = [task terminationStatus];

    return result;
}

@end
