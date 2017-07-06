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


@implementation FRCommand

- (instancetype) initWithPath:(NSString*)inPath
{
    self = [super init];
    if (self != nil) {
        _task = [[NSTask alloc] init];
        _args = [[NSArray array] retain];
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



- (void) setArgs:(NSArray*)pArgs
{
    [pArgs retain];
    [_args release];
    _args = pArgs;
}

- (void) setError:(NSMutableString*)pError
{
    [pError retain];
    [_error release];
    _error = pError;
}

- (void) setOutput:(NSMutableString*)pOutput
{
    [pOutput retain];
    [_output release];
    _output = pOutput;
}


-(void) appendDataFrom:(NSFileHandle*)fileHandle to:(NSMutableString*)string
{
    NSData *data = [fileHandle availableData];

    if ([data length]) {

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

    [self appendDataFrom:fileHandle to:_output];

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:_output];

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated: (NSNotification *)notification
{
    (void)notification;

    // NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _terminated = YES;
}

- (int) execute
{
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:_path]) {
        // executable not found
        return -1;
    }

    [_task setLaunchPath:_path];
    [_task setArguments:_args];

    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    [_task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [_task setStandardOutput:outPipe];
    [_task setStandardError:errPipe];

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
                 object:_task];

    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

    [_task launch];

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while(!_terminated) {
        if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:100000]]) {
            break;
        }
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    [pool drain];

    [self appendDataFrom:outFile to:_output];
    [self appendDataFrom:errFile to:_error];

    int result = [_task terminationStatus];

    return result;
}

@end
