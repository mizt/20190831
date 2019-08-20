class MetalWindow {
	
	private:
	
		NSWindow  *_win;
		MetalView *_view;
	
	public:
	
		MetalView *view() { return this->_view; }
	
		void resize() {
			[this->_view setFrame:WindowUtils::$()->screenRect()];
			[this->_win  setFrame:WindowUtils::$()->screenRect() display:NO];
		}
	
		void appear() {
            this->resize();
            [this->_win makeKeyAndOrderFront:nil];
        }

		MetalWindow(std::vector<NSString *>shaders, int zindex=kCGDesktopWindowLevel) {
			this->_win = [[NSWindow alloc] initWithContentRect:WindowUtils::$()->screenRect() styleMask:0 backing:NSBackingStoreBuffered defer:NO];
			this->_view = [[MetalView alloc] initWithFrame:WindowUtils::$()->baseRect() :shaders];
			[this->_win setBackgroundColor:[NSColor clearColor]];
			[this->_win setOpaque:NO];
			[this->_win setHasShadow:NO];
			[this->_win setIgnoresMouseEvents:YES];
			[this->_win setLevel:zindex];
			[[this->_win contentView] addSubview:this->_view];
		}
	
		~MetalWindow() {
			[this->_view removeFromSuperview];	
			[this->_win setReleasedWhenClosed:NO];
			[this->_win close];
			this->_win = nil;
		}
};
