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

#import "FRConsoleLog.h"
#import "FRConstants.h"
#import "FRApplication.h"

#import <asl.h>
#import <unistd.h>

#define FR_CONSOLELOG_TIME 0
#define FR_CONSOLELOG_TEXT 1

@implementation FRConsoleLog

+ (NSString*) logSince:(NSDate*)since maxSize:(NSNumber*)maxSize
{
    NSUInteger consoleOutputLength = 0;
    NSInteger rawConsoleLinesCapacity = 100;
    NSInteger consoleLinesProcessed = 0;
    NSInteger i;

    char ***rawConsoleLines = (char ***)malloc(rawConsoleLinesCapacity * sizeof(char **));
    NSMutableString *consoleString = [[NSMutableString alloc] init];
    NSMutableArray *consoleLines = [[NSMutableArray alloc] init];

    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

    aslmsg query = asl_new(ASL_TYPE_QUERY);

    if (query != NULL) {

        NSString *applicationName = [FRApplication applicationName];
        NSString *sinceString = [NSString stringWithFormat:@"%01f", [since timeIntervalSince1970]];

        asl_set_query(query, ASL_KEY_SENDER, [applicationName UTF8String], ASL_QUERY_OP_EQUAL);
        asl_set_query(query, ASL_KEY_TIME, [sinceString UTF8String], ASL_QUERY_OP_GREATER_EQUAL);

        // Prevent premature garbage collection (UTF8String returns an inner pointer).
        [applicationName self];
        [sinceString self];

        // This function is very slow. <rdar://problem/7695589>
        aslresponse response = asl_search(NULL, query);

        asl_free(query);

        // Loop through the query response, grabbing the results into a local store for processing
        if (response != NULL) {

            aslmsg msg = NULL;

            while (NULL != (msg = aslresponse_next(response))) {

                const char *time = asl_get(msg, ASL_KEY_TIME);
                
                if (time == NULL) {
                    continue;
                }
                
                const char *text = asl_get(msg, ASL_KEY_MSG);

                if (text == NULL) {
                    continue;
                }

                // Ensure sufficient capacity to store this line in the local cache
                consoleLinesProcessed++;
                if (consoleLinesProcessed > rawConsoleLinesCapacity) {
                    rawConsoleLinesCapacity *= 2;
                    rawConsoleLines = (char ***)realloc(rawConsoleLines, rawConsoleLinesCapacity * sizeof(char **));
                }

                // Add a new entry for this console line
                char **rawLineContents = (char **)malloc(2 * sizeof(char *));

                rawLineContents[FR_CONSOLELOG_TIME] = (char *)malloc(strlen(time) + 1);
                strcpy(rawLineContents[FR_CONSOLELOG_TIME], time);

                rawLineContents[FR_CONSOLELOG_TEXT] = (char *)malloc(strlen(text) + 1);
                strcpy(rawLineContents[FR_CONSOLELOG_TEXT], text);

                rawConsoleLines[consoleLinesProcessed-1] = rawLineContents;
            }

            aslresponse_free(response);

            // Loop through the console lines in reverse order, converting to NSStrings
            if (consoleLinesProcessed) {
                for (i = consoleLinesProcessed - 1; i >= 0; i--) {
                    char **line = rawConsoleLines[i];
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:atof(line[FR_CONSOLELOG_TIME])];
                    [consoleLines addObject:[NSString stringWithFormat:@"%@: %s\n", [dateFormatter stringFromDate:date], line[FR_CONSOLELOG_TEXT]]];

                    // If a maximum size has been provided, respect it and abort if necessary
                    if (maxSize != nil) {
                        consoleOutputLength += [[consoleLines lastObject] length];
                        if (consoleOutputLength > [maxSize unsignedIntegerValue]) break;
                    }
                }
            }
        }
    }

    // Convert the console lines array to an output string
    if ([consoleLines count]) {
        for (i = [consoleLines count] - 1; i >= 0; i--) {
            [consoleString appendString:[consoleLines objectAtIndex:i]];
        }
    }

    // Free data stores
    [consoleLines release];
    for (i = 0; i < consoleLinesProcessed; i++) {
        free(rawConsoleLines[i][FR_CONSOLELOG_TEXT]);
        free(rawConsoleLines[i][FR_CONSOLELOG_TIME]);
        free(rawConsoleLines[i]);
    }
    free(rawConsoleLines);

    return [consoleString autorelease];
}

@end
