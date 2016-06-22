//
//  KSNTransitionViewController.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNTransitionViewController.h"

static const NSTimeInterval TSTAnimationDuration = 0.3;

@interface KSNTransitionViewController ()

@property (nonatomic, strong, readwrite) UIViewController *presentedController;
@end

@implementation KSNTransitionViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showViewControllerIfNeeded];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.presentedController preferredStatusBarStyle];
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.presentedController;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.presentedController;
}

- (BOOL)prefersStatusBarHidden
{
    return [self.presentedController prefersStatusBarHidden];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.presentedController supportedInterfaceOrientations];
}

#pragma mark - KSNTransitionViewController

- (void)showViewControllerIfNeeded
{
    if (self.presentedController.parentViewController != self)
    {
        [self transitionToViewController:self.presentedController
                      fromViewController:nil
                             withOptions:UIViewAnimationOptionTransitionNone
                                animated:NO
                              completion:nil];
    }
}

- (void)showViewController:(UIViewController *)controller animated:(BOOL)animated withOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completionBlock
{
    if ([self isViewLoaded])
    {
        [self transitionToViewController:controller
                      fromViewController:self.presentedController
                             withOptions:options
                                animated:animated
                              completion:^(BOOL finished) {
                                  self.presentedController = controller;
                                  [self setNeedsStatusBarAppearanceUpdate];
                                  if (completionBlock)
                                  {
                                      completionBlock(finished);
                                  }
                              }];
    }
    else
    {
        self.presentedController = controller;
    }
}

- (void)showViewController:(UIViewController *)controller withOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completionBlock
{
    [self showViewController:controller animated:YES withOptions:options completion:completionBlock];
}

- (void)showViewController:(UIViewController *)controller animated:(BOOL)animated
{
    [self showViewController:controller animated:animated withOptions:UIViewAnimationOptionTransitionCrossDissolve completion:nil];
}

- (void)transitionToViewController:(UIViewController *)toViewController
                fromViewController:(UIViewController *)fromViewController
                       withOptions:(UIViewAnimationOptions)options
                          animated:(BOOL)animated
                        completion:(void (^)(BOOL finished))completionBlock
{
    
    UIViewAnimationOptions animationOptions = options | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionOverrideInheritedOptions;
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    
    toViewController.view.frame = self.view.bounds;
    [toViewController.view layoutIfNeeded];
    toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    fromViewController.view.frame = self.view.bounds;
    fromViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    void(^completion)(BOOL finished) = ^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
        
        if (completionBlock)
        {
            completionBlock(finished);
        }
    };
    
    if (animated)
    {
        if (fromViewController)
        {
            
            [UIView transitionFromView:fromViewController.view toView:toViewController.view duration:TSTAnimationDuration options:animationOptions completion:completion];
        }
        else
        {
        
            [UIView transitionWithView:self.view duration:TSTAnimationDuration options:animationOptions animations:^{
                [self.view addSubview:toViewController.view];
            }               completion:completion];
        }
    }
    else
    {
        [fromViewController.view removeFromSuperview];
        [self.view addSubview:toViewController.view];
        completion(YES);
    }
}

@end
