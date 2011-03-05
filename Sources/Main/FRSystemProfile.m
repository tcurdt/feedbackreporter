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

#import "FRSystemProfile.h"
#import <sys/sysctl.h>

@implementation FRSystemProfile

+ (NSArray*) discover
{
    NSMutableArray *discoveryArray = [[[NSMutableArray alloc] init] autorelease];
    NSArray *discoveryKeys = [NSArray arrayWithObjects:@"key", @"visibleKey", @"value", @"visibleValue", nil];

    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"OS_VERSION", @"OS Version", osversion, osversion, nil]
        forKeys:discoveryKeys]];

    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"MACHINE_MODEL", @"Machine Model", machinemodel, machinemodel, nil]
        forKeys:discoveryKeys]];

    NSString *ramsize = [NSString stringWithFormat:@"%ld", [self ramsize]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"RAM_SIZE", @"Memory in (MB)", ramsize, ramsize, nil]
        forKeys:discoveryKeys]];

    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_TYPE", @"CPU Type", cputype, cputype, nil]
        forKeys:discoveryKeys]];

    NSString *cpuspeed = [NSString stringWithFormat:@"%ld", [self cpuspeed]];
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
    
    int cputype = -1;
    size_t length = sizeof(cputype);
    error = sysctlbyname("hw.cputype", &cputype, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU type");
        return nil;
    }
    
    // Intel
    if (cputype == CPU_TYPE_X86) {
        char stringValue[256] = {0};
        size_t stringLength = sizeof(stringValue);
        error = sysctlbyname("machdep.cpu.brand_string", &stringValue, &stringLength, NULL, 0);
        if ((error == 0) && (stringValue != NULL)) {
            NSString *brandString = [NSString stringWithUTF8String:stringValue];
            if (brandString)
                return brandString;
        }
    }
    
    int cpufamily = -1;
    length = sizeof(cpufamily);
    error = sysctlbyname("hw.cpufamily", &cpufamily, &length, NULL, 0);
        
    if (error == 0) {
        // 10.5+
        switch (cpufamily) {
            case CPUFAMILY_POWERPC_G3:
                return @"PowerPC G3";
            case CPUFAMILY_POWERPC_G4:
                return @"PowerPC G4";
            case CPUFAMILY_POWERPC_G5:
                return @"PowerPC G5";
            case CPUFAMILY_INTEL_CORE:
                return @"Intel Core Duo";
            case CPUFAMILY_INTEL_CORE2:
                return @"Intel Core 2 Duo";
            case CPUFAMILY_INTEL_PENRYN:
                return @"Intel Core 2 Duo (Penryn)";
            case CPUFAMILY_INTEL_NEHALEM:
                return @"Intel Xeon (Nehalem)";
        }
        return nil;
    }


    int cpusubtype = -1;
    length = sizeof(cpusubtype);
    error = sysctlbyname("hw.cpusubtype", &cpusubtype, &length, NULL, 0);

    if (error != 0) {
        NSLog(@"Failed to obtain CPU subtype");
        return nil;
    }

    switch (cputype) {
        case CPU_TYPE_X86:
            return @"Intel";
        case CPU_TYPE_POWERPC:
            switch (cpusubtype) {
                case CPU_SUBTYPE_POWERPC_750:
                    return @"PowerPC G3";
                case CPU_SUBTYPE_POWERPC_7400:
                case CPU_SUBTYPE_POWERPC_7450:
                    return @"PowerPC G4";
                case CPU_SUBTYPE_POWERPC_970:
                    return @"PowerPC G5";
            }
            break;
    }

    NSLog(@"Unknown CPU type %d, CPU subtype %d", cputype, cpusubtype);

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
    size_t length = 0;
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU model");
        return nil;
    }

    char *p = malloc(sizeof(char) * length);
    if (p) {
		error = sysctlbyname("hw.model", p, &length, NULL, 0);
    }
	
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

    if ([languages count] == 0) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

+ (long) cpuspeed
{
    SInt32 result = 0;

    OSErr error = Gestalt(gestaltProcClkSpeedMHz, &result);
    if (error) {
        NSLog(@"Failed to obtain CPU speed");
        return -1;
    }
    
    return result;
}

+ (long) ramsize
{
    SInt32 result = 0;

    OSErr error = Gestalt(gestaltPhysicalRAMSizeInMegabytes, &result);
    if (error) {
        NSLog(@"Failed to obtain RAM size");
        return -1;
    }
    
    return result;
}


@end
