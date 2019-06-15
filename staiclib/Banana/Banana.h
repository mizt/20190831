#import "BaseItem.h"
class Banana : public BaseItem {
	private:
		Banana();
		void operator=(const Banana &o) {}
		Banana(const Banana &o) {} 
	public:
		static Banana *$() {
			static Banana instance;
			return &instance;
		}
};

