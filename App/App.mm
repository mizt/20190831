#import <Cocoa/Cocoa.h>

class App {
    
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
            
        }
        
        ~App() {
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