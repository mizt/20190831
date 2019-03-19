#import <Foundation/Foundation.h>
#import <dlfcn.h>

#define USE_PLUGIN
#import "Plugin.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        void *dylib = (Plugin *)dlopen([[NSString stringWithFormat:@"%@/Test/Test.dylib",[[NSBundle mainBundle] bundlePath]] UTF8String],RTLD_LAZY);
        if(dylib) {
            Plugin *plugin = ((newPlugin *)dlsym(dylib,"newPlugin"))();
            if(plugin) {
                plugin->exec();
                ((deletePlugin *)dlsym(dylib,"deletePlugin"))(plugin);
            }
        }
        dlclose(dylib);
    }
}