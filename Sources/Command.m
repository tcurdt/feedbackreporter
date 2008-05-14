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

    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

	[task launch];

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while(!terminated) {
        if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
            break;
        }
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }
    [pool release];

	int result = [task terminationStatus];

	return result;
}

-(void)dealloc
{
    [task release];

    [super dealloc];
}

@end
