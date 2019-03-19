#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

class App {
    
    private:
        
        NSWindow *win;
        id view;
        
        bool isDrop = true;
        
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
        
    public:
        
        App() {
            
            CGRect rect = CGRectMake(0,0,128,118);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
           
            if(objc_getClass("View")==nil) { objc_registerClassPair(objc_allocateClassPair(objc_getClass("NSView"),"View",0)); }
            Class View = objc_getClass("View");
                        
            this->addMethod(View,@"drawRect:",^(id me,NSRect dirtyRect) {
                NSLog(@"drawRect:");                            
                [[NSColor blueColor] set];
                NSRectFill(dirtyRect);
            },"v@:@");
            
            
            this->addMethod(View,@"draggingEntered:",^NSDragOperation(id me,id <NSDraggingInfo> sender) {
                            
                NSLog(@"draggingEntered");
                if(!this->isDrop) return NSDragOperationNone;
                return NSDragOperationLink;
                            
            },"@@:@");

            this->addMethod(View,@"performDragOperation:",^BOOL(id me,id <NSDraggingInfo> sender) {
                NSLog(@"performDragOperation");
                return this->isDrop?YES:NO;
            },"@@:@");
            
            this->addMethod(View,@"concludeDragOperation:",^(id me,id <NSDraggingInfo> sender) {
                    
                NSLog(@"concludeDragOperation");
                this->isDrop = false; 
                
                NSString *path = [[NSURL URLFromPasteboard:[sender draggingPasteboard]] path];
                NSLog(@"%@",path);

                dispatch_async(dispatch_get_main_queue(),^{
                    this->isDrop = true;
                });
                
            },"@@:@");
            
            
            this->view = [[View alloc] initWithFrame:rect];
            [this->view registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeFileURL,nil]];

            [[this->win contentView] addSubview:this->view];
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
            
        }
        
        ~App() {
            
            [this->view removeFromSuperview];

            [this->win setReleasedWhenClosed:NO];
            [this->win close];
            this->win = nil;
        }
};

#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *app;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    app = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete app;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
    
        id app = [NSApplication sharedApplication];
        id delegat = [AppDelegate alloc];
        [app setDelegate:delegat];
        [app run];
    }
}