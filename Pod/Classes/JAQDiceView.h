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
- (void)diceView:(JAQDiceView *)view rolledWithFirstValue:(NSInteger)firstValue secondValue:(NSInteger)secondValue;
@end

@interface JAQDiceView : SCNView

@property (nonatomic, weak) id<JAQDiceProtocol> delegate;

@property (nonatomic, assign) IBInspectable CGFloat maximumJumpHeight;
@property (nonatomic, assign) IBInspectable CGFloat squareSizeHeight;
@property (nonatomic, assign) IBInspectable BOOL cameraPerspective;

@property (nonatomic, weak) IBOutlet UIView *boardView;
@property (nonatomic, weak) IBOutlet UIView *restAreaView;

- (IBAction)rollTheDice:(id)sender;

@end

