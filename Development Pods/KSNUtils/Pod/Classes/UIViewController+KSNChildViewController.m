//
//  UIViewController+KSNChildViewController.m
//
//  Created by Sergey Kovalenko on 1/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "UIViewController+KSNChildViewController.h"

@implementation UIViewController (KSNChildViewController)

- (void)ksn_addChildViewControllerAndSubview:(UIViewController *)vc viewAdjustmentBlock:(void (^)(UIView *view))adjustmentBlock
{
    [self ksn_addChildViewControllerAndSubview:vc toView:self.view viewAdjustmentBlock:adjustmentBlock];
}

- (void)ksn_addChildViewControllerAndSubview:(UIViewController *)vc toView:(UIView *)view viewAdjustmentBlock:(void (^)(UIView *view))adjustmentBlock
{
    [self addChildViewController:vc];

    BOOL isParentVisible = [self isViewLoaded] && self.view.window;

    if (isParentVisible)
    {
        [vc beginAppearanceTransition:YES animated:NO];
    }

    if (adjustmentBlock)
    {
        adjustmentBlock(vc.view);
    }
    [view addSubview:vc.view];

    [vc didMoveToParentViewController:self];

    if (isParentVisible)
    {
        [vc endAppearanceTransition];
    }
}

- (void)ksn_removeChildViewControllerAndSubview:(UIViewController *)vc
{
    BOOL isParentVisible = [self isViewLoaded] && self.view.window;

    if (isParentVisible)
    {
        [vc beginAppearanceTransition:NO animated:NO];
    }

    [vc willMoveToParentViewController:nil];
    if ([vc isViewLoaded])
    {
        [vc.view removeFromSuperview];
    }

    if (isParentVisible)
    {
        [vc endAppearanceTransition];
    }

    [vc removeFromParentViewController];
}

@end
