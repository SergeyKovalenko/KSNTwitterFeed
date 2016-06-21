//
//  KSNItemsTableViewDataSource.m
//
//  Created by Sergey Kovalenko on 12/9/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNItemsTableViewDataSource.h"
#import "KSNDataProvider.h"
#import "KSNSearchResults.h"
#import "NSArray+KSNFunctionalAdditions.h"

@interface KSNItemsTableViewDataSource () <KSNObservableChangeListener>

@property (nonatomic, strong, readwrite) id <KSNItemsDataProviderTraits> dataProvider;

// Use NSArray instead of NSSet. Because we can contains items with the same identifiers.
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign, readwrite) BOOL dataWasRefreshed;
@end

@implementation KSNItemsTableViewDataSource

@synthesize dataWasRefreshed;
@synthesize allowRefresh = _allowRefresh;

- (void)dealloc
{
    [self.dataProvider removeListener:self];
}

- (id)initWithDataProvider:(id <KSNItemsDataProviderTraits>)dataProvider
{
    self = [super init];
    if (self)
    {
        self.dataProvider = dataProvider;
        [self reloadIfNeededWithUserInfo:nil];
        self.allowRefresh = YES;
    }
    return self;
}

#pragma mark - TRADataSource Overridden Methods

- (NSUInteger)numberOfSections
{
    return 1;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return self.items.count;
}

- (NSArray *)allObjects
{
    return [self.items copy];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self numberOfItemsInSection:0])
    {
        return self.items[indexPath.row];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)count
{
    return self.items.count;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSUInteger index = [self.items indexOfObject:item];
    if (index != NSNotFound)
    {
        return [NSIndexPath indexPathForRow:index inSection:0];
    }
    else
    {
        return nil;
    }
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    NSMutableIndexSet *indexSetToRemove = [NSMutableIndexSet indexSet];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *obj, NSUInteger idx, BOOL *stop) {
        [indexSetToRemove addIndex:obj.row];
    }];
    [indexSetToRemove enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        id object = self.items[idx];
        [self.items removeObjectAtIndex:idx];
        [self.notifyProxy dataSource:self
                     didChangeObject:object
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeRemove
                        newIndexPath:nil];
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if (![fromIndexPath isEqual:toIndexPath])
    {
        id object = self.items[fromIndexPath.row];
        [self.items removeObjectAtIndex:fromIndexPath.row];
        [self.items insertObject:object atIndex:toIndexPath.row];
    }
}

- (BOOL)isLoading
{
    return self.dataProvider.isLoading;
}

- (NSUInteger)currentPage
{
    return [self.dataProvider currentPage];
}

- (NSUInteger)numberOfPages
{
    return [self.dataProvider numberOfPages];
}

// Key for user info DB to say whether the latest update was a full refresh
- (void)refreshWithUserInfo:(NSDictionary *)userInfo
{
    if (self.isRefreshAllowed)
    {
        NSMutableDictionary *mutableUserInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
        mutableUserInfo[KSNDataProviderRefreshKey] = @(YES);
        [self.dataProvider startNewSearchForItemsWithUserInfo:mutableUserInfo];
    }
}

- (void)pageUpWithUserInfo:(NSDictionary *)userInfo
{
    if (self.dataProvider.isPaginationSupported)
    {
        NSMutableDictionary *mutableUserInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
        mutableUserInfo[KSNDataProviderRefreshKey] = @(NO);
        [self.dataProvider startNewSearchForItemsOnPreviousPageWithUserInfo:mutableUserInfo];
    }
}

- (void)pageDownWithUserInfo:(NSDictionary *)userInfo
{
    if (self.dataProvider.isPaginationSupported)
    {
        NSMutableDictionary *mutableUserInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
        mutableUserInfo[KSNDataProviderRefreshKey] = @(NO);
        [self.dataProvider startNewSearchForItemsOnNextPageWithUserInfo:mutableUserInfo];
    }
}

- (BOOL)isPaginationSupported
{
    return self.dataProvider.isPaginationSupported;
}

#pragma mark - KSNItemsTableViewDataSource Private Methods

- (void)reloadIfNeededWithUserInfo:(NSDictionary *)userInfo
{
    NSArray *addedItems = userInfo[KSNDataProviderAddedItemKey];

    if (addedItems)
    {
        [self.items addObjectsFromArray:addedItems];
    }
    else
    {
        self.items = [self.dataProvider.searchResults mutableCopyOfItems];
    }

    [self.notifyProxy dataSourceRefreshed:self userInfo:userInfo];
}

- (void)removeItems:(NSArray *)listings
{
    NSArray *indexPaths = [listings ksn_map:^id(id listing) {
        return [self indexPathOfItem:listing];
    }];
    [self removeItemsAtIndexPaths:indexPaths];
}

- (void)insertItems:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    [self.items insertObjects:objects atIndexes:indexes];
    __block NSUInteger objectIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:objects[objectIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeInsert
                        newIndexPath:nil];
        objectIndex++;
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)setDataProvider:(id <KSNItemsDataProviderTraits>)dataProvider
{
    if (_dataProvider != dataProvider)
    {
        [_dataProvider removeListener:self];
        [dataProvider addListener:self];
        _dataProvider = dataProvider;
    }
}

- (void)updateDataRefreshFlagFromUserInfo:(NSMutableDictionary *)userInfo
{
    // If user info is nil or doesn't contain our key, then this was an external refresh
    // We consider external triggers to be new searches, so we set data refreshed to YES
    id valueForRefreshKey = userInfo[KSNDataProviderRefreshKey];
    self.dataWasRefreshed = valueForRefreshKey == nil || [valueForRefreshKey boolValue];
}

#pragma mark - TRAObservableChangeListener

- (void)providerDidChangeContent:(id <KSNItemsDataProviderTraits>)provider userInfo:(NSMutableDictionary *)userInfo
{
    if (provider == self.dataProvider)
    {
        NSArray *removedItems = userInfo[KSNDataProviderRemovedItemKey];
        NSArray *updatedItems = userInfo[KSNDataProviderUpdatedItemKey];

        if (removedItems)
        {
            self.dataWasRefreshed = NO;
            [self removeItems:removedItems];
        }
        else if (updatedItems)
        {
            self.dataWasRefreshed = NO;
            // Start editing the table
            [self.notifyProxy dataSourceBeginUpdates:self];

            self.items = [self.dataProvider.searchResults mutableCopyOfItems];

            // Update these rows
            for (id item in [NSMutableOrderedSet orderedSetWithArray:updatedItems])
            {
                [self.notifyProxy dataSource:self
                             didChangeObject:item
                                 atIndexPath:[self indexPathOfItem:item]
                               forChangeType:KSNDataSourceChangeTypeUpdate
                                newIndexPath:nil];
            }

            // Finish editing the table
            [self.notifyProxy dataSourceEndUpdates:self];
        }
        else
        {
            [self updateDataRefreshFlagFromUserInfo:userInfo];
            [self reloadIfNeededWithUserInfo:userInfo];
            [self.notifyProxy dataSourceEndNetworkUpdate:self];
        }
    }
}

- (void)providerWillChangeContent:(id <KSNItemsDataProviderTraits>)provider userInfo:(NSMutableDictionary *)userInfo
{
    if (provider == self.dataProvider)
    {
        [self.notifyProxy dataSourceBeginNetworkUpdate:self];
    }
}

- (void)provider:(id <KSNItemsDataProviderTraits>)provider failedToUpdateWithError:(NSError *)error userInfo:(NSMutableDictionary *)userInfo
{
    if (provider == self.dataProvider)
    {
        // Nil out data
        [self updateDataRefreshFlagFromUserInfo:userInfo];
//        if (self.dataWasRefreshed)
//        {
//            self.items = nil;
//        }
        // Notify
        [self.notifyProxy dataSource:self updateFailedWithError:error];
    }
}

@end
