#import <Cocoa/Cocoa.h>

#import "AudioOutBase.h"
#define TWO_PI (3.14159265358979323846*2.0)

class AudioOut : public AudioOutBase {

    private:
        
        double phase = 0;
  
    protected:

        static OSStatus onAudioOut(void *inRef, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
                        
            float *L = (float *)ioData->mBuffers[0].mData;
            float *R = (float *)ioData->mBuffers[1].mData;    
            
            AudioOut *me = (AudioOut *)inRef;        
            
            for(int k=0; k<inNumberFrames; k++) {
                
                me->phase+=440.0/me->sampleRate;
                if(me->phase>1) me->phase-=1;
                else if(me->phase<0) me->phase+=1;
            
                *L++ = *R++ = sin((me->phase)*TWO_PI);
            }
            
            return noErr;
        };
  
    public:
        
        AudioOut() {
            AudioOutBase::setup((void *)this,onAudioOut);
        }
        
        ~AudioOut() {}
};


#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    AudioOut *audioOut;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    
    audioOut = new AudioOut();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete audioOut;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
    
        id app = [NSApplication sharedApplication];
        id delegat = [AppDelegate alloc];
        [app setDelegate:delegat];
        [app run];
    }
}