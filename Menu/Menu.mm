#import <Cocoa/Cocoa.h>
#import "Menu.h"

class App {
    
    public:
        
        App() {
            
             Menu::$()->on(^(id me,IMenuItem *item) {
                if(item) {
                    MenuType type = item->type();
                    if(type==MenuType::TEXT) {
                        if(item->eq(@"Quit")) {
                            [NSApp terminate:nil];
                        }
                    }
                    else if(type==MenuType::RADIOBUTTON) {
                        if(item->eq(@"commands")) {
                            NSLog(@"%f",item->value());
                        }
                    }
                    else if(type==MenuType::CHECKBOX) {
                        if(item->eq(@"!")) {
                             NSLog(@"%d",(item->value()>=0.5)?1:0);
                        }
                    }
                    else if(type==MenuType::SLIDER) {
                        if(item->eq(@"~")) {
                            NSLog(@"%f",item->value());
                        }
                    }
                }
            })->addItem(@"~",MenuType::SLIDER,@"{'value':0.8,'min':0.0,'max':1.0}")
            ->hr()
            ->addItem(@"commands",MenuType::RADIOBUTTON,@"{'label':[1,2,3],'value':0.0}")
            ->hr()
            ->addItem(@"!",MenuType::CHECKBOX,@"{'value':0.0}")
            ->hr()
            ->addItem(@"Quit",MenuType::TEXT,@"{'key':'q'}");
            
        }
        
        ~App() {
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