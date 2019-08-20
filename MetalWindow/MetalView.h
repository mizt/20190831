#import <MetalKit/MetalKit.h>
#import <vector>

@interface MetalView:NSView
-(id)initWithFrame:(CGRect)frame :(std::vector<NSString *>)shaders;
-(void)update:(void (^)(id<MTLCommandBuffer>))onComplete;
-(bool)reloadShader:(dispatch_data_t)data :(unsigned int)index;
-(void)mode:(unsigned int)n;
-(id<MTLTexture>)texture;
-(id<MTLTexture>)map;
-(id<MTLTexture>)drawableTexture;
-(void)cleanup;
@end
