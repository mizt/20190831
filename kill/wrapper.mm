#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
               
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSTask *cmd = [[NSTask alloc] init];
        [cmd setLaunchPath:@"/bin/bash"];
        [cmd setArguments:[NSArray arrayWithObjects:@"-c",[NSString stringWithFormat:@"open -a %@/kill",path],nil]];
        [cmd launch];
        
        [[NSApplication sharedApplication] run];  
    }
}