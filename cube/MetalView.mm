#import "MetalView.h"
#import "AAPLTransforms.h"
#import "AAPLSharedTypes.h"

using namespace AAPL;
using namespace simd;

static const NSUInteger kNumberOfBoxes = 9;

static const float kFOVY    = 60.0f;
static const float3 kEye    = {0.0f, 0.0f, 10.0f};
static const float3 kCenter = {0.0f, 0.0f, 0.0f};
static const float3 kUp     = {0.0f, 1.0f, 0.0f};

static const float kWidth  = 1.f;
static const float kHeight = 1.f;
static const float kDepth  = 1.f;

static const float kCubeVertexData[] = {
    
    kWidth, -kHeight, kDepth,   0.0, -1.0,  0.0,
    -kWidth, -kHeight, kDepth,   0.0, -1.0, 0.0,
    -kWidth, -kHeight, -kDepth,   0.0, -1.0,  0.0,
    kWidth, -kHeight, -kDepth,  0.0, -1.0,  0.0,
    kWidth, -kHeight, kDepth,   0.0, -1.0,  0.0,
    -kWidth, -kHeight, -kDepth,   0.0, -1.0,  0.0,
    
    kWidth, kHeight, kDepth,    1.0, 0.0,  0.0,
    kWidth, -kHeight, kDepth,   1.0,  0.0,  0.0,
    kWidth, -kHeight, -kDepth,  1.0,  0.0,  0.0,
    kWidth, kHeight, -kDepth,   1.0, 0.0,  0.0,
    kWidth, kHeight, kDepth,    1.0, 0.0,  0.0,
    kWidth, -kHeight, -kDepth,  1.0,  0.0,  0.0,
    
    -kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,
    -kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,
    -kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,
    
    -kWidth, -kHeight, kDepth,  -1.0,  0.0, 0.0,
    -kWidth, kHeight, kDepth,   -1.0, 0.0,  0.0,
    -kWidth, kHeight, -kDepth,  -1.0, 0.0,  0.0,
    -kWidth, -kHeight, -kDepth,  -1.0,  0.0,  0.0,
    -kWidth, -kHeight, kDepth,  -1.0,  0.0, 0.0,
    -kWidth, kHeight, -kDepth,  -1.0, 0.0,  0.0,
    
    kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,
    -kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,
    -kWidth, -kHeight, kDepth,   0.0,  0.0, 1.0,
    -kWidth, -kHeight, kDepth,   0.0,  0.0, 1.0,
    kWidth, -kHeight, kDepth,   0.0,  0.0,  1.0,
    kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,
    
    kWidth, -kHeight, -kDepth,  0.0,  0.0, -1.0,
    -kWidth, -kHeight, -kDepth,   0.0,  0.0, -1.0,
    -kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0,
    kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0,
    kWidth, -kHeight, -kDepth,  0.0,  0.0, -1.0,
    -kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0
};

@interface MetalView() {
    
    __weak CAMetalLayer *_metalLayer;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<CAMetalDrawable> _metalDrawable;
    
    id<MTLTexture> _depthTex;
    id<MTLTexture> _drawabletexture; 
    
    std::vector<id<MTLLibrary>> _library;
    std::vector<id<MTLRenderPipelineState>> _renderPipelineState;

    std::vector<id<MTLDepthStencilState>> _depthState;

    std::vector<MTLRenderPipelineDescriptor *> _renderPipelineDescriptor;
        
    CGRect _frame;
        
    bool _isGetBytes;
    
    int _mode;
    
    id<MTLBuffer> _dynamicConstantBuffer;
    id<MTLBuffer> _cubeVertexBuffer;
    
    float4x4 _projectionMatrix;
    float4x4 _viewMatrix;
    float _rotation;
        
    long _maxBufferBytesPerFrame;
    size_t _sizeOfConstantT;    
}
@end

@implementation MetalView

+(Class)layerClass { return [CAMetalLayer class]; }
-(void)mode:(unsigned int)n { _mode = n; }
-(BOOL)wantsUpdateLayer { return YES; }
-(void)updateLayer { [super updateLayer]; }
-(id<MTLTexture>)drawableTexture { return _drawabletexture; }
-(void)cleanup { _metalDrawable = nil; }

-(void)resize:(CGRect)frame {
    self.frame = frame; 
    _metalLayer.drawableSize = CGSizeMake(_frame.size.width,_frame.size.height);
}

-(void)setColorAttachment:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachment {
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.sourceAlphaBlendFactor = MTLBlendFactorOne;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOne;
}

-(bool)setupShader {
    
    _sizeOfConstantT = sizeof(constants_t);
    _maxBufferBytesPerFrame = _sizeOfConstantT*kNumberOfBoxes;
    
    float aspect = fabs(_frame.size.width/_frame.size.height);
    _projectionMatrix = perspective_fov(kFOVY,aspect,0.1f,100.0f);
    _viewMatrix = lookAt(kEye,kCenter,kUp);
    
    for(int k=0; k<_library.size(); k++) {
        
        id<MTLFunction> vertexFunction  = [_library[k] newFunctionWithName:@"vertexShader"];
        if(!vertexFunction) return nil;
        
        id<MTLFunction> fragmentFunction = [_library[k] newFunctionWithName:@"fragmentShader"];
        if(!fragmentFunction) return nil;
        
        _renderPipelineDescriptor.push_back([MTLRenderPipelineDescriptor new]);
        if(!_renderPipelineDescriptor[k]) return nil;

        _renderPipelineDescriptor[k].depthAttachmentPixelFormat      = MTLPixelFormatDepth32Float_Stencil8;
        _renderPipelineDescriptor[k].stencilAttachmentPixelFormat    = MTLPixelFormatInvalid;
        _renderPipelineDescriptor[k].colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        if(_isGetBytes) {
            _renderPipelineDescriptor[k].colorAttachments[0].blendingEnabled = NO;
        }
        else {
            [self setColorAttachment:_renderPipelineDescriptor[k].colorAttachments[0]];
        }
        
        _renderPipelineDescriptor[k].sampleCount = 1;
       
        _renderPipelineDescriptor[k].vertexFunction   = vertexFunction;
        _renderPipelineDescriptor[k].fragmentFunction = fragmentFunction;
        
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;
        _depthState.push_back([_device newDepthStencilStateWithDescriptor:depthStateDesc]);
        
        NSError *error = nil;
        _renderPipelineState.push_back([_device newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor[k] error:&error]);
        if(error||!_renderPipelineState[k]) return true;
    }
    
    _dynamicConstantBuffer = [_device newBufferWithLength:_maxBufferBytesPerFrame options:0];
    
    return false;
}

-(bool)updateShader:(unsigned int)index {
    
    if(index>=_library.size()) return true;
    
    id<MTLFunction> vertexFunction  = [_library[index] newFunctionWithName:@"vertexShader"];
    if(!vertexFunction) return nil;
    
    id<MTLFunction> fragmentFunction = [_library[index] newFunctionWithName:@"fragmentShader"];
    if(!fragmentFunction) return nil;
    
    _renderPipelineDescriptor[index].sampleCount = 1;
    _renderPipelineDescriptor[index].vertexFunction   = vertexFunction;
    _renderPipelineDescriptor[index].fragmentFunction = fragmentFunction;
    
    NSError *error = nil;
    _renderPipelineState[index] = [_device newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor[index] error:&error];
    if(error||!_renderPipelineState[index]) return true;
    
    return false;
}

-(bool)reloadShader:(dispatch_data_t)data :(unsigned int)index {
    
    NSError *error = nil;
    _library[index] = [_device newLibraryWithData:data error:&error];
    if(error||!_library[index]) return true;
    if([self updateShader:index]) return true;
    
    return false;
}

-(bool)setup:(std::vector<NSString *>)shaders :(bool)isGetBytes {

    self.wantsLayer = YES;
    self.layer = [CAMetalLayer layer];
    _metalLayer = (CAMetalLayer *)self.layer;
    _device = MTLCreateSystemDefaultDevice();
    
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.colorspace = CGColorSpaceCreateDeviceRGB();
    
    _metalLayer.opaque = NO;
    _metalLayer.framebufferOnly = NO;
    _metalLayer.displaySyncEnabled = YES;
    _metalLayer.backgroundColor = [NSColor clearColor].CGColor;
    
    _commandQueue = [_device newCommandQueue];
    if(!_commandQueue) return true;
    
    
    NSError *error = nil;
    
    for(int k=0; k<shaders.size(); k++) {
         _library.push_back([_device newLibraryWithFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],shaders[k]] error:&error]);
        if(error||!_library[_library.size()-1]) return true;
    }
    
    _isGetBytes = isGetBytes;
    _mode = 0;
    
    if([self setupShader]) return true;
    
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float_Stencil8
        width: _frame.size.width
        height: _frame.size.height
        mipmapped: NO];
    
    desc.textureType = MTLTextureType2D;
    desc.sampleCount = 1;
    desc.usage = MTLTextureUsageUnknown;
    desc.storageMode = MTLStorageModePrivate;
    desc.resourceOptions = MTLResourceStorageModePrivate;
    _depthTex = [_device newTextureWithDescriptor: desc];
    
    // setup the vertex buffers
    _cubeVertexBuffer = [_device newBufferWithBytes:kCubeVertexData length:sizeof(kCubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
 
    return false;
}

-(id)initWithFrame:(CGRect)frame :(std::vector<NSString *>)shaders :(bool)isGetBytes {
    
    if(shaders.size()==0) return nil;
    self = [super initWithFrame:frame];
    if(self) {
        _frame = frame;
       if([self setup:shaders :isGetBytes]) return nil;
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame :(std::vector<NSString *>)shaders {
    
    if(shaders.size()==0) return nil;
    self = [super initWithFrame:frame];
    if(self) {
        _frame = frame;
       if([self setup:shaders :false]) return nil;
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if(self) {
        _frame = frame;
       if([self setup:{@"default.metallib"} :false]) return nil;
    }
    return self;
}

-(id<MTLCommandBuffer>)setupCommandBuffer:(int)mode {
    
    if(!_metalDrawable) {
        _metalDrawable = [_metalLayer nextDrawable];
    }
    
    if(!_metalDrawable) {
        _renderPassDescriptor = nil;
    }
    else {
        
        if(_renderPassDescriptor == nil) {
            _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        }
    }
    
    if(_metalDrawable&&_renderPassDescriptor) {
        
        _rotation += 1.0f;
        
        constants_t *constant_buffer = (constants_t *)[_dynamicConstantBuffer contents];
        for(int i=0; i<kNumberOfBoxes; i++) {
            simd::float4x4 modelViewMatrix = _viewMatrix * (AAPL::translate(i-4,0.f,0.f)*AAPL::rotate(_rotation,0.f,0.f,1.f)*AAPL::rotate(_rotation,1.f,0.f,0.f)*AAPL::rotate(_rotation,0.f,1.f,0.f)*AAPL::scale(i*0.1,i*0.1,i*0.1));
            constant_buffer[i].normal_matrix = inverse(transpose(modelViewMatrix));
            constant_buffer[i].modelview_projection_matrix = _projectionMatrix * modelViewMatrix;
        }
                        
        MTLRenderPassColorAttachmentDescriptor *colorAttachment = _renderPassDescriptor.colorAttachments[0];
        colorAttachment.texture     = _metalDrawable.texture;
        colorAttachment.loadAction  = MTLLoadActionClear;
        colorAttachment.clearColor  = MTLClearColorMake(0.5f, 0.5f, 0.5f, 1.0f);
        colorAttachment.storeAction = MTLStoreActionStore;
        
        MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
        depthAttachment.texture     = _depthTex;
        depthAttachment.loadAction  = MTLLoadActionClear;
        depthAttachment.storeAction = MTLStoreActionDontCare;
        depthAttachment.clearDepth  = 1.0;
        
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
                        
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        [renderEncoder setDepthStencilState:_depthState[mode]];
        [renderEncoder setRenderPipelineState:_renderPipelineState[mode]];
        
        for(int i=0; i<kNumberOfBoxes; i++) {
            [renderEncoder setVertexBuffer:_cubeVertexBuffer offset:0 atIndex:0];
            [renderEncoder setVertexBuffer:_dynamicConstantBuffer offset:i*_sizeOfConstantT atIndex:1 ];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
        }
        
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:_metalDrawable];
    
    
        _drawabletexture = _metalDrawable.texture;

        return commandBuffer;
    }
    
    return nil;
}

-(void)update:(void (^)(id<MTLCommandBuffer>))onComplete {
    
    int mode = _mode;
    if(mode>=_library.size()) mode = (int)_library.size()-1;
    
    if(_renderPipelineState[mode]) {
                
        id<MTLCommandBuffer> commandBuffer = [self setupCommandBuffer:mode];
        if(commandBuffer) {
            [commandBuffer addCompletedHandler:onComplete];
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
    }
}

-(void)dealloc {
    
}

@end