#import <Cocoa/Cocoa.h>
#import "../Metal/MetalView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
namespace stb_image {
    #import "../common/stb_image.h"
}
#pragma clang diagnostic pop

#define WIDTH  1920
#define HEIGHT 1080 

class App {
    
    private:
        
        NSWindow *win;
        MetalView *view;
        
        dispatch_source_t timer;
        
        unsigned int *src = nullptr;
        unsigned int *buffer = nullptr;
        
        unsigned int *map = nullptr;
        
    public:
        
        App() {
            
            int w;
            int h;
            int bpp;
            this->src = (unsigned int *)stb_image::stbi_load("../common/test.png",&w,&h,&bpp,4);
            if(this->src&&(w==WIDTH&&h==HEIGHT&&bpp==4)) {                
                this->buffer = new unsigned int[WIDTH*HEIGHT];
            }
            else {
                delete[] this->src;
                this->src = nullptr;
            }
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"../common/bypass.metallib"}];
            [this->view setFrame:rect];
            [this->view mode:0];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                if(this->src) {
                    
                    id<MTLTexture> texture = [this->view texture];
                    int width  = (int)texture.width;
                    int height = (int)texture.height;
                    
                    double rad = (45.0)*M_PI/180.;

                    double cx =(WIDTH)*0.5;
                    double cy =(HEIGHT)*0.5;

                    double nx=cos(rad);
                    double ny=sin(rad);
                    double bx =-cx; // begin
                    double ex = cx; // end
                                        
                    for(int i=0; i<HEIGHT; i++) {
                        
                        double y = i-cy;
                        double begin = ((bx*nx)+(y*ny));
                        double end   = ((ex*nx)+(y*ny));
                        double step = (end-begin)/((double)(WIDTH-1));
                        double cnt = begin;
                        
                        for(int j=0; j<WIDTH; j++) {
                            
                            int j2= 0;
                            int i2= 0;
                            
                            if(cnt>=0.0f) {
                                j2 = j;
                                i2 = i;
                            }
                            else {
                                double x=j-cx;
                                j2=((x-(cnt*nx))+cx);
                                i2=((y-(cnt*ny))+cy);
                                j2=(j2<0)?0:(j2>=WIDTH -1)?WIDTH -1:j2;
                                i2=(i2<0)?0:(i2>=HEIGHT-1)?HEIGHT-1:i2;
                            }      
                            
                            cnt+=step;
                            
                            if(j2>=0&&i2>=0&&j2<=width-1&&i2<=height-1) {
                                this->buffer[i*WIDTH+j] = this->src[i2*WIDTH+j2];
                            }
                            else {
                                this->buffer[i*WIDTH+j] = 0xFF000000;
                            }
                            
                        }
                    }
                        
                        
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
        
        ~App() {
            
            if(this->src) {
                delete[] this->src;
                this->src = nullptr; 
            }
            
            if(this->buffer) {
                delete[] this->buffer;
                this->buffer = nullptr;
            }
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
                
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