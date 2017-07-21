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
@property (readwrite, strong, nonatomic) NSString *path;
@property (readwrite, strong, nonatomic) NSArray *args;
@property (readwrite, strong, nonatomic) NSMutableString *output;
@property (readwrite, strong, nonatomic) NSMutableString *error;
@property (readwrite, nonatomic) BOOL terminated;
@end


@implementation FRCommand

- (instancetype) initWithPath:(NSString*)inPath
{
    self = [super init];
    if (self != nil) {
        _task = [[NSTask alloc] init];
        _args = [@[] retain];
        _path = [inPath retain];
        _error = nil;
        _output = nil;
        _terminated = NO;
    }
    
    return self;
}

-(void)dealloc
{
    [_task release];
    [_args release];
    [_path release];
    [_error release];
    [_output release];

    [super dealloc];
}


-(void) appendDataFrom:(NSFileHandle*)fileHandle to:(NSMutableString*)string
{
    NSData *data = [fileHandle availableData];

    if ([data length] > 0) {

        // Initially try to read the file in using UTF8
        NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        // If that fails, attempt plain ASCII
        if (!s) {
            s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        }

        if (s) {
            [string appendString:s];
            //NSLog(@"| %@", s);

            [s release];
        }
    }

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) outData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:[self output]];

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:[self output]];

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated: (NSNotification *)notification
{
    (void)notification;

    // NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self setTerminated:YES];
}

- (int) execute
{
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:[self path]]) {
        // executable not found
        return -1;
    }

    NSTask* task = [self task];
    [task setLaunchPath:[self path]];
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

    while(![self terminated]) {
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
