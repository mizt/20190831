#import <Cocoa/Cocoa.h>
#import "TurboJpeg.h"

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
        
         for(int i=0; i<height; i++) {
            unsigned char *src = jpg+i*width*3;
            unsigned int *dst = ((unsigned int *)[bmp bitmapData]+i*([bmp bytesPerRow]>>2));
            for(int j=0; j<width; j++) {
                unsigned char r = *src++;
                unsigned char g = *src++;
                unsigned char b = *src++;
                *dst++ = 0xFF000000|b<<16|g<<8|r;
            }
        }
            
    }  
    return self;
}
- (void)drawRect:(NSRect)rect {
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
        
        NSWindow *win;
    
    public:
        
        App() {
            
            int w = 128;
            int h = 128;
            int ch = 3;
            
            unsigned char *dst = new unsigned char[w*h*ch]; 
            TurboJpeg::load([NSString stringWithFormat:@"%@/blue.jpg",[[NSBundle mainBundle] bundlePath]],dst,w,h,ch);
            ImageView *view = [[ImageView alloc] init:dst :CGRectMake(0,0,w,h)];           
            this->win = [[NSWindow alloc] initWithContentRect:CGRectMake(0,0,w,h) styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
            [[this->win contentView] addSubview:view];
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
            
        }
        
        ~App() {
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
