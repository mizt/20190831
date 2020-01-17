#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>


class App {
    
    private:

#ifdef ENTER_FRAME
        dispatch_source_t timer;
#endif
                
    public:
        
        App() {
            
#ifdef ENTER_FRAME
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/60)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
#endif

                double then = CFAbsoluteTimeGetCurrent();

                int width  = 1920;
                int height = 1080;
                
                NSString *path = @"./default.metallib";
                    
                NSFileManager *fileManager = [NSFileManager defaultManager];
                    
                if([fileManager fileExistsAtPath:path]) {
                                        
                    unsigned int *data = new unsigned int[width*height];

                     id<MTLDevice> device = MTLCreateSystemDefaultDevice();
                        __block id<MTLLibrary> library;
                        
                    dispatch_fd_t fd = open([path UTF8String],O_RDONLY);
                    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
                    long size = [[attributes objectForKey:NSFileSize] integerValue];
                        
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    dispatch_read(fd,size,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(dispatch_data_t d, int e) {
                        
                        library = [device newLibraryWithData:d error:nil];
                        close(fd);
                        dispatch_semaphore_signal(semaphore);

                    });

                    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
                        
                    id<MTLFunction> function = [library newFunctionWithName:@"processimage"];
                    id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:function error:nil];                        
                    id<MTLCommandQueue> queue = [device newCommandQueue];
                        
                    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
                    descriptor.usage = MTLTextureUsageShaderWrite|MTLTextureUsageShaderRead;
                        
                    id<MTLTexture> texture[2] = {
                        [device newTextureWithDescriptor:descriptor],
                        [device newTextureWithDescriptor:descriptor]
                    };
                    
                    NSLog(@"%@",);
                    
                    [texture[0] replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:data bytesPerRow:width<<2];
                        
                    id<MTLCommandBuffer> commandBuffer = queue.commandBuffer;
                    id<MTLComputeCommandEncoder> encoder = commandBuffer.computeCommandEncoder;
                    [encoder setComputePipelineState:pipelineState];
                    [encoder setTexture:texture[0] atIndex:0];
                    [encoder setTexture:texture[1] atIndex:1];
                        
                    MTLSize threadGroupSize = MTLSizeMake(32,32,1);
                    MTLSize threadGroups = MTLSizeMake(std::ceil((float)(texture[1].width/threadGroupSize.width)),std::ceil((float)(texture[1].height/threadGroupSize.height)),1);
                        
                    [encoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
                    [encoder endEncoding];
                    [commandBuffer commit];
                    [commandBuffer waitUntilCompleted];
                    
                    [texture[1] getBytes:data bytesPerRow:width<<2 fromRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0];
                                            
                    double current = CFAbsoluteTimeGetCurrent();
                    NSLog(@"%f",current-then);
                    
                        
                    texture[0] = nil;
                    texture[1] = nil;
                    
                    
                    delete[] data;
                   
                    
                    
                }
                
#ifdef ENTER_FRAME
            });
            if(this->timer) dispatch_resume(this->timer);
#endif
            
        }
        
        
        ~App() {
#ifdef ENTER_FRAME
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
#endif
        }
};

@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *m;
    NSTimer *timer;
    double then;
}
@end

@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    m = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    if(m) delete m;
}
@end

int main (int argc, const char * argv[]) {
    id app = [NSApplication sharedApplication];
    id delegat = [AppDelegate alloc];
    [app setDelegate:delegat];
    [app run];
    return 0;
}