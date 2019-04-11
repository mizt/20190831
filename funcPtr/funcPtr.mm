#import <Cocoa/Cocoa.h>
#import <iostream>
#import <map>

class App {
    
    private:
        
        typedef void (App::*Func)();
        std::map<std::string,Func> func;
        Func process = nullptr;
            
        void a() { NSLog(@"a"); }
        void b() { NSLog(@"b"); }

    public:
        
        App() {
            
            this->func["a"] = &App::a; 
            this->func["b"] = &App::b;
            
            this->process = this->func["a"]; 
            
            if(this->process) {
                ((this)->*(this->process))();
            }
            
            this->process = this->func["b"]; 
            
            if(this->process) {
                ((this)->*(this->process))();
            }
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