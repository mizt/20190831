#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "../common/addMethod.h"

class App {
    
    private:
        
        NSWindow *win;
        NSView *view;
        
        CGDirectDisplayID display;
        AVCaptureVideoPreviewLayer *videoPreviewLayer;
        
        AVCaptureSession *captureSession;
        AVCaptureScreenInput *captureScreenInput;
        
    public:
        
        App() {
            
            this->captureSession = [[AVCaptureSession alloc] init];
            if([this->captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            	[this->captureSession setSessionPreset:AVCaptureSessionPresetHigh];
            }
            
            this->display = CGMainDisplayID();
            this->captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:this->display];
            
            int fps = 30;
            CMTime duration = CMTimeMake(1,(int32_t)fps);
            [this->captureScreenInput setMinFrameDuration:duration];
            
            if ([this->captureSession canAddInput:this->captureScreenInput]) {
                [this->captureSession addInput:this->captureScreenInput];
            } 
            
            [this->captureSession commitConfiguration];
            [this->captureSession startRunning];

            this->videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:this->captureSession];
            
            CGRect rect = CGRectMake(0,0,960,540);
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1 backing:NSBackingStoreBuffered defer:NO];
            this->view = [[NSView alloc] initWithFrame:rect];
            [this->videoPreviewLayer setFrame:rect];
            [this->videoPreviewLayer setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
                
            this->view.wantsLayer = YES;
                
            [[this->view layer] addSublayer:this->videoPreviewLayer];
        	[[this->view layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
            
            [[this->win contentView] addSubview:this->view];
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
            
        }
        
        ~App() {
            
            [this->captureSession stopRunning];
            [this->videoPreviewLayer removeFromSuperlayer];
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