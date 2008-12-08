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

    NSDate* fileDate = [[fileManager fileAttributesAtPath:path traverseLink: YES] fileModificationDate];

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

    int i = [libraryDirectories count];
    while(i--) {
        NSString* libraryDirectory = [libraryDirectories objectAtIndex:i];


        /* Tiger */
        NSString* log1 = [NSString stringWithFormat: @"Logs/CrashReporter/%@.crash.log", [FRApplication applicationName]];
        log1 = [[libraryDirectory stringByAppendingPathComponent:log1] stringByExpandingTildeInPath];

        NSLog(@"Searching for crash files at %@", log1);

        if ([self file:log1 isNewerThan:date]) {
            [files addObject:log1];
        }
                
        /*  Leppard */        
        NSDirectoryEnumerator *enumerator;
        NSString *file;
        
        NSString* log2 = @"Logs/CrashReporter/";
        log2 = [[libraryDirectory stringByAppendingPathComponent:log2] stringByExpandingTildeInPath];

        NSLog(@"Searching for crash files at %@", log2);

        if ([fileManager fileExistsAtPath:log2]) {

            enumerator  = [fileManager enumeratorAtPath:log2];
            while ((file = [enumerator nextObject])) {

                if ([file hasSuffix:@".crash"] && [file hasPrefix:[FRApplication applicationName]]) {

                    file = [[log2 stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

                    if ([self file:file isNewerThan:date]) {
                        [files addObject:file];
                    }
                }
            }
        }


        NSString* log3 = [NSString stringWithFormat: @"Logs/HangReporter/%@/", [FRApplication applicationName]];
        log3 = [[libraryDirectory stringByAppendingPathComponent:log3] stringByExpandingTildeInPath];

        NSLog(@"Searching for hang files at %@", log3);

        if ([fileManager fileExistsAtPath:log3]) {

            enumerator  = [fileManager enumeratorAtPath:log3];
            while ((file = [enumerator nextObject])) {
            
                if ([file hasSuffix:@".hang"]) {

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
