#import <Cocoa/Cocoa.h>

static void onResize(CGDirectDisplayID displayID, CGDisplayChangeSummaryFlags flags, void *me) {
    if(CGMainDisplayID()==displayID) {
        if(flags&kCGDisplayDesktopShapeChangedFlag) {            
            NSLog(@"%@",NSStringFromRect([[[NSScreen screens] objectAtIndex:0] frame]));
        }
    }
}
    
int main(int argc, char *argv[]) {
    @autoreleasepool {
        CGDisplayRegisterReconfigurationCallback(onResize,nullptr);
        [[NSApplication sharedApplication] run];               
    }
}