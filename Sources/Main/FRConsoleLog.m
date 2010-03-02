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


@implementation FRConsoleLog

+ (NSString*) logSince:(NSDate*)since maxSize:(NSNumber*)maxSize
{
    NSMutableString *console = [[NSMutableString alloc] init];

    aslmsg query = asl_new(ASL_TYPE_QUERY);

    if (query != NULL) {
		
		NSString* applicationName = [FRApplication applicationName];
		NSString* sinceString = [NSString stringWithFormat:@"%01f", [since timeIntervalSince1970]];
		
        asl_set_query(query, ASL_KEY_SENDER, [applicationName UTF8String], ASL_QUERY_OP_EQUAL);
        asl_set_query(query, ASL_KEY_TIME, [sinceString UTF8String], ASL_QUERY_OP_GREATER_EQUAL);
		
		// Prevent premature garbage collection (UTF8String returns an inner pointer).
		[applicationName self];
		[sinceString self];

		// This function is very slow. <rdar://problem/7695589>
        aslresponse response = asl_search(NULL, query);

        asl_free(query);

        if (response != NULL) {

            aslmsg msg = NULL;

            while (NULL != (msg = aslresponse_next(response))) {

                const char* time = asl_get(msg, ASL_KEY_TIME);
                
                if (time == NULL) {
                    continue;
                }
                
                const char* text = asl_get(msg, ASL_KEY_MSG);

                if (text == NULL) {
                    continue;
                }

                NSDate *date = [NSDate dateWithTimeIntervalSince1970:atof(time)];

                [console appendFormat:@"%@: %s\n", date, text];
                
                if (maxSize != nil && [console length] > [maxSize unsignedIntegerValue]) {
                    break;
                }
            }

            aslresponse_free(response);
        }

    }

    return [console autorelease];
}

@end
