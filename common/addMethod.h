#import <objc/runtime.h>

void addMethod(Class cls,NSString *method,id block,const char *type,bool isClassMethod=false) {
        
    SEL sel = NSSelectorFromString(method);
    int ret = ([cls respondsToSelector:sel])?1:(([[cls new] respondsToSelector:sel])?2:0);                
    if(ret) {
        class_addMethod(cls,(NSSelectorFromString([NSString stringWithFormat:@"_%@",(method)])),method_getImplementation(class_getInstanceMethod(cls,sel)),type);
        class_replaceMethod((ret==1)?object_getClass((id)cls):cls,sel,imp_implementationWithBlock(block),type);
    }
    else {
        class_addMethod((isClassMethod)?object_getClass((id)cls):cls,sel,imp_implementationWithBlock(block),type);
    }
}
