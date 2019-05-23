#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <vector>
#import <Box2D/Box2D.h>

#define WIDTH  960
#define HEIGHT 540

#define USE_VIEW true

// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Paths/Paths.html#//apple_ref/doc/uid/TP40003290-CH206-SW2

@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath {
 
    // Need to begin a path here.
    CGPathRef immutablePath = NULL;
 
    // Then draw the path elements.
    int numElements = [self elementCount];
    if(numElements>0) {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
 
        for(int i=0; i<numElements; i++) {
            switch([self elementAtIndex:i associatedPoints:points]) {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break; 
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if(!didClosePath) CGPathCloseSubpath(path);
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
 
    return immutablePath;
}
@end

namespace Box2D {
    
    int MAX = 100;
    
    double interval = 1.0/30.0;
    
    int velocityIterations = 8;
    int positionIterations = 1;
    
    enum {
        BOX=0,
        CIRCLE,
        POLYGON
    };
    
    
    int MARGIN = 200;
    
    static double PTM_RATIO = 32.0; // == 1m
    
    NSView *view;
    b2World *world;
    
    class View {
        
        private:
            
            NSView *_view;
            CAShapeLayer *_layer;
            
        public:
            
            View(CGColor *color=NSColor.blackColor.CGColor) {
                this->_view = [[NSView alloc] initWithFrame:CGRectMake(0,0,100,100)];
                [this->_view setWantsLayer:YES];
                this->_layer = [CAShapeLayer layer];
                this->_layer.fillColor = color;
                [[this->_view layer] addSublayer:this->_layer];
                this->_view.layer.masksToBounds = NO;
                this->_layer.masksToBounds = NO;
                this->_view.hidden = true;
            }
            
            ~View() {}
            
            View *setPath(CGPathRef p) {
                [this->_layer setPath:p];
                return this;
            }
            
            View *set(CGColor *color) {
                this->_layer.fillColor = color;
                return this;
            }
            
            View *set(double x,double y,double angle=0,double sx=1,double sy=1) {
                
                CGRect pathRect = CGPathGetPathBoundingBox(this->_layer.path);
                double w = pathRect.size.width;
                double h = pathRect.size.width;
                
                if(angle==0&&sx==1&&sy==1) {
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    this->_layer.transform = CATransform3DIdentity;
                    this->_layer.position = CGPointMake(x-w*0.5,y-h*0.5);
                    [CATransaction commit];
                }
                else {
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    CATransform3D transform = CATransform3DIdentity;
                    transform = CATransform3DTranslate(transform,w*0.5,h*0.5,0.0);
                    transform = CATransform3DRotate(transform,angle,0.0,0.0,-1.0);
                    transform = CATransform3DScale(transform,sx,sy,1);
                    transform = CATransform3DTranslate(transform,-w*0.5,-h*0.5,0.0);
                    this->_layer.transform = transform;
                    this->_layer.position = CGPointMake(x-w*0.5,y-h*0.5);
                    [CATransaction commit];
                }
                
                return this;
            }
            
            View *visible(bool b) {
                this->_view.hidden = !b;
                return this;
            }
            
            CAShapeLayer *layer() { return this->_layer; }
            NSView *view() { return this->_view; }
    };

    class Object {
                
        protected:
            
            int _type;
            bool _use = false;
                        
            b2Body *_body;
            b2Fixture *_fixture;

            b2PolygonShape _shape;
            Box2D::View *_view;
            
            b2CircleShape _circleShape;

            double _angle = 0;
      
        public:
        
            Object() {
                if(USE_VIEW) {
                    this->_view = new Box2D::View();
                    [Box2D::view addSubview:this->_view->view()];
                }
            }
            
            ~Object() {
                
            }
            
            b2Body *body() { return this->_body; }
            Box2D::View *view() { return this->_view; }
            bool isUse() { return this->_use; }
            
            void cleanup() {
                if(this->_use) {
                    this->_body->DestroyFixture(this->_fixture);
                    Box2D::world->DestroyBody(this->_body);
                    this->_use=false;
                    if(USE_VIEW) {
                        this->_view->visible(false);
                    }
                }
            }
            
            double angle() { return this->_angle; }
        
            void polygon(b2Vec2 *vertices,b2BodyType type) {
                if(!this->_use) {
                    this->_use=true;   
                    this->_type = POLYGON;
                    b2BodyDef bodyDef;             
                    bodyDef.position.Set(0,0);
                    bodyDef.type = b2_staticBody;
                    this->_body = Box2D::world->CreateBody(&bodyDef);
                    this->_body->SetType(b2_staticBody);
                    this->_shape.Set(vertices,3);
                    b2FixtureDef fixtureDef;
                    fixtureDef.shape = &this->_shape;
                    fixtureDef.density = 1.0;
                    fixtureDef.friction = 0.5;
                    fixtureDef.restitution = 0.4;
                    this->_fixture = this->_body->CreateFixture(&fixtureDef);
                    if(USE_VIEW) {
                        NSBezierPath *p = [NSBezierPath bezierPath];
                        [p moveToPoint:NSMakePoint(vertices[0].x*Box2D::PTM_RATIO,vertices[0].y*Box2D::PTM_RATIO)];
                        for(int k=1; k<3; k++) {
                            [p lineToPoint:NSMakePoint(vertices[k].x*Box2D::PTM_RATIO,vertices[k].y*Box2D::PTM_RATIO)];
                        }
                        [p closePath];                        
                        this->_view->setPath(p.quartzPath)->visible(true);
                    }
                }
            }
        
            void circle(double x,double y,double r=1) {
                if(!this->_use) {
                    this->_use=true;
                    this->_type = CIRCLE;
                    this->_angle = 0;
                    b2BodyDef bodyDef;
                    bodyDef.position.Set(x,y);
                    bodyDef.type = b2_dynamicBody;
                    this->_body = Box2D::world->CreateBody(&bodyDef);
                    this->_circleShape.m_p.Set(0,0);
                    this->_circleShape.m_radius = r*0.5;
                    b2FixtureDef fixtureDef;
                    fixtureDef.shape = &this->_circleShape;
                    fixtureDef.density = 1.0;
                    fixtureDef.friction = r;
                    fixtureDef.restitution = 0.4;
                    this->_fixture = this->_body->CreateFixture(&fixtureDef);
                    if(USE_VIEW) {
                        this->_view->setPath([NSBezierPath bezierPathWithOvalInRect:CGRectMake(0,0,64*r*0.5,64*r*0.5)].quartzPath)->set(bodyDef.position.x*Box2D::PTM_RATIO, bodyDef.position.y*Box2D::PTM_RATIO)->visible(true);
                    }
                }
            }
        
            void box(double x,double y,double w=1.0,double h=1.0) {
                if(!this->_use) {
                    this->_use=true;
                    this->_type = BOX;
                    this->_angle = ((random()%40)-20)/180.*3.1415;
                    b2BodyDef bodyDef;
                    bodyDef.position.Set(x,y);
                    bodyDef.type = b2_dynamicBody;
                    this->_body = Box2D::world->CreateBody(&bodyDef);
                    b2Vec2 center;
                    center.x = 0;
                    center.y = 0;
                    this->_shape.SetAsBox(w*0.5,h*0.5,center,this->_angle);
                    b2FixtureDef fixtureDef;
                    fixtureDef.shape = &this->_shape;
                    fixtureDef.density = 1.0;
                    fixtureDef.friction = 0.5;
                    fixtureDef.restitution = 0.4;
                    this->_fixture = this->_body->CreateFixture(&fixtureDef);
                    if(USE_VIEW) {
                        this->_view->setPath([NSBezierPath bezierPathWithRect:CGRectMake(0,0,32*w,32*h)].quartzPath)->set(bodyDef.position.x*Box2D::PTM_RATIO, bodyDef.position.y*Box2D::PTM_RATIO)->visible(true);
                    }
                }
            }
    };
    
}

class App {
    
    private:
        
        dispatch_source_t timer;
        
        NSWindow *win;
        CGRect rect = CGRectMake(0,0,WIDTH,HEIGHT);
            
        void setup() {
            b2Vec2 gravity;
            gravity.Set(0.f,-9.81f);
            Box2D::world = new b2World(gravity);
            Box2D::world->SetContinuousPhysics(true);
        }
            
        std::vector<Box2D::Object *> _dynamics;
        
        int frame = 0;
        
        void push() {

            b2Vec2 vertices[] = {                
                b2Vec2(196.0/Box2D::PTM_RATIO,0.0/Box2D::PTM_RATIO),
                b2Vec2((WIDTH*0.5)/Box2D::PTM_RATIO,90.0/Box2D::PTM_RATIO),
                b2Vec2((WIDTH-196.0)/Box2D::PTM_RATIO,0.0/Box2D::PTM_RATIO),
            };
            
            int len = sizeof(vertices)/(sizeof(b2Vec2)*3);
            
            for(int n=0; n<len; n++) {                
                if(n>=_dynamics.size()) _dynamics.push_back(new Box2D::Object());
                _dynamics[n]->polygon(vertices+n*3,b2_staticBody);
            }
            
        }
        
        
        
        
        void add() {
            
            int uid = -1;
            int used = 0;
            
            for(int k=0; k<_dynamics.size(); k++) {
                if(_dynamics[k]->isUse()==false) {
                    uid = k;
                    break;
                }
                else {
                    used++;
                }
            }
            
            if(used>=Box2D::MAX) return;
            
            if(uid==-1) {
                Box2D::Object *o = new Box2D::Object();
                if(random()&1) {
                    o->circle((16+random()%(WIDTH-32))/Box2D::PTM_RATIO,(HEIGHT+32)/Box2D::PTM_RATIO,2);
                }
                else {
                    o->box((16+random()%(WIDTH-32))/Box2D::PTM_RATIO,(HEIGHT+32)/Box2D::PTM_RATIO,2,2);
                }
                _dynamics.push_back(o);
            }
            else {
                if(random()&1) {
                    _dynamics[uid]->circle((16+random()%(WIDTH-32))/Box2D::PTM_RATIO,(HEIGHT+32)/Box2D::PTM_RATIO,2);
                }
                else {
                    _dynamics[uid]->box((16+random()%(WIDTH-32))/Box2D::PTM_RATIO,(HEIGHT+32)/Box2D::PTM_RATIO,2,2);
                }
            }
                    
            NSLog(@"dynamics = %lu",_dynamics.size());
            
        }
        
    public:
        
        App() {
            
            
            this->win = [[NSWindow alloc] initWithContentRect:rect styleMask:1 backing:NSBackingStoreBuffered defer:NO];
            Box2D::view = [[NSView alloc] initWithFrame:rect];
            
            [[this->win contentView] addSubview:Box2D::view];
            [this->win setBackgroundColor:[NSColor whiteColor]];
            
            this->setup();
            this->push();
            
            this->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_queue_create("ENTER_FRAME",0));
            dispatch_source_set_timer(this->timer,dispatch_time(0,0),Box2D::interval*1000000000,0);
            dispatch_source_set_event_handler(this->timer,^{
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    if((this->frame++%10)==0) this->add();
                                    
                    Box2D::world->Step(Box2D::interval,Box2D::velocityIterations,Box2D::positionIterations);
                    
                    for(int k=0; k<this->_dynamics.size(); k++) {
                        Box2D::Object *o = this->_dynamics[k];                    
                        if(o->isUse()) {
                            b2Body *b = o->body();
                            if(b->GetType()!=b2_staticBody) {
                                int x = b->GetPosition().x*Box2D::PTM_RATIO;
                                int y = b->GetPosition().y*Box2D::PTM_RATIO;
                                    
                                if(x<-Box2D::MARGIN||x>WIDTH+Box2D::MARGIN||y<-Box2D::MARGIN) {
                                    o->cleanup();
                                }
                                else {
                                    if(USE_VIEW) {
                                        o->view()->set(x,y,-b->GetAngle()-this->_dynamics[k]->angle());
                                    }
                                }
                            }                          
                        }
                    }
                });
            });
            if(this->timer) dispatch_resume(this->timer);
            [this->win center];
            [this->win makeKeyAndOrderFront:nil];
        }
        
        ~App() {
            
        }
};

#pragma mark AppDelegate
@interface AppDelegate:NSObject <NSApplicationDelegate> {
    App *app;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    app = new App();
}
-(void)applicationWillTerminate:(NSNotification *)aNotification {
    delete app;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        
        srand(CFAbsoluteTimeGetCurrent());
        srandom(CFAbsoluteTimeGetCurrent());
        
        id app = [NSApplication sharedApplication];
        id delegat = [AppDelegate alloc];
        [app setDelegate:delegat];
        [app run];
    }
}
