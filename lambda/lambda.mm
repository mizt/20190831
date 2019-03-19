#import <Foundation/Foundation.h>

// http://urin.github.io/posts/2015/labmda-without-stdcpp/
#define lambda(return_type,arguments,contents) ({ struct { static return_type _ arguments { contents; } } _; _._; })
typedef void (CB)(int a);

void calc(CB *func) {
    func(10);
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        calc(lambda(void,(int n),{
             printf("%d",n);       
        }));
    }
}