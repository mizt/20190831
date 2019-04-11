#import <Cocoa/Cocoa.h>

class App {
        
    public:
        
        App() {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC*0.5),dispatch_get_main_queue(),^{
               NSLog(@"main_queue"); 
            });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC*0.5),dispatch_queue_create("DISPATCH_QUEUE_CONCURRENT",DISPATCH_QUEUE_CONCURRENT),^{  // DISPATCH_QUEUE_SERIAL               
                NSLog(@"DISPATCH_QUEUE_CONCURRENT"); 
                dispatch_async(dispatch_get_main_queue(),^{
                    NSLog(@"DISPATCH_QUEUE_CONCURRENT + main_queue"); 
                });
            });
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