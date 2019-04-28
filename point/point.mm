#import <Cocoa/Cocoa.h>
#import "../common/addMethod.h"

class App {
    
    private:
        
        NSWindow *win;
        id view;
        
        dispatch_source_t timer;   
        
    public:
        
        App() {
            
            CGRect rect = CGRectMake(0,0,48,48);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
           
            if(objc_getClass("View")==nil) { objc_registerClassPair(objc_allocateClassPair(objc_getClass("NSView"),"View",0)); }
            Class View = objc_getClass("View");
                        
            addMethod(View,@"drawRect:",^(id me,NSRect dirtyRect) {
                NSLog(@"drawRect:");   
                
                NSColor* color = [NSColor colorWithRed:0.75 green:0.75 blue:0.75 alpha: 0.7];
                
                NSShadow* shadow = [[NSShadow alloc] init];
                shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent: 0.25];
                shadow.shadowOffset = NSMakeSize(1, -1);
                shadow.shadowBlurRadius = 3;

                NSBezierPath* ovalPath = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(2,2,42,42)];
                [NSGraphicsContext saveGraphicsState];
                [shadow set];
                [color setFill];
                [ovalPath fill];
                [NSGraphicsContext restoreGraphicsState];
                
            },"v@:@");
                
            this->view = [[View alloc] initWithFrame:rect];
            
            [[this->win contentView] addSubview:this->view];
            [this->win setBackgroundColor:[NSColor clearColor]];
            [this->win setHasShadow:NO];
            [this->win setOpaque:NO];
            [this->win setLevel:kCGScreenSaverWindowLevel];
            [this->win setIgnoresMouseEvents:YES];
            [this->win makeKeyAndOrderFront:nil];
            
             this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
                dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/120.0)*1000000000,0);
                dispatch_source_set_event_handler(this->timer,^{
                    double current = CFAbsoluteTimeGetCurrent();                
                    dispatch_async(dispatch_get_main_queue(),^{                                       
                        NSPoint mouseLoc = [NSEvent mouseLocation];
                        [this->win setFrame:CGRectMake(mouseLoc.x-23,mouseLoc.y-22,48,48) display:NO];
                    });
                });
                if(this->timer) dispatch_resume(this->timer);            
        }
        
        ~App() {
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }       
            
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