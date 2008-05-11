#import "FeedbackReporter.h"
#import "FeedbackController.h"

@implementation FeedbackReporter

+ (void) sendReport
{
    FeedbackController *controller = [[FeedbackController alloc] initWithWindowNibName:@"FeedbackReporter"];

    [controller showWindow:self];
}

@end
