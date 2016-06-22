//
//  KSNTransitionViewController.h
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSNTransitionViewController : UIViewController

@property (nonatomic, strong, readonly) UIViewController *presentedController;

- (void)showViewController:(UIViewController *)controller animated:(BOOL)animated;
- (void)showViewController:(UIViewController *)controller withOptions:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completionBlock;

@end
