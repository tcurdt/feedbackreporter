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

#import "ConsoleLog.h"
#import "Constants.h"
#import "Application.h"

#import <asl.h>
#import <unistd.h>


@implementation ConsoleLog

+ (NSString*) logSince:(NSDate*)since;
{
    NSMutableString *console = [[[NSMutableString alloc] init] autorelease];

/* Leopard: */

    aslmsg query = asl_new(ASL_TYPE_QUERY);

    asl_set_query(query, ASL_KEY_SENDER, [[Application applicationName] UTF8String], ASL_QUERY_OP_EQUAL);
    asl_set_query(query, ASL_KEY_TIME, [[NSString stringWithFormat:@"%01f", [since timeIntervalSince1970]] UTF8String], ASL_QUERY_OP_GREATER_EQUAL);

    aslresponse response = asl_search(NULL, query);

    asl_free(query);

    aslmsg msg;
    while ((msg = aslresponse_next(response))) {

        const char* time = asl_get(msg, ASL_KEY_TIME);

        NSDate *date = [NSDate dateWithTimeIntervalSince1970:atof(time)];

        [console appendFormat:@"%@: %s\n", date, asl_get(msg, ASL_KEY_MSG)];
    }

    aslresponse_free(response);

/*  Tiger: */

    NSString *logPath = [NSString stringWithFormat: @"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt:getuid()]];

    // TODO read and filter line by line
    NSString *log = [NSString stringWithContentsOfFile:logPath];

    NSString *filter = [NSString stringWithFormat: @"%@[", [Application applicationName]];


    NSEnumerator *lineEnum = [[log componentsSeparatedByString: @"\n"] objectEnumerator];

    NSString* currentObject;

    while (currentObject = [lineEnum nextObject]) {

        if ([currentObject rangeOfString:filter].location != NSNotFound) {        
            [console appendFormat:@"%@\n", currentObject];
        }  
    }

    if ([console length] != 0) {
        [console appendString:@"..."];
    }

    return console;
}

@end
