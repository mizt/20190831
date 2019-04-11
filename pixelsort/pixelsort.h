#import <algorithm>

class PixelsortBase {
    
    protected:
    
        int _width  = 0;
        int _height = 0;
    
        int *_line = nullptr;
    
        inline unsigned char gris(unsigned int bgr) {
            unsigned char tmp = (306*((bgr)&0xFF)+601*((bgr>>8)&0xFF)+116*((bgr>>8)&0xFF))>>10;
            return tmp;
        }
};

class Pixelsort : PixelsortBase {

    public:
    
        Pixelsort(int w,int h) {
            
            this->_width  = w;
            this->_height = h;
            
            this->_line = new int[(w>h)?w:h];
        }
    
        ~Pixelsort() {
            delete[] this->_line;
        }
    
        void render(unsigned int *src,unsigned int *dst,int rb,unsigned char v) {
            
            int w = this->_width;
            int h = this->_height;
            
            int m = w-1;
            
            int len = 0;
            int then = 0;
            bool state = false;
            
            for(int i=0; i<h; i++) {
                
                then = 0;
                state = false;
                
                unsigned int *p = src+i*rb;
                
                int *l = _line;
                len = w;
                while(len--) {
                                    
                    *l = *p++;
                    unsigned char tmp = gris(*l++);
                    
                    if(state) {
                        if(tmp>v) {
                            std::sort(_line+then,l);
                            state = false;
                        }
                    }
                    else {
                        if(tmp<v) {
                            then = m-len;
                            state = true;
                        }
                    }
                }
                
                if(state&&then<=m) std::sort(_line+then,_line+w);
                
                l = _line;
                p = dst+i*rb;
                len = w;
                while(len--) {
                    *p++ = *l++;
                }
            }
        }
};