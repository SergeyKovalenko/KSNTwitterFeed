//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSNRootViewModel;
@class KSNTransitionViewController;

@interface KSNRootViewController : UIViewController

@property (nonatomic, readonly) KSNRootViewModel *viewModel;

- (instancetype)initWithViewModel:(KSNRootViewModel *)viewModel;

@end