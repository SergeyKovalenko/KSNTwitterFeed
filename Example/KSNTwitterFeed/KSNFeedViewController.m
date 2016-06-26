//
// Created by Sergey Kovalenko on 5/24/16.
// Copyright (c) 2016 Windmill. All rights reserved.
//

#import "KSNFeedViewController.h"

@interface KSNFeedViewController () <ASTableDataSource, ASTableDelegate, KSNDataSourceObserver>

@property (nonatomic, strong) ASTableNode *tableNode;

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
    [self refreshFeed];
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

- (void)refreshFeed
{
    [self.dataSource refreshWithCompletion:nil];
}

- (void)loadNextPageWithContext:(ASBatchContext *)context
{
    [self.dataSource loadNextPageWithCompletion:^{
        [context completeBatchFetching:YES];
    }];
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

#pragma mark - TRADataSourceObserver

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    [self.tableNode.view reloadData];
}

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    // NO-OP (views will be set up accordingly in the success / error handling)
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