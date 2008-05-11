#import "FeedbackController.h"
#import "Uploader.h"

#import <asl.h>
//#import <unistd.h>


@implementation FeedbackController

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
    NSLog(@"cancel");
}

- (IBAction)send:(id)sender
{
    NSLog(@"send");
    
    // FIXME get url from plist
    Uploader *uploader = [[Uploader alloc] initWithURL:@"http://vafer.org/upload.php?project=fossi"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];

    [dict setObject:@"1.0.0" forKey:@"version"];
    [dict setObject:@"anonymous" forKey:@"user"];
    [dict setObject:[systemField stringValue] forKey:@"system"];
    [dict setObject:[consoleField stringValue] forKey:@"console"];
    [dict setObject:[crashesField stringValue] forKey:@"crashes"];
    [dict setObject:[NSURL fileURLWithPath: @"/var/log/fsck_hfs.log"] forKey:@"file"];
    
    [uploader post:dict];
    
    [dict release];
    [uploader release];
}

/*
- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}
*/



- (NSString*) applicationName
{
    NSString *applicationName = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleExecutable"];

    if (!applicationName) {
        applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    }

    return applicationName;
}

- (void) crashes
{
/*  Leppard:
    .Fossi_shodan_CrashHistory.plist
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@_2008-05-09-012401_shodan.crash", [self applicationName]],
    [NSString stringWithFormat: @"/Library/Logs/HangReporter/%@/2008-04-24-132937-Mail.hang", [self applicationName]],
*/

/* Tiger:
    [NSString stringWithFormat: @"~/Library/Logs/CrashReporter/%@.crash.log", [self applicationName]],
*/
}

- (NSString*) console
{
/*  Tiger:
        [NSString stringWithFormat: @"/Library/Logs/Console/%@/console.log", [NSNumber numberWithUnsignedInt: getuid()]],
        | grep Fossi
*/

/* Leopard:
*/
    aslmsg query = asl_new(ASL_TYPE_QUERY);
    asl_set_query(query, ASL_KEY_SENDER, "Fossi", ASL_QUERY_OP_EQUAL);

    aslresponse response = asl_search(NULL, query);

    asl_free(query);

    aslmsg msg;
    while ((msg = aslresponse_next(response))) {
        const char *key;
        for (unsigned i = 0U; (key = asl_key(msg, i)); ++i) {
            const char *value = asl_get(msg, key);

            printf("%s\t%s\n", key, value);
        }
    }

    aslresponse_free(response);




/*
    NSArray *paths = [[NSArray alloc] initWithObjects:

        nil];


    NSString *consolelogPath = 

    NSLog(@"reading console log at %@", consolelogPath);

    NSString *console = [NSString stringWithContentsOfFile: consolelogPath];
    NSEnumerator *theEnum = [[console componentsSeparatedByString: @"\n"] objectEnumerator];
    NSString* currentObject;
    NSMutableArray *profcastStrings = [NSMutableArray array];

    while (currentObject = [theEnum nextObject])
    {
    NSString *keyString = [NSString stringWithFormat: @"%@[", [self applicationName]];
    if ([currentObject rangeOfString: keyString].location != NSNotFound)
      [profcastStrings addObject: currentObject];
    }  

    return [profcastStrings componentsJoinedByString: @"\n"];
    */
    return @"console";
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

    return system;
}




- (void) awakeFromNib
{
    [systemField setStringValue:[self system]];
    [consoleField setStringValue:[self console]];
}


@end
