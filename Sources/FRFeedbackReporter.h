#import <Cocoa/Cocoa.h>


@interface FRFeedbackReporter : NSObject
{
}

+ (void) sendReportForUser:(NSString*)user;

@end
