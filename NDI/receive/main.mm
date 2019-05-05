#import <Cocoa/Cocoa.h>
#import "MetalView.h"
#import <cstdio>
#import <chrono>
#import <Processing.NDI.Lib.h>

#define WIDTH  1920
#define HEIGHT 1080

class App {
    
private:
    
    NSWindow *win;
    MetalView *view;
    
    dispatch_source_t timer;
    
    unsigned int *buffer = nullptr;
    
    NDIlib_find_instance_t pNDI_find  = nullptr;
   
    uint32_t no_sources = 0;
    const NDIlib_source_t* p_sources = nullptr;
    
    NDIlib_recv_instance_t pNDI_recv = nullptr;
    
public:
    
    App() {
        
        if(NDIlib_initialize()) {
            
            this->pNDI_find = NDIlib_find_create_v2();
            
            this->buffer = new unsigned int[WIDTH*HEIGHT];
            
            CGRect rect = CGRectMake(0,0,1280,720);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"bypass.metallib"}];
            [this->view resize:rect];
            [this->view mode:0];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                // Wait until there is one source
                
                if(!this->no_sources) {
                    // Wait until the sources on the nwtork have changed
                    NSLog(@"Looking for sources ...");
                    NDIlib_find_wait_for_sources(this->pNDI_find,5); // 5ms
                    this->p_sources = NDIlib_find_get_current_sources(this->pNDI_find,&this->no_sources);
                
                    if(this->no_sources) {
                        // We now have at least one source, so we create a receiver to look at it.
                        
                        NDIlib_recv_create_v3_t recv_desc;
                        recv_desc.allow_video_fields = true;
                        recv_desc.color_format = NDIlib_recv_color_format_RGBX_RGBA;
                        
                        this->pNDI_recv = NDIlib_recv_create_v3(&recv_desc);
                        
                        if(this->pNDI_recv) {
                            // Connect to our sources
                            NDIlib_recv_connect(this->pNDI_recv,this->p_sources+0);
                           
                            
                            // Destroy the NDI finder. We needed to have access to the pointers to p_sources[0]
                            NDIlib_find_destroy(this->pNDI_find);
                            
                        }
                    }
                }
                
                if(this->pNDI_recv) {
                    
                    NDIlib_video_frame_v2_t video_frame;
                    
                    switch (NDIlib_recv_capture_v2(pNDI_recv, &video_frame,nullptr,nullptr,5)) { // 5ms
                        // No data
                        case NDIlib_frame_type_none:
                            printf("No data received.\n");
                            break;
                            
                        // Video data
                        case NDIlib_frame_type_video:
                            
                            unsigned int type = video_frame.FourCC;
                            
                            NSLog(@"%c%c%c%c",type>>24,(type>>16)&0xFF,(type>>8)&0xFF,(type)&0xFF);

                            if(WIDTH==video_frame.xres&&HEIGHT==video_frame.yres&&video_frame.line_stride_in_bytes>=WIDTH<<2) {
                                
                                for(int i=0; i<HEIGHT; i++) {
                                    
                                    unsigned char *ptr = video_frame.p_data+i*video_frame.line_stride_in_bytes;
                                    
                                    for(int j=0; j<WIDTH; j++) {
                                        
                                        unsigned char r = *ptr++;
                                        unsigned char g = *ptr++;
                                        unsigned char b = *ptr++;
                                        unsigned char a = *ptr++;
                                        
                                        this->buffer[i*WIDTH+j] = a<<24|r<<16|g<<8|b;
                                    }
                                }
                            }
                            else {
                                NSLog(@"Video data received (%dx%d). %d.\n", video_frame.xres, video_frame.yres, video_frame.line_stride_in_bytes);
                            }
                            
                            NDIlib_recv_free_video_v2(this->pNDI_recv,&video_frame);
                            break;
                    }
                    
                }
                
                
                if(this->buffer) {
                    
                    id<MTLTexture> texture = [this->view texture];
                    int width  = (int)texture.width;
                    int height = (int)texture.height;
                    
                   
                    
                    [texture replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:this->buffer bytesPerRow:width<<2];
                    
                    [this->view update:
                     ^(id<MTLCommandBuffer> commandBuffer){
                         [this->view cleanup];
                     }];
                    
                    static dispatch_once_t oncePredicate;
                    dispatch_once(&oncePredicate,^{
                        dispatch_async(dispatch_get_main_queue(),^{
                            [this->win center];
                            [this->win makeKeyAndOrderFront:nil];
                        });
                    });
                }
            });
            if(this->timer) dispatch_resume(this->timer);
        }
    }
    
    ~App() {
        
        if(this->timer){
            dispatch_source_cancel(this->timer);
            this->timer = nullptr;
        }
        
        // Destroy the receiver
        NDIlib_recv_destroy(this->pNDI_recv);
        
        // Not required, but nice
        NDIlib_destroy();
        
        delete[] this->buffer;
        this->buffer = nullptr;
        
        [this->win setReleasedWhenClosed:NO];
        [this->win close];
        this->win = nil;
    }
};

#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *app;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    app = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete app;
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
