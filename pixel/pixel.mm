#import <Cocoa/Cocoa.h>
#import "../Metal/MetalView.h"

#define WIDTH  1920
#define HEIGHT 1080 

class App {
    
    private:
        
        NSWindow *win;
        MetalView *view;
        
        dispatch_source_t timer;
        
        unsigned int *buffer = nullptr;
        
    public:
        
        App() {
            
            this->buffer = new unsigned int[WIDTH*HEIGHT];            
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"../common/bypass.metallib"}];
            [this->view setFrame:rect];
            [this->view mode:0];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                if(this->buffer){
                    
                    id<MTLTexture> texture = [this->view texture];
                    int width  = (int)texture.width;
                    int height = (int)texture.height;
                    
                    for(int i=0; i<height; i++) {
                        int r = 255.*(i/(double)(height-1));
                        for(int j=0; j<width; j++) {
                            int b = 255.*(j/(double)(width-1));
                            this->buffer[i*width+j] =  0xFF000000|r<<16|b;
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
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
            
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