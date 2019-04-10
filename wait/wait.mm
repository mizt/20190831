#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    public:
        
        App() {
            NSLog(@"begin");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_queue_create("wait",DISPATCH_QUEUE_CONCURRENT),^{                 
                dispatch_semaphore_signal(this->semaphore);
            });
            dispatch_semaphore_wait(this->semaphore,DISPATCH_TIME_FOREVER);
            NSLog(@"end");
        }
        
        ~App() {
        }
};

int main(int argc, char *argv[]) {
    @autoreleasepool {
        App *app = new App();
        [[NSApplication sharedApplication] run];       
        
    }
}