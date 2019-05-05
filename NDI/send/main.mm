#import <Cocoa/Cocoa.h>
#import <cstdio>
#import <cstdlib>
#import <cstring>
#import <chrono>
#import <Processing.NDI.Lib.h>

class App {
    
    private:
    
        NDIlib_send_instance_t pNDI_send;
        NDIlib_video_frame_v2_t NDI_video_frame;
    
        dispatch_source_t timer;
        double then = CFAbsoluteTimeGetCurrent();
    
        int frame = 0;
    
    public:
    
        App() {
            
            if(NDIlib_initialize()) {
                
                this->pNDI_send = NDIlib_send_create();
                if(this->pNDI_send) {
                    
                    this->NDI_video_frame.xres = 1920;
                    this->NDI_video_frame.yres = 1080;
                    this->NDI_video_frame.FourCC = NDIlib_FourCC_type_RGBA;
                    this->NDI_video_frame.frame_rate_N = 30000;
                    this->NDI_video_frame.frame_rate_D = 1000;
                    this->NDI_video_frame.p_data = (uint8_t*)malloc((this->NDI_video_frame.xres*this->NDI_video_frame.yres)<<2);
                    this->NDI_video_frame.line_stride_in_bytes = 1920<<2;
                    this->NDI_video_frame.frame_format_type = NDIlib_frame_format_type_progressive;
                    
                    this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
                    dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30)*1000000000,0);
                    dispatch_source_set_event_handler(this->timer,^{
                        double current = CFAbsoluteTimeGetCurrent();
                        NSLog(@"ENTER_FRAME %f",current-this->then);
                        this->then = current;
                        
                        int width  = this->NDI_video_frame.xres;
                        int height = this->NDI_video_frame.yres;
                        
                        unsigned int *p = (unsigned int *)this->NDI_video_frame.p_data;
                        
                        if(this->frame&1) {
                            for(int i=0; i<height; i++) {
                                int r = 255.*(i/(double)(height-1));
                                for(int j=0; j<width; j++) {
                                    int b = 255.*(j/(double)(width-1));
                                    p[i*width+j] =  0xFF000000|r<<16|b;
                                }
                            }
                        }
                        else {
                            for(int i=0; i<height; i++) {
                                int r = 255.*(i/(double)(height-1));
                                for(int j=0; j<width; j++) {
                                    int b = 255.*(j/(double)(width-1));
                                    p[i*width+j] =  0xFF000000|(~(r<<16|b));
                                }
                            }
                        }
                        
                        this->frame++;
                        
                        NDIlib_send_send_video_v2(pNDI_send,&this->NDI_video_frame);
                        
                    });
                    if(this->timer) dispatch_resume(this->timer);
                    
                }
            }
        }
    
        ~App() {
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
            
            // Free the video frame
            free(this->NDI_video_frame.p_data);
            
            // Destroy the NDI sender
            NDIlib_send_destroy(this->pNDI_send);
            
            // Not required, but nice
            NDIlib_destroy();
        }
};

@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *m;
    double then;
}
@end

@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    m = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    if(m) delete m;
}
@end

int main (int argc, const char * argv[]) {
    id app = [NSApplication sharedApplication];
    id delegat = [AppDelegate alloc];
    [app setDelegate:delegat];
    [app run];
    return 0;
}
