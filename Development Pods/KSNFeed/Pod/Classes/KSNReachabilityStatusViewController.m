//
//  KSNReachabilityStatusViewController.m

//
//  Created by Sergey Kovalenko on 1/15/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNReachabilityStatusViewController.h"
#import "KSNReachabilityViewModel.h"
#import "KSNInfoStatusView.h"
#import "KSNLoadingIndicator.h"
#import "UIViewController+KSNTransitions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface KSNReachabilityStatusViewController ()

@property (nonatomic, strong, readwrite) UIViewController *contentViewController;
@property (nonatomic, strong) KSNInfoStatusView *instructionsView;
@property (nonatomic, strong) KSNLoadingIndicator *loadingIndicator;
@property (nonatomic, strong) UIView *disableOverlay;
@end

@implementation KSNReachabilityStatusViewController

#pragma mark - KSNReachabilityStatusViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithReachabilityViewModel:nil];
}


- (id)initWithCoder:(NSCoder *)aDecoder;
{
    return [super initWithCoder:aDecoder];
}

- (instancetype)initWithReachabilityViewModel:(id <KSNReachabilityViewModel>)viewModel
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)showContentViewController:(UIViewController *)controller animated:(BOOL)animated
{
    if ([self isViewLoaded])
    {
        [self transitionToViewController:controller
                      fromViewController:self.contentViewController
                             withOptions:UIViewAnimationOptionTransitionCrossDissolve
                                animated:animated
                              completion:^(BOOL finished) {
                                  self.contentViewController = controller;
                              }];
    }
    else
    {
        self.contentViewController = controller;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self showViewControllerIfNeeded];
    [self loadInstructionsView];
    [self createLoadingIndicator];
    [self createDisableOverlayViewIfNeeded];
    [self createErrorBanner];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.contentViewController setEditing:editing animated:animated];
}

- (void)wk_scrollToTop
{
//    [self.contentViewController wk_scrollToTop];
}

#pragma mark - Public

- (void)setTopLoadingIndicatorInset:(CGFloat)topLoadingIndicatorInset
{
    if (_topLoadingIndicatorInset != topLoadingIndicatorInset)
    {
        _topLoadingIndicatorInset = topLoadingIndicatorInset;
        [self p_adjustLoadingIndicator];
    }
}

#pragma mark - Private methods

- (void)showViewControllerIfNeeded
{
    if (self.contentViewController)
    {
        [self transitionToViewController:self.contentViewController
                      fromViewController:nil
                             withOptions:UIViewAnimationOptionTransitionNone
                                animated:NO
                              completion:nil];
    }
}

- (void)loadInstructionsView
{
    NSString *nibName;
    if ([self.viewModel respondsToSelector:@selector(infoStatusViewNibName)])
    {
        nibName = [self.viewModel infoStatusViewNibName];
    }
    self.instructionsView = [[KSNInfoStatusView alloc] initWithNibName:nibName];
    self.instructionsView.backgroundColor = [UIColor redColor];
    self.instructionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.instructionsView.frame = self.view.bounds;
    [self.instructionsView.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.instructionsView];

    RAC(self.instructionsView, hidden) = RACObserve(self, viewModel.instructionsViewHidden);
    RAC(self.instructionsView, titleLabel.text) = RACObserve(self, viewModel.instructionsTitle);
    RAC(self.instructionsView, subtitleLabel.text) = RACObserve(self, viewModel.instructionsSubtitle);
    RAC(self.instructionsView.titleLabel, textColor) = RACObserve(self, viewModel.instructionsViewTintColor);
    RAC(self.instructionsView.subtitleLabel, textColor) = RACObserve(self, viewModel.instructionsViewTintColor);
    RAC(self.instructionsView.refreshButton, tintColor) = RACObserve(self, viewModel.instructionsViewTintColor);
    RAC(self.instructionsView, backgroundColor) = RACObserve(self, viewModel.instructionsViewBackgroundColor);
    RAC(self.instructionsView.refreshButton, hidden) = [RACObserve(self.viewModel, refreshEnabled) not];
}

- (void)refresh:(id)refresh
{
    if ([self.viewModel respondsToSelector:@selector(refresh:)])
    {
        [self.viewModel refresh:refresh];
    }
}

- (void)createLoadingIndicator
{
    self.loadingIndicator = [[KSNLoadingIndicator alloc] initWithFrame:self.view.bounds];
//    self.loadingIndicator.color = [UIColor wk_tintColor];
    [self.loadingIndicator sizeToFit];
    self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self p_adjustLoadingIndicator];
    [self.view addSubview:self.loadingIndicator];
    [self rac_liftSelector:@selector(updateIndicatorWithLoading:) withSignals:RACObserve(self, viewModel.loading), nil];
}

- (void)createDisableOverlayViewIfNeeded
{
    if (!self.disableOverlay)
    {
        UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.alpha = 0.5f;
        self.disableOverlay = view;
        if ([self.viewModel respondsToSelector:@selector(isContentDimmed)])
        {
            [self rac_liftSelector:@selector(updateDisableOverlay:) withSignals:RACObserve(self, viewModel.dimContent), nil];
        }
    }
}

- (void)createErrorBanner
{
//    self.errorBanner = [[AFMInfoBanner alloc] init];
//    self.errorBanner.style = AFMInfoBannerStyleError;
//    @weakify(self);
//    [[RACObserve(self, viewModel.reachabilityError) ignore:nil] subscribeNext:^(NSError *error) {
//        @strongify(self);
//        self.errorBanner.text = error.localizedDescription;
//        [self.errorBanner show:YES inView:self.view];
//        [NSObject cancelPreviousPerformRequestsWithTarget:self.errorBanner selector:@selector(hide:) object:@YES];
//        [self.errorBanner performSelector:@selector(hide:) withObject:@YES afterDelay:3.0f];
//    }];
}

- (void)updateDisableOverlay:(BOOL)show
{
    if (show)
    {
        [self addDisableOverlay];
    }
    else
    {
        [self removeDisableOverlay];
    }
}

- (void)addDisableOverlay
{
    [self removeDisableOverlay];
    CGRect disableRect = self.disableOverlay.frame;
    disableRect.size.height = CGRectGetHeight(self.view.frame);
    disableRect.size.width = CGRectGetWidth(self.view.frame);
    self.disableOverlay.frame = disableRect;
    self.disableOverlay.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:self.disableOverlay belowSubview:self.loadingIndicator];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//#pragma message("TODO: (Sergey) !!")
//        self.disableOverlay.backgroundColor = [UIColor wk_disableOverlayColor];
    }                completion:NULL];
}

- (void)removeDisableOverlay
{
//    self.view.userInteractionEnabled = YES;
    if (self.disableOverlay.superview)
    {
        [self.disableOverlay removeFromSuperview];
    }
}

- (void)updateIndicatorWithLoading:(BOOL)loading
{
    if (loading)
    {
        [self.view bringSubviewToFront:self.loadingIndicator];
        [self p_adjustLoadingIndicator];
        [self.loadingIndicator fakeProgressWithDuration:self.viewModel.fakeLoadingDuration];
    }
    else
    {
        [self.loadingIndicator finish];
    }
}

- (void)transitionToViewController:(UIViewController *)toViewController
                fromViewController:(UIViewController *)fromViewController
                       withOptions:(UIViewAnimationOptions)options
                          animated:(BOOL)animated
                        completion:(void (^)(BOOL finished))completionBlock
{
    [self ksn_transitionToViewController:toViewController
                      fromViewController:fromViewController
                     viewAdjustmentBlock:^(UIView *fromView, UIView *toView) {
                         fromView.frame = self.view.bounds;
                         toView.frame = self.view.bounds;
                         toView.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                     }
                             withOptions:options
                                animated:animated
                              completion:completionBlock];
}

- (void)p_adjustLoadingIndicator
{
    if ([self isViewLoaded])
    {
        CGRect frame = self.loadingIndicator.frame;
        frame.origin.y = self.topLoadingIndicatorInset;
        self.loadingIndicator.frame = frame;
    }
}

@end
