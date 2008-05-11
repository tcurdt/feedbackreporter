#import <Cocoa/Cocoa.h>


@interface FeedbackController : NSWindowController {

    IBOutlet NSTextField *commentField;
    IBOutlet NSTextField *systemField;
    IBOutlet NSTextField *consoleField;
    IBOutlet NSTextField *crashesField;

    BOOL showSystem;
    BOOL showConsole;
    BOOL showCrashes;
}

- (IBAction)showSystem:(id)sender;
- (IBAction)showConsole:(id)sender;
- (IBAction)showCrashes:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

@end
