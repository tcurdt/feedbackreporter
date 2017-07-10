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

#import "FRApplication.h"
#import "FRConstants.h"

@implementation FRApplication

+ (nullable NSString*) applicationBundleVersion
{
	// CFBundleVersion is documented as not localizable.
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"];
    
    return bundleVersion;
}

+ (nullable NSString*) applicationShortVersion
{
    // CFBundleShortVersionString is documented as localizable, so prefer a localized value if available.
    NSString *shortVersion = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleShortVersionString"];
    
    if (!shortVersion) {
        shortVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleShortVersionString"];
    }
    
    return shortVersion;
}

+ (nullable NSString*) applicationVersion
{
    NSString *applicationVersion = [[self class] applicationShortVersion];
    
    if (applicationVersion != nil) {
        return applicationVersion;
    }

    return [[self class] applicationBundleVersion];
}


+ (nullable NSString*) applicationName
{
    // CFBundleExecutable is not localizable.
   NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    
    return applicationName;
}

+ (nullable NSString*) applicationIdentifier
{
    // CFBundleIdentifier is not localizable.
    NSString *applicationIdentifier = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleIdentifier"];

    return applicationIdentifier;
}

+ (nullable NSString*) feedbackURL
{
    NSString *target = [[[NSBundle mainBundle] infoDictionary] valueForKey: PLIST_KEY_TARGETURL];

    if (target == nil) {
        return nil;
    }

    target = [target stringByReplacingOccurrencesOfString:@"%@" withString:[FRApplication applicationName]];

    return target;
}


@end
