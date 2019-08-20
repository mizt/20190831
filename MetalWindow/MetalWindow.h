#import "MetalLayer.h"
#import "TextureMetalLayer.h"

class MetalWindow {
	
	private:
	
		NSWindow  *_win;
		NSView *_view;
		TextureMetalLayer *_layer;
		
		NSRect rect;
	
	public:
	
		TextureMetalLayer *layer() { return this->_layer; }
	
		void resize() {
			
			[this->_win setFrame:WindowUtils::$()->screenRect() display:YES];
			[this->_view setFrame:WindowUtils::$()->screenRect()];
			this->_layer->resize(WindowUtils::$()->screenRect());
						
		}
	
		void appear() {
            this->resize();
            [this->_win makeKeyAndOrderFront:nil];
        }

		MetalWindow() { 
			
			this->rect = CGRectMake(0,0,WindowUtils::$()->width,WindowUtils::$()->height);
			
			this->_win = [[NSWindow alloc] initWithContentRect:WindowUtils::$()->screenRect() styleMask:0 backing:NSBackingStoreBuffered defer:NO];
			this->_view = [[NSView alloc] initWithFrame:WindowUtils::$()->screenRect()];
			
			 this->_layer = new TextureMetalLayer();
			if(this->_layer->init(this->rect.size.width,this->rect.size.height,{@"default.metallib"})) {
								
				this->_layer->resize(WindowUtils::$()->screenRect());
				[this->_view setWantsLayer:YES];
				this->_view.layer = this->_layer->layer();
				
				[this->_win setBackgroundColor:[NSColor clearColor]];
				[this->_win setOpaque:NO];
				[this->_win setHasShadow:NO];
				[this->_win setIgnoresMouseEvents:YES];
				[this->_win setLevel:kCGDesktopWindowLevel];
				
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
