#import <Foundation/Foundation.h>

namespace Utils {
	bool isApplication() {
		return ([[[[NSBundle mainBundle] bundleURL] pathExtension] compare:@"app"]==NSOrderedSame)?true:false;
	}
}

int main(int argc, char *argv[]) {
	@autoreleasepool {		
		NSLog(@"%d",Utils::isApplication());
	}
}