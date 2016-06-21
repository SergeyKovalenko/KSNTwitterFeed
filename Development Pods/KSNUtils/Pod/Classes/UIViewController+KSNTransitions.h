//
//  UIViewController+KSNTransitions.h
//
//  Created by Sergey Kovalenko on 1/16/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIViewController (KSNTransitions)

- (void)ksn_transitionToViewController:(UIViewController *)toViewController
                    fromViewController:(UIViewController *)fromViewController
                   viewAdjustmentBlock:(void (^)(UIView *fromView, UIView *toView))adjustmentBlock
                           withOptions:(UIViewAnimationOptions)options
                              animated:(BOOL)animated
                            completion:(void (^)(BOOL finished))completionBlock;

- (void)ksn_transitionToViewController:(UIViewController *)toViewController
                    fromViewController:(UIViewController *)fromViewController
                                inView:(UIView *)inView
                   viewAdjustmentBlock:(void (^)(UIView *fromView, UIView *toView))adjustmentBlock
                           withOptions:(UIViewAnimationOptions)options
                              animated:(BOOL)animated
                            completion:(void (^)(BOOL finished))completionBlock;
@end
