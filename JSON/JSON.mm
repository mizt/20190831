#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSError *err = nil;
        NSString *path  = [NSString stringWithFormat:@"%@/color.json",[[NSBundle mainBundle] bundlePath]];
        NSString *json= [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
        if(err==nil) {
            NSData *jsonData = [json dataUsingEncoding:NSUnicodeStringEncoding];
            err = nil;
            NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
            if(err==nil) {
                int ch = 3;
                if([[dict[@"background"] className] compare:@"__NSArrayI"]==NSOrderedSame) {
                    if(dict[@"background"]&&[dict[@"background"] count]==ch) {                    
                        unsigned int color = 0xFF000000;
                        for(int k=0; k<ch; k++) {
                            if([[dict[@"background"][k] className] compare:@"__NSCFNumber"]==NSOrderedSame) {
                                int tmp = [dict[@"background"][k] intValue];
                                if(tmp>0&&tmp<0x100) {
                                    color|=tmp<<(8*(ch-k-1));
                                }
                            }
                        }
                        NSLog(@"0x%X",color);
                    }
                }  
                
                //NSLog(@"%@",[dict[@"timestamp"] className]);
                
                if([[dict[@"timestamp"] className] compare:@"__NSCFNumber"]==NSOrderedSame) {
                    NSLog(@"%f",[dict[@"timestamp"] doubleValue]);
                    
                    NSNumber *val = [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()];
                    NSLog(@"%@",val);
                    
                    [dict setValue:val forKey:@"timestamp"];
                    
                    NSError *error = nil;
                    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:2 error:&error];
                    if(error==nil) {
                        NSString *jsonstr=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                        [jsonstr writeToFile:@"./color.json" atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    }
                }
            }
        }
    }
}