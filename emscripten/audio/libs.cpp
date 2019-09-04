#include <emscripten.h>
#include <math.h>

#define TWO_PI (3.14159265358979323846*2.0)

double SAMPLE_RATE = 44100.;

class Cycle {
	
	private:
		
		double phase=0.;
		double delta=0.;
			
	public:
	
		Cycle(double freq) {			
			this->delta = freq*(1.0/SAMPLE_RATE);
			if(this->delta>=1.0) this->delta=1;
		}
	
		double next() {
		
			this->phase+=this->delta;
            if(this->phase>= 1) this->phase-=1;
            if(this->phase<=-1) this->phase+=1;
			return sin(this->phase*TWO_PI);
		}
};
	
Cycle *cycle = nullptr;
		
extern "C" {
	
	void setup(float sampleRate) {
		SAMPLE_RATE = sampleRate;
		cycle = new Cycle(1000.);
	}
	
	void next(float *L, float *R,int len) {
		if(cycle) {
			for(int k=0; k<len; k++) {
				R[k] = L[k] = cycle->next();
			}	
		}
		else {
			for(int k=0; k<len; k++) {
				R[k] = L[k] = 0;
			}
		}
	}
}