//
//  UIView+KSNAdditions.h
//
//  Created by Sergey Kovalenko on 2/27/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSNBlocks.h"

@interface UIView (KSNAdditions)

@property (nonatomic, assign) CGFloat frameLeft;
@property (nonatomic, assign) CGFloat frameTop;
@property (nonatomic, assign) CGFloat frameRight;
@property (nonatomic, assign) CGFloat frameBottom;
@property (nonatomic, assign) CGFloat frameWidth;
@property (nonatomic, assign) CGFloat frameHeight;
@property (nonatomic, assign) CGPoint frameCenter;
@property (nonatomic, assign) CGFloat frameCenterX;
@property (nonatomic, assign) CGFloat frameCenterY;
@property (nonatomic, readonly) CGFloat boundsTop;
@property (nonatomic, readonly) CGFloat boundsBottom;
@property (nonatomic, readonly) CGFloat boundsLeft;
@property (nonatomic, readonly) CGFloat boundsRight;
@property (nonatomic, readonly) CGPoint boundsCenter;

- (void)ksn_shakeWithMagnitude:(CGFloat)magnitude duration:(CFTimeInterval)duration repeatCount:(float)repeatCount;
- (void)ksn_addShakeAnimatinon;

- (UIImage *)ksn_screenshot;
- (UIView *)ksn_snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;

- (void)ksn_enumerateSubviews:(void (^)(UIView *view, NSUInteger depth, BOOL *recurse))block;

- (NSString *)ksn_describeSubviews;
- (NSString *)ksn_describeViewTree;

+ (void)ksn_beginViewsAtTouch;


+ (void)ksn_animateWithDuration:(NSTimeInterval)duration
                          delay:(NSTimeInterval)delay
         usingSpringWithDamping:(CGFloat)dampingRatio
          initialSpringVelocity:(CGFloat)velocity
                        options:(UIViewAnimationOptions)options
                     animations:(void (^)(void))animations
                     completion:(void (^)(BOOL finished))completion;

+ (void)ksn_performBlock:(KSNVoidBlock)block
   withAnimationDuration:(NSTimeInterval)duration
                animated:(BOOL)animated
              completion:(void (^)(BOOL))completion;

@end
