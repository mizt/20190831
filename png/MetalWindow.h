#import "MetalLayer.h"
#import "TextureMetalLayer.h"

class MetalWindow {
	
	private:
	
		NSWindow  *_win;
		NSView *_view;
		TextureMetalLayer *_layer;

		NSRect rect;
	
	public:
	
		int width() {
			return this->rect.size.width;
		}
		
		int height() {
			return this->rect.size.height;
		}
		
	
		TextureMetalLayer *layer() { return this->_layer; }
		
		void appear() {
			CGRect screen = [[NSScreen mainScreen] frame];
			CGRect center = CGRectMake((screen.size.width-this->rect.size.width)*.5,(screen.size.height-this->rect.size.height)*.5,this->rect.size.width,this->rect.size.height);
			[this->_win setFrame:center display:YES];
					
					
            [this->_win makeKeyAndOrderFront:nil];
        }

		MetalWindow() { 
			
			this->rect = CGRectMake(0,0,1280,720);
						
			int width  = this->rect.size.width;
			int height = this->rect.size.height;
			
			this->_win = [[NSWindow alloc] initWithContentRect:this->rect styleMask:1 backing:NSBackingStoreBuffered defer:NO];
			this->_view = [[NSView alloc] initWithFrame:this->rect];
						
			this->_layer = new TextureMetalLayer();
			if(this->_layer->init(this->rect.size.width,this->rect.size.height,{@"default.metallib"})) {
								
				this->_layer->resize(this->rect);
				[this->_view setWantsLayer:YES];
				this->_view.layer = this->_layer->layer();
				
				[[this->_win contentView] addSubview:this->_view];

			}
		}
	
		~MetalWindow() {
			[this->_view removeFromSuperview];	
			[this->_win setReleasedWhenClosed:NO];
			[this->_win close];
			this->_win = nil;
		}
};
