#import <Cocoa/Cocoa.h>
#import "../Metal/MetalView.h"
#import "rdm-jpg.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
namespace stb_image {
    #import "../common/stb_image.h"
}
#pragma clang diagnostic pop

#define WIDTH 1920
#define HEIGHT 1080 

class App {
    
    private:
        
        NSWindow *win;
        MetalView *view;
        dispatch_source_t timer;
        unsigned int *src = nullptr;
        
        RDM::JPG *rdm;
        
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
            
            this->rdm = new RDM::JPG(src,WIDTH,HEIGHT);
            this->rdm->load("./rdm.jpg");
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"YUV2RGB.metallib"}];
            [this->view setFrame:rect];
            [this->view mode:0];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                if(src){
                    
                    id<MTLTexture> texture = [this->view texture];
                
                    this->rdm->update(texture);
                    
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