#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static void onResize(CGDirectDisplayID displayID,CGDisplayChangeSummaryFlags flags,void *win) {
    if(CGMainDisplayID()==displayID) {
        if(win&&flags&kCGDisplayDesktopShapeChangedFlag) {
            [(__bridge NSWindow *)win setFrame:[[[NSScreen screens] objectAtIndex:0] frame] display:NO];                            
        }
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        objc_registerClassPair(objc_allocateClassPair(objc_getClass("NSView"),"Guide",0));
        Class Guide = objc_getClass("Guide");
        const char *type = "v@:@";
        SEL method = NSSelectorFromString(@"drawRect:");
        class_addMethod(Guide,NSSelectorFromString(@"_drawRect:"),method_getImplementation(class_getInstanceMethod(Guide,method)),type);
        class_replaceMethod(Guide,method,imp_implementationWithBlock(^(id me,Rect dirtyRect) {
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
            [[NSBezierPath bezierPathWithRect:CGRectMake((rect.size.width-1280)*0.5,(rect.size.height-(720+22))*.5,1280,(720+22))] stroke];
        }),type); 
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
