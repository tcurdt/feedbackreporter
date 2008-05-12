#import "FeedbackController.h"
#import "Uploader.h"

#import <asl.h>
#import <unistd.h>


@implementation FeedbackController

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

- (IBAction)showSystem:(id)sender
{
    NSLog(@"showSystem %d", [sender intValue]);
    
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

- (IBAction)showConsole:(id)sender
{
    NSLog(@"showConsole %d", [sender intValue]);
}

- (IBAction)showCrashes:(id)sender
{
    NSLog(@"showCrash %d", [sender intValue]);
}


- (IBAction)cancel:(id)sender
{
    [self close];
}

- (IBAction)send:(id)sender
{
    [indicator setHidden:NO];
    [indicator startAnimation:self];
        
    // FIXME get url from plist    
    NSString *target = [[NSString alloc] initWithFormat:@"http://vafer.org/upload.php?project=%@", [self applicationName]];

    NSLog(@"sending feedback to %@", target);
    
    Uploader *uploader = [[Uploader alloc] initWithTarget:target];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];

    // FIXME get from application
    [dict setObject:@"anonymous" forKey:@"user"];

    [dict setObject:[self applicationVersion] forKey:@"version"];
    [dict setObject:[commentView string] forKey:@"comment"];
    [dict setObject:[systemView string] forKey:@"system"];
    [dict setObject:[consoleView string] forKey:@"console"];
    [dict setObject:[crashesView string] forKey:@"crashes"];
    //[dict setObject:[NSURL fileURLWithPath: @"/var/log/fsck_hfs.log"] forKey:@"file"];
    
    NSString *result = [uploader post:dict];
    
    [indicator stopAnimation:self];
    [indicator setHidden:YES];

    [target release];
    [dict release];
    [uploader release];
    
    [self close];
    
    NSLog(@"result = %@", result);
    
    // FIXME check result for ^ERR
    
    NSRunAlertPanel(
        @"Feedback",
        @"Feedback has been received!",
        @"Thanks!",
        nil, nil);
}


- (NSString*) console
{

    NSMutableString *console = [[NSMutableString alloc] init];

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

- (int)executeCommand:(NSString*)path withArgs:(NSArray*)args output:(NSMutableString*)output error:(NSMutableString*)error
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:path];
	[task setArguments:args];
	
	NSPipe *outPipe = [NSPipe pipe];
	NSFileHandle *outFile = [outPipe fileHandleForReading];
	[task setStandardOutput:outPipe];

	NSPipe *errPipe = [NSPipe pipe];
	NSFileHandle *errFile = [errPipe fileHandleForReading];	
	[task setStandardError:errPipe];
	
	[task launch];
	
	[task waitUntilExit];

    [output appendString:[[NSString alloc] initWithData:[outFile readDataToEndOfFile] encoding: NSUTF8StringEncoding]];
    [error appendString:[[NSString alloc] initWithData:[errFile readDataToEndOfFile] encoding: NSUTF8StringEncoding]];

	int result = [task terminationStatus];
	
	[task release];
	
	return result;
}


- (NSString*) system
{
    NSMutableString *system = [[NSMutableString alloc] init];

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

    // FIXME add output of script defn
    
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"FeedbackReporter" ofType:@"sh"];
    NSArray *args = [[NSArray alloc] init];

    NSLog(@"executing script at %@", scriptPath);

    int ret = [self executeCommand:scriptPath
                          withArgs:args
                            output:system
                             error:system];

    [args release];
                             
    NSLog(@"script returned code = %d", ret);

    return system;
}


- (NSString*) crashes
{
    // read last sent date
    // find all files ...that are from after that given date

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


- (void) awakeFromNib
{
    // FIXME auto-fill based on existence of crash reports
    [commentView setString:@""];

    [systemView setString:[self system]];
    [consoleView setString:[self console]];
    [crashesView setString:[self crashes]];
    
    [indicator setHidden:YES];
}


@end
