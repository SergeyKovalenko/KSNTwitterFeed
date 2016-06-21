//
//  KSNDataSourceMapDecorator.m
//
//  Created by Sergey Kovalenko on 5/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNDataSourceMapDecorator.h"
#import <KSNUtils/NSArray+KSNFunctionalAdditions.h>

@interface KSNDataSourceMapDecorator ()

@property (nonatomic, strong) NSMutableArray *mappedItems;
@property (nonatomic, copy) WKMappingBlock mapBlock;
@end

@implementation KSNDataSourceMapDecorator

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource mapBlock:(WKMappingBlock)mapBlock
{
    self = [super initWithDataSource:dataSource];
    if (self)
    {
        self.mappedItems = [NSMutableArray array];
        self.mapBlock = mapBlock;
        [self refreshDataWithUserInfo:nil];
    }
    return self;
}

- (id)initWithDataSource:(id <KSNDataSource>)dataSource
{
    return [self initWithDataSource:(id <KSNDataSource>) dataSource mapBlock:nil];
}

- (id <KSNDataSource>)itemsDataSource
{
    return self.dataSource;
}

#pragma mark - WKDataSourceObserver

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    [self refreshDataWithUserInfo:userInfo];
    [super dataSourceRefreshed:dataSource userInfo:userInfo];
}

- (void)dataSource:(id <KSNDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(KSNDataSourceChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    id mappedObject = nil;
    if (dataSource == self.itemsDataSource)
    {
        switch (type)
        {
            case KSNDataSourceChangeTypeInsert:
            {
                mappedObject = self.mapBlock ? self.mapBlock(anObject) : anObject;
                [self.mappedItems insertObject:mappedObject atIndex:(NSUInteger) indexPath.row];
            }
                break;

            case KSNDataSourceChangeTypeRemove:
            {
                mappedObject = [self itemAtIndexPath:indexPath];
                [self.mappedItems removeObjectAtIndex:(NSUInteger) indexPath.row];
                break;
            }

            case KSNDataSourceChangeTypeUpdate:
            {
                id mappedObject = self.mapBlock ? self.mapBlock(anObject) : anObject;
                [self.mappedItems replaceObjectAtIndex:(NSUInteger) indexPath.row withObject:mappedObject];
            }
                break;

            case KSNDataSourceChangeTypeMove:
            {
                mappedObject = [self itemAtIndexPath:indexPath];
                [self.mappedItems exchangeObjectAtIndex:(NSUInteger) indexPath.row withObjectAtIndex:(NSUInteger) newIndexPath.row];
            }
                break;
        }
    }
    [super dataSource:dataSource didChangeObject:mappedObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
}

- (void)refreshDataWithUserInfo:(NSDictionary *)userInfo
{
    NSArray *mappedItems = self.mapBlock ? [self.itemsDataSource.allObjects ksn_map:self.mapBlock] : self.itemsDataSource.allObjects;
    self.mappedItems = [mappedItems mutableCopy];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self numberOfItemsInSection:0])
    {
        return self.mappedItems[(NSUInteger) indexPath.row];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return self.mappedItems.count;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    __block NSUInteger index = [self.mappedItems indexOfObject:item];
    if (index != NSNotFound)
    {
        return [NSIndexPath indexPathForRow:index inSection:0];
    }
    else
    {
        return nil;
    }
}

@end

@interface WKDataSourceAsyncMapDecorator ()

@property (nonatomic, strong) NSMutableArray *mappedItems;
@property (nonatomic, strong) dispatch_queue_t mappingQueue;
@property (nonatomic, copy) WKMappingBlock mapBlock;
@end

@implementation WKDataSourceAsyncMapDecorator

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource mapBlock:(WKMappingBlock)mapBlock
{
    self = [super initWithDataSource:dataSource];
    if (self)
    {
        self.mappedItems = [NSMutableArray array];
        self.mapBlock = mapBlock;
        self.mappingQueue = dispatch_queue_create("com.iChannel.WorldKickzW.KDataSourceMapDecorator.mappingQueue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_barrier_async(self.mappingQueue, ^{
            [self refreshDataWithUserInfo:nil];
        });
    }
    return self;
}

- (id)initWithDataSource:(id <KSNDataSource>)dataSource
{
    return [self initWithDataSource:dataSource mapBlock:nil];
}

- (id <KSNDataSource>)itemsDataSource
{
    return self.dataSource;
}

#pragma mark - WKDataSourceObserver

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSourceBeginNetworkUpdate:self];
        });
    });
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSourceEndNetworkUpdate:self];
        });
    });
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    dispatch_barrier_async(self.mappingQueue, ^{
        [self refreshDataWithUserInfo:userInfo];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSourceRefreshed:dataSource userInfo:userInfo];
        });
    });
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)dataSource
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSourceBeginUpdates:self];
        });
    });
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSourceEndUpdates:self];
        });
    });
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSource:self didChange:change atSectionIndex:sectionIndex];
        });
    });
}

- (void)dataSource:(id <KSNDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(KSNDataSourceChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    dispatch_barrier_async(self.mappingQueue, ^{
        id mappedObject = self.mapBlock ? self.mapBlock(anObject) : anObject;
        if (dataSource == self.itemsDataSource)
        {
            switch (type)
            {
                case KSNDataSourceChangeTypeInsert:
                    [self.mappedItems insertObject:mappedObject atIndex:(NSUInteger) indexPath.row];
                    break;

                case KSNDataSourceChangeTypeRemove:
                    [self.mappedItems removeObjectAtIndex:(NSUInteger) indexPath.row];
                    break;

                case KSNDataSourceChangeTypeUpdate:
                {
                    [self.mappedItems replaceObjectAtIndex:(NSUInteger) indexPath.row withObject:mappedObject];
                }
                    break;

                case KSNDataSourceChangeTypeMove:
                    [self.mappedItems exchangeObjectAtIndex:(NSUInteger) indexPath.row withObjectAtIndex:(NSUInteger) newIndexPath.row];
                    break;
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSource:dataSource didChangeObject:mappedObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
        });
    });
}

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSource:self updateFailedWithError:error];
        });
    });
}

- (void)   dataSource:(id <KSNDataSource>)dataSource
selectItemAtIndexPath:(NSIndexPath *)indexPath
             scrollTo:(UITableViewScrollPosition)scrollTo
             animated:(BOOL)animated
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSource:self selectItemAtIndexPath:indexPath scrollTo:scrollTo animated:animated];
        });
    });
}

- (void)dataSource:(id <KSNDataSource>)dataSource deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    dispatch_barrier_async(self.mappingQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super dataSource:self deselectItemAtIndexPath:indexPath animated:animated];
        });
    });
}

- (void)refreshDataWithUserInfo:(NSDictionary *)userInfo
{
    NSArray *mappedItems = self.mapBlock ? [self.itemsDataSource.allObjects ksn_map:self.mapBlock] : self.itemsDataSource.allObjects;
    self.mappedItems = [mappedItems mutableCopy];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self numberOfItemsInSection:0])
    {
        __block id item = nil;
        item = self.mappedItems[(NSUInteger) indexPath.row];
        return item;
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    __block NSUInteger number = 0;
    number = self.mappedItems.count;
    return number;
}

- (NSUInteger)count
{
    __block NSUInteger number = 0;
    number = self.mappedItems.count;
    return number;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    __block NSUInteger index = 0;
    index = [self.mappedItems indexOfObject:item];
    if (index != NSNotFound)
    {
        return [NSIndexPath indexPathForRow:index inSection:0];
    }
    else
    {
        return nil;
    }
}

@end
