#import <Cocoa/Cocoa.h>
#import "jpeglib.h"

namespace Item {
    int target = 0;
    int frame  = 0;
    int speed  = -1;
};

void decode(FILE *file,unsigned char *dst,int w,int h,int ch) {
    
    struct jpeg_error_mgr err;
    struct jpeg_decompress_struct info;
    
    info.err = jpeg_std_error(&err);
    jpeg_create_decompress(&info);
    
    jpeg_stdio_src(&info,file);
    jpeg_read_header(&info,true);
    
    if(w==info.image_width&&h==info.image_height&&ch==info.num_components) {
        
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

#import "Banana.h"

@interface ImageView : NSImageView {
    NSImage *img;
    NSBitmapImageRep *bmp;
    int width, height;
}
@end
@implementation ImageView
-(id)init:(unsigned char *)jpg :(NSRect)rect {
    self = [super initWithFrame:rect];
    if(self) {
        if(self == nil) return nil;
        width  = rect.size.width;
        height = rect.size.height;
        bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:NULL bitsPerPixel:NULL];
        img = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
        [img addRepresentation:bmp];
        [self update:jpg];
    }
    return self;
}
-(void)update:(unsigned char *)jpg {
    for(int i=0; i<height; i++) {
        unsigned char *src = jpg+i*width;//*3;
        unsigned int *dst = ((unsigned int *)[bmp bitmapData]+i*([bmp bytesPerRow]>>2));
        for(int j=0; j<width; j++) {
            unsigned char gris = *src++;
            *dst++ = 0xFF000000|gris<<16|gris<<8|gris;
        }
    }
    [self display];
}

-(void)drawRect:(NSRect)rect {
    NSLog(@"drawRect:");
    [img drawInRect:CGRectMake(0,0,width,height)];
}

-(void)dealloc {
    [img removeRepresentation:bmp];
    img = nil;
    bmp = nil;
}
@end

class App {
    
    private:
    
        dispatch_source_t timer;
    
        NSWindow *win;
        ImageView *view;
    
        unsigned char *dst = nullptr;
        int w = 320;
        int h = 176;
        int ch = 1;
    
        void next() {
            
            if(this->dst==nullptr) {
                this->dst  = new unsigned char[w*h*ch];
            }
            
            BaseItem *item = nullptr;
            
            if(Item::target==0) item = Banana::$();
            
            if(item) {
                
                Item::frame += Item::speed;
                if(Item::frame>=item->num) {
                    Item::frame-=item->num;
                }
                else if(Item::frame<0) {
                    Item::frame+=item->num;
                }
                
                FILE *file = fmemopen(item->data+item->capter[Item::frame][0],item->capter[Item::frame][1],"rb");
                decode(file,this->dst,this->w,this->h,1);
                fclose(file);
            }
            
        }
    
    public:
    
        App() {
            
            this->next();
            
            this->view = [[ImageView alloc] init:this->dst :CGRectMake(0,0,this->w,this->h)];
            this->win = [[NSWindow alloc] initWithContentRect:CGRectMake(0,0,this->w,this->h) styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            [[this->win contentView] addSubview:this->view];
            [this->win center];
            
            

            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                dispatch_async(dispatch_get_main_queue(),^{
                    this->next();
                    [this->view update:this->dst];
                });
                
            });
            if(this->timer) dispatch_resume(this->timer);
            
            [this->win makeKeyAndOrderFront:nil];
            
        }
    
        ~App() {
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
            
            [this->view removeFromSuperview];
            
            [this->win setReleasedWhenClosed:NO];
            [this->win close];
            this->win = nil;
            
            delete[] this->dst;
            
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
