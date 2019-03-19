#import <Cocoa/Cocoa.h>
#import "AudioOut.h"

#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    AudioOut *audioOut;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    audioOut = new AudioOut();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete audioOut;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
    
        id app = [NSApplication sharedApplication];
        id delegat = [AppDelegate alloc];
        [app setDelegate:delegat];
        [app run];
    }
}