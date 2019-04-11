#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

class App {
    
    private:
        
        NSWindow *win;
        NSView *view;
        CGRect rect = CGRectMake(0,0,128,128);
        CAShapeLayer *circle;
        CAGradientLayer *gradient;
        dispatch_source_t timer;        
        double cnt = 0.0;
    
    public:
        
        App() {
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[NSView alloc] initWithFrame:rect];
            this->gradient = [CAGradientLayer layer];
            this->gradient.startPoint = CGPointMake(0.5,0.5);
            this->gradient.endPoint = CGPointMake(0.5,0.0);
            this->gradient.frame = CGRectMake(0,0,128,128);
            this->gradient.colors = @[
                (id)[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.0].CGColor,
                (id)[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor
            ];
            this->gradient.type = kCAGradientLayerConic;
            [this->view setWantsLayer:YES]; 
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddArc(path,NULL,64,64,60,0,M_PI*2,YES);            
            this->circle = [CAShapeLayer layer];
            this->circle.fillColor = [NSColor clearColor].CGColor;
            this->circle.strokeColor = [NSColor whiteColor].CGColor;
            this->circle.lineWidth = 8;
            this->circle.path = path;
            this->gradient.mask = this->circle;
            [[this->view layer] addSublayer:this->gradient];
            [this->view setHidden:NO]; // YES
            [[this->win contentView] addSubview:this->view];
            [this->win setBackgroundColor:[NSColor clearColor]];
            [this->win setHasShadow:NO];
            [this->win setOpaque:NO];
            [this->win setLevel:kCGScreenSaverWindowLevel];
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),(1.0/30.0)*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                double current = CFAbsoluteTimeGetCurrent();                
                dispatch_async(dispatch_get_main_queue(),^{
                    if([this->view isHidden]==NO) {
                        this->gradient.transform = CATransform3DMakeRotation(this->cnt,0.0,0.0,1.0);
                         this->cnt-=0.1;
                    }
                });
            });
            if(this->timer) dispatch_resume(this->timer);
            CGRect screen = [[NSScreen mainScreen] frame];
            CGRect center = CGRectMake((screen.size.width-rect.size.width)*.5,(screen.size.height-rect.size.height)*.5,rect.size.width,rect.size.height);
            [this->win setFrame:center display:YES];            
            [this->win makeKeyAndOrderFront:nil];
        }
        
        ~App() {
            if(this->timer){
                dispatch_source_cancel(this->timer);
                this->timer = nullptr;
            }
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