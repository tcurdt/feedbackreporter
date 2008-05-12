#import <Cocoa/Cocoa.h>


@interface FeedbackController : NSWindowController {

    IBOutlet NSTextView *commentView;
    IBOutlet NSTextView *systemView;
    IBOutlet NSTextView *consoleView;
    IBOutlet NSTextView *crashesView;

    IBOutlet NSProgressIndicator *indicator;

    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *sendButton;

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
