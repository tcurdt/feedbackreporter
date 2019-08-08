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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRCrashLogFinder : NSObject

// Searches the various /Library/Logs/DiagnosticReports/ folders for crash report files whose file name starts with the given base name (and then an underscore) and whose modification date is newer than the given date.  If no date is given, it behaves like giving a date in the distant past.  In all cases, files whose modification date cannot be determined are ignored.  Matches are gathered into an NSArray of NSURLs, sorted from oldest to newest.
+ (NSArray *) findCrashLogsSince:(nullable NSDate *)date
                    withBaseName:(NSString *)inBaseName;

@end

NS_ASSUME_NONNULL_END
