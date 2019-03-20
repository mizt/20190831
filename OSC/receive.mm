#import <Cocoa/Cocoa.h>
#import <string>
#import "OSC.h"

class App : public OSC::Receiver {
	
	private:
		
		dispatch_source_t timer;
		
		void onOSC(OSC::tosc_message *osc) {
			std::string address = OSC::tosc_getAddress(osc);
			std::string format  = OSC::tosc_getFormat(osc);			
			NSLog(@"%s,%s",address.c_str(),format.c_str());
			if(address=="/hello"&&format=="s") {
				NSLog(@"/hello = %s",OSC::tosc_getNextString(osc));
			}
		}
		
	public:
		
		App() : OSC::Receiver(PORT) {
			this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("enterframe",0));
			dispatch_source_set_timer(timer,dispatch_time(0,0),(1.0/120)*1000000000,0);
			dispatch_source_set_event_handler(timer,^{
				OSC::Receiver::update();
			});
			if(this->timer) dispatch_resume(this->timer);
		}
		
		~App() {
			if(this->timer){
				dispatch_source_cancel(this->timer);
				this->timer = nullptr;
			}
		}
};

int main(int argc,char *argv[]) {
	
	 @autoreleasepool {
			
		App *app = new App();
		[[NSApplication sharedApplication] run];       	
	
	}
}