#import <Cocoa/Cocoa.h>

bool FX = false;

class App {
    
    private:
        
        NSDockTile *dock=[[NSApplication sharedApplication] dockTile];
        NSImageView *view=[[NSImageView alloc] init];
 
        NSImage *img;
        NSBitmapImageRep *bmp;
        
    public:
        
        App() {
            
            id menu = [[NSMenu alloc] init];
            id rootMenuItem = [[NSMenuItem alloc] init];
            [menu addItem:rootMenuItem];
            id appMenu = [[NSMenu alloc] init];
            id quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
            [appMenu addItem:quitMenuItem];
            [rootMenuItem setSubmenu:appMenu];
            [NSApp setMainMenu:menu];
            
            // Change icon dynamically
            
            int width = 512;
            int height = 512;
            
            bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:NULL bitsPerPixel:NULL];
            
            
            for(int i=16; i<height-32; i++) {
                unsigned int *dst = (unsigned int *)[bmp bitmapData];
                int row = [bmp bytesPerRow]>>2;
                for(int j=16; j<width-32; j++) {
                    dst[i*row+j] = 0xFFFF0000;
                }
            }
            
            img = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
            [img addRepresentation:bmp];
            [view setImage:img];
            [dock setContentView:view];
            [dock display];
           
        }
        
        ~App() {
            
            [view setImage:nil];
            [img removeRepresentation:bmp];
        
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
-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSLog(@"%@",filename);
    
    FX = true;
    
    
    return YES;
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