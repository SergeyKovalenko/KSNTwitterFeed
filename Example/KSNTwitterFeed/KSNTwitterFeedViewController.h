//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSNTwitterFeedViewModel;
@class KSNFeedViewController;

@interface KSNTwitterFeedViewController : UIViewController

@property (nonatomic, readonly) KSNTwitterFeedViewModel *viewModel;

- (instancetype)initWithViewModel:(KSNTwitterFeedViewModel *)viewModel;

@end