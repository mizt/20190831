#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import "../common/addMethod.h"

class App {
    
    private:
        
        bool isInit = false;
        NSWindow *win;
        WKWebView<WKNavigationDelegate> *view;
        
    public:
        
        App() {
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1|1<<2 backing:NSBackingStoreBuffered defer:NO];
           
            if(objc_getClass("Web")==nil) { objc_registerClassPair(objc_allocateClassPair(objc_getClass("WKWebView"),"Web",0)); }
            Class Web = objc_getClass("Web");
            
            addMethod(Web,@"webView:didFinishNavigation:",^(id me,WKWebView *webView,WKNavigation *navigation) {
                if(this->isInit==false) {
                    NSLog(@"webView:didFinishNavigation:");
                    [this->win makeKeyAndOrderFront:nil];
                    this->isInit = true;
                }
            },"v@:@@");
                        
            this->view = [[Web alloc] initWithFrame:rect];
            [this->view setNavigationDelegate:this->view];
            [this->view loadHTMLString:[NSString stringWithUTF8String:R"(<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>
    * {
        margin:0;
        padding:0;
    }
    body {
        width:100%;
        height:100vh;
        overflow:hidden;
        background-color:#0033FF;
    }
    </style>
    </head>
    <body></body>
</html>)"] baseURL:nil];
            [this->view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];            
            [[this->win contentView] addSubview:this->view];
            [this->win center];
            
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