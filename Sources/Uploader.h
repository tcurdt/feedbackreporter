#import <Cocoa/Cocoa.h>


@interface Uploader : NSObject {
    NSString *target;
}

- (id) initWithTarget:(NSString*)target;
- (NSString*) post:(NSDictionary*)dict;

@end
