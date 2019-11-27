/*
    usage:

    clang++ -std=c++17 -Wc++17-extensions -fobjc-arc -O3 -framework Metal -framework QuartzCore -framework Cocoa -framework CoreMedia -I./ -L./ -lspng -lz PNG.mm -o PNG
    ./PNG
*/

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "vector"
#import "MetalWindow.h"
#import "spng.h"
#import <libkern/OSByteOrder.h>
#define htobe32(x) OSSwapHostToBigInt32(x)

class App {
    
    private:
        
        MetalWindow *win;
        
        dispatch_source_t timer;
        
        unsigned int *texture = nullptr;
        
        int width  = 1280;
        int height = 720;

    public:
        
        App() {
            
            this->win = new MetalWindow();            
            
            this->width  = this->win->width();
            this->height = this->win->height();
            
            NSData *data = [[NSData alloc] initWithContentsOfFile:@"./test.png"];
            char *bytes = (char *)[data bytes];
            long size = [data length];
            
            NSLog(@"%c%c%c",bytes[1],bytes[2],bytes[3]);
            NSLog(@"%c%c%c%c",bytes[12],bytes[13],bytes[14],bytes[15]);
            NSLog(@"%d",htobe32(*((unsigned int *)(bytes+16)))); // 画像の幅
            NSLog(@"%d",htobe32(*((unsigned int *)(bytes+20)))); // 画像の高さ
            NSLog(@"%d",*(bytes+24)); // ビット深度
            NSLog(@"%d",*(bytes+25)); // カラータイプ
            NSLog(@"%d",*(bytes+26)); // 圧縮手法
            NSLog(@"%d",*(bytes+27)); // フィルター手法（0=None,1=Sub,2=Up,3=Average,4=Paeth）
            NSLog(@"%d",*(bytes+28)); // インターレース手法（0=インターレスなし、1=あり）
            
            this->texture = new unsigned int[width*height];
            
            spng_ctx *ctx = spng_ctx_new(0);
            spng_set_crc_action(ctx,SPNG_CRC_USE,SPNG_CRC_USE);
            spng_set_png_buffer(ctx,bytes,size);
            struct spng_ihdr ihdr;
            spng_get_ihdr(ctx,&ihdr);
            size_t out_size;
            spng_decoded_image_size(ctx,SPNG_FMT_RGBA8,&out_size);
            spng_decode_image(ctx,(unsigned char *)this->texture,out_size,SPNG_FMT_RGBA8,0);
            spng_ctx_free(ctx);

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
            
            delete[] this->texture;    
            
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
                
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