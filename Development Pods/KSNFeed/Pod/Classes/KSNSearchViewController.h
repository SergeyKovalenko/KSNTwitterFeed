//
//  KSNSearchViewController.h

//
//  Created by Sergey Kovalenko on 11/5/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KSNSearchController;

@interface KSNSearchViewController : UIViewController

- (instancetype)initWithSearchController:(KSNSearchController *)searchController;

- (void)showContentViewController:(UIViewController *)controller animated:(BOOL)animated;

@property (nonatomic, strong, readonly) UIViewController *contentController;

- (UIBarButtonItem *)searchButton;
@end
