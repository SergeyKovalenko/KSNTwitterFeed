//
//  UIViewController+KSNChildViewController.h
//
//  Created by Sergey Kovalenko on 1/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (KSNChildViewController)

- (void)ksn_addChildViewControllerAndSubview:(UIViewController *)vc viewAdjustmentBlock:(void (^)(UIView *view))adjustmentBlock;

- (void)ksn_addChildViewControllerAndSubview:(UIViewController *)vc toView:(UIView *)view viewAdjustmentBlock:(void (^)(UIView *view))adjustmentBlock;

- (void)ksn_removeChildViewControllerAndSubview:(UIViewController *)vc;

@end
