#import "CommandTestCase.h"
#import "Command.h"

@implementation CommandTestCase

- (void) testSimple
{
    Command *cmd = [[Command alloc] initWithPath:@"/bin/ls"];
    
    NSMutableString *err = [[NSMutableString alloc] init];
    NSMutableString *out = [[NSMutableString alloc] init];
    
    [cmd setOutput:out];
    [cmd setError:err];
    
    int result = [cmd execute];

    STAssertTrue(result == 0, @"Return code was %d", result);    
    STAssertTrue([out length] > 0, @"Found no output on stdout");
    STAssertTrue([err length] == 0, @"Found output on stderr");

    [err release], err = nil;
    [out release], out = nil;
    
    [cmd release], cmd = nil;
}

@end
