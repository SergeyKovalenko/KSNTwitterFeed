//
//  KSNSearchController.m
//
//  Created by Sergey Kovalenko on 1/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNSearchController.h"
#import "UIResponder+KSNNextViewController.h"
#import "KSNGlobalFunctions.h"
#import "UIViewController+KSNChildViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Masonry/Masonry.h>

@interface KSNSearchController () <TRASearchBarDelegate>

@property (nonatomic, retain, readwrite) UIViewController *searchResultsController;
@property (nonatomic, retain, readwrite) UIView <KSNSearchBar> *searchBar;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) BOOL dynamicResultsController;
@end

@implementation UIViewController (TRASearchControllerItem)

- (KSNSearchController *)ksn_searchController
{
    id nextResponder = [self nextResponder];
    while (!KSNSafeCast([KSNSearchController class], nextResponder) && nextResponder != nil)
    {
        nextResponder = [nextResponder nextResponder];
    }
    return nextResponder;
}

@end

@implementation KSNSearchController

#pragma mark - KSNSearchController

- (instancetype)initWithSearchResultsController:(UIViewController *)searchResultsController searchBar:(UIView <KSNSearchBar> *)searchBar;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.searchResultsController = searchResultsController;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        self.dimsBackgroundDuringPresentation = YES;
        self.dynamicResultsController = searchResultsController == nil;
        self.searchBar = searchBar;
        searchBar.delegate = self;
        [self.searchBar addTarget:self action:@selector(searchBarDidStart:) forControlEvents:TRASearchBarEventSearchDidBegin];
        [self.searchBar addTarget:self action:@selector(searchBarDidChange:) forControlEvents:TRASearchBarEventValueChanged];
        [self.searchBar addTarget:self action:@selector(searchBarDidEnd:) forControlEvents:TRASearchBarEventSearchDidEnd];
        self.clearSearchOnDeactivate = YES;
    }
    return self;
}

- (void)setActive:(BOOL)active
{
    if (_active != active)
    {
        _active = active;
        if (!_active)
        {
            if (self.clearSearchOnDeactivate)
            {
                [self.searchBar clearSearchCriteria];
            }

            if ([self.delegate respondsToSelector:@selector(searchControllerEndSearch:)])
            {
                [self.delegate searchControllerEndSearch:self];
            }
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(searchControllerStartSearch:)])
            {
                [self.delegate searchControllerStartSearch:self];
            }
        }
        [self deferredUpdate];
    }
}

- (void)cancelDeferredUpdate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
}

- (void)deferredUpdate
{
    __weak id weakSelf = self;
    [self cancelDeferredUpdate];
    [weakSelf performSelector:@selector(update) withObject:nil afterDelay:0.1];
}

- (void)update
{
    if (!self.active && self.active != [self.searchBar isFirstResponder])
    {
        [self.searchBar resignFirstResponder];
    }
    [self p_starSearchControllerTransition:^{
        if (self.active && self.active != [self.searchBar isFirstResponder])
        {
            [self.searchBar becomeFirstResponder];
        }
    }];
}

#pragma mark - KSNSearchController

- (void)viewDidLoad
{
    [super viewDidLoad];
    RAC(self.view, backgroundColor) = [RACObserve(self, dimsBackgroundDuringPresentation) map:^id(NSNumber *hide) {
        return !hide.boolValue ? [UIColor clearColor] : [[UIColor blackColor] colorWithAlphaComponent:0.3];
    }];
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimViewTapped:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    [self p_searchResultsControllerAsParent];
}

- (void)dimViewTapped:(UITapGestureRecognizer *)tap
{
    if (self.dimsBackgroundDuringPresentation && tap.state == UIGestureRecognizerStateRecognized)
    {
        self.active = NO;
    }
}

#pragma mark - Private Methods

- (void)p_searchResultsControllerAsParent
{
    if (self.searchResultsController)
    {
        [self ksn_addChildViewControllerAndSubview:self.searchResultsController viewAdjustmentBlock:nil];
        [self p_hideSearchResultsControllerIfNeeded];
    }
}

- (void)p_starSearchControllerTransition:(void (^)(void))completion
{
    [self p_notifyWillChangeTransition];
    if (self.isActive)
    {
        [self p_showSearchController:completion];
    }
    else
    {
        [self p_hideSearchController:completion];
    }
    [self p_notifyDidChangeTransition];
}

- (void)p_notifyWillChangeTransition
{
    if (self.isActive)
    {
        if ([self.delegate respondsToSelector:@selector(willPresentSearchController:)])
        {
            [self.delegate willPresentSearchController:self];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(willDismissSearchController:)])
        {
            [self.delegate willDismissSearchController:self];
        }
    }
}

- (void)p_notifyDidChangeTransition
{
    if (self.isActive)
    {
        if ([self.delegate respondsToSelector:@selector(didPresentSearchController:)])
        {
            [self.delegate didPresentSearchController:self];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(didDismissSearchController:)])
        {
            [self.delegate didDismissSearchController:self];
        }
    }
}

- (BOOL)p_presentSearchControllerExternally
{
    BOOL externalPresentationSupported = [self.delegate respondsToSelector:@selector(presentSearchController:)];
    if (externalPresentationSupported)
    {
        [self.delegate presentSearchController:self];
    }
    return externalPresentationSupported;
}

- (void)p_showSearchController:(void (^)(void))completion
{
    if (![self p_presentSearchControllerExternally])
    {
        UIViewController *toViewController = [self.searchBar ksn_nextViewController];
        if ([toViewController isKindOfClass:[UINavigationController class]])
        {
            toViewController = [KSNSafeCast([UINavigationController class], toViewController) topViewController];
        }
        if (self.dynamicResultsController && [self.delegate respondsToSelector:@selector(searchControllerWillShowSearchResultsControllerFor:)])
        {
            self.searchResultsController = [self.delegate searchControllerWillShowSearchResultsControllerFor:self];
            [self ksn_addChildViewControllerAndSubview:self.searchResultsController viewAdjustmentBlock:^(UIView *view) {
                view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                view.frame = self.view.bounds;
            }];
            [self p_hideSearchResultsControllerIfNeeded];
        }
        [toViewController ksn_addChildViewControllerAndSubview:self viewAdjustmentBlock:^(UIView *view) {
            view.alpha = 0.f;
        }];

        [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.searchBar.mas_bottom);
            make.leading.equalTo(toViewController.view);
            make.trailing.equalTo(toViewController.view);
            make.bottom.equalTo(toViewController.view);
        }];

        [UIView animateWithDuration:0.3
                              delay:0.3
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.view.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             if (completion)
                             {
                                 completion();
                             }
                         }];
    }
    else if (completion)
    {
        completion();
    }
}

- (void)p_hideSearchController:(void (^)(void))completion
{
    if (self.parentViewController)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.view.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [self.parentViewController ksn_removeChildViewControllerAndSubview:self];
                             if (self.dynamicResultsController)
                             {
                                 [self ksn_removeChildViewControllerAndSubview:self.searchResultsController];
                                 self.searchResultsController = nil;
                             }
                             if (completion)
                             {
                                 completion();
                             }
                         }];
    }
    else if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:UIViewAnimationOptionCurveEaseInOut completion:^{
            if (self.dynamicResultsController)
            {
                [self ksn_removeChildViewControllerAndSubview:self.searchResultsController];
                self.searchResultsController = nil;
            }
            if (completion)
            {
                completion();
            }
        }];
    }
}

- (void)p_hideSearchResultsControllerIfNeeded
{
    BOOL hasSearchCriteria = [self.searchBar hasSearchCriteria];
    self.searchResultsController.view.hidden = !hasSearchCriteria;
    self.tapGestureRecognizer.enabled = !hasSearchCriteria;
}

#pragma mark - TRASearchBarDelegate

- (void)searchBarDidStart:(UIView <KSNSearchBar> *)searchBar
{
    [self p_hideSearchResultsControllerIfNeeded];
    [self setActive:YES];
}

- (void)searchBarDidEnd:(UIView <KSNSearchBar> *)searchBar
{
}

- (void)searchBarDidChange:(UIView <KSNSearchBar> *)searchBar
{
    __weak KSNSearchController *this = self;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSearchBarDidChange:) object:searchBar];
    [this performSelector:@selector(handleSearchBarDidChange:) withObject:searchBar afterDelay:0.5];
}

- (void)handleSearchBarDidChange:(UIView <KSNSearchBar> *)searchBar
{
    [self p_hideSearchResultsControllerIfNeeded];
    [self.searchResultsUpdater updateSearchResultsForSearchController:self];
}

- (void)searchBarSearchButtonClicked:(UIView *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
