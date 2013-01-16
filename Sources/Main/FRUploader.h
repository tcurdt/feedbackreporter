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

#import <Cocoa/Cocoa.h>

@protocol FRUploaderDelegate;

@interface FRUploader : NSObject {

@private
    NSString *target;
    id<FRUploaderDelegate> delegate;

    NSURLConnection *connection;
    NSMutableData *responseData;
}

- (id) initWithTarget:(NSString*)target delegate:(id<FRUploaderDelegate>)delegate;
- (NSString*) post:(NSDictionary*)dict;
- (void) postAndNotify:(NSDictionary*)dict;
- (void) cancel;
- (NSString*) response;

@end


@protocol FRUploaderDelegate <NSObject>

@optional
- (void) uploaderStarted:(FRUploader*)uploader;
- (void) uploaderFailed:(FRUploader*)uploader withError:(NSError*)error;
- (void) uploaderFinished:(FRUploader*)uploader;

@end
