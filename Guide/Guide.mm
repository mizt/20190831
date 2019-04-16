#import <Cocoa/Cocoa.h>
#import "../common/addMethod.h"

static void onResize(CGDirectDisplayID displayID,CGDisplayChangeSummaryFlags flags,void *win) {
    if(CGMainDisplayID()==displayID) {
        if(win&&flags&kCGDisplayDesktopShapeChangedFlag) {
            [(__bridge NSWindow *)win setFrame:[[[NSScreen screens] objectAtIndex:0] frame] display:NO];                            
        }
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        int w = 1280;
        int h = 720+22;
        
        NSApplication *app = [NSApplication sharedApplication];
        if(objc_getClass("Guide")==nil) { objc_registerClassPair(objc_allocateClassPair(objc_getClass("NSView"),"Guide",0)); }
        Class Guide = objc_getClass("Guide");
        addMethod(Guide,@"drawRect:",^(id me,NSRect dirtyRect) {
             CGRect rect = [[[NSScreen screens] objectAtIndex:0] frame];
                [[NSColor clearColor] setFill];
                [[NSBezierPath bezierPathWithRect:rect] fill];
                [[NSColor colorWithRed:0.
                    green:1.
                    blue:1.
                    alpha:0.9] setStroke];
                NSBezierPath *path = [NSBezierPath bezierPath];
                path.lineWidth = 1.;
                [path moveToPoint:NSMakePoint(rect.size.width*.5,0)];
                [path lineToPoint: NSMakePoint(rect.size.width*.5,rect.size.height)];
                [path moveToPoint:NSMakePoint(0,rect.size.height*.5)];
                [path lineToPoint: NSMakePoint(rect.size.width,rect.size.height*.5)];
                [path stroke];
                [[NSBezierPath bezierPathWithRect:CGRectMake((rect.size.width-w)*0.5,(rect.size.height-(h))*.5,w,h)] stroke];
        },"v@:@");
        CGRect rect = [[[NSScreen screens] objectAtIndex:0] frame];
        NSView *view = [[Guide alloc] initWithFrame:rect];
        [view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        NSWindow *win = [[NSWindow alloc] initWithContentRect:rect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
        [win setBackgroundColor:[NSColor clearColor]];
        [win setOpaque:NO];
        [win setHasShadow:NO];
        [win setIgnoresMouseEvents:YES];
        [win setLevel:kCGMaximumWindowLevel];
        [[win contentView] addSubview:view];
        [win makeKeyAndOrderFront:nil];
        CGDisplayRegisterReconfigurationCallback(onResize,(void *)win);
        [app run];       
    }
}
