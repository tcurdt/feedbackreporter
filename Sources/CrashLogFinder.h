#import <Cocoa/Cocoa.h>


@interface CrashLogFinder : NSObject {

}

+ (NSArray*) findCrashLogsBefore:(NSDate*)date;

@end
