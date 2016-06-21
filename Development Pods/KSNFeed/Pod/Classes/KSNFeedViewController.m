//
//  KSNFeedViewController.m
//
//  Created by Sergey Kovalenko on 4/29/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNFeedViewController.h"
#import "KSNFeedViewModel.h"
#import "KSNTableViewController.h"
#import <KSNDataSource/KSNDataSource.h>
#import "KSNReachabilityStatusViewController.h"
#import "KSNSearchViewController.h"
#import "KSNSearchController.h"
#import "KSNCollectionViewController.h"
#import "KSNCollectionViewModelTraits.h"
#import "KSNTableViewModelTraits.h"
#import "KSNSearchBar.h"
#import "UIViewController+KSNChildViewController.h"
#import "KSNGlobalFunctions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface KSNFeedViewController () <KSNDataSourceObserver, TRASearchControllerUpdating, KSNSearchControllerDelegate>

@property (nonatomic, strong, readwrite) id <KSNFeedViewModel> feedViewModel;
@property (nonatomic, strong, readwrite) id <KSNSearchableFeedViewModel> searchFeedViewModel;
@property (nonatomic, strong) KSNSearchViewController *searchContentViewController;
@property (nonatomic, strong) KSNSearchController *searchController;
@property (nonatomic, strong) RACSignal *insetsSignal;

@property (nonatomic, strong) KSNTableViewController *tableViewController;
@property (nonatomic, strong) KSNCollectionViewController *collectionViewController;

@property (nonatomic, strong) UIView <KSNSearchBar> *searchBar;

@end

@implementation KSNFeedViewController

- (instancetype)initWithFeedViewModel:(id <KSNFeedViewModel>)feedViewModel searchFeedViewModel:(id <KSNSearchableFeedViewModel>)searchFeedViewModel
{
    return [self initWithFeedViewModel:feedViewModel searchFeedViewModel:searchFeedViewModel searchBar:nil];
}

- (instancetype)initWithFeedViewModel:(id <KSNFeedViewModel>)feedViewModel
                  searchFeedViewModel:(id <KSNSearchableFeedViewModel>)searchFeedViewModel
                            searchBar:(UIView <KSNSearchBar> *)searchBar
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.feedViewModel = feedViewModel;
        self.searchFeedViewModel = searchFeedViewModel;
        self.searchBar = searchBar;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithFeedViewModel:nil searchFeedViewModel:nil];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    NSAssert(self.feedViewModel, @"feedViewModel is required");

    UIViewController *searchResultsViewController = [self createFeedStackControllerWithForFeedViewModel:self.searchFeedViewModel];

    // Search controller for managing search results presentation
    UIView <KSNSearchBar> *searchBar = self.searchFeedViewModel ? (self.searchBar ?: [KSNSearchBar new]) : nil;
    self.searchController = [[KSNSearchController alloc] initWithSearchResultsController:searchResultsViewController searchBar:searchBar];
    // For updating search result according to new input
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;

    UIViewController *contentViewController = [self createFeedStackControllerWithForFeedViewModel:self.feedViewModel];
    // Manage search bar presentation
    self.searchContentViewController = [[KSNSearchViewController alloc] initWithSearchController:self.searchController];
    [self.searchContentViewController showContentViewController:contentViewController animated:NO];

    [self setupNavigationItem];
}

- (UIViewController *)createFeedStackControllerWithForFeedViewModel:(id <KSNFeedViewModel>)feedViewModel
{
    if (!feedViewModel)
    {
        return nil;
    }

    UIViewController *contentController = nil;

    if ([feedViewModel respondsToSelector:@selector(tableViewModel)] && feedViewModel.tableViewModel)
    {
        UITableViewStyle style = [feedViewModel.tableViewModel respondsToSelector:@selector(tableStyle)] ? [feedViewModel.tableViewModel tableStyle] : UITableViewStylePlain;
        KSNTableViewController *tableViewController = [[KSNTableViewController alloc] initWithStyle:style];
        RAC(tableViewController, tableViewDataSource) = RACObserve(feedViewModel, dataSource);
        RAC(tableViewController, viewModel) = RACObserve(feedViewModel, tableViewModel);
        RAC(tableViewController, listInsets) = [self insetsSignal];
        RAC(tableViewController, scrollIndicatorInsets) = [self insetsSignal];
        [RACObserve(tableViewController, tableView) subscribeNext:^(UITableView *tableView) {
            tableView.separatorStyle = [feedViewModel.tableViewModel respondsToSelector:@selector(separatorStyle)] ? [feedViewModel.tableViewModel separatorStyle] : UITableViewCellSeparatorStyleNone;
        }];
        contentController = tableViewController;
        self.tableViewController = tableViewController;
    }
    else if ([feedViewModel respondsToSelector:@selector(collectionViewModel)] && feedViewModel.collectionViewModel)
    {
        KSNCollectionViewController *collectionViewController = [[KSNCollectionViewController alloc] initWithCollectionViewLayout:feedViewModel.collectionViewModel.layout];
        RAC(collectionViewController, viewModel) = RACObserve(feedViewModel, collectionViewModel);
        RAC(collectionViewController, dataSource) = RACObserve(feedViewModel, dataSource);

//        if ([feedViewModel respondsToSelector:@selector(selectionDataSource)])
//        {
//            RAC(collectionViewController, selectionDataSource) = RACObserve(feedViewModel, selectionDataSource);
//        }

        RAC(collectionViewController, listInsets) = [self insetsSignal];
        RAC(collectionViewController, scrollIndicatorInsets) = [self insetsSignal];
        collectionViewController.showLogo = YES;
        contentController = collectionViewController;
        self.collectionViewController = collectionViewController;
    }
    else
    {
        NSAssert(NO, @"Feed View Model should implement either tableViewModel or collectionViewModel method.");
    }

    // Embedding in status VC
    KSNReachabilityStatusViewController *reachabilityStatusViewController = [[KSNReachabilityStatusViewController alloc] initWithReachabilityViewModel:[feedViewModel reachabilityViewModel]];
    [reachabilityStatusViewController showContentViewController:contentController animated:NO];
    return reachabilityStatusViewController;
}

- (RACSignal *)insetsSignal
{
    if (!_insetsSignal)
    {
        @weakify(self);
        _insetsSignal = [[self rac_signalForSelector:@selector(viewDidLayoutSubviews)] map:^id(id x) {
            @strongify(self);
            return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 0, self.bottomLayoutGuide.length, 0)];
        }];
    }
    return _insetsSignal;
}

- (void)setupNavigationItem
{
//    if (self.searchFeedViewModel)
//    {
//        RAC(self, navigationItem.rightBarButtonItem) = RACObserve(self, searchContentViewController.searchButton); // search button used for activation / deactivation search
//    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"common.backtitle", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    [self ksn_addChildViewControllerAndSubview:self.searchContentViewController viewAdjustmentBlock:^(UIView *view) {
        view.frame = self.view.bounds;
        view.backgroundColor = [UIColor clearColor];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }];

//    if ([self.feedViewModel respondsToSelector:@selector(feedTheme)] && self.feedViewModel.feedTheme)
//    {
//        KSNReachabilityStatusViewController *controller = TRASafeCast([KSNReachabilityStatusViewController class], self.searchContentViewController.contentController);
//        [self.feedViewModel.feedTheme applyForViewController:controller.contentViewController];
//    }
}

#pragma mark - TRASearchControllerUpdating

- (void)updateSearchResultsForSearchController:(KSNSearchController *)searchController
{
    KSNSearchBar *seachBar = KSNSafeCast([KSNSearchBar class], searchController.searchBar);
    [self.searchFeedViewModel startSearchWithTerm:seachBar.text
                                         userInfo:@{@keypath(UISearchBar.new, selectedScopeButtonIndex) : @(seachBar.searchBar.selectedScopeButtonIndex)}];
}

#pragma mark - TRASearchControllerDelegate

- (void)willPresentSearchController:(KSNSearchController *)searchController
{
//    if ([self.searchFeedViewModel respondsToSelector:@selector(feedTheme)] && self.searchFeedViewModel.feedTheme)
//    {
//        KSNReachabilityStatusViewController *controller = TRASafeCast([KSNReachabilityStatusViewController class], searchController.searchResultsController);
//        [self.feedViewModel.feedTheme applyForViewController:controller.contentViewController];
//    }
    if ([self.delegate respondsToSelector:@selector(willPresentSearchController:)])
    {
        [self.delegate willPresentSearchController:searchController];
    }
}

- (void)didDismissSearchController:(KSNSearchController *)searchController
{
    [self.searchFeedViewModel endSearch];

    if ([self.delegate respondsToSelector:@selector(didDismissSearchController:)])
    {
        [self.delegate didDismissSearchController:searchController];
    }
}

#pragma mark - Public

- (void)reload
{
    [self.tableViewController.tableView reloadData];
    [self.collectionViewController.collectionView reloadData];
}

@end
