#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

class AudioIn {

    private:
        
        AudioUnit au;
        AudioComponentDescription acd;
        AudioComponent ac;
        AudioDeviceID did;
        AudioStreamBasicDescription asbd;
        AURenderCallbackStruct cbs;

        int head = 0;
    
        AudioBufferList *bufferList = nil;
        int bufferListSize = 0;

        static OSStatus inputRenderer(void *inRef,AudioUnitRenderActionFlags *ioActionFlags,const AudioTimeStamp *inTimeStamp,UInt32 inBusNumber,UInt32 inNumberFrames, AudioBufferList *ioData) {
                        
            AudioIn *audioIn = (AudioIn *)inRef;
            
            if(audioIn->bufferList==nil) {
                
                audioIn->bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer) * 1);
                audioIn->bufferList->mNumberBuffers = 1;
                audioIn->bufferList->mBuffers[0].mNumberChannels = 1;
                audioIn->bufferListSize = inNumberFrames*sizeof(Float32);
                audioIn->bufferList->mBuffers[0].mDataByteSize = audioIn->bufferListSize;
                audioIn->bufferList->mBuffers[0].mData = malloc(audioIn->bufferListSize);
            }
            else {                
                if(audioIn->bufferListSize != inNumberFrames*sizeof(Float32)) {
                    audioIn->bufferListSize = inNumberFrames*sizeof(Float32);
                    audioIn->bufferList->mBuffers[0].mDataByteSize = audioIn->bufferListSize;
                    free(audioIn->bufferList->mBuffers[0].mData);
                    audioIn->bufferList->mBuffers[0].mData = malloc(audioIn->bufferListSize);

                }					
            }
            
            OSStatus err = AudioUnitRender(audioIn->au,ioActionFlags,inTimeStamp,inBusNumber,inNumberFrames,audioIn->bufferList);
                            
            if(err==noErr&&inNumberFrames) {
                
                float *buffer = (float *)audioIn->bufferList->mBuffers[0].mData;
                    
                for(int k=0; k<inNumberFrames; k++) {
                    
                    audioIn->buffer[audioIn->head++] = buffer[k];
                    if(audioIn->head>=1024) audioIn->head = 0;
                }
                    
            }
            
            return err;
        };

    public:

        double *buffer = new double[1024]{0.0};
        
        AudioIn() {
            
            OSStatus err;
            
            for(int k=0; k<1024; k++) this->buffer[k] = 0;
            
            
            this->acd.componentType = kAudioUnitType_Output;
            this->acd.componentSubType = kAudioUnitSubType_HALOutput;
            this->acd.componentManufacturer = kAudioUnitManufacturer_Apple;
            this->acd.componentFlags = 0;
            this->acd.componentFlagsMask = 0;
            
            this->ac = AudioComponentFindNext(NULL,&this->acd);
            AudioComponentInstanceNew(this->ac,&this->au);
            AudioUnitInitialize(this->au);
            
            int inputEnable  = 1;
            err = AudioUnitSetProperty(this->au,kAudioOutputUnitProperty_EnableIO,kAudioUnitScope_Input,1,&inputEnable,sizeof(UInt32));
            
            int outputEnable = 0;
            err = AudioUnitSetProperty(this->au,kAudioOutputUnitProperty_EnableIO,kAudioUnitScope_Output,0,&outputEnable,sizeof(UInt32));
            
            this->did = AudioDeviceID();
            AudioObjectPropertyAddress addr;
            addr.mScope = kAudioObjectPropertyScopeOutput;
            addr.mElement = kAudioObjectPropertyElementMaster;
            addr.mSelector = kAudioHardwarePropertyDefaultInputDevice;
            UInt32 propsize = sizeof(AudioDeviceID);
            err = AudioObjectGetPropertyData(kAudioObjectSystemObject,&addr,0,NULL,&propsize,&this->did);
            
            addr.mScope    = kAudioObjectPropertyScopeOutput;
            addr.mElement  = kAudioObjectPropertyElementMaster;
            addr.mSelector = kAudioDevicePropertyBufferFrameSize;
                        
            UInt32 bufferFrameSize = 1024;
            AudioObjectSetPropertyData(this->did,&addr,0,NULL,sizeof(UInt32),&bufferFrameSize);
            
            addr.mScope    = kAudioUnitScope_Global;
            addr.mElement  = kAudioObjectPropertyElementMaster;
            addr.mSelector = kAudioDevicePropertyNominalSampleRate;
                                
            Float64 sampleRate = 0;
            UInt32 size = sizeof(Float64);
            AudioObjectGetPropertyData(this->did,&addr,0,NULL,&size,&sampleRate);
                              
            this->asbd.mSampleRate = sampleRate;
            this->asbd.mFormatID = kAudioFormatLinearPCM;
            this->asbd.mFormatFlags = kAudioFormatFlagIsFloat|kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsPacked|kAudioFormatFlagIsNonInterleaved;
            this->asbd.mBitsPerChannel = 8*sizeof(Float32);
            this->asbd.mChannelsPerFrame = 1;
            this->asbd.mBytesPerFrame = sizeof(Float32);
            this->asbd.mFramesPerPacket = 1;
            this->asbd.mBytesPerPacket = this->asbd.mBytesPerFrame*this->asbd.mChannelsPerFrame;
            this->asbd.mReserved = 0;
            
            err = AudioUnitSetProperty(au,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Output,1,&this->asbd,sizeof(this->asbd));
            
            this->cbs.inputProc = inputRenderer;
            this->cbs.inputProcRefCon = (void *)this;
            err = AudioUnitSetProperty(au,kAudioOutputUnitProperty_SetInputCallback,kAudioUnitScope_Output,0,&this->cbs,sizeof(AURenderCallbackStruct));
            
            err = AudioUnitSetProperty(au,kAudioOutputUnitProperty_CurrentDevice,kAudioUnitScope_Output,0,&this->did,propsize);
                                    
        }
        
        void stop()  { 
            AudioOutputUnitStop(au);
        }
        
        void start() { 
            for(int k=0; k<1024; k++) this->buffer[k] = 0;
            AudioOutputUnitStart(au);
        }
        
        ~AudioIn() {
            AudioOutputUnitStop(au);
            AudioUnitUninitialize(au);
            AudioComponentInstanceDispose(au);
            au = NULL;
            if(this->bufferList!=nil) {
                free(bufferList->mBuffers[0].mData);
                free((void *)bufferList);
            }
        }
};


#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    AudioIn *audioIn;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    
    audioIn = new AudioIn();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete audioIn;
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