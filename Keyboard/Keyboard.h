#import <IOKit/hid/IOHIDManager.h>
#import <map>
#import <vector>
#import <string>

#define USE_SIGINT


class Keyboard {
	
	private:
		
		IOHIDManagerRef manager;
		std::vector<IOHIDDeviceRef> devices;
	
		bool LEFT_SHIFT  = false; // 225
		bool RIGHT_SHIFT = false; // 229
		bool CONTROL = false; // 224
	
		virtual void onKeyDown(std::string key)  = 0;
		virtual void onKeyUp(std::string key)  = 0;
#ifdef USE_SIGINT	
		virtual void onSIGINT() = 0;
#endif
		void append(CFMutableArrayRef arr, uint32_t page, uint32_t use) {
			CFMutableDictionaryRef result = CFDictionaryCreateMutable(kCFAllocatorDefault,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
			if (!result) return;
			CFNumberRef pageNumber = CFNumberCreate(kCFAllocatorDefault,kCFNumberIntType,&page);
			CFDictionarySetValue(result,CFSTR(kIOHIDDeviceUsagePageKey),pageNumber);
			CFRelease(pageNumber);
			CFNumberRef useNumber = CFNumberCreate(kCFAllocatorDefault,kCFNumberIntType,&use);
			CFDictionarySetValue(result,CFSTR(kIOHIDDeviceUsageKey),useNumber);
			CFRelease(useNumber);
			CFArrayAppendValue(arr,result);
			CFRelease(result);
		}
		
		void input(bool isKeyDown,unsigned int usage) {
			if(isKeyDown) {
				if(Keyboard::map.count(usage)!=0) {
					this->onKeyDown(std::get<0>(Keyboard::map.at(usage)));
				}
			}
			else {
				
				if(Keyboard::map.count(usage)!=0) {
					this->onKeyUp(std::get<0>(Keyboard::map.at(usage)));
				}
			}
		}
	
		static void input(void *me, IOReturn result, void *sender,IOHIDValueRef value) {
			
			IOHIDElementRef element = IOHIDValueGetElement(value);
			unsigned int type = (unsigned int)IOHIDElementGetType(element);
			unsigned int page = (unsigned int)IOHIDElementGetUsagePage(element);
			unsigned int usage = (unsigned int)IOHIDElementGetUsage(element);
						
			if(type==2&&page==7&&(usage!=1&&usage!=-1)) {
				
				bool isKeyDown = ((unsigned int)IOHIDValueGetIntegerValue(value)==1)?true:false;
				
				if(usage==225) {
					((Keyboard *)me)->LEFT_SHIFT = isKeyDown;
				}
				else if(usage==229) {
					((Keyboard *)me)->RIGHT_SHIFT = isKeyDown;
				}
				else if(usage==224) {
					((Keyboard *)me)->CONTROL = isKeyDown;
				}
				else if(usage) {
					
					if(((Keyboard *)me)->CONTROL==true&&usage==6) {
#ifdef USE_SIGINT	
						if(isKeyDown) ((Keyboard *)me)->onSIGINT();
#else
						((Keyboard *)me)->input(isKeyDown,usage);
#endif
						
					}
					else {
						((Keyboard *)me)->input(isKeyDown,usage);
					}
				}
			}
		}
	
		static void detached(void *me, IOReturn result, void *sender, IOHIDDeviceRef device) {
			Keyboard::cleanupKeyboard(me);
		}
	
		static void cleanupKeyboard(void* me) {
			
			long len = ((Keyboard *)me)->devices.size();
			
			if(len>0) {
				while(len--) IOHIDDeviceClose(((Keyboard *)me)->devices[len],kIOHIDOptionsTypeNone);
			}
			if(((Keyboard *)me)->manager) {
				IOHIDManagerUnscheduleFromRunLoop(((Keyboard *)me)->manager,CFRunLoopGetCurrent(),kCFRunLoopCommonModes);
				IOHIDManagerClose(((Keyboard *)me)->manager,kIOHIDOptionsTypeNone);
				CFRelease(((Keyboard *)me)->manager);
				((Keyboard *)me)->manager = nullptr;
			}
		}
	
		static void attached(void *me, IOReturn result, void *sender, IOHIDDeviceRef device) {
			
			CFStringRef name = (CFStringRef)(IOHIDDeviceGetProperty(device,CFSTR(kIOHIDProductKey)));
			if (!name) return;
			
			char _name[1024];
			CFStringGetCString(name,_name,1024,kCFStringEncodingUTF8);
			
			IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);
			IOHIDDeviceScheduleWithRunLoop(device,CFRunLoopGetCurrent(),kCFRunLoopCommonModes);
			IOHIDDeviceRegisterInputValueCallback(device,input,me);
			((Keyboard *)me)->devices.push_back(device);
		}
	
	public:
		
		static const std::map<int,std::tuple<std::string,std::string>> map;
		
		Keyboard() {
#ifdef USE_SIGINT			
			signal(SIGINT,SIG_IGN);
#endif
			this->manager = IOHIDManagerCreate(kCFAllocatorDefault,kIOHIDOptionsTypeNone);
			if(this->manager) {
				CFMutableArrayRef arr = CFArrayCreateMutable(kCFAllocatorDefault,0,&kCFTypeArrayCallBacks);
				if(arr) {
					this->append(arr,kHIDPage_GenericDesktop,kHIDUsage_GD_Keyboard);
					IOHIDManagerSetDeviceMatchingMultiple(this->manager,arr);
					CFRelease(arr);
					IOHIDManagerRegisterDeviceMatchingCallback(this->manager,Keyboard::attached,this);
					IOHIDManagerRegisterDeviceRemovalCallback(this->manager,Keyboard::detached,this);
					IOHIDManagerScheduleWithRunLoop(this->manager,CFRunLoopGetMain(),kCFRunLoopCommonModes);
					IOHIDManagerOpen(this->manager,kIOHIDOptionsTypeNone);
				}
				else {
					Keyboard::cleanupKeyboard(this);
				}
			}
		}
	
		virtual ~Keyboard() {}
	
		void cleanup() {
			Keyboard::cleanupKeyboard(this);
		}
   
};

const std::map<int,std::tuple<std::string,std::string>> Keyboard::map {
	{4 ,std::make_tuple("a","A")},
	{5 ,std::make_tuple("b","B")},
	{6 ,std::make_tuple("c","C")},
	{7 ,std::make_tuple("d","D")},
	{8 ,std::make_tuple("e","E")},
	{9 ,std::make_tuple("f","F")},
	{10,std::make_tuple("g","G")},
	{11,std::make_tuple("h","H")},
	{12,std::make_tuple("i","I")},
	{13,std::make_tuple("j","J")},
	{14,std::make_tuple("k","K")},
	{15,std::make_tuple("l","L")},
	{16,std::make_tuple("m","M")},
	{17,std::make_tuple("n","N")},
	{18,std::make_tuple("o","O")},
	{19,std::make_tuple("p","P")},
	{20,std::make_tuple("q","Q")},
	{21,std::make_tuple("r","R")},
	{22,std::make_tuple("s","S")},
	{23,std::make_tuple("t","T")},
	{24,std::make_tuple("u","U")},
	{25,std::make_tuple("v","V")},
	{26,std::make_tuple("w","W")},
	{27,std::make_tuple("x","X")},
	{28,std::make_tuple("y","Y")},
	{29,std::make_tuple("z","Z")},
	{30,std::make_tuple("1","!")},
	{31,std::make_tuple("2","@")},
	{32,std::make_tuple("3","#")},
	{33,std::make_tuple("4","$")},
	{34,std::make_tuple("5","%")},
	{35,std::make_tuple("6","^")},
	{36,std::make_tuple("7","&")},
	{37,std::make_tuple("8","*")},
	{38,std::make_tuple("9","(")},
	{39,std::make_tuple("0",")")},
	{40,std::make_tuple("RETURN","RETURN")},
	{41,std::make_tuple("ESC","ESC")},
	{42,std::make_tuple("DEL","DEL")},
	{43,std::make_tuple("TAB","TAB")},
	{44,std::make_tuple(" "," ")},
	{45,std::make_tuple("-","_")},
	{46,std::make_tuple("=","+")},
	{49,std::make_tuple("|","\\")},
	{47,std::make_tuple("[","{")},
	{48,std::make_tuple("]","}")},
	{51,std::make_tuple(";",":")},
	{52,std::make_tuple("'","\"")},
	{53,std::make_tuple("`","~")},
	{54,std::make_tuple(",","<")},
	{55,std::make_tuple(".",">")},
	{56,std::make_tuple("/","?")},
	{79,std::make_tuple("RIGHT","RIGHT")},
	{80,std::make_tuple("LEFT","LEFT")},
	{81,std::make_tuple("DOWN","DOWN")},
	{82,std::make_tuple("UP","UP")}
};
