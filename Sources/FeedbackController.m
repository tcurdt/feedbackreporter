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

- (NSString*) applicationIdentifier
{
    NSString *applicationIdentifier = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleIdentifier"];

    return applicationIdentifier;
}


- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    NSSize fullSize = NSMakeSize(455, 302);
    
    NSRect windowFrame = [[self window] frame];
        
    if (show) {

        [tabView setFrameSize:fullSize];
        [tabView setNeedsDisplay:YES];
        windowFrame.origin.y -= fullSize.height;
        windowFrame.size.height += fullSize.height;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: animate];

    } else {
        [tabView setFrameSize:NSMakeSize(0,0)];
        [tabView setNeedsDisplay:YES];
        windowFrame.origin.y += fullSize.height;
        windowFrame.size.height -= fullSize.height;
        [[self window] setFrame: windowFrame
                        display: YES
                        animate: animate];
        
    }
    
    NSRect tabFrame = [tabView frame];
    
    NSLog(@"(%f,%f) (%fx%f)", tabFrame.origin.x, tabFrame.origin.y, tabFrame.size.width, tabFrame.size.height);
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

- (BOOL)file:(NSString*)path isNewerThan:(NSDate*)date
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:path]) {
        return NO;
    }

    if (!date) {
        return YES;
    }

    NSDate* fileDate = [[fileManager fileAttributesAtPath:path traverseLink: YES] fileModificationDate];

    if ([date compare:fileDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (NSArray*) findCrashDumpsBefore:(NSDate*)date
{

    NSMutableArray *files = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *libraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask|NSUserDomainMask, FALSE);

    int i = [libraryDirectories count];
    while(i--) {
        NSString* libraryDirectory = [libraryDirectories objectAtIndex:i];


/* Tiger:
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@.crash.log", [self applicationName]],
*/
        NSString* log1 = [NSString stringWithFormat: @"Logs/CrashReporter/%@.crash.log", [self applicationName]];
        log1 = [[libraryDirectory stringByAppendingPathComponent:log1] stringByExpandingTildeInPath];

        if ([self file:log1 isNewerThan:date]) {
            [files addObject:log1];
        }
                
/*  Leppard:
    .Fossi_shodan_CrashHistory.plist
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@_2008-05-09-012401_shodan.crash", [self applicationName]],
    [NSString stringWithFormat: @"/Library/Logs/HangReporter/%@/2008-04-24-132937-Mail.hang", [self applicationName]],
*/
        
        NSDirectoryEnumerator *enumerator;
        NSString *file;
        
        NSString* log2 = [NSString stringWithFormat: @"Logs/CrashReporter/", [self applicationName]];
        log2 = [[libraryDirectory stringByAppendingPathComponent:log2] stringByExpandingTildeInPath];

        NSLog(@"searching for crash files at %@", log2);

        if ([fileManager fileExistsAtPath:log2]) {

            enumerator  = [fileManager enumeratorAtPath:log2];
            while ((file = [enumerator nextObject])) {
            
                file = [[libraryDirectory stringByAppendingPathComponent:file] stringByExpandingTildeInPath];
            
                if ([file hasSuffix:@".crash"]) {
                    if ([self file:file isNewerThan:date]) {
                        [files addObject:file];
                    }
                }
            }
        }


        NSString* log3 = [NSString stringWithFormat: @"Logs/HangReporter/%@/", [self applicationName]];
        log3 = [[libraryDirectory stringByAppendingPathComponent:log3] stringByExpandingTildeInPath];

        NSLog(@"searching for hang files at %@", log3);

        if ([fileManager fileExistsAtPath:log3]) {

            enumerator  = [fileManager enumeratorAtPath:log3];
            while ((file = [enumerator nextObject])) {

                file = [[libraryDirectory stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

                if ([file hasSuffix:@".hang"]) {
                    if ([self file:file isNewerThan:date]) {
                        [files addObject:file];
                    }
                }
            }
        }
    }
    
    return files;
}

- (NSString*) crashes
{
    NSMutableString *crashes = [NSMutableString string];

    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTSUBMISSIONDATE];

    NSLog(@"checking for crash files earlier than %@", lastSubmissionDate);

    NSArray *crashFiles = [self findCrashDumpsBefore:lastSubmissionDate];

    int i = [crashFiles count];
    while(i--) {
        NSString *crashFile = [crashFiles objectAtIndex:i];
        [crashes appendFormat:@"File: %@\n", crashFile];
        [crashes appendString:[NSString stringWithContentsOfFile:crashFile]];
        [crashes appendString:@"\n"];
    }

    return crashes;
}

- (NSString*) preferences
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    return [NSString stringWithFormat:@"%@", [preferences persistentDomainForName:[self applicationIdentifier]]];
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
    [preferencesView setString:[self preferences]];
    
    [indicator setHidden:YES];

    [tabView setAutoresizesSubviews:NO];
    [self showDetails:NO animate:NO];
}


@end
