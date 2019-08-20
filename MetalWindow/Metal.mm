#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

#import "vector"
#import "WindowUtils.h"
#import "MetalWindow.h"

class App {
    
    private:
        
        MetalWindow *win;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_source_t timer;
        
        unsigned int *texture = nullptr;
        
        int width  = WindowUtils::$()->width;
        int height = WindowUtils::$()->height;

    public:
        
        App() {
            
            this->texture = new unsigned int[width*height];
            for(unsigned int k=0; k<width*height; k++) this->texture[k] = 0xFFFF0000;

            this->win = new MetalWindow();            
                            
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