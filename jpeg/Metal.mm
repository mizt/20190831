/*
    usage:

    clang++ -std=c++17 -Wc++17-extensions -fobjc-arc -O3 -framework Metal -framework QuartzCore -framework Cocoa -framework CoreMedia -I../libs/libjpeg-turbo -L../libs/libjpeg-turbo -lturbojpeg Metal.mm -o Metal
    ./Metal
*/

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "vector"
#import "MetalWindow.h"
#include "jpeglib.h"

class App {
    
    private:
        
        MetalWindow *win;
        
        dispatch_source_t timer;
        
        unsigned int *texture = nullptr;
        
        int width  = 1280;
        int height = 720;
        
        void decode(FILE *file,unsigned char *dst,int w,int h,int ch) {
            
            struct jpeg_error_mgr err;
            struct jpeg_decompress_struct info;
            
            info.err = jpeg_std_error(&err);
            jpeg_create_decompress(&info);
            jpeg_stdio_src(&info,file);
            jpeg_read_header(&info,true);
            
            if(w==info.image_width&&h==info.image_height&&info.num_components==3) {
                                
                info.out_color_space = JCS_EXT_RGBX;
                info.out_color_components = ch;
                info.raw_data_out = false;
                
                jpeg_start_decompress(&info);
                unsigned char *ptr;
                while(info.output_scanline<h) {
                    ptr = dst+info.output_scanline*w*ch;
                    jpeg_read_scanlines(&info,&ptr,1);
                }                
                jpeg_finish_decompress(&info);
                jpeg_destroy_decompress(&info);
            }
        }
        
        void load(NSString *filename,unsigned char *dst,int w,int h,int ch) {               
            FILE *file = fopen([filename UTF8String],"rb");
            decode(file,dst,w,h,ch);
            fclose(file);
        }

    public:
        
        App() {
            
            this->win = new MetalWindow();            
            
            this->width  = this->win->width();
            this->height = this->win->height();

            this->texture = new unsigned int[width*height];
            for(unsigned int k=0; k<width*height; k++) this->texture[k] = 0xFFFF0000;
                            
            this->load([NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"test.jpg"],(unsigned char *)this->texture,this->width,this->height,4);
                         
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                                
                TextureMetalLayer *layer = win->layer();
                                
                id<MTLTexture> texture = layer->texture();
                [texture replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:this->texture bytesPerRow:width<<2];
                                                
                layer->update(^(id<MTLCommandBuffer> commandBuffer){
                    layer->cleanup();
                });
                
                static dispatch_once_t oncePredicate;
                dispatch_once(&oncePredicate,^{
                    dispatch_async(dispatch_get_main_queue(),^{
                        this->win->appear();
                    });
                });
                
            });
            if(this->timer) dispatch_resume(this->timer);
        }
        
        ~App() {            
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
                
            delete this->win;
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