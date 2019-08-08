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

#include <unistd.h>
#include <pwd.h>

#import "FRCrashLogFinder.h"
#import "FRApplication.h"

@implementation FRCrashLogFinder

+ (nullable NSURL *)fileURLForLibrarySubdirectory:(NSString *)pathComponent
                                         inDomain:(NSSearchPathDomainMask)domain
{
    assert(pathComponent);
    assert(domain != NSAllDomainsMask);
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [fileManager URLForDirectory:NSLibraryDirectory
                                     inDomain:domain
                            appropriateForURL:nil
                                       create:NO
                                        error:&error];
    if (url) {
        url = [url URLByAppendingPathComponent:pathComponent isDirectory:YES];
    }
    
    return url;
}

+ (NSArray *)enumerateDirectory:(NSURL *)directory
             forFilesWithPrefix:(NSString *)desiredPrefix
                      extension:(NSString *)desiredExtension
                    isNewerThan:(nullable NSDate *)testDate
{
    assert(directory);
    assert(desiredPrefix);
    assert(desiredExtension);
    
    NSMutableArray *matchingFiles = [NSMutableArray array];
    
    BOOL success = NO;
    NSError *error = nil;
    
    NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                             NSDirectoryEnumerationSkipsPackageDescendants |
                                             NSDirectoryEnumerationSkipsHiddenFiles);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directory
                                          includingPropertiesForKeys:@[NSURLContentModificationDateKey]
                                                             options:options
                                                        errorHandler:nil];
    
    for (NSURL *fileURL in enumerator)
    {
        // Does the filename have the given prefix and extension?
        NSString *fileName = [fileURL lastPathComponent];
        NSString *extension = [fileURL pathExtension];
        if ([fileName hasPrefix:desiredPrefix] &&
            [extension isEqualToString:desiredExtension])
        {
            // Is the modification date newer than the given date? (If no given date, accept the file.)
            NSDate *fileDate = nil;
            success = [fileURL getResourceValue:&fileDate
                                         forKey:NSURLContentModificationDateKey
                                          error:&error];
            if (success && fileDate)
            {
                if (!testDate || ([testDate compare:fileDate] == NSOrderedAscending))
                {
                    // Is it a regular file?
                    NSNumber *isRegularFile = nil;
                    success = [fileURL getResourceValue:&isRegularFile
                                                 forKey:NSURLIsRegularFileKey
                                                  error:&error];
                    if (success && [isRegularFile boolValue])
                    {
                        NSDictionary *item = @{@"date" : fileDate,
                                               @"fileURL" : fileURL};
                        [matchingFiles addObject:item];
                    }
                }
            }
        }
    }
    
    return matchingFiles;
}

+ (NSArray*)findCrashLogsSince:(nullable NSDate *)date
                  withBaseName:(NSString *)inBaseName
{
    assert(inBaseName);
    
    // Create URLs to 3 folders we'll check for crash log files.
    NSString *diagnosticReports = @"Logs/DiagnosticReports";
    NSURL *logDir1 = [self fileURLForLibrarySubdirectory:diagnosticReports inDomain:NSLocalDomainMask];
    NSURL *logDir2 = [self fileURLForLibrarySubdirectory:diagnosticReports inDomain:NSUserDomainMask];
    NSURL *logDir3 = nil;
    const struct passwd *passwd = getpwuid(getuid());
    if (passwd) {
        const char *realHome = passwd->pw_dir;
        if (realHome) {
            logDir3 = [NSURL fileURLWithPathComponents:@[@(realHome), @"Library", diagnosticReports]];
        }
    }
    
    // Without App Sandbox, logDir3 will usually be the same as logDir2, in which case don't search it twice.
    if (logDir2 && logDir3 && [logDir2 isEqual:logDir3]) {
        logDir3 = nil;
    }
    
    // We expect an underscore between the given prefix and the date.
    NSString *expectedPrefix = [inBaseName stringByAppendingString:@"_"];
    
    // Search all 3 folders for crash logs newer than the (optional) date and gather the results in an array.
    NSMutableArray *allResults = [NSMutableArray array];
    if (logDir1) {
        NSArray *results1 = [self enumerateDirectory:logDir1
                                  forFilesWithPrefix:expectedPrefix
                                           extension:@"crash"
                                         isNewerThan:date];
        [allResults addObjectsFromArray:results1];
    }
    if (logDir2) {
        NSArray *results2 = [self enumerateDirectory:logDir2
                                  forFilesWithPrefix:expectedPrefix
                                           extension:@"crash"
                                         isNewerThan:date];
        [allResults addObjectsFromArray:results2];
    }
    if (logDir3) {
        NSArray *results3 = [self enumerateDirectory:logDir3
                                  forFilesWithPrefix:expectedPrefix
                                           extension:@"crash"
                                         isNewerThan:date];
        [allResults addObjectsFromArray:results3];
    }
    
    // Sort from oldest to newest.
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [allResults sortUsingDescriptors:@[sd]];
    
    // Make a new array containing only the file URLs.
    NSMutableArray *fileURLs = [NSMutableArray arrayWithCapacity:[allResults count]];
    for (NSDictionary *item in allResults) {
        [fileURLs addObject:[item objectForKey:@"fileURL"]];
    }
    
    return fileURLs;
}

@end
