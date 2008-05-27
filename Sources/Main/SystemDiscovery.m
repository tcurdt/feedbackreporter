/*
 * Copyright 2008, Torsten Curdt
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

#import "SystemDiscovery.h"


@implementation SystemDiscovery

- (NSDictionary*) discover
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];

    OSType error;
    long result;

    NSProcessInfo *info = [NSProcessInfo processInfo];

    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:7];
    }

    [dict setObject:version forKey:@"OS_VERSION"];
    
    error = Gestalt(gestaltPhysicalRAMSizeInMegabytes, &result);
    if (!error) {
        [dict setObject:[NSString stringWithFormat:@"%d", result] forKey:@"RAM"];
    } else {
        NSLog(@"Failed to detect RAM. Error %d", error);
    }
    
    error = Gestalt(gestaltNativeCPUtype, &result);
    if (!error) {
    
        char type[5] = { 0 };
        long swappedResult = EndianU32_BtoN(result);

        NSLog(@"result=%d, swappedResult=%d", result, swappedResult); 

        memmove(type, &swappedResult, 4);

        NSString *s = nil;
        
        switch(result) {
            case gestaltCPU601:        s = @"PowerPC 601"; break;
            case gestaltCPU603:        s = @"PowerPC 603"; break;
            case gestaltCPU603e:       s = @"PowerPC 603e"; break;
            case gestaltCPU603ev:      s = @"PowerPC 603ev"; break;
            case gestaltCPU604:        s = @"PowerPC 604"; break;
            case gestaltCPU604e:       s = @"PowerPC 604e"; break;
            case gestaltCPU604ev:      s = @"PowerPC 604ev"; break;
            case gestaltCPU750:        s = @"G3"; break;
            case gestaltCPUG4:         s = @"G4"; break;
            case gestaltCPU970:        s = @"G5 (970)"; break;
            case gestaltCPU970FX:      s = @"G5 (970 FX)"; break;
            case gestaltCPU486 :       s = @"Intel 486"; break;
            case gestaltCPUPentium:    s = @"Intel Pentium"; break;
            case gestaltCPUPentiumPro: s = @"Intel Pentium Pro"; break;
            case gestaltCPUPentiumII:  s = @"Intel Pentium II"; break;
            case gestaltCPUX86:        s = @"Intel x86"; break;
            case gestaltCPUPentium4:   s = @"Intel Pentium 4"; break;
        }

        if (s != nil) {
            [dict setObject:[NSString stringWithFormat:@"%@ (%s, %d)", s, type, result] forKey:@"CPU_TYPE"];
        } else {
            NSLog(@"Unknown cpu type %d", result);
        }
        
    } else {
        NSLog(@"Failed to detect cpu type. Error %d", error);
    }
    
    error = Gestalt(gestaltProcClkSpeed, &result);
    if (!error) {
        [dict setObject:[NSString stringWithFormat:@"%d MHz", (result/1000000)] forKey:@"CPU_SPEED"];
    } else {
        NSLog(@"Error detecting cpu speed. Error %d", error);
    }

    return dict;
}

@end
