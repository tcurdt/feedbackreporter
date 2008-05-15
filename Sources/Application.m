#import "Application.h"


@implementation Application

+ (NSString*) applicationVersion
{
    NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleLongVersionString"];

    if (!applicationVersion) {
        applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"];
    }

    return applicationVersion;
}

+ (NSString*) applicationName
{
    NSString *applicationName = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleExecutable"];

    if (!applicationName) {
        applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    }

    return applicationName;
}

+ (NSString*) applicationIdentifier
{
    NSString *applicationIdentifier = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleIdentifier"];

    return applicationIdentifier;
}

@end
