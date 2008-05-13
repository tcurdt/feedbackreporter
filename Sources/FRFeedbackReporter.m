#import "FRFeedbackReporter.h"
#import "FeedbackController.h"

@implementation FRFeedbackReporter

+ (void) sendReportForUser:(NSString*)user
{
    FeedbackController *controller = [[FeedbackController alloc] initWithUser:user];

    [controller showWindow:self];
}

@end
