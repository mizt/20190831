#import <Foundation/Foundation.h>
#import <fts.h>

#define contains(str1,str2) ([str1 rangeOfString:str2].location!=NSNotFound)

int main(int argc, char *argv[]) {

    @autoreleasepool {
        
        NSString *fileURL = [[NSBundle mainBundle] bundlePath];
        BOOL isDirectory;
        if([[NSFileManager defaultManager] fileExistsAtPath:fileURL isDirectory:&isDirectory]) {
            if(isDirectory) {
                char *paths[] = {(char *)[fileURL UTF8String],NULL};
                FTSENT *entry;
                int count = 0;
                FTS *fts = fts_open(paths,0,NULL);
                while((entry = fts_read(fts))) {
                    if(entry->fts_info&FTS_DP||entry->fts_level==0) continue;
                    if(entry->fts_info&FTS_F) {
                        count++;
                        char *dir = entry->fts_path;
                        NSString *path = [NSString stringWithCString:dir encoding:NSUTF8StringEncoding];
                        if(!contains(path,@".DS_Store")) {
                            NSFileHandle *src = [NSFileHandle fileHandleForReadingAtPath:path];
                            if(src) {
                                NSLog(@"%@",path);
                            }
                        }
                    }
                }
            }
            else {
                NSLog(@"%@",fileURL);
            }        
        }
    }
}