//
//  KSNNetworkReachabilityViewController.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/27/16.
//
//

#import <AFMInfoBanner/AFMInfoBanner.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNNetworkReachabilityViewController.h"
#import "KSNReachabilityPlaceholderView.h"

@interface KSNNetworkReachabilityViewController ()

@property (nonatomic, strong) AFMInfoBanner *bannerView;
@property (nonatomic, strong) KSNReachabilityPlaceholderView *placeholderView;
@property (nonatomic, assign) KSNNetworkReachabilityStatus currentStatus;
@end

@implementation KSNNetworkReachabilityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bannerView = [[AFMInfoBanner alloc] init];
    self.placeholderView = [[KSNReachabilityPlaceholderView alloc] init];
    self.placeholderView.imageView.image = [UIImage imageNamed:@"connect_icon"];
    self.placeholderView.titleLabel.text = @"No Connection";
    self.placeholderView.backgroundColor = [UIColor lightGrayColor];
    self.placeholderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.currentStatus = KSNNetworkReachabilityStatusUnknown;
    @weakify(self);
    [[[[[RACObserve(self, viewModel) ignore:nil] flattenMap:^RACStream *(id <KSNNetworkReachabilityViewModel> value) {
        return value.reachabilityStatusSignal;
    }] ignore:@(KSNNetworkReachabilityStatusUnknown)] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self reachabilityStatusChanged:(KSNNetworkReachabilityStatus) x.integerValue];
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.bannerView.topInset = self.isNavigationBarHidden ? self.topLayoutGuide.length : CGRectGetMaxY(self.navigationBar.frame);
}

- (void)reachabilityStatusChanged:(KSNNetworkReachabilityStatus)status
{
    if (self.currentStatus == KSNNetworkReachabilityStatusUnknown)
    {
        if (status == KSNNetworkReachabilityStatusNotReachable)
        {
            self.placeholderView.frame = self.view.bounds;
            [self.view addSubview:self.placeholderView];
        }
    }
    else
    {
        [self.placeholderView removeFromSuperview];
        self.bannerView.text = [self.viewModel stringFromNetworkReachabilityStatus:status];

        if (status == KSNNetworkReachabilityStatusNotReachable)
        {
            self.bannerView.style = AFMInfoBannerStyleError;
            [self.bannerView show:YES inView:self.view belowSubview:self.navigationBar];
        }
        else
        {
            if (!self.bannerView.superview)
            {
                [self.bannerView show:YES inView:self.view belowSubview:self.navigationBar];
            }
            self.bannerView.style = AFMInfoBannerStyleInfo;
            self.bannerView.text = @"Loading";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.bannerView.text = @"Connected";
                [self.bannerView performSelector:@selector(hideWithAnimatedNumber:) withObject:@YES afterDelay:1];
            });
        }
    }
    self.currentStatus = status;
}

@end
