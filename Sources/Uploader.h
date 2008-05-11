#import <Cocoa/Cocoa.h>


@interface Uploader : NSObject {
    NSString *target;
}

- (id) initWithTarget:(NSString*)target;
- (void) post:(NSDictionary*)dict;

@end
