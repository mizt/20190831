namespace TurboJpeg {

    #include "jpeglib.h"
  
    struct jpeg_decompress_struct info;

    void load(NSString *filename,unsigned char *dst,int w,int h,int ch) {
        
        FILE *file = fopen([filename UTF8String],"rb");
        struct jpeg_error_mgr err;
        
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