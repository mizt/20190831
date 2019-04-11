#import <Cocoa/Cocoa.h>
#import "../Metal/MetalView.h"
#import <vector>
#import "pixelsort.h"

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
        
        dispatch_group_t _group = dispatch_group_create();
        dispatch_queue_t _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
        
        std::vector<Pixelsort *> _pixelsort;
            
    public:
        
        App() {
            
            int w;
            int h;
            int bpp;
            this->src = (unsigned int *)stb_image::stbi_load("../common/test.png",&w,&h,&bpp,4);
            if(!(this->src&&(w==WIDTH&&h==HEIGHT&&bpp==4))) {
                delete[] this->src;
                this->src = nullptr;
            }
            else {
                this->buffer = new unsigned int[WIDTH*HEIGHT];
            }
            
            this->_pixelsort.push_back(new Pixelsort(WIDTH,HEIGHT>>2));
            this->_pixelsort.push_back(new Pixelsort(WIDTH,HEIGHT>>2));
            this->_pixelsort.push_back(new Pixelsort(WIDTH,HEIGHT>>2));
            this->_pixelsort.push_back(new Pixelsort(WIDTH,HEIGHT-(HEIGHT>>2)*3));
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"../common/bypass.metallib"}];
            [this->view setFrame:rect];
            [this->view mode:0];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                if(src){
                    
                    id<MTLTexture> texture = [this->view texture];
                    int width  = (int)texture.width;
                    int height = (int)texture.height;
                                        
                    dispatch_group_async(_group,_queue,^{ this->_pixelsort[0]->render((this->src+(HEIGHT>>2)*0*WIDTH),(this->buffer+(HEIGHT>>2)*0*WIDTH),WIDTH,250); });
                    dispatch_group_async(_group,_queue,^{ this->_pixelsort[1]->render((this->src+(HEIGHT>>2)*1*WIDTH),(this->buffer+(HEIGHT>>2)*1*WIDTH),WIDTH,250); });
                    dispatch_group_async(_group,_queue,^{ this->_pixelsort[2]->render((this->src+(HEIGHT>>2)*2*WIDTH),(this->buffer+(HEIGHT>>2)*2*WIDTH),WIDTH,250); });
                    dispatch_group_async(_group,_queue,^{ this->_pixelsort[3]->render((this->src+(HEIGHT>>2)*3*WIDTH),(this->buffer+(HEIGHT>>2)*3*WIDTH),WIDTH,250); });

                    dispatch_group_wait(_group,DISPATCH_TIME_FOREVER);
                                
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
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
            
            if(this->src) {
                delete[] this->src;
                delete[] this->buffer;
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