//
//  KSNLoadingView.h
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/27/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KSNRefreshView;

@interface KSNLoadingView : UIView

@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong, readonly) KSNRefreshView *refreshView;
@end
