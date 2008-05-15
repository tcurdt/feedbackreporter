#import <Cocoa/Cocoa.h>


@interface FRFeedbackReporter : NSObject
{
}

+ (void) reportAsUser:(NSString*)user;
+ (void) reportCrashAsUser:(NSString*)user;

@end
