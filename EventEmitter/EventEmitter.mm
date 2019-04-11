#import <Cocoa/Cocoa.h>
#import "EventEmitter.h"

class App {
    
    public:
        
        App() {
            //NSLog(@"%p",this);
            EventEmitter::$()->on(Event::test,^(NSDictionary *dict) {
                NSLog(@"on %s, this %p",Event::test,this);
                if(EventEmitter::exists(dict)) {
                    if(EventEmitter::is_double(dict)) {
                        NSLog(@"%f",EventEmitter::get_double(dict));
                    }
                    else if(EventEmitter::is_NSString(dict)) {
                        NSLog(@"%@",EventEmitter::get_NSString(dict));
                    }
                }
            });
            EventEmitter::$()->emit(Event::test);
            EventEmitter::$()->emit(Event::test,2000.);
        }
        
        ~App() {
        }
};

int main(int argc, char *argv[]) {
    @autoreleasepool {
        App *app = new App();    
        EventEmitter::$()->emit(Event::test,@"hello");
        EventEmitter::$()->off(Event::test);
        EventEmitter::$()->emit(Event::test);
        [[NSApplication sharedApplication] run];
    }
}