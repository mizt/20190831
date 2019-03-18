#import <Foundation/Foundation.h>
#import "../common/isRunningApp.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSLog(@"%d",isRunningApp(@"Finder"));
    }
}