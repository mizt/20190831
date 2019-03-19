#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#define TWO_PI (3.14159265358979323846*2.0)

class AudioOut {
    
    protected:
    
        double sampleRate = 44100.0;

        AudioUnit au;
        AudioComponentDescription acd;
        AudioComponent ac;
        AURenderCallbackStruct cbs;
        AudioStreamBasicDescription asbd;
        AudioDeviceID adid;
        AudioObjectPropertyAddress pa;
        
        double phase = 0;
    
    
        static OSStatus renderer(void *inRef, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
            
            float *L = (float *)ioData->mBuffers[0].mData;
            float *R = (float *)ioData->mBuffers[0].mData;    
            
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
            
            this->pa.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
            this->pa.mScope = kAudioObjectPropertyScopeGlobal;
            this->pa.mElement = kAudioObjectPropertyElementMaster;
            UInt32 size = sizeof(this->adid);
            OSStatus result = AudioObjectGetPropertyData(kAudioObjectSystemObject,&this->pa,0,0,&size,&this->adid);
            
            UInt32 buffer_size;
            UInt32 property_size = sizeof(buffer_size);
            this->pa.mSelector = kAudioDevicePropertyBufferFrameSize;
            this->pa.mScope = kAudioObjectPropertyScopeWildcard;
            this->pa.mElement = kAudioObjectPropertyElementMaster;
            result = AudioObjectGetPropertyData(this->adid,&this->pa,0,0,&property_size,&buffer_size);
            
            property_size = sizeof(this->sampleRate);
            this->pa.mSelector = kAudioDevicePropertyActualSampleRate;
            result = AudioObjectGetPropertyData(this->adid,&this->pa,0,0,&property_size,&this->sampleRate);
            
            this->acd.componentType = kAudioUnitType_Output;
            this->acd.componentSubType = kAudioUnitSubType_HALOutput;
            this->acd.componentManufacturer = kAudioUnitManufacturer_Apple;
            this->acd.componentFlags = 0;
            this->acd.componentFlagsMask = 0;
            
            this->ac = AudioComponentFindNext(NULL,&this->acd);
            AudioComponentInstanceNew(this->ac,&this->au);
            AudioUnitInitialize(this->au);
            
            this->cbs.inputProc = renderer;
            this->cbs.inputProcRefCon = (void *)this;
            
            AudioUnitSetProperty(au,kAudioUnitProperty_SetRenderCallback,kAudioUnitScope_Input,0,&this->cbs,sizeof(AURenderCallbackStruct));
            
            this->asbd.mSampleRate = this->sampleRate;
            this->asbd.mFormatID = kAudioFormatLinearPCM;
            this->asbd.mFormatFlags = kAudioFormatFlagIsFloat|kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsPacked|kAudioFormatFlagIsNonInterleaved;
            this->asbd.mChannelsPerFrame = 2;
            this->asbd.mBytesPerPacket = sizeof(Float32);
            this->asbd.mBytesPerFrame  = sizeof(Float32);
            this->asbd.mFramesPerPacket = 1;
            this->asbd.mBitsPerChannel = 8*sizeof(Float32);
            this->asbd.mReserved = 0;
                        
            AudioUnitSetProperty(this->au,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Input,0,&this->asbd,sizeof(this->asbd));
            AudioOutputUnitStart(this->au);
        }
        
        ~AudioOut() {
            AudioOutputUnitStop(this->au);
            AudioUnitUninitialize(this->au);
            AudioComponentInstanceDispose(this->au);
            this->au = NULL;
        }
    
};
