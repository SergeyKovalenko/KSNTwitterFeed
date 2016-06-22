//
//  KSNLoginViewController.h
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

@import UIKit;

@class KSNTwitterLoginViewModel;

@interface KSNLoginViewController : UIViewController

@property (nonatomic, readonly) KSNTwitterLoginViewModel *viewModel;

- (instancetype)initWithViewModel:(KSNTwitterLoginViewModel *)viewModel;

@end
