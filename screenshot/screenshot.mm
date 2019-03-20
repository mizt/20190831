#import <Foundation/Foundation.h>
#import "Menu.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
namespace stb_image {
    #import "./stb_image_write.h"
}
#pragma clang diagnostic pop

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        CGRect rect = CGRectMake(0,0,128,128);
        
        CGImageRef imgRef = CGWindowListCreateImage(rect,kCGWindowListOptionAll,kCGNullWindowID,kCGWindowImageDefault);
                            
        CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(imgRef));
        int w = (int)CGImageGetWidth(imgRef);
        int h = (int)CGImageGetHeight(imgRef);
        int rows = ((int)CGImageGetBytesPerRow(imgRef))>>2;
        
        unsigned int *src = (unsigned int *)CFDataGetBytePtr(data);
        unsigned int *dst = new unsigned int[w*h];
            
        for(int i=0; i<h; i++) {
            unsigned int *tmp = src+i*(rows);
            for(int j=0; j<w; j++) {
                
                unsigned int abgr = 0xFF000000;
                abgr |= (*tmp>>16)&0xFF;
                abgr |= *tmp&0xFF00;
                
                dst[i*w+j] = abgr|((*tmp++)&0xFF)<<16;
            }
        }
        
        stb_image::stbi_write_png([[NSString stringWithFormat:@"%@/dst.png",[[NSBundle mainBundle] bundlePath]] UTF8String],w,h,4,(void const*)dst,w<<2);
        
        CFRelease(data);
        CGImageRelease(imgRef);
        delete[] dst;

    }
}