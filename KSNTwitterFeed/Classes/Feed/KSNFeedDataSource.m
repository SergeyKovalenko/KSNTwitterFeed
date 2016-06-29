//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNFeedDataSource.h"
#import <KSNTwitterFeed/KSNFeedDataProvider.h>
#import <libkern/OSAtomic.h>
#import <KSNObservable/KSNObservable.h>

static dispatch_queue_t dataprovider_notification_queue()
{
    static dispatch_queue_t ksn_dataprovider_notification_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ksn_dataprovider_notification_queue = dispatch_queue_create("com.dataprovider.notification.queue", DISPATCH_QUEUE_SERIAL);
    });

    return ksn_dataprovider_notification_queue;
}

@interface KSNDataSource ()

@property (nonatomic, strong) KSNObservable *observable;
@end

@interface KSNFeedDataSource () <KSNFeedDataProviderObserver>

@property (nonatomic, strong) KSNFeedDataProvider *dataProvider;
@property (nonatomic, strong) id <KSNItemsStore> store;
@end

@implementation KSNFeedDataSource
{
    int32_t volatile _loading;
}

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

- (instancetype)initWithDataProvider:(KSNFeedDataProvider *)dataProvider itemsStore:(id <KSNItemsStore>)storeClass;
{
    NSParameterAssert(dataProvider);
    NSParameterAssert(storeClass);
    self = [super init];
    if (self)
    {
        self.dataProvider = dataProvider;
        [self.dataProvider addObserver:self];
        self.dataProvider.notificationQueue = dataprovider_notification_queue();
        self.store = storeClass;
        self.observable.notificationQueue = dispatch_get_main_queue();

    }

    return self;
}

- (void)dealloc
{
    [self.dataProvider removeObserver:self];
}

#pragma mark - KSNFeedDataSource

- (BOOL)isLoading
{
    return _loading > 0;
}

- (void)lock
{
    self.dataProvider.suspended = YES;
}

- (void)unlock
{
    self.dataProvider.suspended = NO;
}

- (void)loadNextPageWithCompletion:(void (^)(void))completion
{
    [self.dataProvider nextPageTaskWithCompletion:^{
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }];
}

- (void)refreshWithCompletion:(void (^)(void))completion
{
    [self.dataProvider refreshDataTaskWithCompletion:^{
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }];
}

#pragma mark - KSNFeedDataProviderObserver

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider willStartTask:(KSNDaraProviderTask *)task
{
    OSAtomicIncrement32Barrier(&_loading);
    [self.notifyProxy dataSourceBeginNetworkUpdate:self];
}

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didSuspendTask:(KSNDaraProviderTask *)task
{
    [self.notifyProxy dataSourceEndNetworkUpdate:self];
}

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didResumeTask:(KSNDaraProviderTask *)task;
{
    [self.notifyProxy dataSourceBeginNetworkUpdate:self];
}

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didCompleteTask:(KSNDaraProviderTask *)task withError:(NSError *)error
{
    if (error)
    {
        [self.notifyProxy dataSource:self updateFailedWithError:error];
    }
    else
    {
        [self addItems:task.items];
        [self.notifyProxy dataSourceEndNetworkUpdate:self];
    }

    OSAtomicDecrement32(&_loading);
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