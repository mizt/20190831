#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <vector>
#import "MetalLayer.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
namespace stb_image {
    #import "stb_image.h"
}
#pragma clang diagnostic pop

namespace Plane {
    static const int TEXCOORD_SIZE = 4;
    static const float texcoord[TEXCOORD_SIZE][2] = {
        { 0.f, 0.f },
        { 1.f, 0.f },
        { 1.f, 1.f },
        { 0.f, 1.f }
    };
}

class TextureMetalLayer : public MetalLayer {
    
    private:
        
        id<MTLBuffer> _resolutionBuffer;
        
        id<MTLTexture> _texture;
        id<MTLBuffer> _texcoordBuffer;

        std::vector<id<MTLBuffer>> _argumentEncoderBuffer;

    public:
        
        id<MTLTexture> texture() { 
            return this->_texture; 
        }
        
        void texture(id<MTLTexture> texture) { 
            this->_texture = texture; 
        }
        
        bool setup() {
            
            MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:this->_width height:this->_height mipmapped:NO];
            if(!texDesc) return false;
            
            this->_texture = [_device newTextureWithDescriptor:texDesc];
            if(!this->_texture) return false;
            
            this->_resolutionBuffer = [this->_device newBufferWithLength:sizeof(float)*2 options:MTLResourceOptionCPUCacheModeDefault];
            if(!this->_resolutionBuffer) return false;
            
            float *resolutionBuffer = (float *)[this->_resolutionBuffer contents];
            resolutionBuffer[0] = this->_width;
            resolutionBuffer[1] = this->_height;
            
            if(MetalLayer::setup()==false) return false;
            
            this->_texcoordBuffer = [this->_device newBufferWithBytes:Plane::texcoord length:Plane::TEXCOORD_SIZE*sizeof(float)*2 options:MTLResourceOptionCPUCacheModeDefault];
            if(!this->_texcoordBuffer) return false;
            
            for(int k=0; k<this->_library.size(); k++) {
                this->_argumentEncoderBuffer.push_back([this->_device newBufferWithLength:sizeof(float)*[this->_argumentEncoder[k] encodedLength] options:MTLResourceOptionCPUCacheModeDefault]);
            
                [this->_argumentEncoder[k] setArgumentBuffer:this->_argumentEncoderBuffer[k] offset:0];
                
                [this->_argumentEncoder[k] setBuffer:this->_resolutionBuffer offset:0 atIndex:0];
                [this->_argumentEncoder[k] setTexture:this->_texture atIndex:1];
            }
                        
            return true;
        } 
        
        id<MTLCommandBuffer> setupCommandBuffer(int mode) {
                        
            id<MTLCommandBuffer> commandBuffer = [this->_commandQueue commandBuffer];
            MTLRenderPassColorAttachmentDescriptor *colorAttachment = this->_renderPassDescriptor.colorAttachments[0];
            colorAttachment.texture = this->_metalDrawable.texture;
            colorAttachment.loadAction  = MTLLoadActionClear;
            colorAttachment.clearColor  = MTLClearColorMake(0.0f,0.0f,0.0f,0.0f);
            colorAttachment.storeAction = MTLStoreActionStore;
            
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:this->_renderPassDescriptor];
            [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
            [renderEncoder setRenderPipelineState:this->_renderPipelineState[mode]];
            [renderEncoder setVertexBuffer:this->_verticesBuffer offset:0 atIndex:0];
            [renderEncoder setVertexBuffer:this->_texcoordBuffer offset:0 atIndex:1];
            
            [renderEncoder useResource:this->_resolutionBuffer usage:MTLResourceUsageRead];
            [renderEncoder useResource:this->_texture usage:MTLResourceUsageSample];
            [renderEncoder setFragmentBuffer:this->_argumentEncoderBuffer[mode] offset:0 atIndex:0];
            
            [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:Plane::INDICES_SIZE indexType:MTLIndexTypeUInt16 indexBuffer:this->_indicesBuffer indexBufferOffset:0];
            
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:this->_metalDrawable];
            this->_drawabletexture = this->_metalDrawable.texture;
            return commandBuffer;
        }
        
        TextureMetalLayer() {
            
        }
        
        ~TextureMetalLayer() {
            
        }
};

class App {
    
    private:
        
        NSWindow *_win;
        NSView *_view;
        
        int _width  = 0;
        int _height = 0;
        
        TextureMetalLayer *_layer[2];

        dispatch_source_t _timer;
        
        int _radius = 400;
        
        unsigned int *_input;
        unsigned int *_blur;
        
        unsigned int *_buffer;
        
        dispatch_group_t _group = dispatch_group_create();
        dispatch_queue_t _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);

        void blur(unsigned int *dst,unsigned int *src,int w,int h,unsigned int radius=100) {
            
            int max = (((w<h)?h:w)-1)>>1;
            if(radius>=max) radius = max;
            
            int j2 = 0;
            
            unsigned int p;
            
            double coeff = 1.0/(radius*radius+2*radius+1);
            
            unsigned char r = 0;
            unsigned char g = 0;
            unsigned char b = 0;
                
            int then_r = 0;
            int then_g = 0;
            int then_b = 0;
            
            int mw = (w<<1)-1;
            
            for(int i=0; i<h; i++) {
                
                int sum_r = 0;
                int sum_g = 0;
                int sum_b = 0;
                
                int left_r = 0;
                int left_g = 0;
                int left_b = 0;
                
                int right_r = 0;
                int right_g = 0;
                int right_b = 0;
                
                unsigned int *head = src+i*w;
                
                // L
                for(int k=-radius; k<0; k++) {
                    
                    int num = (radius+k)+1;

                    j2 = k-1;
                    if(j2<0) j2=-j2;
                    
                    p = *(head+j2);
                    
                    r=(p&0xFF);
                    g=(p&0xFF00)>>8;
                    b=(p&0xFF0000)>>16;
                    
                    left_r+=r;
                    left_g+=g;
                    left_b+=b;
                    
                    sum_r+=r*num;
                    sum_g+=g*num;
                    sum_b+=b*num;
                }
                
                // R
                for(int k=1; k<=radius; k++) {
                    
                    int num = (radius-k)+1;
                    
                    j2 = k-1;
                    if(j2>=w) j2 = mw-j2;
                    
                    p = *(head+j2);

                    r=(p&0xFF);
                    g=(p&0xFF00)>>8;
                    b=(p&0xFF0000)>>16;
                    
                    right_r+=r;
                    right_g+=g;
                    right_b+=b;
                    
                    sum_r+=r*num;
                    sum_g+=g*num;
                    sum_b+=b*num;
                }

                p = *(head+1);
                
                then_r = (p&0xFF);
                then_g = (p&0xFF00)>>8;
                then_b = (p&0xFF0000)>>16;
                
                left_r+=then_r;
                left_g+=then_g;
                left_b+=then_b;
                
                right_r+=then_r;
                right_g+=then_g;
                right_b+=then_b;
                
                sum_r+=then_r*(radius+1);
                sum_g+=then_g*(radius+1);
                sum_b+=then_b*(radius+1);

                for(int j=0; j<w; j++) {                    
                   
                    // R
                    right_r-=then_r;
                    right_g-=then_g;
                    right_b-=then_b;
                    
                    j2 = j+radius;
                    if(j2>=w) j2 = mw-j2;
                    p = *(head+j2);
                    
                    right_r+=(p&0xFF);
                    right_g+=(p&0xFF00)>>8;
                    right_b+=(p&0xFF0000)>>16;
                    
                    // sum
                    sum_r+=right_r;
                    sum_g+=right_g;
                    sum_b+=right_b;
                    
                    sum_r-=left_r;
                    sum_g-=left_g;
                    sum_b-=left_b;
                    
                    // L
                    j2 = j-radius-1;
                    if(j2<0) j2=-j2;
                    p = *(head+j2);
                    
                    left_r-=(p&0xFF);
                    left_g-=(p&0xFF00)>>8;
                    left_b-=(p&0xFF0000)>>16;
                    
                    p = *(head+j);
                    
                    then_r = (p&0xFF);
                    then_g = (p&0xFF00)>>8;
                    then_b = (p&0xFF0000)>>16;
                    
                    left_r+=then_r;
                    left_g+=then_g;
                    left_b+=then_b;
                    
                    r = (sum_r*coeff);
                    g = (sum_g*coeff);
                    b = (sum_b*coeff);
                                
                    *dst++ = b<<16|g<<8|r;   
                    
                                 

                }
            }
        }
        
    public:
        
        App() {
            
            int bpp;
            unsigned char *tmp = stb_image::stbi_load("./test.png",&this->_width,&this->_height,&bpp,4);
        
            if(bpp==3||bpp==4) {
                this->_input = (unsigned int *)tmp;
            }
            else {           
                NSLog(@"Error");     
                return;
            }
            CGRect rect = CGRectMake(0,0,this->_width,this->_height);
            this->_win = [[NSWindow alloc] initWithContentRect:rect styleMask:1 backing:NSBackingStoreBuffered defer:NO];
            this->_view = [[NSView alloc] initWithFrame:rect];
        
            this->_blur  = new unsigned int[this->_width*this->_height];
            this->_buffer = new unsigned int[this->_width*this->_height];

            this->_layer[0] = new TextureMetalLayer();
            if(this->_layer[0]->init(this->_width,this->_height,{@"xy.metallib"})) {
                this->_layer[1] = new TextureMetalLayer();
                if(this->_layer[1]->init(this->_width,this->_height,{@"yx.metallib"})) {
                    [this->_view setWantsLayer:YES];
                    this->_view.layer = this->_layer[1]->layer();
                    [[this->_win contentView] addSubview:this->_view];
                }
            }     
                   
            this->_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->_timer,dispatch_time(0,0),(1.0/30.0)*1000000000,0);
            dispatch_source_set_event_handler(this->_timer,^{
                
                double then = CFAbsoluteTimeGetCurrent();
                
                NSPoint mouseLoc = [NSEvent mouseLocation];
                this->_radius = 1 + mouseLoc.x*0.25;
                                                   
                if(this->_layer[0]->isInit()) {
                    
                    dispatch_group_async(this->_group,this->_queue,^{
                        this->blur(this->_blur,this->_input,this->_width,(this->_height>>2),this->_radius);
                    });
                    dispatch_group_async(this->_group,this->_queue,^{
                        int o = this->_width*(this->_height>>2);
                        this->blur(this->_blur+o,this->_input+o,this->_width,this->_height>>2,this->_radius);
                    });
                    dispatch_group_async(this->_group,this->_queue,^{
                        int o = this->_width*(this->_height>>2)*2;
                        this->blur(this->_blur+o,this->_input+o,this->_width,this->_height>>2,this->_radius);
                    });
                    
                    dispatch_group_async(this->_group,this->_queue,^{
                        int o = this->_width*(this->_height>>2)*3;
                        blur(this->_blur+o,this->_input+o,this->_width,this->_height-(this->_height>>2)*3,this->_radius);
                    });
                    dispatch_group_wait(this->_group,DISPATCH_TIME_FOREVER);
                                                                         
                    [this->_layer[0]->texture() replaceRegion:MTLRegionMake2D(0,0,this->_width,this->_height) mipmapLevel:0 withBytes:this->_blur bytesPerRow:this->_width<<2];
                        
                    this->_layer[0]->update(^(id<MTLCommandBuffer> commandBuffer) {
                        
                        [this->_layer[0]->drawableTexture() getBytes:this->_buffer bytesPerRow:(this->_width<<2) fromRegion:MTLRegionMake2D(0,0,this->_width,this->_height) mipmapLevel:0];
                        this->_layer[0]->cleanup(); 
                    });
                }
                
                if(this->_layer[1]->isInit()) {
                    
                    dispatch_group_async(this->_group,this->_queue,^{
                        this->blur(this->_blur,this->_buffer,this->_height,(this->_width>>2),this->_radius);
                    });

                    dispatch_group_async(this->_group,this->_queue,^{
                        int o = (this->_width>>2)*this->_height;
                        this->blur(this->_blur+o,this->_buffer+o,this->_height,(this->_width>>2),this->_radius);
                    });
                    
                     dispatch_group_async(this->_group,this->_queue,^{
                        int o = (this->_width>>2)*2*this->_height;
                        this->blur(this->_blur+o,this->_buffer+o,this->_height,(this->_width>>2),this->_radius);
                    });
                                        
                    dispatch_group_async(this->_group,this->_queue,^{
                        int o = (this->_width>>2)*3*this->_height;
                        this->blur(this->_blur+o,this->_buffer+o,this->_height,this->_width-(this->_width>>2)*3,this->_radius);
                    });
 
                    dispatch_group_wait(this->_group,DISPATCH_TIME_FOREVER);
                        
                    [this->_layer[1]->texture() replaceRegion:MTLRegionMake2D(0,0,this->_width,this->_height) mipmapLevel:0 withBytes:this->_blur bytesPerRow:this->_width<<2];
                                        
                    this->_layer[1]->update(^(id<MTLCommandBuffer> commandBuffer) {
                        this->_layer[1]->cleanup();                                                
                    });    
                }
                            
                NSLog(@"ENTER_FRAME %f",CFAbsoluteTimeGetCurrent()-then);
                
                static dispatch_once_t oncePredicate;
                dispatch_once(&oncePredicate,^{
                    dispatch_async(dispatch_get_main_queue(),^{
                        [this->_win center];
                        [this->_win makeKeyAndOrderFront:nil];
                    });
                });
                
            });
            if(this->_timer) dispatch_resume(this->_timer);                
        }
        
        ~App() {
            
            if(this->_timer){
                dispatch_source_cancel(this->_timer);
                this->_timer = nullptr;
            }
                
            [this->_win setReleasedWhenClosed:NO];
            [this->_win close];
            this->_win = nil;
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