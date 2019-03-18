#import <Cocoa/Cocoa.h>
#import "Keyboard.h"

class App : public Keyboard {
    
    protected:
        
        void onKeyDown(std::string key) {
            NSLog(@"onKeyDown %s",key.c_str());
        }
        
        void onKeyUp(std::string key) {
            NSLog(@"onKeyUp %s",key.c_str());
        }
    
        void onSIGINT() {
            [NSApp terminate:nil];
        }
        
    public:
        
        App() {
            
        }
        
        ~App() {
            Keyboard::cleanup();
        }
};

int main(int argc, char *argv[]) {

    @autoreleasepool {
        App *app = new App();
        [[NSApplication sharedApplication] run];       
        
    }
}