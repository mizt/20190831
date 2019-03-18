typedef struct { int number; int layer; } WindowInfo;

WindowInfo *getDockWindowInfo() {
     
    bool found = false;
    int number = -1;
    int layer = 0x7FFFFF;
        
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,kCGNullWindowID);
    for(int i=0; i<CFArrayGetCount(windowList); i++) {
        NSDictionary *target = (__bridge NSDictionary *)CFArrayGetValueAtIndex(windowList,i);
        if([@"Dock" compare:target[@"kCGWindowOwnerName"]]==NSOrderedSame) {            
            if([target[@"kCGWindowNumber"] intValue]>kCGDesktopWindowLevel&&[target[@"kCGWindowNumber"] intValue]<layer) {
                found = true;
                number = [target[@"kCGWindowNumber"] intValue];
                layer = [target[@"kCGWindowLayer"] intValue];
            }
        }
    };
    CFRelease(windowList);

    if(found) {
        WindowInfo *info = new WindowInfo; 
        info->number = number;
        info->layer = layer;
        return info;
    }
    
    return nullptr;
} 
