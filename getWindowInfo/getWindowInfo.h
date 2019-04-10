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
