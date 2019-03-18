#import <Cocoa/Cocoa.h>
#import "getDockWindowInfo.h"

int main(int argc, char *argv[]) {

    @autoreleasepool {
        
        WindowInfo *info = getDockWindowInfo();
        
        if(info==nullptr) {
            info = new WindowInfo; 
            info->number = -1;
            info->layer = kCGDesktopWindowLevel;
        }
        
        NSLog(@"%d,%d",info->number,info->layer);
        
        delete info;
       
        [[NSApplication sharedApplication] run];       
    }
}