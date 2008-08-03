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

+ (NSArray*) discover
{
	NSMutableArray *discoveryArray = [NSMutableArray array];
	NSArray *discoveryKeys = [NSArray arrayWithObjects:@"key", @"visibleKey", @"value", @"visibleValue", nil];

    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"OS_VERSION", @"OS Version", osversion, osversion, nil]
        forKeys:discoveryKeys]];

    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"MACHINE_MODEL", @"Machine Model", machinemodel, machinemodel, nil]
        forKeys:discoveryKeys]];

    NSString *ramsize = [NSString stringWithFormat:@"%d", [self ramsize]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"RAM_SIZE", @"Memory in (MB)", ramsize, ramsize, nil]
        forKeys:discoveryKeys]];

    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_TYPE", @"CPU Type", cputype, cputype, nil]
        forKeys:discoveryKeys]];

    NSString *cpuspeed = [NSString stringWithFormat:@"%d", [self cpuspeed]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_SPEED", @"CPU Speed (MHz)", cpuspeed, cpuspeed, nil]
        forKeys:discoveryKeys]];

    NSString *cpucount = [NSString stringWithFormat:@"%d", [self cpucount]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_COUNT", @"Number of CPUs", cpucount, cpucount, nil]
        forKeys:discoveryKeys]];

    NSString *is64bit = [NSString stringWithFormat:@"%@", ([self is64bit])?@"YES":@"NO"];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_64BIT", @"CPU is 64-Bit", is64bit, is64bit, nil]
        forKeys:discoveryKeys]];

    NSString *language = [NSString stringWithFormat:@"%@", [self language]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"LANGUAGE", @"Preferred Language", language, language, nil]
        forKeys:discoveryKeys]];

    return discoveryArray;
}

+ (BOOL) is64bit
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);

	error = sysctlbyname("hw.cpu64bit_capable", &value, &length, NULL, 0);
	
    if(error != 0) {
		error = sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0); //x86 specific
    }
	
    if(error != 0) {
		error = sysctlbyname("hw.optional.64bitops", &value, &length, NULL, 0); //PPC specific
    }
	
	BOOL is64bit = NO;
	
	if (error == 0) {
		is64bit = value == 1;
	}
    
    return is64bit;
 }

+ (NSString*) cputype
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.cpusubtype", &value, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU type");
        return nil;
    }

    switch (value) {
        case 4:
            if ([self is64bit]) {
                return @"Intel Core2 Duo";
            } else {
                return @"Intel Core";
            }
        case 9:
            return @"G3";
        case 10:
        case 11:
            return @"G4";
        case 100:
            return @"G5";
    }

    NSLog(@"Unknown CPU type %d", value);

    return nil;
}

+ (NSString*) osversion
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    return version;
}

+ (NSString*) architecture
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.cputype", &value, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU type");
        return nil;
    }
    
    switch (value) {
        case 7:
            return @"Intel";
        case 18:
            return @"PPC";
    }

    NSLog(@"Unknown CPU %d", value);

    return nil;
}

+ (int) cpucount
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.ncpu", &value, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU count");
        return 1;
    }
    
    return value;
}

+ (NSString*) machinemodel
{
    int error = 0;
    size_t length;
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU model");
        return nil;
    }

    char *p = malloc(sizeof(char) * length);
    error = sysctlbyname("hw.model", p, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain machine model");
        free(p);
        return nil;
    }

    NSString *machinemodel = [NSString stringWithFormat:@"%s", p];
    
    free(p);

    return machinemodel;
}

+ (NSString*) language
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs objectForKey:@"AppleLanguages"];

    if (!languages || ([languages count]  == 0)) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

+ (long) cpuspeed
{
    OSType error;
    long result;

    error = Gestalt(gestaltProcClkSpeed, &result);
    if (error) {
        NSLog(@"Failed to obtain CPU speed");
        return -1;
    }
    
    return result / 1000000;
}

+ (long) ramsize
{
    OSType error;
    long result;

    error = Gestalt(gestaltPhysicalRAMSizeInMegabytes, &result);
    if (error) {
        NSLog(@"Failed to obtain RAM size");
        return -1;
    }
    
    return result;
}


@end
