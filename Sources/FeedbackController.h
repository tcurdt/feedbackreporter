#import <Cocoa/Cocoa.h>


@interface FeedbackController : NSWindowController {

    IBOutlet NSTextView *commentView;
    IBOutlet NSTextField *emailField;
    IBOutlet NSTextView *systemView;
    IBOutlet NSTextView *consoleView;
    IBOutlet NSTextView *crashesView;

    IBOutlet NSProgressIndicator *indicator;

    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *sendButton;

    BOOL showSystem;
    BOOL showConsole;
    BOOL showCrashes;

    NSString *user;
}

- (id) initWithUser:(NSString*)user;

- (IBAction)showSystem:(id)sender;
- (IBAction)showConsole:(id)sender;
- (IBAction)showCrashes:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

@end
