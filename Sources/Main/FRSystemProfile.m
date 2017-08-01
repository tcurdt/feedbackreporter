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

#import "FRSystemProfile.h"
#import <sys/sysctl.h>

@implementation FRSystemProfile

+ (NSArray*) discover
{
    NSMutableArray *discoveryArray = [[NSMutableArray alloc] init];
    NSArray *discoveryKeys = @[@"key", @"visibleKey", @"value", @"visibleValue"];
    
    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"OS_VERSION", @"OS Version", osversion, osversion]
                                                          forKeys:discoveryKeys]];
    
    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"MACHINE_MODEL", @"Machine Model", machinemodel, machinemodel]
                                                          forKeys:discoveryKeys]];
    
    NSString *ramsize = [NSString stringWithFormat:@"%lld", [self ramsize]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"RAM_SIZE", @"Memory in (MB)", ramsize, ramsize]
                                                          forKeys:discoveryKeys]];
    
    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_TYPE", @"CPU Type", cputype, cputype]
                                                          forKeys:discoveryKeys]];
    
    NSString *cpuspeed = [NSString stringWithFormat:@"%lld", [self cpuspeed]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_SPEED", @"CPU Speed (MHz)", cpuspeed, cpuspeed]
                                                          forKeys:discoveryKeys]];
    
    NSString *cpucount = [NSString stringWithFormat:@"%d", [self cpucount]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_COUNT", @"Number of CPUs", cpucount, cpucount]
                                                          forKeys:discoveryKeys]];
    
    NSString *is64bit = [NSString stringWithFormat:@"%@", ([self is64bit])?@"YES":@"NO"];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"CPU_64BIT", @"CPU is 64-Bit", is64bit, is64bit]
                                                          forKeys:discoveryKeys]];
    
    NSString *language = [NSString stringWithFormat:@"%@", [self language]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:@[@"LANGUAGE", @"Preferred Language", language, language]
                                                          forKeys:discoveryKeys]];
    
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

+ (nullable NSString*) cputype
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


+ (NSString*) osversion
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    return version;
}

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

+ (nullable NSString*) machinemodel
{
    int error = 0;
    size_t length = 0;
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain machine model");
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

    NSString *machinemodel = [NSString stringWithUTF8String:p];
    
    free(p);

    return machinemodel;
}

+ (nullable NSString*) language
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs stringArrayForKey:@"AppleLanguages"];

    if ([languages count] == 0) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

+ (long long) cpuspeed
{
    long long result = 0;

    int error = 0;

    int64_t hertz = 0;
    size_t size = sizeof(hertz);
    int mib[2] = {CTL_HW, HW_CPU_FREQ};
    
    error = sysctl(mib, 2, &hertz, &size, NULL, 0);
    
    if (error) {
        NSLog(@"Failed to obtain CPU speed");
        return -1;
    }
    
    result = (long long)(hertz/1000000); // Convert to MHz
    
    return result;
}

+ (long long) ramsize
{
    long long result = 0;

    int error = 0;
    int64_t value = 0;
    size_t length = sizeof(value);
    
    error = sysctlbyname("hw.memsize", &value, &length, NULL, 0);
    if (error) {
        NSLog(@"Failed to obtain RAM size");
        return -1;
    }
    const int64_t kBytesPerMebibyte = 1024*1024;
    result = (long long)(value/kBytesPerMebibyte);
    
    return result;
}

@end
