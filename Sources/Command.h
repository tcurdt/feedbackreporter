#import <Cocoa/Cocoa.h>


@interface Command : NSObject {

    NSTask *task;

    NSString *path;
    NSArray *args;
    
    NSMutableString *output;
    NSMutableString *error;
    
    BOOL terminated;
}


- (id) initWithPath:(NSString*)path;

- (void) setArgs:(NSArray*)args;

- (void) setError:(NSMutableString*)error;
- (void) setOutput:(NSMutableString*)output;

- (int) execute;


@end
