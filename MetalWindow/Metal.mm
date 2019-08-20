#import <Cocoa/Cocoa.h>
#import "vector"
#import "WindowUtils.h"
#import "MetalView.h"
#import "MetalWindow.h"

class App {
    
    private:
        
        MetalWindow *win;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_source_t timer;
        unsigned int *texture = nullptr;

    public:
        
        App() {
            
            int width  = WindowUtils::$()->width;
            int height = WindowUtils::$()->height;
            
            this->texture = new unsigned int[width*height];
            for (unsigned int k=0; k<width*height; k++) this->texture[k] = 0xFF0000FF;

            this->win = new MetalWindow({@"bypass.metallib"},WindowUtils::$()->layer()+2);            
                    
             if([this->win->view() texture]) {
                [[this->win->view() texture] replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:texture bytesPerRow:width<<2];
                [this->win->view() update:
                ^(id<MTLCommandBuffer> commandBuffer){
                    dispatch_semaphore_signal(this->semaphore);
                }];
                dispatch_semaphore_wait(this->semaphore,DISPATCH_TIME_FOREVER);
                [this->win->view() cleanup];
            }
                            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
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


            /*
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
                
            [this->win setReleasedWhenClosed:NO];
            [this->win close];
            this->win = nil;
            */
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