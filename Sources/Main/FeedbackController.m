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
#import "Uploader.h"
#import "Command.h"
#import "Application.h"
#import "CrashLogFinder.h"
#import "SystemDiscovery.h"

#import <asl.h>
#import <unistd.h>

static NSString *FILE_SHELLSCRIPT= @"FRFeedbackReporter";
static NSString *KEY_SENDEREMAIL = @"FRFeedbackReporter.sender";
static NSString *KEY_LASTSUBMISSIONDATE = @"FRFeedbackReporter.lastSubmissionDate";
static NSString *KEY_TARGETURL = @"FRFeedbacReporter.targetURL";

@implementation FeedbackController

- (id) initWithUser:(NSString*)pUser
{
    return [self initWithUser:pUser comment:@""];
}

- (id) initWithUser:(NSString*)pUser comment:(NSString*)pComment
{
    self = [super initWithWindowNibName:@"FeedbackReporter"];
    if (self != nil) {
        user = pUser;
        
        if (user == nil) {
            user = @"unknown";
        }
        
        comment = pComment;
    }
    return self;
}


// FIXME just for the display pattern binding
- (NSString*) applicationName
{
    return [Application applicationName];
}


- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
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
}

- (IBAction)showDetails:(id)sender
{
    [self showDetails:[sender intValue] animate:YES];
}

- (IBAction)cancel:(id)sender
{
    [self close];
}

- (NSString*) target
{
    NSString *target = [[[NSBundle mainBundle] infoDictionary] valueForKey: KEY_TARGETURL];

    return [NSString stringWithFormat:target, [Application applicationName]];
}


- (IBAction)send:(id)sender
{
    [indicator setHidden:NO];
    [indicator startAnimation:self];
        
    NSString *target = [self target];

    NSLog(@"Sending feedback to %@", target);
    
    Uploader *uploader = [[Uploader alloc] initWithTarget:target];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];

    [dict setObject:user forKey:@"user"];
    [dict setObject:[emailField stringValue] forKey:@"email"];
    [dict setObject:[Application applicationVersion] forKey:@"version"];
    [dict setObject:[commentView string] forKey:@"comment"];
    [dict setObject:[systemView string] forKey:@"system"];
    [dict setObject:[consoleView string] forKey:@"console"];
    [dict setObject:[crashesView string] forKey:@"crashes"];
    [dict setObject:[shellView string] forKey:@"shell"];
    [dict setObject:[preferencesView string] forKey:@"preferences"];
    //[dict setObject:[NSURL fileURLWithPath: @"/var/log/fsck_hfs.log"] forKey:@"file"];
    
    NSString *result = [uploader post:dict];
    
    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    [dict release];
    [uploader release];
    
    [self close];
    
    NSLog(@"result = %@", result);
    
    // FIXME check result for ^ERR
    
    NSRunAlertPanel(
        @"Feedback",
        @"Your feedback has been received!",
        @"Thanks!",
        nil, nil);


    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTSUBMISSIONDATE];

    [[NSUserDefaults standardUserDefaults] setObject:[emailField stringValue]
                                              forKey:KEY_SENDEREMAIL];

}


- (NSString*) console
{

    NSMutableString *console = [[[NSMutableString alloc] init] autorelease];

/* Leopard: */

    [console appendString:@"ASL:\n"];

    aslmsg query = asl_new(ASL_TYPE_QUERY);
    asl_set_query(query, ASL_KEY_SENDER, [[Application applicationName] lossyCString], ASL_QUERY_OP_EQUAL);

    aslresponse response = asl_search(NULL, query);

    asl_free(query);

    NSDateFormatter *formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y.%m.%d %H:%M:%S %Z" allowNaturalLanguage:NO] autorelease];

    aslmsg msg;
    while ((msg = aslresponse_next(response))) {

        NSString *dateString = [NSString stringWithUTF8String:asl_get(msg, ASL_KEY_TIME)];
        
        NSDate *date = [formatter dateFromString:dateString];
        if(!date) {
            NSTimeInterval timestamp = [dateString doubleValue];
            date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        }

        [console appendFormat:@"%@: %s\n", date, asl_get(msg, ASL_KEY_MSG)];
    }

    aslresponse_free(response);

/*  Tiger: */

    [console appendString:@"LOG:\n"];

    NSString *logPath = [NSString stringWithFormat: @"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt:getuid()]];

    NSString *log = [NSString stringWithContentsOfFile:logPath];

    NSString *filter = [NSString stringWithFormat: @"%@[", [Application applicationName]];


    NSEnumerator *lineEnum = [[log componentsSeparatedByString: @"\n"] objectEnumerator];

    NSString* currentObject;

    while (currentObject = [lineEnum nextObject]) {

        if ([currentObject rangeOfString:filter].location != NSNotFound) {        
            [console appendFormat:@"%@\n", currentObject];
        }  
    }

    return console;
}


- (NSString*) system
{
    NSMutableString *system = [[[NSMutableString alloc] init] autorelease];

    SystemDiscovery *discovery = [[SystemDiscovery alloc] init];

    NSDictionary *dict = [discovery discover];

    [system appendFormat:@"os version = %@\n", [dict valueForKey:@"OS_VERSION"]];
    [system appendFormat:@"ram = %@\n", [dict valueForKey:@"RAM"]];
    [system appendFormat:@"cpu type = %@\n", [dict valueForKey:@"CPU_TYPE"]];
    [system appendFormat:@"cpu speed = %@\n", [dict valueForKey:@"CPU_SPEED"]];

    [discovery release];

    return system;
}


- (NSString*) crashes
{
    NSMutableString *crashes = [NSMutableString string];

    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTSUBMISSIONDATE];

    NSLog(@"Checking for crash files earlier than %@", lastSubmissionDate);

    NSArray *crashFiles = [CrashLogFinder findCrashLogsBefore:lastSubmissionDate];

    int i = [crashFiles count];
    while(i--) {
        NSString *crashFile = [crashFiles objectAtIndex:i];
        [crashes appendFormat:@"File: %@\n", crashFile];
        [crashes appendString:[NSString stringWithContentsOfFile:crashFile]];
        [crashes appendString:@"\n"];
    }

    return crashes;
}

- (NSString*) shell
{
    NSMutableString *shell = [NSMutableString string];

    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {

        Command *cmd = [[Command alloc] initWithPath:scriptPath];
        [cmd setOutput:shell];
        [cmd setError:shell];
        int ret = [cmd execute];
        [cmd release];

        NSLog(@"Script returned code = %d", ret);
        
    } else {
        NSLog(@"No custom script to execute");
    }

    return shell;
}

- (NSString*) preferences
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    return [NSString stringWithFormat:@"%@", [preferences persistentDomainForName:[Application applicationIdentifier]]];
}


- (void) windowDidLoad
{

    [commentView setString:comment];

    NSString *sender = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_SENDEREMAIL];
    
    if (sender == nil) {
        sender = @"anonymous";
    }

    [emailField setStringValue:sender];

    [systemView setString:[self system]];
    [consoleView setString:[self console]];
    [crashesView setString:[self crashes]];
    [shellView setString:[self shell]];
    [preferencesView setString:[self preferences]];
    
    [indicator setHidden:YES];

    [self showDetails:NO animate:NO];
}


@end
