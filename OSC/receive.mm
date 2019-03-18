#import <Cocoa/Cocoa.h>
#import <string>

namespace OSC {
	
	#define PORT 54321
	
	#import "tinyosc.h"

	class Receiver {
		
		private:
					
			char recvbuf[0xFFFF];
			const int fd = socket(AF_INET,SOCK_DGRAM,0);
				
			virtual void onOSC(tosc_message *osc) = 0;
				
		public:
			
			Receiver(int port) {
	            
				fcntl(this->fd,F_SETFL,O_NONBLOCK); // set the socket to non-blocking
				struct sockaddr_in sin;
				sin.sin_family = AF_INET;
				sin.sin_port = htons(port);
				sin.sin_addr.s_addr = INADDR_ANY;
				bind(this->fd,(struct sockaddr *)&sin,sizeof(struct sockaddr_in));
				
			}		
			
			void update() {
				
				fd_set readSet;
				FD_ZERO(&readSet);
				FD_SET(fd, &readSet);
				struct timeval timeout = {1, 0}; // select times out after 1 second
				if(select(fd+1, &readSet, NULL, NULL, &timeout) > 0) {
					struct sockaddr sa; // can be safely cast to sockaddr_in
					socklen_t sa_len = sizeof(struct sockaddr_in);
					int len = 0;
					while((len = (int) recvfrom(fd, recvbuf, sizeof(recvbuf), 0, &sa, &sa_len)) > 0) {
						if(tosc_isBundle(recvbuf)) {
							tosc_bundle bundle;
							tosc_parseBundle(&bundle, recvbuf, len);
							const uint64_t timetag = tosc_getTimetag(&bundle);
							tosc_message osc;
							while (tosc_getNextMessage(&bundle, &osc)) {
								this->onOSC(&osc);
							}
						} 
						else {
							tosc_message osc;
							tosc_parseMessage(&osc, recvbuf, len);
							this->onOSC(&osc);
						}
					}
				}
			}
	};
}

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