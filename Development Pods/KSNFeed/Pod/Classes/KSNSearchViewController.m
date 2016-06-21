//
//  KSNSearchViewController.m

//
//  Created by Sergey Kovalenko on 11/5/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNSearchViewController.h"
#import "KSNSearchController.h"
#import "UIViewController+KSNTransitions.h"
#import <Masonry/Masonry.h>

@interface KSNSearchViewController ()

@property (nonatomic, strong) UIBarButtonItem *searchButton;

@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong, readwrite) UIViewController *contentController;
@property (nonatomic, strong) KSNSearchController *searchController;
@end

@implementation KSNSearchViewController

#pragma mark - KSNSearchViewController Public Methods

- (instancetype)initWithSearchController:(KSNSearchController *)searchController
{
    self = [super init];
    if (self)
    {
        self.searchController = searchController;
    }
    return self;
}

- (void)showContentViewController:(UIViewController *)controller animated:(BOOL)animated
{
    if ([self isViewLoaded])
    {
        [self transitionToViewController:controller
                      fromViewController:self.contentController
                             withOptions:UIViewAnimationOptionTransitionCrossDissolve
                                animated:animated
                              completion:^(BOOL finished) {
                                  self.contentController = controller;
                              }];
    }
    else
    {
        self.contentController = controller;
    }
}

- (UIBarButtonItem *)searchButton
{
    if (!_searchButton)
    {
        UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage new] // !!!
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(toggleSearchBar)];
//        RAC(searchButton, tintColor) = [RACObserve(self.searchController, active) map:^id(NSNumber *active) {
//            return active.boolValue ? [UIColor wk_tabBarTintColor] : nil;
//        }];
        _searchButton = searchButton;
    }

    return _searchButton;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadContentView];
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    // Adjust content view top position from under nav bar
//    CGRect contentRect = self.view.bounds;
//    // iOS 7 bug
//    CGFloat topInset = MAX(self.topLayoutGuide.length, self.parentViewController.topLayoutGuide.length);
//    contentRect.origin.y = topInset;
//    contentRect.size.height -= topInset;
//    self.contentContainerView.frame = contentRect;
//}

#pragma mark - TRASearchController Private Methods

- (void)loadContentView
{
    self.contentContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentContainerView];
    [self loadSearchBar];
    [self showViewControllerIfNeeded];
}

- (void)loadSearchBar
{
    UIView <KSNSearchBar> *searchBar = self.searchController.searchBar;
    if (searchBar)
    {
        [self.view addSubview:searchBar];
        [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
        }];
    }

    [self.contentContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchBar.mas_bottom ?: self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

- (void)toggleSearchBar
{
    self.searchController.active = !self.searchController.active;
}

- (void)showViewControllerIfNeeded
{
    if (self.contentController)
    {
        [self transitionToViewController:self.contentController
                      fromViewController:nil
                             withOptions:UIViewAnimationOptionTransitionNone
                                animated:NO
                              completion:nil];
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
                                  inView:self.contentContainerView
                     viewAdjustmentBlock:^(UIView *fromView, UIView *toView) {
//                         CGRect contentRect = self.contentContainerView.bounds;
//                         contentRect.origin.y = CGRectGetHeight(self.searchController.searchBar.frame);
//                         contentRect.size.height -= CGRectGetHeight(self.searchController.searchBar.frame);
                         fromView.frame = self.contentContainerView.bounds;
                         toView.frame = self.contentContainerView.bounds;
                         toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;;
                     }
                             withOptions:options
                                animated:animated
                              completion:^(BOOL finished) {
//                                  [toViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
//                                      make.top.equalTo(self.searchController.searchBar.mas_bottom);
//                                      make.left.equalTo(self.contentContainerView.mas_left);
//                                      make.right.equalTo(self.contentContainerView.mas_right);
//                                      make.bottom.equalTo(self.contentContainerView.mas_bottom);
//                                  }];
                                  if (completionBlock)
                                  {
                                      completionBlock(finished);
                                  }
                              }];
}

@end
