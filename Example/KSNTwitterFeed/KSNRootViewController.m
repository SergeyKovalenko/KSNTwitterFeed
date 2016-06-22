//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <KSNUtils/UIViewController+KSNChildViewController.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNRootViewController.h"
#import "KSNRootViewModel.h"
#import "KSNTransitionViewController.h"
#import "KSNLoginViewController.h"
#import "KSNTwitterFeedViewController.h"

@interface KSNRootViewController ()

@property (nonatomic, readwrite) KSNRootViewModel *viewModel;
@property (nonatomic, strong) KSNTransitionViewController *transitionViewController;
@end

@implementation KSNRootViewController

- (instancetype)initWithViewModel:(KSNRootViewModel *)viewModel
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _viewModel = viewModel;
        _transitionViewController = [[KSNTransitionViewController alloc] init];
        @weakify(self);
        [[viewModel transitionSignal] subscribeNext:^(id x) {
            @strongify(self);
            NSNumber *transitionNumber = KSNSafeCast([NSNumber class], x);
            NSParameterAssert(transitionNumber);
            KSNRootViewModelTransition transition = (KSNRootViewModelTransition) transitionNumber.unsignedIntegerValue;
            switch (transition)
            {
                case KSNRootViewModelToLoginTransition:
                {
                    KSNLoginViewController *loginViewController = [[KSNLoginViewController alloc] initWithViewModel:viewModel.twitterLoginViewModel];
                    [self.transitionViewController showViewController:loginViewController animated:YES];
                }
                    break;
                case KSNRootViewModelToFeedTransition:
                {
                    KSNTwitterFeedViewController *feedViewController = [[KSNTwitterFeedViewController alloc] initWithViewModel:viewModel.twitterFeedViewModel];
                    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:feedViewController];
                    [navigationController setNavigationBarHidden:YES];
                    [self.transitionViewController showViewController:navigationController animated:YES];
                }
                    break;
            }
        }];
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithViewModel:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSAssert(NO, @"initWithCoder unsupported");
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self ksn_addChildViewControllerAndSubview:self.transitionViewController viewAdjustmentBlock:^(UIView *view) {
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.frame = self.view.bounds;
    }];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.transitionViewController preferredStatusBarStyle];
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.transitionViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.transitionViewController;
}

- (BOOL)prefersStatusBarHidden
{
    return [self.transitionViewController prefersStatusBarHidden];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.transitionViewController supportedInterfaceOrientations];
}

@end