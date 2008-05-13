#import "Command.h"


@implementation Command

- (id) initWithPath:(NSString*)pPath
{
    self = [super init];
    if (self != nil) {
    	task = [[NSTask alloc] init];
        args = [NSArray array];
        path = pPath;
        error = nil;
        output = nil;
        terminated = NO;
    }
    
    return self;
}

- (void) setArgs:(NSArray*)pArgs
{
    args = pArgs;
}

- (void) setError:(NSMutableString*)pError
{
    error = pError;
}

- (void) setOutput:(NSMutableString*)pOutput
{
    output = pOutput;
}


-(void) outData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];


    NSData *data = [fileHandle availableData];

    if ([data length]) {
        NSString *s = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
    
        [output appendString:s];
        
        [s release];
    }
    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];

    NSData *data = [fileHandle availableData];

    if ([data length]) {
        NSString *s = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];

        [error appendString:s];
        
        [s release];
    }

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated: (NSNotification *)notification
{
    NSLog(@"task terminated");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    terminated = YES;
}

- (int) execute
{
	[task setLaunchPath:path];
	[task setArguments:args];

	NSPipe *outPipe = [NSPipe pipe];
	NSPipe *errPipe = [NSPipe pipe];

    [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];

    NSFileHandle *outFile = [outPipe fileHandleForReading];
    NSFileHandle *errFile = [errPipe fileHandleForReading];	

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:outFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:errFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task];

    NSLog(@"start receiving");
    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

    NSLog(@"launching command %@", path);
	[task launch];

    NSLog(@"waiting for command to finsh");
    //[task waitUntilExit];

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while(!terminated) {
        NSLog(@"run");
        if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
            NSLog(@"app end");
            break;
        }
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }
    [pool release];

    NSLog(@"finshed");

	int result = [task terminationStatus];

    NSLog(@"command exited with status %d", result);
	
	return result;
}

-(void)dealloc
{
    [task release];

    [super dealloc];
}

@end
