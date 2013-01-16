/*
 * Copyright 2008-2011, Torsten Curdt
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

- (id) initWithPath:(NSString*)inPath
{
    self = [super init];
    if (self != nil) {
        task = [[NSTask alloc] init];
        args = [[NSArray array] retain];
        path = [inPath retain];
        error = nil;
        output = nil;
        terminated = NO;
    }
    
    return self;
}

-(void)dealloc
{
    [task release];
    [args release];
    [path release];
    [error release];
    [output release];

    [super dealloc];
}



- (void) setArgs:(NSArray*)pArgs
{
    [pArgs retain];
    [args release];
    args = pArgs;
}

- (void) setError:(NSMutableString*)pError
{
    [pError retain];
    [error release];
    error = pError;
}

- (void) setOutput:(NSMutableString*)pOutput
{
    [pOutput retain];
    [output release];
    output = pOutput;
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

    [self appendDataFrom:fileHandle to:output];

    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    [self appendDataFrom:fileHandle to:output];

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated: (NSNotification *)notification
{
    // NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    terminated = YES;
}

- (int) execute
{
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
        // executable not found
        return -1;
    }

    [task setLaunchPath:path];
    [task setArguments:args];

    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];

    NSFileHandle *outFile = [outPipe fileHandleForReading];
    NSFileHandle *errFile = [errPipe fileHandleForReading]; 

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:outFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:errFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task];

    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

    [task launch];

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while(!terminated) {
        if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:100000]]) {
            break;
        }
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    [pool drain];

    [self appendDataFrom:outFile to:output];
    [self appendDataFrom:errFile to:error];

    int result = [task terminationStatus];

    return result;
}

@end
