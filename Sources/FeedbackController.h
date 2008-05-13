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

    BOOL showDetails;

    NSString *user;
}

- (id) initWithUser:(NSString*)user;

- (NSString*) applicationName;
- (NSString*) applicationVersion;

- (IBAction)showDetails:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

@end
