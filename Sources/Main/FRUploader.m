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

#import "FRUploader.h"

// Private interface.
@interface FRUploader()
@property (readwrite, weak, nonatomic) id<FRUploaderDelegate> delegate;
@property (readwrite, strong, nonatomic) NSString *target;
@property (readwrite, strong, nonatomic) NSURLConnection *connection;
@property (readwrite, strong, nonatomic) NSMutableData *responseData;
@end

@implementation FRUploader

// Cover the superclass' designated initialiser
- (instancetype)init NS_UNAVAILABLE
{
    assert(0);
    return nil;
}

- (instancetype) initWithTarget:(NSString*)pTarget delegate:(id<FRUploaderDelegate>)pDelegate
{
    assert(pTarget);
    assert(pDelegate);

    self = [super init];
    if (self != nil) {
        _target = pTarget;
        _delegate = pDelegate;
        _responseData = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (NSData *) generateFormData: (NSDictionary *)dict forBoundary:(NSString*)formBoundary
{
    assert(dict);
    assert(formBoundary);

    NSString *boundary = formBoundary;
    NSArray *keys = [dict allKeys];
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:100];
    
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = [dict valueForKey: [keys objectAtIndex: i]];
        
        [result appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        if ([value class] != [NSURL class]) {
            [result appendData:[[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([value class] == [NSURL class] && [value isFileURL]) {
            NSString *disposition = [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [keys objectAtIndex:i], [[value path] lastPathComponent]];
            [result appendData: [disposition dataUsingEncoding:NSUTF8StringEncoding]];
            
            [result appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[NSData dataWithContentsOfFile:[value path]]];
        }

        [result appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [result appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return result;
}


- (nullable NSString*) post:(NSDictionary*)dict
{
    assert(dict);

    NSString *formBoundary = [[NSProcessInfo processInfo] globallyUniqueString];

    NSData *formData = [self generateFormData:dict forBoundary:formBoundary];

    NSLog(@"Posting %lu bytes to %@", (unsigned long)[formData length], [self target]);

    NSMutableURLRequest *post = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self target]]];
    
    NSString *boundaryString = [NSString stringWithFormat: @"multipart/form-data; boundary=%@", formBoundary];
    [post addValue: boundaryString forHTTPHeaderField: @"Content-Type"];
    [post setHTTPMethod: @"POST"];
    [post setHTTPBody:formData];
    [post setCachePolicy:NSURLRequestReloadIgnoringCacheData];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest: post
                                           returningResponse: &response
                                                       error: &error];

    if (result == nil) {
        NSLog(@"Post failed. Error: %ld, Description: %@", (long)[error code], [error localizedDescription]);
        return nil;
    }

    return [[NSString alloc] initWithData:result
                                 encoding:NSUTF8StringEncoding];
}

- (void) postAndNotify:(NSDictionary*)dict
{
    assert(dict);

    NSString *formBoundary = [[NSProcessInfo processInfo] globallyUniqueString];

    NSData *formData = [self generateFormData:dict forBoundary:formBoundary];

    NSLog(@"Posting %lu bytes to %@", (unsigned long)[formData length], [self target]);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self target]]];
    
    NSString *boundaryString = [NSString stringWithFormat: @"multipart/form-data; boundary=%@", formBoundary];
    [request addValue: boundaryString forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:formData];

    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self setConnection:connection];

    id<FRUploaderDelegate> strongDelegate = [self delegate];
    if (connection != nil) {
        if ([strongDelegate respondsToSelector:@selector(uploaderStarted:)]) {
            [strongDelegate performSelector:@selector(uploaderStarted:) withObject:self];
        }
    } else {
        if ([strongDelegate respondsToSelector:@selector(uploaderFailed:withError:)]) {
            NSError *error = [NSError errorWithDomain:@"Failed to establish connection" code:0 userInfo:nil];
            [strongDelegate performSelector:@selector(uploaderFailed:withError:) withObject:self
                withObject:error];
        }
    }
}



- (void) connection: (NSURLConnection *)pConnection didReceiveData: (NSData *)data
{
    assert(pConnection); (void)pConnection;
    assert(data);

    NSLog(@"Connection received data");

    [[self responseData] appendData:data];
}

- (void) connection:(NSURLConnection *)pConnection didFailWithError:(NSError *)error
{
    assert(pConnection); (void)pConnection;
    assert(error);

    NSLog(@"Connection failed");
    
    id<FRUploaderDelegate> strongDelegate = [self delegate];
    if ([strongDelegate respondsToSelector:@selector(uploaderFailed:withError:)]) {

        [strongDelegate performSelector:@selector(uploaderFailed:withError:) withObject:self withObject:error];
    }
    
    [self setConnection:nil];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)pConnection
{
    assert(pConnection); (void)pConnection;

    // NSLog(@"Connection finished");

    id<FRUploaderDelegate> strongDelegate = [self delegate];
    if ([strongDelegate respondsToSelector: @selector(uploaderFinished:)]) {
        [strongDelegate performSelector:@selector(uploaderFinished:) withObject:self];
    }
    
    [self setConnection:nil];
}


- (void) cancel
{
    [[self connection] cancel];
    [self setConnection:nil];
}

- (nullable NSString*) response
{
    return [[NSString alloc] initWithData:[self responseData]
                                 encoding:NSUTF8StringEncoding];
}

@end
