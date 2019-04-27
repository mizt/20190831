#import <Cocoa/Cocoa.h>
#import <sys/sysctl.h>


namespace Check {

     bool Model(int min=13) {
            
        int mib[2];
        mib[0] = CTL_HW;
        mib[1] = HW_MODEL;
        size_t len = 0;
        
        sysctl(mib,2,NULL,&len,NULL,0);
        
        if(len>0) {
            
            char *rstring = (char *)malloc(len);
            sysctl(mib,2,rstring,&len,NULL,0);
            
            NSString *model = [NSString stringWithFormat:@"%s",rstring];
            NSLog(@"%@",model);
            
            free(rstring);
            rstring = NULL;
            
            NSRange range = [model rangeOfString:@"MacBookPro"];
            if (range.location != NSNotFound) {
                NSRange match = [
                    model rangeOfString:@"[0-9]+,[0-9]+"
                    options:NSRegularExpressionSearch
                ];
                if(match.location != NSNotFound) {
                    NSArray *arr = [[model substringWithRange:match] componentsSeparatedByString:@","];
                    if([arr count]==2&&[arr[0] intValue]>=min) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    }
        
    bool Version(int min=14) {
        NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
        NSLog(@"%@",version);
        NSRange match = [
            version rangeOfString:@"[0-9]+.[0-9]+"
            options:NSRegularExpressionSearch
        ];
        if(match.location != NSNotFound) {
            NSArray *arr = [[version substringWithRange:match] componentsSeparatedByString:@"."];
            if([arr count]==2&&[arr[0] intValue]==10&&[arr[1] intValue]>=min) {
                return true;
            }
        }
        return false;
    }
    
    
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSLog(@"%s",Check::Model()?"true":"false");
        NSLog(@"%s",Check::Version()?"true":"false");
    }
}