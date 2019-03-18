#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        NSWindow *win;
    
    public:
        
        App() {
            
            this->win = [[NSWindow alloc] initWithContentRect:CGRectMake(0,0,960,540) styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
            
        }
        
        ~App() {
            [this->win setReleasedWhenClosed:NO];
            [this->win close];
            this->win = nil;
        }
};

#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *app;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    app = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete app;
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