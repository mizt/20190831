#import <Cocoa/Cocoa.h>

namespace OSC {
	
	#define PORT 54321
	
	#import <arpa/inet.h>
	#import "tinyosc.h"

	class Sender {
			
		private:
				
			struct sockaddr_in addr;
			const int udp = socket(AF_INET,SOCK_DGRAM,0);
			char buffer[0xFFFF];
			
		public:
			
			Sender(const char *ip,int port) {
				addr.sin_family = AF_INET;
				addr.sin_addr.s_addr = inet_addr(ip);
				addr.sin_port = htons(port);
			}
			
			~Sender() {
				close(this->udp);
			}
		
			void send(const char *address, const char *format, ...) {
				if(udp) {
					va_list ap;
					va_start(ap,format);
					const uint32_t len = OSC::tosc_vwrite(buffer,sizeof(buffer),address,format,ap);
					va_end(ap);        
					sendto(udp,buffer,len,0,(struct sockaddr *)&addr,sizeof(addr));
				}
			}
	};
}

int main(int argc,char *argv[]) {
	
	OSC::Sender *sender = new OSC::Sender("127.0.0.1",PORT);
	sender->send("/hello","s","world");
	usleep(1000);
	
	return 0;	
}