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
        int tid = 0;
        CGSNewTransition(cid,&spec,&tid);
        CGSInvokeTransition(cid,tid,TRANSITION_DURATION);
        usleep(TRANSITION_DURATION*1000000.0);
        CGSReleaseTransition(cid,tid);
    }
}
