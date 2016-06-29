//
//  KSNNetworkReachabilityViewController.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/27/16.
//
//

#import <UIKit/UIKit.h>
#import "KSNNetworkReachabilityViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KSNNetworkReachabilityViewModel;

@interface KSNNetworkReachabilityViewController : UINavigationController

@property (nullable, nonatomic, strong) id <KSNNetworkReachabilityViewModel> viewModel;

@end

NS_ASSUME_NONNULL_END
