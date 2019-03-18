#import <Foundation/Foundation.h>
#import "sys/sysctl.h"
#import "../common/isRunningApp.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        int pid = isRunningApp(@"Finder");
        NSLog(@"%d",pid);
        
        if(pid!=-1) {
            kill(pid,SIGKILL);
        }
    }
}