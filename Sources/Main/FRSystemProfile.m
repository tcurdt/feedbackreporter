/*
 * Copyright 2008-2019, Torsten Curdt
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

+ (NSArray *) discover
{
    NSMutableArray *discoveryArray = [[NSMutableArray alloc] init];
    NSArray *discoveryKeys = @[@"key", @"visibleKey", @"value", @"visibleValue"];
    
    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"OS_VERSION", @"macOS Version", osversion, osversion]
                                                          forKeys:discoveryKeys]];
    
    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"MACHINE_MODEL", @"Mac Model", machinemodel, machinemodel]
                                                          forKeys:discoveryKeys]];
    
    NSString *ramsize = [NSString stringWithFormat:@"%llu", [self ramsize]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"RAM_SIZE", @"Memory (MiB)", ramsize, ramsize]
                                                          forKeys:discoveryKeys]];
    
    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_TYPE", @"CPU Type", cputype, cputype]
                                                          forKeys:discoveryKeys]];
    
    NSString *cpuspeed = [NSString stringWithFormat:@"%lld", [self cpuspeed]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_SPEED", @"CPU Speed (MHz)", cpuspeed, cpuspeed]
                                                          forKeys:discoveryKeys]];
    
    NSString *cpucount = [NSString stringWithFormat:@"%zu", [self processorCount]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_COUNT", @"Number of CPUs", cpucount, cpucount]
                                                          forKeys:discoveryKeys]];
    
    NSString *activecpucount = [NSString stringWithFormat:@"%zu", [self activeProcessorCount]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"ACTIVE_CPU_COUNT", @"Number of Active CPUs", activecpucount, activecpucount]
                                                          forKeys:discoveryKeys]];
    
    NSString *is64bit = [NSString stringWithFormat:@"%@", ([self is64bit]) ? @"YES" : @"NO"];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_64BIT", @"CPU is 64-Bit", is64bit, is64bit]
                                                          forKeys:discoveryKeys]];
    
    NSString *language = [NSString stringWithFormat:@"%@", [self language]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"LANGUAGE", @"Preferred Language", language, language]
                                                          forKeys:discoveryKeys]];
    
    NSString *hostname = [NSString stringWithFormat:@"%@", [self hostName]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"HOST_NAME", @"Host Name", hostname, hostname]
                                                          forKeys:discoveryKeys]];
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 101003)
    if (NSAppKitVersionNumber >= 1347 /* NSAppKitVersionNumber10_10_3 */)
    {
        NSString *thermalState = [NSString stringWithFormat:@"%@", [self thermalState]];
        [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"THERMAL_STATE", @"Thermal State", thermalState, thermalState]
                                                              forKeys:discoveryKeys]];
    }
#endif
    
    return discoveryArray;
}

+ (BOOL) is64bit
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);

    error = sysctlbyname("hw.cpu64bit_capable", &value, &length, NULL, 0);

    if (error != 0) {
        NSLog(@"Failed to determine if CPU supports 64 bit");
        return NO;
    }
    
    BOOL is64bit = (value == 1);

    return is64bit;
}

+ (nullable NSString *) cputype
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
        if (error == 0) {
            NSString *brandString = [NSString stringWithUTF8String:stringValue];
            if (brandString) {
                return brandString;
            }
        }
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
        case CPU_TYPE_ARM64:
            return @"ARM64";
    }

    NSLog(@"Unknown CPU type %d, CPU subtype %d", cputype, cpusubtype);

    return nil;
}


+ (NSString *) osversion
{
    NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
    
    NSString *prefix = @"Version ";
    if ([version hasPrefix:prefix]) {
        version = [version substringFromIndex:[prefix length]];
    }

    return version;
}

// TODO: not actually used, but might be useful one day.
+ (nullable NSString*) architecture
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
        case CPU_TYPE_X86:
            return @"Intel";
        case CPU_TYPE_ARM64:
            return @"ARM64";
    }

    NSLog(@"Unknown CPU %d", value);

    return nil;
}

+ (NSUInteger) processorCount
{
    NSUInteger count = [[NSProcessInfo processInfo] processorCount];
    
    return count;
}

+ (NSUInteger) activeProcessorCount
{
    NSUInteger count = [[NSProcessInfo processInfo] activeProcessorCount];
    
    return count;
}

+ (NSString *) hostName
{
    NSString *hostName = [[NSProcessInfo processInfo] hostName];
    
    return hostName;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 101003)
+ (nullable NSString *) thermalState
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    switch (thermalState) {
        case NSProcessInfoThermalStateNominal:
            return @"Nominal";
            break;
        case NSProcessInfoThermalStateFair:
            return @"Fair";
            break;
        case NSProcessInfoThermalStateSerious:
            return @"Serious";
            break;
        case NSProcessInfoThermalStateCritical:
            return @"Critical";
            break;
    }
    
    return nil;
}
#endif

+ (nullable NSString *) machinemodel
{
    int error = 0;
    size_t length = 0;
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain machine model");
        return nil;
    }

    char *p = malloc(sizeof(char) * length);
    if (!p) {
        return nil;
    }
    
    error = sysctlbyname("hw.model", p, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain machine model");
        free(p);
        return nil;
    }

    NSString *machinemodel = [NSString stringWithUTF8String:p];
    
    free(p);

    return machinemodel;
}

+ (nullable NSString *) language
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs stringArrayForKey:@"AppleLanguages"];

    if ([languages count] == 0) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages firstObject];
}

+ (long long) cpuspeed
{
    int error = 0;

    int64_t hertz = 0;
    size_t length = sizeof(hertz);
    
    error = sysctlbyname("hw.cpufrequency", &hertz, &length, NULL, 0);
    
    if (error) {
        NSLog(@"Failed to obtain CPU speed");
        return -1;
    }
    
    long long result = (long long)(hertz / 1000000); // Hz to MHz
    
    return result;
}

+ (unsigned long long) ramsize
{
    unsigned long long ram = [[NSProcessInfo processInfo] physicalMemory];
    ram /= (1024 * 1024); // bytes to mebibytes
	
    return ram;
}

@end
