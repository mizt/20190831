#include <emscripten.h>
#include "json.hpp"

static nlohmann::json _json = nullptr;


extern "C" {
		
	void setup(const char *jsonstr) {
		try {                        
			_json = nlohmann::json::parse(jsonstr);
			//printf("success\n");
		}
		catch(std::exception e) {        
			printf("%s is not valid\n",jsonstr);
		}
	}
	
	int get(const char *key) {
		
		//printf("%s\n",key);
		
		if(_json!=nullptr&&_json[key].is_number()) {
			return _json[key]; 
		}
		
		return 0;
	}
	
	void set(const char *key,double value) {
		if(_json!=nullptr&&_json[key].is_number()) {
			_json[key] = value;
		}
	}
	
	
	
}