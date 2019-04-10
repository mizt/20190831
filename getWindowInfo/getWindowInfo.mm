#import <Cocoa/Cocoa.h>
#import "vector"
#import "getWindowInfo.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        std::vector<WindowInfo *> info = getWindowInfo(@"Finder");
        NSLog(@"size=%lu",info.size());
        for(int k=0; k<info.size(); k++) {
            NSLog(@"number=%d,layer=%d",info[k]->number,info[k]->layer);
        }
        [[NSApplication sharedApplication] run];       
    }
}