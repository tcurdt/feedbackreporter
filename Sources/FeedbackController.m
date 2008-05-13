#import "FeedbackController.h"
#import "Uploader.h"
#import "Command.h"

#import <asl.h>
#import <unistd.h>

static NSString *FILE_SHELLSCRIPT= @"FRFeedbackReporter";
static NSString *KEY_SENDEREMAIL = @"FRFeedbackReporter.sender";
static NSString *KEY_LASTSUBMISSIONDATE = @"FRFeedbackReporter.lastSubmissionDate";
static NSString *KEY_TARGETURL = @"FRFeedbacReporter.targetURL";

@implementation FeedbackController

- (id) initWithUser:(NSString*)pUser
{
    self = [super initWithWindowNibName:@"FeedbackReporter"];
    if (self != nil) {
        user = pUser;
        
        if (user == nil) {
            user = @"unknown";
        }
    }
    return self;
}

- (NSString*) applicationVersion
{
    NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleLongVersionString"];

    if (!applicationVersion) {
        applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"];
    }

    return applicationVersion;
}


- (NSString*) applicationName
{
    NSString *applicationName = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleExecutable"];

    if (!applicationName) {
        applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    }

    return applicationName;
}


- (IBAction)showDetails:(id)sender
{
    NSLog(@"showDetails %d", [sender intValue]);
    
    /*
    NSRect windowFrame = [[self window] frame];
    
    NSRect controlFrame = [systemField frame];
    
    if ([sender intValue]) {
        [systemField setFrameSize:NSMakeSize(10,10)];
        [systemField setNeedsDisplay:YES];
        windowFrame.origin.y -= 10;
        windowFrame.size.height += 10;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: YES];
    } else {
        [systemField setFrameSize:NSMakeSize(0,0)];
        [systemField setNeedsDisplay:YES];
        windowFrame.origin.y += controlFrame.size.height;
        windowFrame.size.height -= controlFrame.size.height;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: YES];
        
    }
    */
}

- (IBAction)cancel:(id)sender
{
    [self close];
}

- (NSString*) target
{
    NSString *target = [[[NSBundle mainBundle] infoDictionary] valueForKey: KEY_TARGETURL];

    return [NSString stringWithFormat:target, [self applicationName]];
}


- (IBAction)send:(id)sender
{
    [indicator setHidden:NO];
    [indicator startAnimation:self];
        
    NSString *target = [self target];

    NSLog(@"sending feedback to %@", target);
    
    Uploader *uploader = [[Uploader alloc] initWithTarget:target];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];

    [dict setObject:user forKey:@"user"];
    [dict setObject:[emailField stringValue] forKey:@"email"];
    [dict setObject:[self applicationVersion] forKey:@"version"];
    [dict setObject:[commentView string] forKey:@"comment"];
    [dict setObject:[systemView string] forKey:@"system"];
    [dict setObject:[consoleView string] forKey:@"console"];
    [dict setObject:[crashesView string] forKey:@"crashes"];
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
    asl_set_query(query, ASL_KEY_SENDER, [[self applicationName] lossyCString], ASL_QUERY_OP_EQUAL);

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

    NSString *filter = [NSString stringWithFormat: @"%@[", [self applicationName]];


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

    OSType error;
    long result;

    NSProcessInfo *info = [NSProcessInfo processInfo];

    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:7];
    }

    [system appendFormat:@"os version = %@\n", version];
    
    error = Gestalt(gestaltPhysicalRAMSizeInMegabytes, &result);
    if (!error) {
        [system appendFormat:@"ram = %d MB\n", result];
    } else {
        NSLog(@"error detecting ram: %d", error);
    }
    
    error = Gestalt(gestaltNativeCPUtype, &result);
    if (!error) {
        char type[5] = { 0 };
        long swappedResult = EndianU32_BtoN(result);

        memmove(type, &swappedResult, 4);

        NSString *s = nil;
        
        switch(result) {
            case gestaltCPU601:        s = @"PowerPC 601"; break;
            case gestaltCPU603:        s = @"PowerPC 603"; break;
            case gestaltCPU603e:       s = @"PowerPC 603e"; break;
            case gestaltCPU603ev:      s = @"PowerPC 603ev"; break;
            case gestaltCPU604:        s = @"PowerPC 604"; break;
            case gestaltCPU604e:       s = @"PowerPC 604e"; break;
            case gestaltCPU604ev:      s = @"PowerPC 604ev"; break;
            case gestaltCPU750:        s = @"G3"; break;
            case gestaltCPUG4:         s = @"G4"; break;
            case gestaltCPU970:        s = @"G5 (970)"; break;
            case gestaltCPU970FX:      s = @"G5 (970 FX)"; break;
            case gestaltCPU486 :       s = @"Intel 486"; break;
            case gestaltCPUPentium:    s = @"Intel Pentium"; break;
            case gestaltCPUPentiumPro: s = @"Intel Pentium Pro"; break;
            case gestaltCPUPentiumII:  s = @"Intel Pentium II"; break;
            case gestaltCPUX86:        s = @"Intel x86"; break;
            case gestaltCPUPentium4:   s = @"Intel Pentium 4"; break;
        }

        if (s != nil) {
            [system appendFormat:@"cpu type = %@ (%s, %d)\n", s, type, result];
        } else {
            NSLog(@"error detecting cpu type: %d", error);
        }
    }
    
    error = Gestalt(gestaltProcClkSpeed, &result);
    if (!error) {
        [system appendFormat:@"cpu speed = %d MHz\n", (result/1000000)];
    } else {
        NSLog(@"error detecting cpu speed: %d", error);
    }

    [system appendString:@"\n"];

    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {

        Command *cmd = [[Command alloc] initWithPath:scriptPath];
        [cmd setOutput:system];
        [cmd setError:system];
        int ret = [cmd execute];

        NSLog(@"script returned code = %d", ret);
        
    } else {
        NSLog(@"no custom script to execute");
    }


    return system;
}

- (NSDate*) fileModificationDateForPath:(NSString*)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [[fileManager fileAttributesAtPath:path traverseLink: YES] fileModificationDate];
}

- (NSString*) crashes
{
    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTSUBMISSIONDATE];

    NSLog(@"checking for crash files earlier than %@", lastSubmissionDate);

    NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, FALSE);

    int i = [libraryDirectories count];
    while(i--) {
        NSString* libraryDirectory = [libraryDirectories objectAtIndex:i];


        NSString* log1 = [NSString stringWithFormat: @"Logs/CrashReporter/%@.crash.log", [self applicationName]];
        log1 = [[libraryDirectory stringByAppendingPathComponent:log1] stringByExpandingTildeInPath];

        NSLog(@"checking for crash file %@", log1);
                
        if (lastSubmissionDate && ([lastSubmissionDate compare:[self fileModificationDateForPath:log1]] == NSOrderedDescending)) {
            NSLog(@"");
        }
    }


/*  Leppard:
    .Fossi_shodan_CrashHistory.plist
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@_2008-05-09-012401_shodan.crash", [self applicationName]],
    [NSString stringWithFormat: @"/Library/Logs/HangReporter/%@/2008-04-24-132937-Mail.hang", [self applicationName]],
*/

/* Tiger:
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@.crash.log", [self applicationName]],
*/
    return @"";
}

- (void) windowDidLoad
{

    // FIXME auto-fill based on existence of crash reports
    [commentView setString:@""];

    NSString *sender = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_SENDEREMAIL];
    
    if (sender == nil) {
        sender = @"anonymous";
    }

    [emailField setStringValue:sender];

    [systemView setString:[self system]];
    [consoleView setString:[self console]];
    [crashesView setString:[self crashes]];
    
    [indicator setHidden:YES];
}


@end
