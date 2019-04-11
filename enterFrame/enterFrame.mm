#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        dispatch_source_t timer;
        double then = CFAbsoluteTimeGetCurrent();
        
    public:
        
        App() {
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                double current = CFAbsoluteTimeGetCurrent();
                NSLog(@"ENTER_FRAME %f",current-this->then);
                this->then = current;
            });
            if(this->timer) dispatch_resume(this->timer);
        }
        
        void update(double time) {
             NSLog(@"update %f",time);
        }
        
        ~App() {
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
        }
};

@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *m;
    NSTimer *timer;
    double then;
}
@end

@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    m = new App();
    then = CFAbsoluteTimeGetCurrent();
    timer = [NSTimer scheduledTimerWithTimeInterval:1/60. target:self selector:@selector(update:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    if(timer&&[timer isValid]) [timer invalidate];
    if(m) delete m;
}
-(void)update:(NSTimer*)timer {
    if(m) {
        double current = CFAbsoluteTimeGetCurrent();
        m->update(current-then);
        then = current;
    }
}
@end

int main (int argc, const char * argv[]) {
    id app = [NSApplication sharedApplication];
    id delegat = [AppDelegate alloc];
    [app setDelegate:delegat];
    [app run];
    return 0;
}