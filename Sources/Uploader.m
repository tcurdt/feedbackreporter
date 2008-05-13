#import "Uploader.h"


@implementation Uploader

- (id) initWithTarget:(NSString*)pTarget;
{
    self = [super init];
    if (self != nil) {
        target = pTarget;
    }
    
    return self;
}

- (NSData *)generateFormData: (NSDictionary *)dict forBoundary:(NSString*)formBoundary
{
	NSString* boundary = formBoundary;
	NSArray* keys = [dict allKeys];
	NSMutableData* result = [[NSMutableData alloc] initWithCapacity:100];
	
	int i;
	for (i = 0; i < [keys count]; i++) 
	{
		id value = [dict valueForKey: [keys objectAtIndex: i]];
		
		[result appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

		if ([value class] != [NSURL class]) {
			[result appendData:[[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
			[result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		else if ([value class] == [NSURL class] && [value isFileURL]) {
			NSString *disposition = [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [keys objectAtIndex:i], [[value path] lastPathComponent]];
			[result appendData: [disposition dataUsingEncoding:NSUTF8StringEncoding]];
			
			[result appendData:[[NSString stringWithString: @"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
			[result appendData:[NSData dataWithContentsOfFile:[value path]]];
		}
		[result appendData:[[NSString stringWithString:@"\r\n"]
       dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return [result autorelease];
}

- (NSString*) post:(NSDictionary*)dict
{
    NSString *formBoundary = [[NSProcessInfo processInfo] globallyUniqueString];

	NSData *formData = [self generateFormData:dict forBoundary:formBoundary];

    NSLog(@"posting %d bytes to %@", [formData length], target);

	NSMutableURLRequest* post = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:target]];
	
	NSString *boundaryString = [NSString stringWithFormat: @"multipart/form-data; boundary=%@", formBoundary];
	[post addValue: boundaryString forHTTPHeaderField: @"Content-Type"];
	[post setHTTPMethod: @"POST"];
	[post setHTTPBody:formData];

	NSURLResponse *response;
	NSError *error;
	NSData *result = [NSURLConnection sendSynchronousRequest: post
										   returningResponse: &response
													   error: &error];

	if(error != nil) {
		NSLog(@"Error: %d, Description: %@", [error code], [error localizedDescription]);
	}

    return [[[NSString alloc] initWithData:result
                                  encoding:NSUTF8StringEncoding] autorelease];
}



@end
