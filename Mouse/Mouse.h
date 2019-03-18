class Mouse {

    protected:
           
        virtual void onMouseDown(int x, int  y, int modifiers) = 0;
        virtual void onMouseUp(int x, int  y, int modifiers) = 0;
        
        int mouseX() { return this->_mouseX; }
        int mouseY() { return this->_mouseY; }
        int mouseDown() { return this->_mouseDown; }
    
    private:
        
        dispatch_source_t timer;
        
        int _mouseX = 0;
        int _mouseY = 0;		
        int _mouseDown = 0;
            
    public:

        Mouse() {}
    
    
        void update() {
            
            NSRect screen = [[NSScreen mainScreen] frame];

            NSPoint mouseLoc = [NSEvent mouseLocation];
            unsigned long mousedown = [NSEvent pressedMouseButtons];

            this->_mouseX = mouseLoc.x;
            this->_mouseY = screen.size.height-mouseLoc.y;
            
            int then =  this->_mouseDown;
            
            this->_mouseDown = mousedown;
            
            if(then!=this->_mouseDown) {
                
                if(this->_mouseDown==1) {
                    this->onMouseDown(this->_mouseX,this->_mouseY,1<<4);
                }
                else {
                    this->onMouseUp(this->_mouseX,this->_mouseY,1<<4);
                }
                
            }
        }
        
    
        ~Mouse() {}
    
};
