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

    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [dict setObject:osversion forKey:@"OS_VERSION"];
    NSLog(@"OS_VERSION=%@", osversion);

    NSString *ramsize = [NSString stringWithFormat:@"%d MB", [self ramsize]];
    [dict setObject:ramsize forKey:@"RAM_SIZE"];
    NSLog(@"RAM_SIZE=%@", ramsize);

    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [dict setObject:cputype forKey:@"CPU_TYPE"];
    NSLog(@"CPU_TYPE=%@", cputype);

    NSString *is64bit = [NSString stringWithFormat:@"%@", ([self is64bit])?@"YES":@"NO"];
    [dict setObject:cputype forKey:@"CPU_64BIT"];
    NSLog(@"CPU_64BIT=%@", is64bit);

    NSString *cpucount = [NSString stringWithFormat:@"%d", [self cpucount]];
    NSLog(@"CPU_COUNT=%@", cpucount);
    [dict setObject:cpucount forKey:@"CPU_COUNT"];
    
    NSString *cpuspeed = [NSString stringWithFormat:@"%d MHz", [self cpuspeed]];
    NSLog(@"CPU_SPEED=%@", cpuspeed);
    [dict setObject:cpuspeed forKey:@"CPU_SPEED"];

    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [dict setObject:machinemodel forKey:@"MACHINE_MODEL"];
    NSLog(@"MACHINE_MODEL=%@", machinemodel);

    NSString *language = [NSString stringWithFormat:@"%@", [self language]];
    [dict setObject:language forKey:@"LANGUAGE"];
    NSLog(@"LANGUAGE=%@", language);

    return dict;
}

- (BOOL) is64bit
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

- (NSString*) cputype
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

- (NSString*) osversion
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    return version;
}

- (NSString*) architecture
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

- (int) cpucount
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

- (NSString*) machinemodel
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

- (NSString*) language
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs objectForKey:@"AppleLanguages"];

    if (!languages || ([languages count]  == 0)) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

- (long) cpuspeed
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

- (long) ramsize
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
