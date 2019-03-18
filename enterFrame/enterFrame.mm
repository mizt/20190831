#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        dispatch_source_t timer;
        double then = CFAbsoluteTimeGetCurrent();
        
    public:
        
        App() {
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/120)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                double current = CFAbsoluteTimeGetCurrent();
                NSLog(@"%f",current-this->then);
                this->then = current;
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

int main(int argc, char *argv[]) {

    @autoreleasepool {
        App *app = new App();
        [[NSApplication sharedApplication] run];       
        
    }
}