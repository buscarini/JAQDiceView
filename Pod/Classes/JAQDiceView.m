//
//  JAQDiceView.m
//  Pods
//
//  Created by Javier Querol on 19/11/14.
//
//

#import "JAQDiceView.h"
#import "SCNNode+Utils.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define WALL_THICKNESS 1
#define FOV 60

@interface JAQDiceView ()

@property (nonatomic, strong) SCNNode *dice1;
@property (nonatomic, strong) SCNNode *dice2;
@property (nonatomic, strong) SCNNode *camera;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger timesStopped;

@property (nonatomic, strong) SCNNode *leftWall;
@property (nonatomic, strong) SCNNode *rightWall;
@property (nonatomic, strong) SCNNode *frontWall;
@property (nonatomic, strong) SCNNode *backWall;
@property (nonatomic, strong) SCNNode *topWall;
@property (nonatomic, strong) SCNNode *bottomWall;

@property (nonatomic, assign) CGFloat cameraHeight;
@property (nonatomic, assign) CGFloat wallsHeight;

@property (nonatomic, copy) IBInspectable NSString *floorImageName;
@end

@implementation JAQDiceView

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.backgroundColor = [UIColor blackColor];
	
	if (!self.maximumJumpHeight) self.maximumJumpHeight = 120;
	if (!self.squareSizeHeight || self.squareSizeHeight<30) self.squareSizeHeight = 60;
	
	[self loadScene];
}

- (void) setShowWalls:(BOOL)showWalls {
	_showWalls = showWalls;
	
	BOOL opacity = 0.01;
	if (showWalls) opacity = 0.5;
	
	self.leftWall.opacity = opacity;
	self.rightWall.opacity = opacity;
	self.frontWall.opacity = opacity;
	self.backWall.opacity = opacity;
	self.topWall.opacity = opacity;
	self.bottomWall.opacity = opacity;
}

- (void)setOpacity:(CGFloat)opacity toNode:(SCNNode *)node {
	for (SCNMaterial *material in node.geometry.materials) {
		if (opacity==0)	material.diffuse.contents = [UIColor clearColor];
		material.transparency = opacity;
	}
}

- (void)loadScene {
	NSURL *bundleUrl = [[NSBundle mainBundle] URLForResource:@"JAQDiceView" withExtension:@"bundle"];
	NSBundle *bundle = [NSBundle bundleWithURL:bundleUrl];
	
	NSURL *url = [bundle URLForResource:@"Dices" withExtension:@"dae"];
	self.scene = [SCNScene sceneWithURL:url options:nil error:nil];
	
	self.timesStopped = 0;
	self.scene.physicsWorld.gravity = SCNVector3Make(0, -980, 0);
	
	SCNFloor *floorGeometry = [SCNFloor floor];

//	for (SCNMaterial *material in floorGeometry.materials) {
//		material.diffuse.contents = [UIColor clearColor];
//		material.transparency = 0;
//	}
	
	SCNNode *floorNode = [SCNNode node];
	floorNode.geometry = floorGeometry;
	floorNode.physicsBody = [SCNPhysicsBody staticBody];
	[self setOpacity:0 toNode:floorNode];
	
	[self.scene.rootNode addChildNode:floorNode];
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	self.dice1 = [self.scene.rootNode childNodeWithName:@"Dice_1" recursively:YES];
	self.dice1.physicsBody = [SCNPhysicsBody dynamicBody];
	
	self.dice2 = [self.scene.rootNode childNodeWithName:@"Dice_2" recursively:YES];
//	self.dice2.scale = SCNVector3Make(0.2, 0.2, 0.2);
	self.dice2.physicsBody = [SCNPhysicsBody dynamicBody];
	
	self.camera = [SCNNode node];
	self.camera.camera = [SCNCamera camera];
	self.antialiasingMode = SCNAntialiasingModeMultisampling2X;
	
	self.camera.camera.yFov = FOV;
	self.camera.camera.xFov = self.camera.camera.yFov*(self.bounds.size.width/self.bounds.size.height);

	self.camera.camera.zFar = self.maximumJumpHeight*2;
	self.camera.eulerAngles = SCNVector3Make(-M_PI/2, 0, 0);
	
	self.cameraHeight = self.maximumJumpHeight+50;
	self.wallsHeight = self.cameraHeight-20;
	
	self.camera.position = SCNVector3Make(0, self.cameraHeight, 0);
//	if (self.cameraPerspective) {
////		self.camera.rotation = SCNVector4Make(-1, 0, 0, M_PI/3);
//		self.camera.position = SCNVector3Make(0, self.maximumJumpHeight-30, 40);
//	}
	[self.scene.rootNode addChildNode:self.camera];
	
	SCNNode *diffuseLightFrontNode = [SCNNode node];
	diffuseLightFrontNode.light = [SCNLight light];
	diffuseLightFrontNode.light.type = SCNLightTypeOmni;
//	diffuseLightFrontNode.light.shadowMode = SCNShadowModeDeferred;
	diffuseLightFrontNode.position = SCNVector3Make(0, self.maximumJumpHeight, self.maximumJumpHeight/3);
	[self.scene.rootNode addChildNode:diffuseLightFrontNode];
	
	[self placeWallsInScene:self.scene adjustToView:self.restAreaView height:self.wallsHeight];
	
	self.pointOfView = self.camera;
	self.allowsCameraControl = NO;
	
//	self.dice1.scale = SCNVector3Make(0.2, 0.2, 0.2);
//	[self.dice1.physicsBody resetTransform];
}

- (IBAction)resetScene:(id)sender {
	self.camera.camera.yFov = FOV;
	self.camera.camera.xFov = self.camera.camera.yFov*(self.bounds.size.width/self.bounds.size.height);
	[self removeWalls];
	[self placeWallsInScene:self.scene adjustToView:self.restAreaView height:self.wallsHeight];
}

- (SCNVector3) scenePoint:(CGPoint)point fromView:(UIView *)view {
	CGFloat frustumWidth = 2*self.cameraHeight*tan(DEGREES_TO_RADIANS(self.camera.camera.xFov)/2);
	CGFloat frustumHeight = 2*self.cameraHeight*tan(DEGREES_TO_RADIANS(self.camera.camera.yFov)/2);
	CGFloat proportionContainerViewScene = self.bounds.size.width/frustumWidth;

	CGPoint convertedPoint = [self convertPoint:point fromView:view];
	convertedPoint.x /= proportionContainerViewScene;
	convertedPoint.y /= proportionContainerViewScene;
	convertedPoint.x -= frustumWidth/2;
	convertedPoint.y -= frustumHeight/2;

	return SCNVector3Make(convertedPoint.x, convertedPoint.y, 0);
}

- (void) removeWalls {
	[self.leftWall removeFromParentNode];
	[self.leftWall removeFromParentNode];
	[self.rightWall removeFromParentNode];
	[self.frontWall removeFromParentNode];
	[self.backWall removeFromParentNode];
	[self.topWall removeFromParentNode];
	[self.bottomWall removeFromParentNode];
}

- (SCNVector3)placeWallsInScene:(SCNScene *)scene adjustToView:(UIView *)view height: (CGFloat) height {
	
	SCNVector3 origin = [self scenePoint:CGPointZero fromView:view];
	SCNVector3 final = [self scenePoint:CGPointMake(view.bounds.size.width,view.bounds.size.height) fromView:view];
	
	CGFloat viewWidth = final.x-origin.x;
	CGFloat viewHeight = final.y-origin.y;
	
//	height = viewWidth;
	
	CGFloat h2 = height/2;
	
	CGFloat wallLength = viewWidth*10;
	
	// Walls position corresponds to their center
	self.leftWall = [SCNNode node];
	self.leftWall.position = SCNVector3Make(origin.x, h2, origin.y+viewHeight/2);
	self.leftWall.geometry = [SCNBox boxWithWidth:WALL_THICKNESS height:height length:wallLength chamferRadius:0];
	[scene.rootNode addChildNode:self.leftWall];
	
	self.frontWall = [SCNNode node];
	self.frontWall.position = SCNVector3Make(origin.x+viewWidth/2, h2, origin.y+viewHeight);
	self.frontWall.geometry = [SCNBox boxWithWidth:wallLength height:height length:WALL_THICKNESS chamferRadius:0];
	[scene.rootNode addChildNode:self.frontWall];
	
	self.rightWall = [SCNNode node];
	self.rightWall.position = SCNVector3Make(origin.x+viewWidth, h2, origin.y+viewHeight/2);
	self.rightWall.geometry = [SCNBox boxWithWidth:WALL_THICKNESS height:height length:wallLength chamferRadius:0];
	[scene.rootNode addChildNode:self.rightWall];
	
	self.backWall = [SCNNode node];
	self.backWall.position = SCNVector3Make(origin.x+viewWidth/2, h2, origin.y);
	self.backWall.geometry = [SCNBox boxWithWidth:wallLength height:height length:WALL_THICKNESS chamferRadius:0];
	[scene.rootNode addChildNode:self.backWall];
	
	self.topWall = [SCNNode node];
	self.topWall.position = SCNVector3Make(origin.x+viewWidth/2, height, origin.y+viewHeight/2);
	self.topWall.geometry = [SCNBox boxWithWidth:wallLength height:WALL_THICKNESS length:wallLength chamferRadius:0];
	[scene.rootNode addChildNode:self.topWall];
	
	[self applyRigidPhysics:self.leftWall];
	[self applyRigidPhysics:self.frontWall];
	[self applyRigidPhysics:self.rightWall];
	[self applyRigidPhysics:self.backWall];
	[self applyRigidPhysics:self.topWall];
	
	// Adjust dices to center of walls
	SCNVector3 center = SCNVector3Make((final.x+origin.x)/2, (final.y+origin.y)/2, (final.z+origin.z)/2);
	self.dice1.position = SCNVector3Make(center.x, center.z, center.y);
	self.dice2.position = SCNVector3Make(center.x, center.z, center.y);
	[self.dice1.physicsBody resetTransform];
	[self.dice2.physicsBody resetTransform];
//	self.diceGroup.position = SCNVector3Make(center.x, center.z, center.y);
	
	return SCNVector3Make(origin.x+viewWidth/2, 0, origin.y+viewHeight/2);
}

- (void) adjustWallsToView:(UIView *)view {
	SCNVector3 origin = [self scenePoint:CGPointZero fromView:view];
	SCNVector3 final = [self scenePoint:CGPointMake(view.bounds.size.width,view.bounds.size.height) fromView:view];

	CGFloat viewWidth = final.x-origin.x;
	CGFloat viewHeight = final.y-origin.y;
	
	[SCNTransaction setAnimationDuration:3];
	
	self.leftWall.position = SCNVector3Make(origin.x, self.leftWall.position.y, origin.y+viewHeight/2);
	self.frontWall.position = SCNVector3Make(origin.x+viewWidth/2, self.frontWall.position.y, origin.y+viewHeight);
	self.rightWall.position = SCNVector3Make(origin.x+viewWidth, self.rightWall.position.y, origin.y+viewHeight/2);
	self.backWall.position = SCNVector3Make(origin.x+viewWidth/2, self.backWall.position.y, origin.y);
	self.topWall.position = SCNVector3Make(origin.x+viewWidth/2, self.topWall.position.y, origin.y+viewHeight/2);
	
	[SCNTransaction setCompletionBlock:^{
		if ([self.delegate respondsToSelector:@selector(dicesAdjustedToView:)]) {
			[self.delegate dicesAdjustedToView:view];
		}
	}];
}

- (void)applyRigidPhysics:(SCNNode *)node {
	node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic
											  shape:[SCNPhysicsShape shapeWithNode:node options:nil]];

	if (self.showWalls) [self setOpacity:0.5 toNode:node];
	else [self setOpacity:0.0 toNode:node];
}

- (CGFloat)randomJump {
	int lowerBound = 260;
	int upperBound = 320;
	return lowerBound + arc4random() % (upperBound - lowerBound);
}

- (IBAction)rollTheDice:(id)sender {
	[self.dice1.physicsBody applyTorque:SCNVector4Make([self randomJump], -12, 0, 10) impulse:YES];
	[self.dice2.physicsBody applyTorque:SCNVector4Make([self randomJump], +10, 0, 10) impulse:YES];
	[self adjustWallsToView:self.boardView];
	
	self.timesStopped = 0;
	
	[self.timer invalidate];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkStatus:) userInfo:nil repeats:YES];
}

- (void)checkStatus:(id)sender {
	float result = [self.dice1 jaq_rotatedVector].x;
	if ((result>0.95 && result<1.05) ||
		(result<0.05 && result>-0.05) ||
		(result>-1.05 && result<-0.95)) {
		
		self.timesStopped++;
		
		int threshold = 8;
#if TARGET_IPHONE_SIMULATOR
		threshold = 25;
#endif
		if (self.timesStopped>threshold) {
			[self.timer invalidate];
			
			[self adjustWallsToView:self.restAreaView];
			
			if ([self.delegate respondsToSelector:@selector(diceView:rolledWithFirstValue:secondValue:)]) {
				[self.delegate diceView:self
				   rolledWithFirstValue:[self.dice1 jaq_boxUpIndex]
							secondValue:[self.dice2 jaq_boxUpIndex]];
			}

			[self adjustWallsToView:self.restAreaView];
		}
	} else {
		self.timesStopped = 0;
	}
}


@end


