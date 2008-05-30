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
#import <sys/sysctl.h>

@implementation SystemDiscovery

- (NSDictionary*) discover
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];

    OSType error;
    long result;

    NSProcessInfo *info = [NSProcessInfo processInfo];

    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    [dict setObject:version forKey:@"OS_VERSION"];
    NSLog(@"OS_VERSION=%@", version);
    
    error = Gestalt(gestaltPhysicalRAMSizeInMegabytes, &result);
    if (!error) {
        [dict setObject:[NSString stringWithFormat:@"%d", result] forKey:@"RAM"];
        NSLog(@"RAM=%d", result);
    } else {
        NSLog(@"Failed to detect RAM. Error %d", error);
    }
    
    error = Gestalt(gestaltNativeCPUtype, &result);
    if (!error) {
    
        NSString *p = nil;
        
        switch(result) {
            case gestaltCPU601:        p = @"PowerPC 601"; break;
            case gestaltCPU603:        p = @"PowerPC 603"; break;
            case gestaltCPU603e:       p = @"PowerPC 603e"; break;
            case gestaltCPU603ev:      p = @"PowerPC 603ev"; break;
            case gestaltCPU604:        p = @"PowerPC 604"; break;
            case gestaltCPU604e:       p = @"PowerPC 604e"; break;
            case gestaltCPU604ev:      p = @"PowerPC 604ev"; break;
            case gestaltCPU750:        p = @"G3"; break;
            case 275:
            case gestaltCPUG4:         p = @"G4"; break;
            case gestaltCPU970:        p = @"G5 (970)"; break;
            case gestaltCPU970FX:      p = @"G5 (970 FX)"; break;
            case gestaltCPU486 :       p = @"Intel 486"; break;
            case gestaltCPUPentium:    p = @"Intel Pentium"; break;
            case gestaltCPUPentiumPro: p = @"Intel Pentium Pro"; break;
            case gestaltCPUPentiumII:  p = @"Intel Pentium II"; break;
            case gestaltCPUX86:        p = @"Intel x86"; break;
            case gestaltCPUPentium4:   p = @"Intel Pentium 4"; break;
            default: p = @"???"; break;
        }

        if (p != nil) {
            NSString *s = [NSString stringWithFormat:@"%@ (%d)", p, result];
            [dict setObject:s forKey:@"CPU_TYPE"];
            NSLog(@"CPU_TYPE=%@", s);
        } else {
            NSLog(@"Unknown cpu type %d", result);
        }
        
    } else {
        NSLog(@"Failed to detect cpu type. Error %d", error);
    }

    int     count;
    size_t  size = sizeof(count);

    if (sysctlbyname("hw.ncpu", &count, &size, NULL, 0)) {
        count = 1;
    }
    
    NSLog(@"CPU_COUNT=%d", count);
    [dict setObject:[NSNumber numberWithInt:count] forKey:@"CPU_COUNT"];
    
    error = Gestalt(gestaltProcClkSpeed, &result);
    if (!error) {
        NSString *s = [NSString stringWithFormat:@"%d MHz", (result/1000000)];
        [dict setObject:s forKey:@"CPU_SPEED"];
        NSLog(@"CPU_SPEED=%@", s);
    } else {
        NSLog(@"Error detecting cpu speed. Error %d", error);
    }

    return dict;
}

@end
