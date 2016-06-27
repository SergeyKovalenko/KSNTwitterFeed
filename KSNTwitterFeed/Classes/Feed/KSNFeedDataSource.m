//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNFeedDataSource.h"
#import <KSNTwitterFeed/KSNFeedDataProvider.h>
#import <libkern/OSAtomic.h>

@interface KSNFeedDataSource ()

@property (nonatomic, strong) id <KSNFeedDataProvider> dataProvider;
@property (nonatomic, strong) id <KSNItemsStore> store;
@end

@implementation KSNFeedDataSource
{
    int32_t volatile _hasLocked;
}

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithDataProvider:(id <KSNFeedDataProvider>)dataProvider itemsStore:(id <KSNItemsStore>)storeClass;
{
    NSParameterAssert(dataProvider);
    NSParameterAssert(storeClass);
    self = [super init];
    if (self)
    {
        self.dataProvider = dataProvider;
        self.store = storeClass;
    }

    return self;
}

#pragma mark - KSNFeedDataSource

- (BOOL)isLoading
{
    return self.dataProvider.loading;
}

- (void)lock
{
    OSAtomicCompareAndSwap32Barrier(0, 1, &_hasLocked);
}

- (void)unlock
{
    OSAtomicCompareAndSwap32Barrier(1, 0, &_hasLocked);
}

- (void)loadNextPageWithCompletion:(void (^)(void))completion
{
    if (!_hasLocked)
    {
        [self.notifyProxy dataSourceBeginNetworkUpdate:self];
        [self.dataProvider loadNextPageWithCompletion:^(NSArray *items, NSError *error) {
            if (error)
            {
                [self.notifyProxy dataSource:self updateFailedWithError:error];
            }
            else
            {
                [self addItems:items];
                [self.notifyProxy dataSourceEndNetworkUpdate:self];
            }

            if (completion)
            {
                completion();
            }
        }];
    }
    else
    {
        //TODO: Add a pending operation to the serial queue
    }
}

- (void)refreshWithCompletion:(void (^)(void))completion
{
    if (!_hasLocked)
    {
        [self.notifyProxy dataSourceBeginNetworkUpdate:self];
        [self.dataProvider refreshWithCompletion:^(NSArray *items, NSError *error) {
            if (error)
            {
                [self.notifyProxy dataSource:self updateFailedWithError:error];
            }
            else
            {
                [self addItems:items];
                [self.notifyProxy dataSourceEndNetworkUpdate:self];
            }

            if (completion)
            {
                completion();
            }
        }];
    }
    else
    {
        //TODO: Add a pending operation to the serial queue
    }
}

#pragma mark - KSNFeedDataSource

- (NSArray *)allObjects
{
    return self.store.allItems;
}

- (NSUInteger)numberOfSections
{
    return [self.store itemsCountForDimension:0];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return [self.store itemsCountForDimension:1];
}

- (NSUInteger)count
{
    return self.store.allItems.count;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    return [[self.store indexPathsForRegisteredItems:@[item]] lastObject];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.store registeredItemsForIndexPaths:@[indexPath]] lastObject];;
}

#pragma mark - Private Methods

- (void)addItems:(NSArray *)items
{
    if (items)
    {
        [self.notifyProxy dataSourceBeginUpdates:self];
        [self.store registerItems:items withChangeBlock:^(id item, NSIndexPath *insertedIndexPath) {
            [self.notifyProxy dataSource:self
                         didChangeObject:item
                             atIndexPath:insertedIndexPath
                           forChangeType:KSNDataSourceChangeTypeInsert
                            newIndexPath:nil];
        }];
        [self.notifyProxy dataSourceEndUpdates:self];
    }
}

@end