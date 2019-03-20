#import <Cocoa/Cocoa.h>
#import "OSC.h"

int main(int argc,char *argv[]) {
	
	OSC::Sender *sender = new OSC::Sender("127.0.0.1",PORT);
	sender->send("/hello","s","world");
	usleep(1000);
	
	return 0;	
}