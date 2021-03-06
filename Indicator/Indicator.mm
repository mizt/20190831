#import <Cocoa/Cocoa.h>
#import "Indicator.h"

class App {
    
    private:
        
        dispatch_source_t timer;    
        Indicator *indicator;
        
    public:
        
        App() {
            
            this->indicator = new Indicator();
            this->indicator->appear();
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30.0)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                double current = CFAbsoluteTimeGetCurrent();                
                dispatch_async(dispatch_get_main_queue(),^{                   
                    this->indicator->update();
                });
            });
            if(this->timer) dispatch_resume(this->timer);
        }
        
        ~App() {
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }            
            delete indicator;
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