/*
 * Copyright 2008, Torsten Curdt
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

#import "FeedbackController.h"
#import "FRFeedbackReporter.h"
#import "Uploader.h"
#import "Command.h"
#import "Application.h"
#import "CrashLogFinder.h"
#import "SystemProfile.h"
#import "Constants.h"
#import "ConsoleLog.h"

@implementation FeedbackController

#pragma mark Construction

- (id) init
{
    self = [super initWithWindowNibName:@"FeedbackReporter"];
    if (self != nil) {
        detailsShown = YES;
    }
    return self;
}

#pragma mark Destruction

- (void) dealloc
{
    [tabConsole release];
    [tabCrash release];
    [tabScript release];
    [tabPreferences release];
    [tabException release];
    
    [super dealloc];
}


#pragma mark Accessors

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id) pDelegate
{
	delegate = pDelegate;
}

- (void) setMessage:(NSString*)message
{
    [messageField setStringValue:message];
}

- (void) setComment:(NSString*)comment
{
    [commentView setString:comment];
}

- (void) setException:(NSString*)exception
{
    [exceptionView setString:exception];
}


#pragma mark information gathering

- (NSString*) consoleLog
{
    // TODO make configurable
    NSDate* since = [[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];

    return [ConsoleLog logSince:since];
}


static NSArray *systemProfile = nil;
- (NSArray*) systemProfile
{
    if (systemProfile == nil) {
        systemProfile = [SystemProfile discover];
    }
    return systemProfile;
}

- (NSString*) systemProfileAsString
{
    NSMutableString *string = [NSMutableString string];
    NSArray *dicts = [self systemProfile];
    int i = [dicts count];
    while(i--) {
        NSDictionary *dict = [dicts objectAtIndex:i];
        [string appendFormat:@"%@ = %@\n", [dict objectForKey:@"key"], [dict objectForKey:@"value"]];
    }
    return string;
}

- (NSString*) crashLog
{

    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTSUBMISSIONDATE];

    NSArray *crashFiles = [CrashLogFinder findCrashLogsSince:lastSubmissionDate];

    int i = [crashFiles count];

    NSLog(@"Found %d crash files earlier than latest submission on %@", i, lastSubmissionDate);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSDate *newest = nil;
    int newestIndex = -1;

    while(i--) {
    
        NSString *crashFile = [crashFiles objectAtIndex:i];
        NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:crashFile traverseLink:YES];
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        
        if ([fileModDate earlierDate:newest] == fileModDate) {
            newest = fileModDate;
            newestIndex = i;
        }

    }
    
    if (newestIndex != -1) {
        return [NSString stringWithContentsOfFile:[crashFiles objectAtIndex:newestIndex]];
    }

    return @"";
}

- (NSString*) scriptLog
{
    NSMutableString *log = [NSMutableString string];

    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {

        Command *cmd = [[Command alloc] initWithPath:scriptPath];
        [cmd setOutput:log];
        [cmd setError:log];
        int ret = [cmd execute];
        [cmd release];

        NSLog(@"Script returned code = %d", ret);
        
    } else {
        NSLog(@"No custom script to execute");
    }

    return log;
}

- (NSString*) preferences
{
    NSDictionary *preferences = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[Application applicationIdentifier]];
    
    if (preferences == nil) {
        return @"";
    }
    
    return [NSString stringWithFormat:@"%@", preferences];
}


#pragma mark UI Actions

- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    if (detailsShown == show) {
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
    
    detailsShown = show;    
}

- (IBAction)showDetails:(id)sender
{
    [self showDetails:[sender intValue] animate:YES];
}

- (IBAction)cancel:(id)sender
{
    [uploader cancel];
    
    [self close];
}

- (IBAction)send:(id)sender
{
    if (uploader != nil) {
        NSLog(@"Still uploading");
        return;
    }
            
    NSString *target = [Application feedbackURL];
    
    if (target == nil) {
        NSLog(@"You are missing the %@ key in your Info.plist!", KEY_TARGETURL);
        return;        
    }

    uploader = [[Uploader alloc] initWithTarget:[Application feedbackURL] delegate:self];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];

	if ([delegate respondsToSelector:@selector(customParametersForFeedbackReport)]) {
        [dict addEntriesFromDictionary:[delegate customParametersForFeedbackReport]];
    }

    [dict setObject:[emailField stringValue]
             forKey:POST_KEY_EMAIL];

    [dict setObject:[Application applicationVersion]
             forKey:POST_KEY_VERSION];

    [dict setObject:[commentView string]
             forKey:POST_KEY_COMMENT];

    [dict setObject:[self systemProfileAsString]
             forKey:POST_KEY_SYSTEM];

    [dict setObject:[consoleView string]
             forKey:POST_KEY_CONSOLE];

    [dict setObject:[crashesView string]
             forKey:POST_KEY_CRASHES];

    [dict setObject:[scriptView string]
             forKey:POST_KEY_SHELL];

    [dict setObject:[preferencesView string]
             forKey:POST_KEY_PREFERENCES];

    [dict setObject:[exceptionView string]
             forKey:POST_KEY_EXCEPTION];
    
    NSLog(@"Sending feedback to %@", target);
    
    [uploader postAndNotify:dict];

    [dict release];
}

- (void) uploaderStarted:(Uploader*)pUploader
{
    NSLog(@"Upload started");

    [indicator setHidden:NO];
    [indicator startAnimation:self];    
    
    [commentView setEditable:NO];
    [sendButton setEnabled:NO];
}

- (void) uploaderFailed:(Uploader*)pUploader withError:(NSError*)error
{
    NSLog(@"Upload failed: %@", error);

    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    [uploader release], uploader = nil;
    
    [commentView setEditable:YES];
    [sendButton setEnabled:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert setMessageText:NSLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), [error localizedDescription]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    [alert release];

    [self close];
}

- (void) uploaderFinished:(Uploader*)pUploader
{
    NSLog(@"Upload finished");

    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    NSString *response = [uploader response];

    [uploader release], uploader = nil;

    [commentView setEditable:YES];
    [sendButton setEnabled:YES];

    NSLog(@"response = %@", response);

    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    int i = [lines count];
    while(i--) {
        NSString *line = [lines objectAtIndex:i];
        
        if ([line length] == 0) {
            continue;
        }
        
        if (![line hasPrefix:@"OK "]) {

            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert setMessageText:NSLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), line]];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
            [alert release];
            
            return;
        }
    }

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTSUBMISSIONDATE];

    [[NSUserDefaults standardUserDefaults] setObject:[emailField stringValue]
                                              forKey:KEY_SENDEREMAIL];

    [self close];
}


- (void) windowWillClose: (NSNotification *) n
{
	[uploader cancel];
}

- (void) windowDidLoad
{
	[[self window] setDelegate:self];

    [tabConsole retain];
    [tabCrash retain];
    [tabScript retain];
    [tabPreferences retain];
    [tabException retain];


    [commentLabel setStringValue:NSLocalizedString(@"Comments:", nil)];
    [addressLabel setStringValue:NSLocalizedString(@"Email address:", nil)];
    
    [tabConsole setLabel:NSLocalizedString(@"Console", nil)];
    [tabCrash setLabel:NSLocalizedString(@"CrashLog", nil)];
    [tabScript setLabel:NSLocalizedString(@"Script", nil)];
    [tabPreferences setLabel:NSLocalizedString(@"Preferences", nil)];
    [tabException setLabel:NSLocalizedString(@"Exception", nil)];
    
    [sendButton setStringValue:NSLocalizedString(@"Send", nil)];
    [cancelButton setStringValue:NSLocalizedString(@"Cancel", nil)];


    // FIXME do this in IB
    [[consoleView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[consoleView textContainer] setWidthTracksTextView:NO];
    [[crashesView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[crashesView textContainer] setWidthTracksTextView:NO];
    [[scriptView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[scriptView textContainer] setWidthTracksTextView:NO];
    [[preferencesView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[preferencesView textContainer] setWidthTracksTextView:NO];
    [[exceptionView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[exceptionView textContainer] setWidthTracksTextView:NO];
    
}


- (void) reset
{
    [tabView removeTabViewItem:tabConsole];
    [tabView removeTabViewItem:tabCrash];
    [tabView removeTabViewItem:tabScript];
    [tabView removeTabViewItem:tabPreferences];
    [tabView removeTabViewItem:tabException];

    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_SENDEREMAIL];
    
    if (email == nil) {
        email = NSLocalizedString(@"anonymous", nil);

/*
        ABAddressBook *book = [ABAddressBook sharedAddressBook];
        ABMultiValue *addrs = [[book me] valueForProperty:kABEmailProperty];
        int count = [addrs count];
        
        if (count > 0) {
            email = [addrs valueAtIndex:0];
        }
*/
    }

    [emailField   setStringValue:email];

    [messageField setStringValue:@""];
    [commentView       setString:@""];
    [exceptionView     setString:@""];

    NSLog(@"console");
    [consoleView       setString:[self consoleLog]];
    NSLog(@"crashes");
    [crashesView       setString:[self crashLog]];
    NSLog(@"shell");
    [scriptView         setString:[self scriptLog]];
    NSLog(@"preferences");
    [preferencesView   setString:[self preferences]];
    NSLog(@"ready");
    
    [indicator setHidden:YES];

    [self showDetails:NO animate:NO];
    [detailsButton setIntValue:NO];    
}

- (void) showWindow:(id)sender
{
    if ([[consoleView string] length] != 0) {
        [tabView insertTabViewItem:tabConsole atIndex:1];
    }

    if ([[crashesView string] length] != 0) {
        [tabView insertTabViewItem:tabCrash atIndex:1];
    }

    if ([[scriptView string] length] != 0) {
        [tabView insertTabViewItem:tabScript atIndex:1];
    }

    if ([[preferencesView string] length] != 0) {
        [tabView insertTabViewItem:tabPreferences atIndex:1];
    }

    if ([[exceptionView string] length] != 0) {
        [tabView insertTabViewItem:tabException atIndex:1];
        [tabView selectTabViewItemWithIdentifier:@"Exception"];
    } else {
        [tabView selectTabViewItemWithIdentifier:@"System"];
    }

    [super showWindow:sender];
}

- (BOOL) isShown
{
    return [[self window] isVisible];
}


@end
