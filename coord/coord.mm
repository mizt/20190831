#import <Cocoa/Cocoa.h>
#import "MetalView.h"

#define WIDTH  1920
#define HEIGHT 1080 

class App {
    
    private:
        
        NSWindow *win;
        MetalView *view;
        
        dispatch_source_t timer;
        unsigned int *abgr = nullptr;        
        
    public:
        
        App() {
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->abgr = new unsigned int[WIDTH*HEIGHT]; 
        
            for(int i=0; i<HEIGHT; i++) {
                for(int j=0; j<WIDTH; j++) {             
                    this->abgr[i*WIDTH+j] = 0xFF000000|((i)&0xFF)<<16|(j&0xF)<<12|((i>>8)&0xF)<<8|((j>>4)&0xFF);
                }
            }
         
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[MetalView alloc] initWithFrame:CGRectMake(0,0,WIDTH,HEIGHT) :{@"coord.metallib"} :false];
            [this->view resize:rect];
            [[this->win contentView] addSubview:this->view];
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                
                id<MTLTexture> texture = [this->view texture];
                int width  = (int)texture.width;
                int height = (int)texture.height;
                
                [texture replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:this->abgr bytesPerRow:width<<2];
                  
                [this->view update:
                ^(id<MTLCommandBuffer> commandBuffer){
                    
                    double x = this->win.frame.origin.x;
                    double y = this->win.frame.origin.y;
                              
                    NSPoint mouseLoc = [NSEvent mouseLocation];
                    int mx = (mouseLoc.x-x)*((WIDTH -1)/((double)(rect.size.width-1)));
                    int my = (mouseLoc.y-y)*((HEIGHT-1)/((double)(rect.size.height-1)));
                    
                    if(mx<0) mx = 0;
                    if(my<0) my = 0;
                    if(mx>WIDTH-1) mx = WIDTH-1;
                    if(my>HEIGHT-1) my = HEIGHT-1;
                    
                    unsigned int coord;
                                        
                    [[this->view drawableTexture] getBytes:&coord bytesPerRow:(width<<2) fromRegion:MTLRegionMake2D(mx,my,1,1) mipmapLevel:0];
                
                    NSLog(@"%d,%d,%d,%d",mx,my,(coord>>12)&0xFFF,coord&0xFFF);
                    
                    [this->view cleanup];
                }];
                
                static dispatch_once_t oncePredicate;
                dispatch_once(&oncePredicate,^{
                    dispatch_async(dispatch_get_main_queue(),^{
                        [this->win center];
                        [this->win makeKeyAndOrderFront:nil];
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
            
            delete[] this->abgr;
            this->abgr = nullptr;
                
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