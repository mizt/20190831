#import <Cocoa/Cocoa.h>
#import "../Plugin.h"

namespace Test {
	class Object {
		public:
			Object() {}
			~Object() {}
			void exec() { NSLog(@"Test"); }			
	};
}

Plugin::Plugin() {	
	this->instance = (void *)(new Test::Object());	
}

Plugin::~Plugin() {
	delete (Test::Object *)this->instance;
}

void Plugin::exec() {
	((Test::Object *)this->instance)->exec();	
}

extern "C" Plugin *newPlugin() { return new Plugin(); }
extern "C" void deletePlugin(Plugin *plugin) { delete plugin; }