#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        dispatch_source_t timer;
        double then = CFAbsoluteTimeGetCurrent();
    
    public:
        
        App() {
            
            id menu = [[NSMenu alloc] init];
            id rootMenuItem = [[NSMenuItem alloc] init];
            [menu addItem:rootMenuItem];
            id appMenu = [[NSMenu alloc] init];
            id quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
            [appMenu addItem:quitMenuItem];
            [rootMenuItem setSubmenu:appMenu];
            [NSApp setMainMenu:menu];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30.0)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    int pid = [[NSProcessInfo processInfo] processIdentifier];
                    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
                    if(app.active) {
                        
                        // deactive
                        
                        NSTask *cmd = [[NSTask alloc] init];
                        [cmd setLaunchPath:@"/bin/bash"];
                        [cmd setArguments:[NSArray arrayWithObjects:@"-c",@"open -a Finder",nil]];
                        [cmd launch];
                    }
                });
                
            });
            if(this->timer) dispatch_resume(this->timer);            
        }
        
        ~App() {
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
            
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