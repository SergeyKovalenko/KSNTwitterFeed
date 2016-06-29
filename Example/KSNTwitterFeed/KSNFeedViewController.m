//
// Created by Sergey Kovalenko on 5/24/16.
// Copyright (c) 2016 Windmill. All rights reserved.
//

#import <KSNErrorHandler/KSNErrorHandler.h>
#import "KSNFeedViewController.h"
#import "KSNLoadingView.h"
#import "KSNRefreshMediatorInfo.h"
#import "KSNRefreshMediator.h"
#import "KSNRefreshView.h"

@interface KSNFeedViewController () <ASTableDataSource, ASTableDelegate, KSNDataSourceObserver, KSNRefreshMediatorDelegate>

@property (nonatomic, strong) ASTableNode *tableNode;

@property (nonatomic, strong) KSNLoadingView *loadingView;
@property (nonatomic, strong) KSNRefreshMediatorInfo *topRefreshMediatorInfo;
@property (nonatomic, strong) KSNRefreshMediator *refreshMediator;
@end

@implementation KSNFeedViewController

- (instancetype)init
{
    ASTableNode *tableNode = [[ASTableNode alloc] init];
    return [self initWithTableNode:tableNode];;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self init];
}

- (instancetype)initWithTableNode:(ASTableNode *)node
{
    self = [super initWithNode:node];
    if (self)
    {
        self.tableNode = node;
        self.tableNode.delegate = self;
        self.tableNode.dataSource = self;
    }

    return self;
}

- (void)dealloc
{
    self.tableNode.delegate = nil;
    self.tableNode.dataSource = nil;
    [self.dataSource removeChangeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.dataSource addChangeObserver:self];
    self.loadingView = [[KSNLoadingView alloc] init];
    [self createRefreshMediator];
    self.tableNode.view.backgroundView = self.loadingView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshFeed];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self scrollViewContentInsetsChanged];
}

- (void)scrollViewContentInsetsChanged
{
    if (!self.topRefreshMediatorInfo.isRefreshing)
    {
        [self.refreshMediator scrollViewContentInsetsChanged];
    }
}

- (void)setDataSource:(id <KSNCellNodeDataSource>)dataSource
{
    [_dataSource removeChangeObserver:self];
    _dataSource = dataSource;
    if ([self isViewLoaded])
    {
        [self.dataSource addChangeObserver:self];
        [self refreshFeed];
    }
}

#pragma mark - Internal Methods

- (void)createRefreshMediator
{
    self.topRefreshMediatorInfo = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionTop];
    self.topRefreshMediatorInfo.refreshView = self.loadingView.refreshView;

    self.refreshMediator = [[KSNRefreshMediator alloc] initWithRefreshInfo:@[self.topRefreshMediatorInfo]];
    self.refreshMediator.scrollView = self.tableNode.view;
    self.refreshMediator.delegate = self;
}

- (void)refreshFeed
{
    [self.dataSource refreshWithCompletion:^{
        [self.topRefreshMediatorInfo setRefreshing:NO animated:YES];
    }];
}

- (void)loadNextPageWithContext:(ASBatchContext *)context
{
    [self.dataSource loadNextPageWithCompletion:^{
        [context completeBatchFetching:YES];
    }];
}

#pragma mark - TRARefreshMediatorDelegate

- (void)refreshMediator:(KSNRefreshMediator *)mediator didTriggerUpdateAtPossition:(KSNRefreshMediatorInfo *)position
{
    if (position == self.topRefreshMediatorInfo)
    {
        [self refreshFeed];
    }
}

#pragma mark - ASTableDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInSection:(NSUInteger) section];
}

- (ASCellNode *)tableView:(ASTableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return [self.dataSource cellNodeAtIndexPath:indexPath];
}

- (void)tableViewLockDataSource:(ASTableView *)tableView
{
    LOG(@"tableViewLockDataSource");
    [self.dataSource lock];
}

- (void)tableViewUnlockDataSource:(ASTableView *)tableView
{
    LOG(@"tableViewUnlockDataSource");
    [self.dataSource unlock];
}

#pragma mark - ASTableDelegate

- (BOOL)shouldBatchFetchForTableView:(ASTableView *)tableView
{
    return !self.dataSource.isLoading;
}

- (void)tableView:(ASTableView *)tableView willBeginBatchFetchWithContext:(ASBatchContext *)context
{
    [self loadNextPageWithContext:context];
}

- (void)startLoading
{
    [self.loadingView.activityIndicator startAnimating];
    UIEdgeInsets insets = self.tableNode.view.contentInset;
    insets.bottom += 55.f;
    self.tableNode.view.contentInset = insets;
}

- (void)endLoading
{
    [self.loadingView.activityIndicator stopAnimating];
    UIEdgeInsets insets = self.tableNode.view.contentInset;
    insets.bottom -= 55.f;
    self.tableNode.view.contentInset = insets;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshMediator scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshMediator scrollViewDidEndDragging];
}

#pragma mark - TRADataSourceObserver

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    [self.tableNode.view reloadData];
}

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self startLoading];
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self endLoading];
}

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    [APP_DELEGATE.errorHandler handleError:error];
    [self endLoading];
}

- (void)dataSource:(id <KSNDataSource>)datasource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    if (datasource == self.dataSource)
    {
        switch (change)
        {
            case KSNDataSourceChangeTypeInsert:
                [self.tableNode.view insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                break;

            case KSNDataSourceChangeTypeRemove:
                [self.tableNode.view deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                break;

            case KSNDataSourceChangeTypeUpdate:
                [self.tableNode.view reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                break;

            case KSNDataSourceChangeTypeMove:
                NSAssert(YES, @"Unsupported type KSNDataSourceChangeTypeMove");
                break;
        }
    }
}

- (void)dataSource:(id <KSNDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(KSNDataSourceChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    if (dataSource == self.dataSource)
    {
        LOG(@"didChangeObject %@ %@", @(indexPath.row), @(type));

        switch (type)
        {
            case KSNDataSourceChangeTypeInsert:
                [self.tableNode.view insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;

            case KSNDataSourceChangeTypeRemove:
                [self.tableNode.view deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;

            case KSNDataSourceChangeTypeUpdate:
            {
                [self.tableNode.view reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
                break;

            case KSNDataSourceChangeTypeMove:
                [self.tableNode.view moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
                break;
        }
    }
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)datasource
{
    if (datasource == self.dataSource)
    {
        LOG(@"dataSourceBeginUpdates");

        [self.tableNode.view beginUpdates];
    }
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)datasource
{
    if (datasource == self.dataSource)
    {
        LOG(@"dataSourceEndUpdates");

        [self.tableNode.view endUpdates];
    }
}

@end