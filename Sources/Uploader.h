#import <Cocoa/Cocoa.h>


@interface Uploader : NSObject {
    NSString *target;
}

- (id) initWithURL:(NSString*)target;
- (void) post:(NSDictionary*)dict;

@end
