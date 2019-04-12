#import <Foundation/Foundation.h>

typedef int CGSWindowID;

#import "CGSInternal/CGSConnection.h"
#import "CGSInternal/CGSTransitions.h"

#define TRANSITION_DURATION 1

int main(int argc, char *argv[]) {
    @autoreleasepool {        
        CGSConnectionID cid = CGSMainConnectionID();
        CGSTransitionSpec spec = {
            0,
            kCGSTransitionWarpSwitch,
            kCGSTransitionDirectionLeft,
            0,
            NULL
        };

        int transition = 0;
        CGSNewTransition(cid,&spec,&transition);
        CGSInvokeTransition(cid,transition,TRANSITION_DURATION);
        sleep(TRANSITION_DURATION);
        CGSReleaseTransition(cid,transition);
            
    }
}
