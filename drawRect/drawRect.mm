#import <Cocoa/Cocoa.h>
#import "../common/addMethod.h"

class App {
    
    private:
        
        NSWindow *win;
        id view;
        
    public:
        
        App() {
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
           
            if(objc_getClass("View")==nil) { objc_registerClassPair(objc_allocateClassPair(objc_getClass("NSView"),"View",0)); }
            Class View = objc_getClass("View");
                        
            addMethod(View,@"drawRect:",^(id me,NSRect dirtyRect) {
                NSLog(@"drawRect:");                            
                [[NSColor blackColor] set];
                NSRectFill(dirtyRect);
            },"v@:@");
                
            this->view = [[View alloc] initWithFrame:rect];
            
            [[this->win contentView] addSubview:this->view];
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
            
        }
        
        ~App() {
            
            [this->view removeFromSuperview];

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