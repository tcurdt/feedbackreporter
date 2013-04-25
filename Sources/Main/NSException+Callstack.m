/*
 * Copyright 2008, Jens Alfke, Torsten Curdt
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

#import "NSException+Callstack.h"
#import "FRCommand.h"
#import "FRConstants.h"
#import <unistd.h>

@implementation NSException (Callstack)

- (NSArray*) my_callStackReturnAddresses
{
    // On 10.5 or later, can get the backtrace:
    if( [self respondsToSelector: @selector(callStackReturnAddresses)] ) {
        return [self valueForKey: @"callStackReturnAddresses"];
    } else {
        return nil;
    }
}

- (NSArray*) my_callStackReturnAddressesSkipping: (NSUInteger)skip limit: (NSUInteger)limit
{
    NSArray *addresses = [self my_callStackReturnAddresses];
    if( addresses ) {
        NSUInteger n = [addresses count];
        skip = MIN(skip,n);
        limit = MIN(limit,n-skip);
        addresses = [addresses subarrayWithRange: NSMakeRange(skip,limit)];
    }
    return addresses;
}

- (NSString*) my_callStack
{
	if ([self respondsToSelector:@selector(callStackSymbols)]) {
		NSArray *symbols = [(id)self callStackSymbols];
		return [NSString stringWithFormat:@"%@\n",symbols];
	}

    NSArray *addresses = [self my_callStackReturnAddressesSkipping: EXCEPTION_STACK_SKIP limit: EXCEPTION_STACK_LIMIT];

    if (!addresses) {
        return nil;
    }
    
    // We pipe the hex return addresses through the 'atos' tool to get symbolic names:
    // Adapted from <http://paste.lisp.org/display/47196>:

    NSMutableArray *args = [NSMutableArray arrayWithObjects:
            @"-p",
            [NSString stringWithFormat:@"%d", getpid()],
            nil];
            
    NSUInteger len = [addresses count];
    for(NSUInteger i = 0; i<len; i++) {
        NSValue *addr = [addresses objectAtIndex:i];
        [args addObject:[NSString stringWithFormat:@"%p", [addr pointerValue]]];
    }
    
    NSMutableString *output = [NSMutableString string];

    FRCommand *cmd = [[FRCommand alloc] initWithPath:@"/usr/bin/atos"];
    [cmd setArgs:args];
    [cmd setOutput:output];
    [cmd setError:output];

    // execute returns -1 if command does not exist

    if([cmd execute] != 0) {
        [cmd release];
        return nil;
    }
    [cmd release];
    
    NSMutableString *result = [NSMutableString string];

    NSArray *lines = [output componentsSeparatedByString: @"\n"];
    len = [lines count];
    for(NSUInteger i = 0; i<len; i++) {
        NSString *line = [lines objectAtIndex:i];
        
        // Skip  frames that are part of the exception/assertion handling itself:
        if( [line hasPrefix: @"-[NSAssertionHandler"] || [line hasPrefix: @"+[NSException"] 
                || [line hasPrefix: @"-[NSException"] || [line hasPrefix: @"_AssertFailed"] ) {
            continue;
        }

        if( [result length] ) {
            [result appendString: @"\n"];
        }

        [result appendString: line];

        // Don't show the "__start" frame below "main":
        if( [line hasPrefix: @"main "] ) {
            break;
        }
    }
    
    return result;
}

@end
