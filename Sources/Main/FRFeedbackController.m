/*
 * Copyright 2008-2017, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FRFeedbackController.h"
#import "FRFeedbackReporter.h"
#import "FRUploader.h"
#import "FRCommand.h"
#import "FRApplication.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "FRConstants.h"
#import "FRConsoleLog.h"
#import "FRLocalizedString.h"

#import "NSMutableDictionary+Additions.h"

#import <AddressBook/AddressBook.h>
#import <SystemConfiguration/SystemConfiguration.h>

// Private interface.
@interface FRFeedbackController()
@property (readwrite, strong, nonatomic) IBOutlet NSArrayController *systemDiscovery;

@property (readwrite, weak, nonatomic) IBOutlet NSTextField *headingField;
@property (readwrite, weak, nonatomic) IBOutlet NSTextField *subheadingField;

@property (readwrite, weak, nonatomic) IBOutlet NSTextField *messageLabel;
#if (MAC_OS_X_VERSION_MIN_REQUIRED < 101200)
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *messageView;
#else
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *messageView;
#endif

@property (readwrite, weak, nonatomic) IBOutlet NSTextField *emailLabel;
@property (readwrite, weak, nonatomic) IBOutlet NSComboBox *emailBox;

@property (readwrite, weak, nonatomic) IBOutlet NSButton *detailsButton;
@property (readwrite, weak, nonatomic) IBOutlet NSTextField *detailsLabel;

@property (readwrite, weak, nonatomic) IBOutlet NSButton *sendDetailsCheckbox;

@property (readwrite, weak, nonatomic) IBOutlet NSTabView *tabView;

// Even though they are not top-level objects, keep strong references to the tabViews.
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabSystem;
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabConsole;
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabCrash;
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabScript;
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabPreferences;
@property (readwrite, strong, nonatomic) IBOutlet NSTabViewItem *tabException;

@property (readwrite, weak, nonatomic) IBOutlet NSTableView *systemView;
#if (MAC_OS_X_VERSION_MIN_REQUIRED < 101200)
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *consoleView;
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *crashesView;
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *scriptView;
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *preferencesView;
@property (readwrite, assign, nonatomic) IBOutlet NSTextView *exceptionView;
#else
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *consoleView;
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *crashesView;
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *scriptView;
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *preferencesView;
@property (readwrite, weak, nonatomic) IBOutlet NSTextView *exceptionView;
#endif

@property (readwrite, weak, nonatomic) IBOutlet NSProgressIndicator *indicator;

@property (readwrite, weak, nonatomic) IBOutlet NSButton *cancelButton;
@property (readwrite, weak, nonatomic) IBOutlet NSButton *sendButton;

@property (readwrite, nonatomic) BOOL detailsShown;
@property (readwrite, strong, nonatomic) FRUploader *uploader;
@property (readwrite, strong, nonatomic) NSString *type;
@end

@implementation FRFeedbackController

#pragma mark Construction

- (instancetype) init
{
    self = [super initWithWindowNibName:@"FeedbackReporter"];
    if (self != nil) {
        _detailsShown = YES;
    }
    return self;
}

#pragma mark Accessors

- (void) setHeading:(NSString*)message
{
    [[self headingField] setStringValue:message];
}

- (void) setSubheading:(NSString *)informativeText
{
    [[self subheadingField] setStringValue:informativeText];
}

- (void) setMessage:(NSString*)message
{
    [[self messageView] setString:message];
}

- (void) setException:(NSString*)exception
{
    [[self exceptionView] setString:exception];
}

#pragma mark information gathering

- (NSString*) consoleLog
{
    NSNumber *hours = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_LOGHOURS];

    int h = 24;

    if (hours != nil) {
        h = [hours intValue];
    }

    NSDate *since = [NSDate dateWithTimeIntervalSinceNow:-h * 60.0 * 60.0];

    NSNumber *maximumSize = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_MAXCONSOLELOGSIZE];

    return [FRConsoleLog logSince:since maxSize:maximumSize];
}


- (NSArray*) systemProfile
{
    static NSArray *systemProfile = nil;

    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{ systemProfile = [FRSystemProfile discover]; });

    return systemProfile;
}

- (NSString*) systemProfileAsString
{
    NSMutableString *string = [NSMutableString string];
    NSArray *dicts = [self systemProfile];
    NSUInteger i = [dicts count];
    while(i--) {
        NSDictionary *dict = [dicts objectAtIndex:i];
        [string appendFormat:@"%@ = %@\n", [dict objectForKey:@"key"], [dict objectForKey:@"value"]];
    }
    return string;
}

- (NSString*) crashLog
{
    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];

    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastSubmissionDate];

    NSUInteger i = [crashFiles count];

    if (i == 1) {
        if (lastSubmissionDate == nil) {
            NSLog(@"Found a crash file");
        } else {
            NSLog(@"Found a crash file earlier than latest submission on %@", lastSubmissionDate);
        }
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:[crashFiles lastObject] encoding: NSUTF8StringEncoding error:&error];
        if (result == nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }

    if (lastSubmissionDate == nil) {
        NSLog(@"Found %lu crash files", (unsigned long)i);
    } else {
        NSLog(@"Found %lu crash files earlier than latest submission on %@", (unsigned long)i, lastSubmissionDate);
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSDate *newest = nil;
    NSInteger newestIndex = -1;

    while(i--) {

        NSString *crashFile = [crashFiles objectAtIndex:i];
        NSError* error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:crashFile error:&error];
        if (!fileAttributes) {
            NSLog(@"Error while fetching file attributes: %@", [error localizedDescription]);
        }
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];

        NSLog(@"CrashLog: %@", crashFile);

        if ([fileModDate laterDate:newest] == fileModDate) {
            newest = fileModDate;
            newestIndex = i;
        }

    }

    if (newestIndex != -1) {
        NSString *newestCrashFile = [crashFiles objectAtIndex:newestIndex];

        NSLog(@"Picking CrashLog: %@", newestCrashFile);

        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:newestCrashFile encoding: NSUTF8StringEncoding error:&error];
        if (result == nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }

    return @"";
}

- (NSString*) scriptLog
{
    NSMutableString *scriptLog = [NSMutableString string];

    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {

        FRCommand *cmd = [[FRCommand alloc] initWithPath:scriptPath];
        [cmd setOutput:scriptLog];
        [cmd setError:scriptLog];
        int ret = [cmd execute];

        NSLog(@"Script exit code = %d", ret);

    } /* else {
        NSLog(@"No custom script to execute");
    }
    */

    return scriptLog;
}

- (NSString*) preferences
{
    NSMutableDictionary *preferences = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[FRApplication applicationIdentifier]] mutableCopy];

    if (preferences == nil) {
        return @"";
    }

    [preferences removeObjectForKey:DEFAULTS_KEY_SENDEREMAIL];

    id<FRFeedbackReporterDelegate> strongDelegate = [self delegate];
    if ([strongDelegate respondsToSelector:@selector(anonymizePreferencesForFeedbackReport:)]) {
        preferences = [strongDelegate anonymizePreferencesForFeedbackReport:preferences];
    }

    return [NSString stringWithFormat:@"%@", preferences];
}


#pragma mark UI Actions

- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    if ([self detailsShown] == show) {
        return;
    }

    NSSize fullSize = NSMakeSize(455, 302);

    NSRect windowFrame = [[self window] frame];

    if (show) {

        windowFrame.origin.y -= fullSize.height;
        windowFrame.size.height += fullSize.height;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: animate];

    } else {
        windowFrame.origin.y += fullSize.height;
        windowFrame.size.height -= fullSize.height;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: animate];

    }

    [self setDetailsShown:show];
}

- (IBAction) showDetails:(id)sender
{
    BOOL show = [[sender objectValue] boolValue];
    [self showDetails:show animate:YES];
}

- (IBAction) cancel:(id)sender
{
    (void)sender;

    [[self uploader] cancel];
    [self setUploader:nil];

    [self close];
}

- (IBAction) send:(id)sender
{
    (void)sender;

    if ([self uploader] != nil) {
        NSLog(@"Still uploading");
        return;
    }

    NSString *target = [[FRApplication feedbackURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;

    id<FRFeedbackReporterDelegate> strongDelegate = [self delegate];
    if ([strongDelegate respondsToSelector:@selector(targetUrlForFeedbackReport)]) {
        target = [strongDelegate targetUrlForFeedbackReport];
    }

    if (target == nil) {
        NSLog(@"You are missing the %@ key in your Info.plist!", PLIST_KEY_TARGETURL);
        return;
    }

    NSURL *url = [NSURL URLWithString:target];

    SCNetworkConnectionFlags reachabilityFlags = 0;

    NSString *host = [url host];
    const char *hostname = [host UTF8String];

    Boolean reachabilityResult = false;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, hostname);
    if (reachability) {
        reachabilityResult = SCNetworkReachabilityGetFlags(reachability, &reachabilityFlags);
        CFRelease(reachability);
    }

    BOOL reachable = reachabilityResult
        &&  (reachabilityFlags & kSCNetworkFlagsReachable)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionRequired)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionAutomatic)
        && !(reachabilityFlags & kSCNetworkFlagsInterventionRequired);

    if (!reachable) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:FRLocalizedString(@"Proceed Anyway", nil)];
        [alert addButtonWithTitle:FRLocalizedString(@"Cancel", nil)];
        [alert setMessageText:FRLocalizedString(@"Feedback Host Not Reachable", nil)];
        [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"You may not be able to send feedback because %@ isn't reachable.", nil), host]];
        NSInteger alertResult = [alert runModal];

        if (alertResult != NSAlertFirstButtonReturn) {
            return;
        }
    }

    FRUploader* uploader = [[FRUploader alloc] initWithTarget:target delegate:self];
    [self setUploader:uploader];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setValidString:[[self emailBox] stringValue]
                  forKey:POST_KEY_EMAIL];

    [dict setValidString:[[self messageView] string]
                  forKey:POST_KEY_MESSAGE];

    [dict setValidString:[self type]
                  forKey:POST_KEY_TYPE];

    [dict setValidString:[FRApplication applicationLongVersion]
                  forKey:POST_KEY_VERSION_LONG];

    [dict setValidString:[FRApplication applicationShortVersion]
                  forKey:POST_KEY_VERSION_SHORT];

    [dict setValidString:[FRApplication applicationBundleVersion]
                  forKey:POST_KEY_VERSION_BUNDLE];

    [dict setValidString:[FRApplication applicationVersion]
                  forKey:POST_KEY_VERSION];

    if ([[self sendDetailsCheckbox] state] == NSOnState) {
        if ([strongDelegate respondsToSelector:@selector(customParametersForFeedbackReport)]) {
            [dict addEntriesFromDictionary:[strongDelegate customParametersForFeedbackReport]];
        }

        [dict setValidString:[self systemProfileAsString]
                      forKey:POST_KEY_SYSTEM];

        [dict setValidString:[[self consoleView] string]
                      forKey:POST_KEY_CONSOLE];

        [dict setValidString:[[self crashesView] string]
                      forKey:POST_KEY_CRASHES];

        [dict setValidString:[[self scriptView] string]
                      forKey:POST_KEY_SHELL];

        [dict setValidString:[[self preferencesView] string]
                      forKey:POST_KEY_PREFERENCES];

        [dict setValidString:[[self exceptionView] string]
                      forKey:POST_KEY_EXCEPTION];
    }

    NSLog(@"Sending feedback to %@", target);

    [uploader postAndNotify:dict];
}

- (void) uploaderStarted:(FRUploader*)pUploader
{
    (void)pUploader;

    // NSLog(@"Upload started");

    [[self indicator] setHidden:NO];
    [[self indicator] startAnimation:self];

    [[self messageView] setEditable:NO];
    [[self sendButton] setEnabled:NO];
}

- (void) uploaderFailed:(FRUploader*)pUploader withError:(NSError*)error
{
    (void)pUploader;

    NSLog(@"Upload failed: %@", error);

    [[self indicator] stopAnimation:self];
    [[self indicator] setHidden:YES];

    [self setUploader:nil];

    [[self messageView] setEditable:YES];
    [[self sendButton] setEnabled:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:FRLocalizedString(@"OK", nil)];
    [alert setMessageText:FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
    [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), [error localizedDescription]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];

    [self close];
}

- (void) uploaderFinished:(FRUploader*)pUploader
{
    (void)pUploader;

    // NSLog(@"Upload finished");

    [[self indicator] stopAnimation:self];
    [[self indicator] setHidden:YES];

    NSString *response = [[self uploader] response];

    [self setUploader:nil];

    [[self messageView] setEditable:YES];
    [[self sendButton] setEnabled:YES];

    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    NSUInteger i = [lines count];
    while(i--) {
        NSString *line = [lines objectAtIndex:i];

        if ([line length] == 0) {
            continue;
        }

        if (![line hasPrefix:@"OK "]) {

            NSLog (@"Failed to submit to server: %@", response);

            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:FRLocalizedString(@"OK", nil)];
            [alert setMessageText:FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
            [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), line]];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];

            return;
        }
    }

    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date]
                                             forKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];

    [[NSUserDefaults standardUserDefaults] setObject:[[self emailBox] stringValue]
                                              forKey:DEFAULTS_KEY_SENDEREMAIL];

    [self close];
}

- (void) windowWillClose: (NSNotification *) n
{
    (void)n;

    [[self uploader] cancel];

    if ([[self type] isEqualToString:FR_EXCEPTION]) {
        NSString *exitAfterException = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_EXITAFTEREXCEPTION];
        if (exitAfterException && [exitAfterException isEqualToString:@"YES"]) {
            // We want a pure exit() here I think.
            // As an exception has already been raised there is no
            // guarantee that the code path to [NSAapp terminate] is functional.
            // Calling abort() will crash the app here but is that more desirable?
            exit(EXIT_FAILURE);
        }
    }
}

- (void) windowDidLoad
{
    [[self window] setDelegate:self];

    [[self window] setTitle:FRLocalizedString(@"Feedback", nil)];

    [[self emailLabel] setStringValue:FRLocalizedString(@"Email address:", nil)];
    [[self detailsLabel] setStringValue:FRLocalizedString(@"Details", nil)];

    [[self tabSystem] setLabel:FRLocalizedString(@"System", nil)];
    [[self tabConsole] setLabel:FRLocalizedString(@"Console", nil)];
    [[self tabCrash] setLabel:FRLocalizedString(@"CrashLog", nil)];
    [[self tabScript] setLabel:FRLocalizedString(@"Script", nil)];
    [[self tabPreferences] setLabel:FRLocalizedString(@"Preferences", nil)];
    [[self tabException] setLabel:FRLocalizedString(@"Exception", nil)];

    [[self sendButton] setTitle:FRLocalizedString(@"Send", nil)];
    [[self cancelButton] setTitle:FRLocalizedString(@"Cancel", nil)];

    [[[self consoleView] textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[[self consoleView] textContainer] setWidthTracksTextView:NO];
    [[self consoleView] setString:@""];

    [[[self crashesView] textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[[self crashesView] textContainer] setWidthTracksTextView:NO];
    [[self crashesView] setString:@""];

    [[[self scriptView] textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[[self scriptView] textContainer] setWidthTracksTextView:NO];
    [[self scriptView] setString:@""];

    [[[self preferencesView] textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[[self preferencesView] textContainer] setWidthTracksTextView:NO];
    [[self preferencesView] setString:@""];

    [[[self exceptionView] textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[[self exceptionView] textContainer] setWidthTracksTextView:NO];
    [[self exceptionView] setString:@""];
}

- (void) stopSpinner
{
    [[self indicator] stopAnimation:self];
    [[self indicator] setHidden:YES];
    [[self sendButton] setEnabled:YES];
}

- (void) addTabViewItem:(NSTabViewItem*)theTabViewItem
{
    [[self tabView] insertTabViewItem:theTabViewItem atIndex:1];
}

- (void) populate
{
    @autoreleasepool {
        
        NSString *consoleLog = [self consoleLog];
        if ([consoleLog length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:[self tabConsole] waitUntilDone:YES];
            [[self consoleView] performSelectorOnMainThread:@selector(setString:) withObject:consoleLog waitUntilDone:YES];
        }
        
        NSString *crashLog = [self crashLog];
        if ([crashLog length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:[self tabCrash] waitUntilDone:YES];
            [[self crashesView] performSelectorOnMainThread:@selector(setString:) withObject:crashLog waitUntilDone:YES];
        }
        
        NSString *scriptLog = [self scriptLog];
        if ([scriptLog length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:[self tabScript] waitUntilDone:YES];
            [[self scriptView] performSelectorOnMainThread:@selector(setString:) withObject:scriptLog waitUntilDone:YES];
        }
        
        NSString *preferences = [self preferences];
        if ([preferences length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:[self tabPreferences] waitUntilDone:YES];
            [[self preferencesView] performSelectorOnMainThread:@selector(setString:) withObject:preferences waitUntilDone:YES];
        }
        
        [self performSelectorOnMainThread:@selector(stopSpinner) withObject:self waitUntilDone:YES];
    }
}

- (void) reset
{
    [[self tabView] removeTabViewItem:[self tabConsole]];
    [[self tabView] removeTabViewItem:[self tabCrash]];
    [[self tabView] removeTabViewItem:[self tabScript]];
    [[self tabView] removeTabViewItem:[self tabPreferences]];
    [[self tabView] removeTabViewItem:[self tabException]];

    ABPerson *me = [[ABAddressBook sharedAddressBook] me];
    ABMutableMultiValue *emailAddresses = [me valueForProperty:kABEmailProperty];

    NSUInteger count = [emailAddresses count];

    [[self emailBox] removeAllItems];

    [[self emailBox] addItemWithObjectValue:FRLocalizedString(@"anonymous", nil)];

    for(NSUInteger i=0; i<count; i++) {

        NSString *emailAddress = [emailAddresses valueAtIndex:i];

        [[self emailBox] addItemWithObjectValue:emailAddress];
    }

    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_SENDEREMAIL];

    NSInteger found = [[self emailBox] indexOfItemWithObjectValue:email];
    if (found != NSNotFound) {
        [[self emailBox] selectItemAtIndex:found];
    } else if ([[self emailBox] numberOfItems] >= 2) {
        NSString *defaultSender = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTSENDER];
        NSUInteger idx = (defaultSender && [defaultSender isEqualToString:@"firstEmail"]) ? 1 : 0;
        [[self emailBox] selectItemAtIndex:idx];
    }

    [[self headingField] setStringValue:@""];
    [[self messageView] setString:@""];
    [[self exceptionView] setString:@""];

    [self showDetails:NO animate:NO];
    [[self detailsButton] setIntValue:NO];

    [[self indicator] setHidden:NO];
    [[self indicator] startAnimation:self];
    [[self sendButton] setEnabled:NO];

    //  setup 'send details' checkbox...
    [[self sendDetailsCheckbox] setTitle:FRLocalizedString(@"Send details", nil)];
    [[self sendDetailsCheckbox] setState:NSOnState];
    NSString *sendDetailsIsOptional = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_SENDDETAILSISOPTIONAL];
    if (sendDetailsIsOptional && [sendDetailsIsOptional isEqualToString:@"YES"]) {
        [[self detailsLabel] setHidden:YES];
        [[self sendDetailsCheckbox] setHidden:NO];
    } else {
        [[self detailsLabel] setHidden:NO];
        [[self sendDetailsCheckbox] setHidden:YES];
    }
}

- (void) showWindow:(id)sender
{
    if ([[self type] isEqualToString:FR_FEEDBACK]) {
        [[self messageLabel] setStringValue:FRLocalizedString(@"Feedback comment label", nil)];
    } else {
        [[self messageLabel] setStringValue:FRLocalizedString(@"Comments:", nil)];
    }

    if ([[[self exceptionView] string] length] != 0) {
        [[self tabView] insertTabViewItem:[self tabException] atIndex:1];
        [[self tabView] selectTabViewItemWithIdentifier:@"Exception"];
    } else {
        [[self tabView] selectTabViewItemWithIdentifier:@"System"];
    }

    [NSThread detachNewThreadSelector:@selector(populate) toTarget:self withObject:nil];

    [super showWindow:sender];
}

- (BOOL) isShown
{
    return [[self window] isVisible];
}

@end
