#import "FRFeedbackReporter.h"
#import "FeedbackController.h"
#import "CrashLogFinder.h"

static NSString *KEY_LASTCRASHCHECKDATE = @"FRFeedbackReporter.lastCrashCheckDate";

@implementation FRFeedbackReporter

+ (void) reportAsUser:(NSString*)user
{
    FeedbackController *controller = [[FeedbackController alloc] initWithUser:user];

    [controller showWindow:self];
}

+ (void) reportCrashAsUser:(NSString*)user
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTCRASHCHECKDATE];
    
    if (lastCrashCheckDate != nil) {
        NSArray *crashFiles = [CrashLogFinder findCrashLogsBefore:lastCrashCheckDate];
        
        if ([crashFiles count] > 0) {
            NSLog(@"found new crash files");

            NSString *comment = NSLocalizedString(@"The application crashed after I...", nil);

            FeedbackController *controller = [[FeedbackController alloc] initWithUser:user comment:comment];

            [controller showWindow:self];

        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTCRASHCHECKDATE];

}

@end
