### Main

	#import <Cocoa/Cocoa.h>
	
	#pragma mark AppDelegate
	@interface AppDelegate:NSObject <NSApplicationDelegate> {} @end
	
	@implementation AppDelegate
	-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	    if(!SMLoginItemSetEnabled((__bridge CFStringRef)@"org.mizt.MainHelper",YES)) {
	        NSLog(@"Failed to enable login item.");
	    }
	}
	-(void)applicationWillTerminate:(NSNotification *)aNotification {
	}
	@end
	
	int main (int argc, const char * argv[]) {
	    id app = [NSApplication sharedApplication];
	    id delegat = [AppDelegate alloc];
	    [app setDelegate:delegat];
	    [app run];
	    return 0;
	}

### Helper 

	#import <Cocoa/Cocoa.h>

	#define kMainAppBundleIdentifier @"org.mizt.Main"
	#define kMainAppURLScheme @"Main"
	
	@interface AppDelegate:NSObject <NSApplicationDelegate> {} @end
	
	@implementation AppDelegate
	
	-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	    
	    NSArray *applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:kMainAppBundleIdentifier];
	    if(applications.count==0) {
	        if(![application isActive]) {
	            NSURL *applicationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://",kMainAppURLScheme]];
	            [[NSWorkspace sharedWorkspace] openURL:applicationURL];
	        }
	    }
	    [NSApp terminate:nil];
	}
	
	-(void)applicationWillTerminate:(NSNotification *)aNotification {
	}
	@end
	
	int main(int argc, const char * argv[]) {
	    @autoreleasepool {
	        id app = [NSApplication sharedApplication];
	        id delegat = [AppDelegate alloc];
	        [app setDelegate:delegat];
	        [app run];
	    }
	    return 0;
	}
	
### Reference
[「ログイン時に起動」を実装する](https://questbeat.hatenablog.jp/entry/2014/04/19/123207)	
