#import <MetalKit/MetalKit.h>
#import <vector>

@interface MetalView:NSView
-(id)initWithFrame:(CGRect)frame :(std::vector<NSString *>)shaders :(bool)isGetbyte;
-(id)initWithFrame:(CGRect)frame :(std::vector<NSString *>)shaders;
-(id)initWithFrame:(CGRect)frame;
-(void)update:(void (^)(id<MTLCommandBuffer>))onComplete;
-(bool)reloadShader:(dispatch_data_t)data :(unsigned int)index;
-(void)mode:(unsigned int)n;
-(id<MTLTexture>)drawableTexture;
-(void)cleanup;
-(void)resize:(CGRect)frame;
@end
