//
//  UIViewController+KSNTransitions.h
//
//  Created by Sergey Kovalenko on 1/16/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "UIViewController+KSNTransitions.h"

static const NSTimeInterval KSNTransitionAnimationDuration = 0.3;

@implementation UIViewController (KSNTransitions)

- (void)ksn_transitionToViewController:(UIViewController *)toViewController
                    fromViewController:(UIViewController *)fromViewController
                   viewAdjustmentBlock:(void (^)(UIView *fromView, UIView *toView))adjustmentBlock
                           withOptions:(UIViewAnimationOptions)options
                              animated:(BOOL)animated
                            completion:(void (^)(BOOL finished))completionBlock
{
    return [self ksn_transitionToViewController:toViewController
                             fromViewController:fromViewController
                                         inView:nil
                            viewAdjustmentBlock:adjustmentBlock
                                    withOptions:options
                                       animated:animated
                                     completion:completionBlock];
}

- (void)ksn_transitionToViewController:(UIViewController *)toViewController
                    fromViewController:(UIViewController *)fromViewController
                                inView:(UIView *)inView
                   viewAdjustmentBlock:(void (^)(UIView *fromView, UIView *toView))adjustmentBlock
                           withOptions:(UIViewAnimationOptions)options
                              animated:(BOOL)animated
                            completion:(void (^)(BOOL finished))completionBlock
{
    UIViewAnimationOptions animationOptions = options | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionOverrideInheritedOptions;

    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];

    UIView *containerView = inView ?: self.view;

    void(^completion)(BOOL) = ^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];

        if (completionBlock)
        {
            completionBlock(finished);
        }
    };

    if (adjustmentBlock)
    {
        adjustmentBlock(fromViewController.view, toViewController.view);
    }

    if (animated)
    {
        if (fromViewController)
        {
            [UIView transitionFromView:fromViewController.view
                                toView:toViewController.view
                              duration:KSNTransitionAnimationDuration
                               options:animationOptions
                            completion:completion];
        }
        else
        {
            [UIView transitionWithView:containerView duration:KSNTransitionAnimationDuration options:animationOptions animations:^{
                [containerView addSubview:toViewController.view];
            }               completion:completion];
        }
    }
    else
    {
        [fromViewController.view removeFromSuperview];
        [containerView addSubview:toViewController.view];
        completion(YES);
    }
}

@end
