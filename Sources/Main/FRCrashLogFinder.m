/*
 * Copyright 2008-2011, Torsten Curdt
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

#import "FRCrashLogFinder.h"
#import "FRApplication.h"

@implementation FRCrashLogFinder

+ (BOOL)file:(NSString*)path isNewerThan:(NSDate*)date
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:path]) {
        return NO;
    }

    if (!date) {
        return YES;
    }

    NSError* error = nil;
    NSDate* fileDate = [[fileManager attributesOfItemAtPath:path error:&error] fileModificationDate];
    if (!fileDate) {
        NSLog(@"Error while fetching file attributes: %@", [error localizedDescription]);
    }

    if ([date compare:fileDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

+ (NSArray*) findCrashLogsSince:(NSDate*)date
{
    NSMutableArray *files = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask|NSUserDomainMask, FALSE);

    NSUInteger i = [libraryDirectories count];
    while(i--) {
        NSString* libraryDirectory = [libraryDirectories objectAtIndex:i];

        NSDirectoryEnumerator *enumerator = nil;
        NSString *file = nil;
        
        NSString* logDir = @"Logs/CrashReporter/";
        logDir = [[libraryDirectory stringByAppendingPathComponent:logDir] stringByExpandingTildeInPath];

        // NSLog(@"Searching for crash files at %@", logDir2);

        // 10.8 Mountain Lion no longer appears to create the Logs/CrashReporter directory
        NSString *logDir2 = @"Logs/DiagnosticReports/";
        logDir2 = [[libraryDirectory stringByAppendingPathComponent:logDir2] stringByExpandingTildeInPath];
        
        NSArray *crashDirs = [NSArray arrayWithObjects:logDir, logDir2, nil];

        for (NSString *crashDir in crashDirs) {
            if ([fileManager fileExistsAtPath:crashDir]) {

                enumerator  = [fileManager enumeratorAtPath:crashDir];
                while ((file = [enumerator nextObject])) {

                    // NSLog(@"Checking crash file %@", file);
                    
                    NSString* expectedPrefix = [[FRApplication applicationName] stringByAppendingString:@"_"];
                    if ([[file pathExtension] isEqualToString:@"crash"] && [[file stringByDeletingPathExtension] hasPrefix:expectedPrefix]) {

                        file = [[crashDir stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

                        if ([self file:file isNewerThan:date]) {

                            // NSLog(@"Found crash file %@", file);

                            [files addObject:file];
                        }
                    }
                }
            }
        }

        NSString* logDir3 = [NSString stringWithFormat: @"Logs/HangReporter/%@/", [FRApplication applicationName]];
        logDir3 = [[libraryDirectory stringByAppendingPathComponent:logDir3] stringByExpandingTildeInPath];

        // NSLog(@"Searching for hang files at %@", logDir3);

        if ([fileManager fileExistsAtPath:logDir3]) {

            enumerator  = [fileManager enumeratorAtPath:logDir3];
            while ((file = [enumerator nextObject])) {
            
                if ([[file pathExtension] isEqualToString:@"hang"]) {

                    file = [[libraryDirectory stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

                    if ([self file:file isNewerThan:date]) {
                        [files addObject:file];
                    }
                }
            }
        }
    }
    
    return files;
}

@end
