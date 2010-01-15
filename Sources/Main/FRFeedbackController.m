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

#import "FRFeedbackController.h"
#import "FRFeedbackReporter.h"
#import "FRUploader.h"
#import "FRCommand.h"
#import "FRApplication.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "FRConstants.h"
#import "FRConsoleLog.h"

#import "NSMutableDictionary+Additions.h"

#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import <SystemConfiguration/SCNetwork.h>
#import <SystemConfiguration/SCNetworkReachability.h>


@implementation FRFeedbackController

#pragma mark Construction

- (id) init
{
    self = [super initWithWindowNibName:@"FeedbackReporter"];
    if (self != nil) {
        detailsShown = YES;
    }
    return self;
}

- (void) awakeFromNib
{
    [tabConsole retain];
    [tabCrash retain];
    [tabScript retain];
    [tabPreferences retain];
    [tabException retain];
}

#pragma mark Destruction

- (void) dealloc
{
    [type release];

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

- (void) setInformativeText:(NSString *)informativeText
{
    [informativeTextField setStringValue:informativeText];
}

- (void) setComment:(NSString*)comment
{
    [commentView setString:comment];
}

- (void) setCommentLabel:(NSString*)label 
{
    [commentLabel setStringValue:label];
}

- (void) setException:(NSString*)exception
{
    [exceptionView setString:exception];
}

- (void) setType:(NSString*)theType
{
    [theType retain];
    [type release];
    type = theType;
}

#pragma mark information gathering

- (NSString*) consoleLog
{
    NSNumber *hours = [[NSUserDefaults standardUserDefaults] valueForKey:PLIST_KEY_LOGHOURS];

    int h = 24;

    if (hours != nil) {
        h = [hours intValue];
    }
    
    NSDate *since = [[NSCalendarDate calendarDate] dateByAddingYears:0 months:0 days:0 hours:-h minutes:0 seconds:0];

    NSNumber *maxSize = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_MAXCONSOLELOGSIZE];

    return [FRConsoleLog logSince:since maxSize:maxSize];
}


- (NSArray*) systemProfile
{
    static NSArray *systemProfile = nil;

    if (systemProfile == nil) {
        systemProfile = [[FRSystemProfile discover] retain];
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

    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];

    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastSubmissionDate];

    int i = [crashFiles count];

    if (i == 1) {
        if (lastSubmissionDate == nil) {
            NSLog(@"Found a crash file");
        } else {
            NSLog(@"Found a crash file earlier than latest submission on %@", lastSubmissionDate);
        }
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:[crashFiles lastObject] encoding: NSUTF8StringEncoding error:&error];
        if (error != nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }

    if (lastSubmissionDate == nil) {
        NSLog(@"Found %d crash files", i);
    } else {
        NSLog(@"Found %d crash files earlier than latest submission on %@", i, lastSubmissionDate);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSDate *newest = nil;
    int newestIndex = -1;

    while(i--) {
    
        NSString *crashFile = [crashFiles objectAtIndex:i];
		NSError* error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:crashFile error:&error];
		if (error) {
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
        if (error != nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }

    return @"";
}

- (NSString*) scriptLog
{
    NSMutableString *log = [NSMutableString string];

    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {

        FRCommand *cmd = [[FRCommand alloc] initWithPath:scriptPath];
        [cmd setOutput:log];
        [cmd setError:log];
        int ret = [cmd execute];
        [cmd release];

        NSLog(@"Script exit code = %d", ret);
        
    } /* else {
        NSLog(@"No custom script to execute");
    }
    */

    return log;
}

- (NSString*) preferences
{
    NSMutableDictionary *preferences = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:[FRApplication applicationIdentifier]] mutableCopy] autorelease];
    
    if (preferences == nil) {
        return @"";
    }

    [preferences removeObjectForKey:DEFAULTS_KEY_SENDEREMAIL];

    if ([delegate respondsToSelector:@selector(anonymizePreferencesForFeedbackReport:)]) {
        preferences = [delegate anonymizePreferencesForFeedbackReport:preferences];
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

- (IBAction) showDetails:(id)sender
{
    [self showDetails:[sender intValue] animate:YES];
}

- (IBAction) cancel:(id)sender
{
    [uploader cancel], uploader = nil;
    
    [self close];
}

- (IBAction) send:(id)sender
{
    if (uploader != nil) {
        NSLog(@"Still uploading");
        return;
    }
            
    NSString *target = [[FRApplication feedbackURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
    
    if (target == nil) {
        NSLog(@"You are missing the %@ key in your Info.plist!", PLIST_KEY_LOGHOURS);
        return;        
    }

    NSURL *url = [NSURL URLWithString:target];

    SCNetworkConnectionFlags reachabilityFlags;
    
    const char *hostname = [[url host] UTF8String];  

#ifdef MAC_OS_X_VERSION_10_6
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, hostname);
    Boolean reachabilityResult = SCNetworkReachabilityGetFlags(reachability, &reachabilityFlags);
    CFRelease(reachability);
#else  
    Boolean reachabilityResult = SCNetworkCheckReachabilityByName(hostname, &reachabilityFlags);
#endif
        
    BOOL reachable = reachabilityResult
        &&  (reachabilityFlags & kSCNetworkFlagsReachable)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionRequired)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionAutomatic)
        && !(reachabilityFlags & kSCNetworkFlagsInterventionRequired);
    
    if (!reachable) {
        int alertResult = [[NSAlert alertWithMessageText:FRLocalizedString(@"Feedback Host Not Reachable", nil)
                                           defaultButton:FRLocalizedString(@"Proceed Anyway", nil)
                                         alternateButton:FRLocalizedString(@"Cancel", nil)
                                             otherButton:nil
                               informativeTextWithFormat:FRLocalizedString(@"You may not be able to send feedback because %@ isn't reachable.", nil), [url host]
                            ] runModal];

        if (alertResult != NSAlertDefaultReturn) {
            return;
        }
    }

    uploader = [[FRUploader alloc] initWithTarget:target delegate:self];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];
	
    [dict setValidString:[emailField stringValue]
				  forKey:POST_KEY_EMAIL];
	
    [dict setValidString:[commentView string]
				  forKey:POST_KEY_COMMENT];
	
	if ([sendDetailsCheckbox state] == NSOnState) {
		if ([delegate respondsToSelector:@selector(customParametersForFeedbackReport)]) {
			[dict addEntriesFromDictionary:[delegate customParametersForFeedbackReport]];
		}
		
		[dict setValidString:type
					  forKey:POST_KEY_TYPE];
		
		[dict setValidString:[FRApplication applicationVersion]
					  forKey:POST_KEY_VERSION];
		
		[dict setValidString:[self systemProfileAsString]
					  forKey:POST_KEY_SYSTEM];
		
		[dict setValidString:[consoleView string]
					  forKey:POST_KEY_CONSOLE];
		
		[dict setValidString:[crashesView string]
					  forKey:POST_KEY_CRASHES];
		
		[dict setValidString:[scriptView string]
					  forKey:POST_KEY_SHELL];
		
		[dict setValidString:[preferencesView string]
					  forKey:POST_KEY_PREFERENCES];
		
		[dict setValidString:[exceptionView string]
					  forKey:POST_KEY_EXCEPTION];		
	}	
    
    NSLog(@"Sending feedback to %@", target);
    
    [uploader postAndNotify:dict];
	
    [dict release];
}

- (void) uploaderStarted:(FRUploader*)pUploader
{
    // NSLog(@"Upload started");

    [indicator setHidden:NO];
    [indicator startAnimation:self];    
    
    [commentView setEditable:NO];
    [sendButton setEnabled:NO];
}

- (void) uploaderFailed:(FRUploader*)pUploader withError:(NSError*)error
{
    NSLog(@"Upload failed: %@", error);

    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    [uploader release], uploader = nil;
    
    [commentView setEditable:YES];
    [sendButton setEnabled:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:FRLocalizedString(@"OK", nil)];
    [alert setMessageText:FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
    [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), [error localizedDescription]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    [alert release];

    [self close];
}

- (void) uploaderFinished:(FRUploader*)pUploader
{
    // NSLog(@"Upload finished");

    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    NSString *response = [uploader response];

    [uploader release], uploader = nil;

    [commentView setEditable:YES];
    [sendButton setEnabled:YES];

    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    int i = [lines count];
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
            [alert release];
            
            return;
        }
    }

    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date]
                                             forKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];

    [[NSUserDefaults standardUserDefaults] setObject:[emailField stringValue]
                                              forKey:DEFAULTS_KEY_SENDEREMAIL];

    [self close];
}

- (void) windowWillClose: (NSNotification *) n
{
    [uploader cancel];
}

- (void) windowDidLoad
{
    [[self window] setDelegate:self];

    [commentLabel setStringValue:FRLocalizedString(@"Comments:", nil)];
    [addressLabel setStringValue:FRLocalizedString(@"Email address:", nil)];
    
    [tabConsole setLabel:FRLocalizedString(@"Console", nil)];
    [tabCrash setLabel:FRLocalizedString(@"CrashLog", nil)];
    [tabScript setLabel:FRLocalizedString(@"Script", nil)];
    [tabPreferences setLabel:FRLocalizedString(@"Preferences", nil)];
    [tabException setLabel:FRLocalizedString(@"Exception", nil)];
    
    [sendButton setTitle:FRLocalizedString(@"Send", nil)];
    [cancelButton setTitle:FRLocalizedString(@"Cancel", nil)];

    [[consoleView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[consoleView textContainer] setWidthTracksTextView:NO];
    [consoleView setString:@""];
    [[crashesView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[crashesView textContainer] setWidthTracksTextView:NO];
    [crashesView setString:@""];
    [[scriptView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[scriptView textContainer] setWidthTracksTextView:NO];
    [scriptView setString:@""];
    [[preferencesView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[preferencesView textContainer] setWidthTracksTextView:NO];
    [preferencesView setString:@""];
    [[exceptionView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[exceptionView textContainer] setWidthTracksTextView:NO];
    [exceptionView setString:@""];
}

- (void) stopSpinner
{
    [indicator stopAnimation:self];
    [indicator setHidden:YES];
    [sendButton setEnabled:YES];
}

- (void) addTabViewItem:(NSTabViewItem*)theTabViewItem
{
    [tabView insertTabViewItem:theTabViewItem atIndex:1];
}

- (void) populate
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *consoleLog = [self consoleLog];
    if ([consoleLog length] > 0) {
        [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:tabConsole waitUntilDone:YES];
        [consoleView performSelectorOnMainThread:@selector(setString:) withObject:consoleLog waitUntilDone:YES];
    }

    NSString *crashLog = [self crashLog];
    if ([crashLog length] > 0) {
        [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:tabCrash waitUntilDone:YES];
        [crashesView performSelectorOnMainThread:@selector(setString:) withObject:crashLog waitUntilDone:YES];
    }

    NSString *scriptLog = [self scriptLog];
    if ([scriptLog length] > 0) {
        [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:tabScript waitUntilDone:YES];
        [scriptView performSelectorOnMainThread:@selector(setString:) withObject:scriptLog waitUntilDone:YES];
    }

    NSString *preferences = [self preferences];
    if ([preferences length] > 0) {
        [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:tabPreferences waitUntilDone:YES];
        [preferencesView performSelectorOnMainThread:@selector(setString:) withObject:preferences waitUntilDone:YES];
    }

    [self performSelectorOnMainThread:@selector(stopSpinner) withObject:self waitUntilDone:YES];
    
    [pool release];
}

- (void) reset
{
    [tabView removeTabViewItem:tabConsole];
    [tabView removeTabViewItem:tabCrash];
    [tabView removeTabViewItem:tabScript];
    [tabView removeTabViewItem:tabPreferences];
    [tabView removeTabViewItem:tabException];

    ABPerson *me = [[ABAddressBook sharedAddressBook] me];
    ABMutableMultiValue *emailAddresses = [me valueForProperty:kABEmailProperty];

    int i, count = [emailAddresses count];
    
    [emailField removeAllItems];

    [emailField addItemWithObjectValue:FRLocalizedString(@"anonymous", nil)];

    for(i=0; i<count; i++) {

        NSString *emailAddress = [emailAddresses valueAtIndex:i];

        [emailField addItemWithObjectValue:emailAddress];
    }

    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_SENDEREMAIL];

    NSInteger found = [emailField indexOfItemWithObjectValue:email];
    if (found != NSNotFound) {
        [emailField selectItemAtIndex:found];
	} else if ([emailField numberOfItems] >= 2) {
		NSString *defaultSender = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTSENDER];
		NSUInteger index = (defaultSender && [defaultSender isEqualToString:@"firstEmail"]) ? 1 : 0;
		[emailField selectItemAtIndex:index];
    }

    [messageField setStringValue:@""];
    [commentView setString:@""];
    [exceptionView setString:@""];

    [self showDetails:NO animate:NO];
    [detailsButton setIntValue:NO];    

    [indicator setHidden:NO];
    [indicator startAnimation:self];    
    [sendButton setEnabled:NO];

	//	setup 'send details' checkbox...
	[sendDetailsCheckbox setTitle:FRLocalizedString(@"Send details", nil)];
	[sendDetailsCheckbox setState:NSOnState];
	NSString *sendDetailsIsOptional = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_SENDDETAILSISOPTIONAL];
	if (sendDetailsIsOptional && [sendDetailsIsOptional isEqualToString:@"YES"]) {
		[detailsLabel setHidden:YES];
		[sendDetailsCheckbox setHidden:NO];
	} else {
		[detailsLabel setHidden:NO];
		[sendDetailsCheckbox setHidden:YES];
	}
}

- (void) showWindow:(id)sender
{
    if ([[exceptionView string] length] != 0) {
        [tabView insertTabViewItem:tabException atIndex:1];
        [tabView selectTabViewItemWithIdentifier:@"Exception"];
    } else {
        [tabView selectTabViewItemWithIdentifier:@"System"];
    }

    [NSThread detachNewThreadSelector:@selector(populate) toTarget:self withObject:nil];
    
    [super showWindow:sender];
}

- (BOOL) isShown
{
    return [[self window] isVisible];
}


@end
