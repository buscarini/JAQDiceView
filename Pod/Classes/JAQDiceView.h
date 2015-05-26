//
//  JAQDiceView.h
//  Pods
//
//  Created by Javier Querol on 19/11/14.
//
//

#import <SceneKit/SceneKit.h>

@class JAQDiceView;

@protocol JAQDiceProtocol <NSObject>

- (void) diceViewWillRoll:(JAQDiceView *)view;
- (void)diceView:(JAQDiceView *)view rolledWithFirstValue:(NSInteger)firstValue secondValue:(NSInteger)secondValue;

@optional

- (void) dicesAdjustedToView:(UIView *)view;

@end

@interface JAQDiceView : SCNView

@property (nonatomic, weak) id<JAQDiceProtocol> delegate;

@property (nonatomic, assign) IBInspectable CGFloat maximumJumpHeight;
@property (nonatomic, assign) IBInspectable CGFloat squareSizeHeight;
@property (nonatomic, assign) IBInspectable BOOL cameraPerspective;

@property (nonatomic, assign) IBInspectable BOOL showWalls; // Usefull for debugging

@property (nonatomic, weak) IBOutlet UIView *boardView;
@property (nonatomic, weak) IBOutlet UIView *restAreaView;

- (IBAction)rollTheDice:(id)sender;
- (IBAction)resetScene:(id)sender;

@end

