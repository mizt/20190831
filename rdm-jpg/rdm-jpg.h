#include "jpeglib.h"

namespace RDM {    
    
    enum MODE {
        GOLDEN = 0,
        GOLDEN_MV = 1,
        INTER = 2,
        INTER_MV = 3,
        INTRA = 4
    };
    
    class JPG {
        
        private:
            
            static const int SHIFT = 3;
            static const int CH = 3;
            static const int KEYFRAME_INTERVAL = 2;
            
            CGRect rect;
            
            int w;
            int h;
            
            int size;
            
            int frame = 0;
            
            unsigned char *golden = nullptr;
            unsigned char *inter = nullptr;
            unsigned int *intra = nullptr;
                        
            unsigned char *residual = nullptr;
            
            unsigned char *df = nullptr;
            unsigned char *cm = nullptr;
            char *vx  = nullptr;
            char *vy  = nullptr;
            
            void copy(unsigned char *src1, unsigned char *src2, unsigned int *dst) {
                for(int i=0; i<8; i++) {
                    unsigned char *d = (unsigned char *)(dst+i*this->w);
                    unsigned char *a = src1+(i*this->w)*CH;
                    unsigned char *b = src2+(i*this->w)*CH;
                    for(int j=0; j<8; j++) {
                        *d++ = ((*a++)+(*b++))>>1;
                        *d++ = ((*a++)+(*b++))>>1;
                        *d   = ((*a++)+(*b++))>>1;
                        d+=2;
                    }
                }
            }
        
            void copy(unsigned char *src, unsigned int *dst) {
                for(int i=0; i<8; i++) {
                    unsigned char *d = (unsigned char *)(dst+i*this->w);
                    unsigned char *s = src+(i*this->w)*CH;
                    for(int j=0; j<8; j++) {
                        *d++ = *s++;
                        *d++ = *s++;
                        *d   = *s++;
                        d+=2;
                    }
                }
            }
            
        public:
            
            JPG(unsigned int *src, int width=1920, int height=1080) {
                this->rect = CGRectMake(0,0,width,height);
                    
                this->w = (width +15)&~0xF;
                this->h = (height+15)&~0xF;
                
                this->size = (this->w>>SHIFT)*(this->h>>SHIFT);
                    
                this->residual = new unsigned char[this->w*this->h*CH];
                
                this->df = new unsigned char[this->size];
                this->cm = new unsigned char[this->size];
                this->vx = new char[this->size];
                this->vy = new char[this->size];
                
                this->golden = new unsigned char[this->w*this->h*CH];
                this->inter = new unsigned char[this->w*this->h*CH];
                this->intra = new unsigned int[this->w*this->h];
                
                unsigned char *pInter = this->inter+8*width*CH;
                unsigned char *pGolden = this->golden+8*width*CH;
                
                 for(int i=0; i<height; i++) {
                    unsigned int *tmp = src+i*width;
                        
                    for(int j=0; j<width; j++) {
                        unsigned int rgba = *tmp++;
                        
                        unsigned char r=(rgba)&0xFF;
                        unsigned char g=(rgba>>8)&0xFF;
                        unsigned char b=(rgba>>16)&0xFF;
                        
                        int luma = 263*r+516*g+100*b+16384;
                        int cb = -152*r-298*g+450*b+131072;
                        int cr = 450*r-377*g-73*b+131072;
                        
                        luma = (luma<0)?0:(luma>261120)?0xFF:(luma>>10);
                        cb = (cb<0)?0:(cb>261120)?0xFF:(cb>>10);
                        cr = (cr<0)?0:(cr>261120)?0xFF:(cr>>10);
                        
                        *pGolden++ = *pInter++ = luma;
                        *pGolden++ = *pInter++ = cb;
                        *pGolden++ = *pInter++ = cr;
                    }
                }
                
                for(int i=0; i<this->h; i++) {
                    unsigned char *pIntra = (unsigned char *)(intra+(i*this->w));
                    unsigned char *pInter = inter+(i*this->w)*CH;
                    for(int j=0; j<this->w; j++) {
                        *pIntra++ = *pInter++;
                        *pIntra++ = *pInter++;
                        *pIntra++ = *pInter++;
                        *pIntra++ = 0xFF;
                    }
                }
            }
            
            ~JPG() {
                
                delete[] this->residual;
                    
                delete[] this->df;
                delete[] this->cm;
                delete[] this->vx;
                delete[] this->vy;
                
                delete[] this->golden;
                delete[] this->inter;
                delete[] this->intra;
            }
            
            void load(const char *filename) {
                
                FILE *file = fopen(filename,"rb");
                
                struct jpeg_decompress_struct info;
                struct jpeg_error_mgr err;
                info.err = jpeg_std_error(&err);
  
                jpeg_create_decompress(&info);
                
                jpeg_save_markers(&info,JPEG_APP0+3,0xFFFF);
                jpeg_save_markers(&info,JPEG_APP0+4,0xFFFF);
                jpeg_save_markers(&info,JPEG_APP0+5,0xFFFF);
                jpeg_save_markers(&info,JPEG_APP0+6,0xFFFF);
                jpeg_save_markers(&info,JPEG_APP0+7,1);
                
                jpeg_stdio_src(&info,file);
                jpeg_read_header(&info,true);
                
                if(w==info.image_width&&h==info.image_height&&3==info.num_components) {
                    
                    unsigned int b=0;
                    
                    jpeg_saved_marker_ptr cmarker = info.marker_list;
                    while(cmarker) {
                        if(cmarker->marker==JPEG_APP0+3) {
                            if(cmarker->data_length==(this->w*this->h)>>9) b|=1;                            
                        }
                        else if(cmarker->marker==JPEG_APP0+4) {
                            if(cmarker->data_length==(this->w*this->h)>>7) b|=(1<<1);
                        }
                        else if(cmarker->marker==JPEG_APP0+5) {
                           if(cmarker->data_length==(this->w*this->h)>>6) b|=(1<<2);
                        }
                        else if(cmarker->marker==JPEG_APP0+6) {
                            if(cmarker->data_length==(this->w*this->h)>>6) b|=(1<<3);
                        }
                        cmarker=cmarker->next;
                    }
                    
                    if(b==15) {
                        cmarker = info.marker_list;
                        while(cmarker) {
                            if(cmarker->marker==JPEG_APP0+3) {
                                unsigned char *p = cmarker->data;
                                for(int k=0; k<cmarker->data_length; k++) this->df[k] = *p++;
                            }
                            else if(cmarker->marker==JPEG_APP0+4) {
                                unsigned char *p = cmarker->data;
                                for(int k=0; k<cmarker->data_length; k++) this->cm[k] = *p++;
                            }
                            else if(cmarker->marker==JPEG_APP0+5) {
                                char *p = (char *)cmarker->data;
                                for(int k=0; k<cmarker->data_length; k++) this->vx[k] = *p++;
                            }
                            else if(cmarker->marker==JPEG_APP0+6) {
                                char *p = (char *)cmarker->data;
                                for(int k=0; k<cmarker->data_length; k++) this->vy[k] = *p++;
                            }
                            /*
                            else if(cmarker->marker==JPEG_APP0+7) {
                                if(cmarker->data_length==1) NSLog(@"quality = %d",*cmarker->data);
                            }
                            */
                            
                            cmarker=cmarker->next;
                        }
                        
                         jpeg_start_decompress(&info);
                            
                        int w = info.output_width;
                        int h = info.output_height;
                        int bpp = info.num_components;
                        
                        while(info.output_scanline<h) {
                            unsigned char *rowptr = this->residual+info.output_scanline*(w*bpp);
                            jpeg_read_scanlines(&info,&rowptr,1);
                        }
                        
                        jpeg_finish_decompress(&info);
                        jpeg_destroy_decompress(&info);
                        
                        fclose(file);
                    }
                }
            }
            
            void update(id<MTLTexture> texture) {
                
                for(int i=0; i<this->h; i++) {
                    unsigned char *pIntra = (unsigned char *)(intra+(i*this->w));
                    unsigned char *pInter = inter+(i*this->w)*CH;
                    for(int j=0; j<this->w; j++) {
                        *pIntra++ = *pInter++;
                        *pIntra++ = *pInter++;
                        *pIntra   = *pInter++;
                        pIntra+=2;
                    }
                }
                
                int sw = this->w>>SHIFT;
                int sh = this->h>>SHIFT;
                
                for(int i=0; i<sh; i++) {
                    for(int j=0; j<sw; j++) {
                        
                        int i2 = i<<SHIFT;
                        int j2 = j<<SHIFT;
                        
                        int addr = i*sw+j;
                        
                        unsigned char isUpate = (this->df[(addr>>3)]>>(addr%8))&0x1;
                        unsigned char mode = (this->cm[(addr>>1)]>>(((addr&1)*4)))&0xF;
                        
                        char mvx = this->vx[addr];
                        char mvy = this->vy[addr];
                        
                        if(isUpate) {
                            
                            unsigned int *pIntra = intra + i2*this->w+j2;
                            
                            if(mode==MODE::GOLDEN) {
                                copy(
                                     golden+(i2*this->w+j2)*CH,
                                     pIntra
                                );
                            }
                            else if(mode==MODE::GOLDEN_MV) {
                                
                                int vx1 = mvx>>1;
                                int vy1 = mvy>>1;
                                
                                int vx2 = (mvx%2)?(mvx>0?1:-1):0;
                                int vy2 = (mvy%2)?(mvy>0?1:-1):0;
                                
                                if(vx2==0&&vy2==0) {
                                    copy(
                                         golden+((i2+vy1)*this->w+(j2+vx1))*CH,
                                         pIntra
                                    );
                                }
                                else {                                    
                                    copy(
                                         golden+((i2+vy1)*this->w+(j2+vx1))*CH,
                                         golden+((i2+vy1+vy2)*this->w+(j2+vx1+vx2))*CH,
                                         pIntra
                                    );
                                }
                            }
                            else if(mode==MODE::INTER_MV) {
                                
                                int vx1 = mvx>>1;
                                int vy1 = mvy>>1;
                                
                                int vx2 = (mvx%2)?(mvx>0?1:-1):0;
                                int vy2 = (mvy%2)?(mvy>0?1:-1):0;
                                
                                if(vx2==0&&vy2==0) {
                                    copy(
                                         inter+((i2+vy1)*this->w+(j2+vx1))*CH,
                                         pIntra
                                    );
                                }
                                else {                                    
                                    copy(
                                         inter+((i2+vy1)*this->w+(j2+vx1))*CH,
                                         inter+((i2+vy1+vy2)*this->w+(j2+vx1+vx2))*CH,
                                         pIntra
                                    );
                                }
                            }
                        }
                    }
                }
                
                for(int i=0; i<this->h; i++) {
                    for(int j=0; j<this->w; j++) {
                        int addr = (i>>SHIFT)*sw+(j>>SHIFT);
                        unsigned char isUpate = (this->df[(addr>>3)]>>(addr%8))&1;
                        if(isUpate) {
                            
                            unsigned char *pIntra = (unsigned char *)(intra+(i*this->w+j));
                            unsigned char mode = (this->cm[(addr>>1)]>>(((addr&1)<<2)))&0xF;
                            
                            unsigned char *yuv  = residual+(i*this->w+j)*CH;

                            int tmp = *yuv++;
                            int y = (tmp<<1)-(tmp>>7)-0xFF;
                            
                            tmp = *yuv++;
                            int u = (tmp<<1)-(tmp>>7)-0xFF;
                            
                            tmp = *yuv;
                            int v = (tmp<<1)-(tmp>>7)-0xFF;
                                                                                
                            if(mode==MODE::INTRA) {
                                
                                y += 0x80;
                                *pIntra++ = (y<0)?0:(y>0xFF)?0xFF:y;
                                u += 0x80;
                                *pIntra++ = (u<0)?0:(u>0xFF)?0xFF:u;
                                v += 0x80;
                                *pIntra = (v<0)?0:(v>0xFF)?0xFF:v;
                                
                            }
                            else {
                                y += *pIntra;
                                *pIntra++ = (y<0)?0:(y>0xFF)?0xFF:y;
                                u += *pIntra;
                                *pIntra++ = (u<0)?0:(u>0xFF)?0xFF:u;                                
                                v += *pIntra;
                                *pIntra = (v<0)?0:(v>0xFF)?0xFF:v;
                            }
                        }
                    }
                }
                
                frame++;
                if(frame%KEYFRAME_INTERVAL==0) {
                    for(int i=0; i<this->h; i++) {
                        unsigned char *pIntra  = (unsigned char *)(intra+(i*this->w));
                        unsigned char *pInter  = inter+(i*this->w)*CH;
                        unsigned char *pGolden = golden+(i*this->w)*CH;
                        
                        for(int j=0; j<this->w; j++) {
                            *pGolden++ = *pInter++ = *pIntra++;
                            *pGolden++ = *pInter++ = *pIntra++;
                            *pGolden++ = *pInter++ = *pIntra;
                            pIntra+=2;
                        }
                    }
                }
                else {
                    for(int i=0; i<this->h; i++) {
                        unsigned char *pIntra = (unsigned char *)(intra+(i*this->w));
                        unsigned char *pInter = inter+(i*this->w)*CH;
                        
                        for(int j=0; j<this->w; j++) {
                            *pInter++ = *pIntra++;
                            *pInter++ = *pIntra++;
                            *pInter++ = *pIntra;
                            pIntra+=2;
                        }
                    }
                }
                
                int width  = (int)texture.width;
                int height = (int)texture.height;
                                    
                [texture replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:this->intra+(this->h-height)*this->w bytesPerRow:this->w<<2];
                
            }
    };
}