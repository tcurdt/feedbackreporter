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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FRUploaderDelegate;

@interface FRUploader : NSObject

- (instancetype) initWithTargetURL:(NSURL*)targetURL delegate:(id<FRUploaderDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (nullable NSString*) post:(NSDictionary*)dict;
- (void) postAndNotify:(NSDictionary*)dict;
- (void) cancel;
- (nullable NSString*) response;

@end


@protocol FRUploaderDelegate <NSObject>

@optional
- (void) uploaderStarted:(FRUploader*)uploader;
- (void) uploaderFailed:(FRUploader*)uploader withError:(NSError*)error;
- (void) uploaderFinished:(FRUploader*)uploader;

@end

NS_ASSUME_NONNULL_END
