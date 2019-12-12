class WindowUtils {
    
    private:
    
        unsigned int  *_desktop = nullptr;
    
        int _number = -1;
        int _layer = kCGDesktopWindowLevel;
    
        typedef struct { int number; int layer; } WindowInfo;
    
        std::vector<WindowInfo *>getWindowInfo(NSString *appName) {
            
            std::vector<WindowInfo *> info;
            
            CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,kCGNullWindowID);
            for(int i=0; i<CFArrayGetCount(windowList); i++) {
                NSDictionary *target = (__bridge NSDictionary *)CFArrayGetValueAtIndex(windowList,i);
                if([appName compare:target[@"kCGWindowOwnerName"]]==NSOrderedSame) {
                    WindowInfo *tmp = new WindowInfo;
                    tmp->number = [target[@"kCGWindowNumber"] intValue];
                    tmp->layer = [target[@"kCGWindowLayer"] intValue];
                    info.push_back(tmp);
                }
            };
            CFRelease(windowList);
            
            std::sort(info.begin(),info.end(),[](const WindowInfo *a, const WindowInfo *b) {
                return a->layer < b->layer;
            });
            
            return info;
        }
    
        WindowUtils() {
                        
            this->_desktop = new unsigned int[width*height];
            
            for (unsigned int k=0; k<width*height; k++) this->_desktop[k] = 0x0;
            
            std::vector<WindowUtils::WindowInfo *> info = WindowUtils::getWindowInfo(@"Dock");
            if(info.size()>0) {
                WindowUtils::_number = info[0]->number;
                WindowUtils::_layer  = info[0]->layer+1;
            }
            else {
                info = WindowUtils::getWindowInfo(@"Finder");
                if(info.size()>0) {
                    WindowUtils::_number = info[0]->number;
                }
            }
        }
    
        WindowUtils(const WindowUtils& $d) {}
        virtual ~WindowUtils() {}
    
    public:
    
        static const int width  = 1920;
        static const int height = 1080;
    
        unsigned int *desktop() { return _desktop; }
    
        int number() { return _number; }
        int layer() { return _layer; }
    
        CGRect baseRect() { return CGRectMake(0,0,WindowUtils::width,WindowUtils::height); }
        CGRect screenRect() { return [[[NSScreen screens] objectAtIndex:0] frame]; }
    
        static WindowUtils *$() {
            static WindowUtils instance;
            return &instance;
        }
    
};
