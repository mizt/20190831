#import <map>
#import <string>

namespace Event {
    static const char *test = "test";
}

class EventEmitter {
    
    private:
    
        std::map<std::string,void (^)(NSDictionary *)> events;

        EventEmitter() {}
        
        EventEmitter(const EventEmitter& $d) {}
        virtual ~EventEmitter() {}
    
    public:
        
        static EventEmitter *$() {
            static EventEmitter instance;
            return &instance;
        }
        
        void on(const char *key,void (^cb)(NSDictionary *)) {
            if(events.count(key)==0) {
                events.insert(std::make_pair(key,cb));
            }
        }
        
        void off(const char *key) {
            if(events.count(key)) {
                events.erase(key);
            }
        }
        
        void emit(const char *key,NSDictionary *dict=nil) {
            if(events.count(key)) {
                events[key](dict);
            }
        }
    
        void emit(const char *key,NSString *string) {
            if(events.count(key)) {
                events[key](@{@"data":string});
            }
        }
        
        void emit(const char *key,double value) {
            if(events.count(key)) {
                events[key](@{@"data":@(value)});
            }
        }
        
        static bool exists(NSDictionary *dict) {
            return (dict&&dict[@"data"])?true:false;
        }
        
        static bool is_double(NSDictionary *dict) {
            
            return ([[dict[@"data"] className] compare:@"__NSCFNumber"]==NSOrderedSame)?true:false;
        }
        
        static double get_double(NSDictionary *dict) {
            
            return [dict[@"data"] doubleValue];
        }
        
        static bool is_NSString(NSDictionary *dict) { 
            return ([[dict[@"data"] className] compare:@"__NSCFConstantString"]==NSOrderedSame)?true:false;
        }
        
        static NSString *get_NSString(NSDictionary *dict) {
            return dict[@"data"];
        }
};