namespace TurboJpeg {

    #include "jpeglib.h"
    #include <setjmp.h>

    typedef struct error_mgr {
        struct jpeg_error_mgr pub;
        jmp_buf setjmp_buffer;
    } *error_ptr;
  
    struct jpeg_decompress_struct cinfo;
    struct TurboJpeg::error_mgr jerr;
    
    struct jpeg_decompress_struct info;
    struct jpeg_error_mgr err;

    void load(NSString *filename,unsigned char *dst,int w,int h,int ch) {
        
        FILE *file = fopen([filename UTF8String],"rb");
        
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

            fclose(file);
        }
    }
}