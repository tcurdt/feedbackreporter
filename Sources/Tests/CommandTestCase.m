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

#import <XCTest/XCTest.h>
#import "FRCommand.h"

@interface CommandTestCase : XCTestCase {}
@end

@implementation CommandTestCase

- (void) testSimple
{
    FRCommand *cmd = [[FRCommand alloc] initWithPath:@"/bin/ls"];
    
    NSMutableString *err = [[NSMutableString alloc] init];
    NSMutableString *output = [[NSMutableString alloc] init];
    
    [cmd setOutput:output];
    [cmd setError:err];
    
    int result = [cmd execute];

    XCTAssertTrue(result == 0, @"Return code was %d", result);
    XCTAssertTrue([output length] > 0, @"Found no output on stdout");
    XCTAssertTrue([err length] == 0, @"Found output on stderr");
}

@end
