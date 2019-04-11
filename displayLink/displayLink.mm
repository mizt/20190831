#import <Cocoa/Cocoa.h>

class App {
    
    private:
        
        double then = CFAbsoluteTimeGetCurrent();

        CVDisplayLinkRef displayLink;
        
        static CVReturn OnDisplayLinkFrame(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
            
            if(displayLink&&displayLinkContext) {
                
                App *me =(App *)displayLinkContext;
                double current = CFAbsoluteTimeGetCurrent();
                NSLog(@"%f",current-me->then);
                me->then = current;
            }
            
            
            return kCVReturnSuccess;
        }
        
    public:
        
        App() {
            
            CVReturn cvReturn = CVDisplayLinkCreateWithActiveCGDisplays(&this->displayLink);
            cvReturn = CVDisplayLinkSetOutputCallback(this->displayLink,&OnDisplayLinkFrame,this);
            cvReturn = CVDisplayLinkSetCurrentCGDisplay(this->displayLink,CGMainDisplayID());
            CVDisplayLinkStart(this->displayLink);
        }
        
        ~App() {
            CVDisplayLinkStop(this->displayLink);
            CVDisplayLinkRelease(this->displayLink);
            this->displayLink = nullptr;
        }
};

int main(int argc, char *argv[]) {
    @autoreleasepool {
        App *app = new App();
        [[NSApplication sharedApplication] run];
    }
}