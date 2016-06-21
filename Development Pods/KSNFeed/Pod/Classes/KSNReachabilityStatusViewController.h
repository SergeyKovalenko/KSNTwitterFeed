//
//  KSNReachabilityStatusViewController.h
//
//  Created by Sergey Kovalenko on 1/15/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KSNReachabilityViewModel;
@class KSNLoadingIndicator;

@interface KSNReachabilityStatusViewController : UIViewController

@property (nonatomic, assign) CGFloat topLoadingIndicatorInset;

@property (nonatomic, strong) id <KSNReachabilityViewModel> viewModel;

- (instancetype)initWithReachabilityViewModel:(id <KSNReachabilityViewModel>)viewModel NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)showContentViewController:(UIViewController *)controller animated:(BOOL)animated;

@property (nonatomic, strong, readonly) UIViewController *contentViewController;

@end
