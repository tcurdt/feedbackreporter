#import "CrashLogFinder.h"
#import "Application.h"

@implementation CrashLogFinder

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

+ (NSArray*) findCrashLogsBefore:(NSDate*)date
{

    NSMutableArray *files = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask|NSUserDomainMask, FALSE);

    int i = [libraryDirectories count];
    while(i--) {
        NSString* libraryDirectory = [libraryDirectories objectAtIndex:i];


/* Tiger:
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@.crash.log", [Application applicationName]],
*/
        NSString* log1 = [NSString stringWithFormat: @"Logs/CrashReporter/%@.crash.log", [Application applicationName]];
        log1 = [[libraryDirectory stringByAppendingPathComponent:log1] stringByExpandingTildeInPath];

        if ([self file:log1 isNewerThan:date]) {
            [files addObject:log1];
        }
                
/*  Leppard:
    .Fossi_shodan_CrashHistory.plist
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@_2008-05-09-012401_shodan.crash", [self applicationName]],
    [NSString stringWithFormat: @"/Library/Logs/HangReporter/%@/2008-04-24-132937-Mail.hang", [self applicationName]],
*/
        
        NSDirectoryEnumerator *enumerator;
        NSString *file;
        
        NSString* log2 = [NSString stringWithFormat: @"Logs/CrashReporter/", [Application applicationName]];
        log2 = [[libraryDirectory stringByAppendingPathComponent:log2] stringByExpandingTildeInPath];

        NSLog(@"searching for crash files at %@", log2);

        if ([fileManager fileExistsAtPath:log2]) {

            enumerator  = [fileManager enumeratorAtPath:log2];
            while ((file = [enumerator nextObject])) {
            
                file = [[libraryDirectory stringByAppendingPathComponent:file] stringByExpandingTildeInPath];
            
                if ([file hasSuffix:@".crash"]) {
                    if ([self file:file isNewerThan:date]) {
                        [files addObject:file];
                    }
                }
            }
        }


        NSString* log3 = [NSString stringWithFormat: @"Logs/HangReporter/%@/", [Application applicationName]];
        log3 = [[libraryDirectory stringByAppendingPathComponent:log3] stringByExpandingTildeInPath];

        NSLog(@"searching for hang files at %@", log3);

        if ([fileManager fileExistsAtPath:log3]) {

            enumerator  = [fileManager enumeratorAtPath:log3];
            while ((file = [enumerator nextObject])) {

                file = [[libraryDirectory stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

                if ([file hasSuffix:@".hang"]) {
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
