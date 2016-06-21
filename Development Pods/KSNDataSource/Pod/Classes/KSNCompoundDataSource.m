//
//  KSNCompoundDataSource.m
//
//  Created by Sergey Kovalenko on 6/18/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNCompoundDataSource.h"
#import <KSNUtils/KSNDebug.h>
#import <KSNUtils/KSNGlobalFunctions.h>

@interface KSNCompoundDataSource () <KSNDataSourceObserver>

@end

@implementation KSNCompoundDataSource

- (instancetype)initWithType:(KSNCompoundPredicateType)type subdataSources:(NSArray *)subdataSources;
{
    self = [super init];
    if (self)
    {
        _compoundType = type;
        for (id <KSNDataSource> subdataSource in subdataSources)
        {
            KSNASSERT([subdataSource conformsToProtocol:@protocol(KSNDataSource)]);
            if (type == KSNFlatCompoundType)
            {
                KSNASSERT([subdataSource numberOfSections] == 1);
            }
            [subdataSource addChangeObserver:self];
        }
        _subdataSources = subdataSources;
    }
    return self;
}

- (void)dealloc
{
    for (id <KSNDataSource> subdataSource in self.subdataSources)
    {
        [subdataSource removeChangeObserver:self];
    }
}

+ (instancetype)sectionDataSourceWithSubdataSources:(NSArray *)subdataSources
{
    return [[self alloc] initWithType:KSNSectionsCompoundType subdataSources:subdataSources];
}

+ (instancetype)flatDataSourceWithSubdataSources:(NSArray *)subdataSources
{
    return [[self alloc] initWithType:KSNFlatCompoundType subdataSources:subdataSources];
}

- (void)enumerateSubdataSources:(void (^)(id <KSNDataSource> subdataSource, BOOL *stop))enumerator
{
    if (enumerator)
    {
        [self.subdataSources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            enumerator(obj, stop);
        }];
    }
}

- (id <KSNDataSource>)subdataSourceForIndexPath:(NSIndexPath *)indexPath subindexPath:(NSIndexPath *__autoreleasing *)subindexPath
{
    __block id <KSNDataSource> subdataSourceForSection;
    __block NSIndexPath *internalSubindexPath;
    if (self.compoundType == KSNSectionsCompoundType)
    {
        __block NSUInteger numberOfSections = 0;
        [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
            *stop = numberOfSections + [subdataSource numberOfSections] > indexPath.section;
            if (*stop)
            {
                subdataSourceForSection = subdataSource;
                internalSubindexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - numberOfSections];
            }
            numberOfSections += [subdataSource numberOfSections];
        }];
    }
    else
    {
        __block NSUInteger numberOfItems = 0;
        [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
            *stop = numberOfItems + [subdataSource numberOfItemsInSection:indexPath.section] > indexPath.row;
            if (*stop)
            {
                subdataSourceForSection = subdataSource;
                internalSubindexPath = [NSIndexPath indexPathForRow:indexPath.row - numberOfItems inSection:indexPath.section];
            }
            numberOfItems += [subdataSource count];
        }];
    }
    if (subindexPath)
    {
        *subindexPath = internalSubindexPath;
    }
    return subdataSourceForSection;
}

- (id <KSNDataSource>)subdataSourceForItem:(id)item indexPath:(NSIndexPath **)indexPath subindexPath:(NSIndexPath **)subindexPath
{
    __block id <KSNDataSource> subdataSourceForItem;
    __block NSUInteger numberOfSections = 0;
    __block NSUInteger numberOfItems = 0;
    __block NSIndexPath *internalIndexPath;
    __block NSIndexPath *internalSubindexPath;

    [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
        NSIndexPath *itemIndexPath = [subdataSource indexPathOfItem:item];
        if (itemIndexPath)
        {
            *stop = YES;
            subdataSourceForItem = subdataSource;
            internalSubindexPath = itemIndexPath;

            if (self.compoundType == KSNSectionsCompoundType)
            {
                internalIndexPath = [NSIndexPath indexPathForRow:itemIndexPath.row inSection:numberOfSections + itemIndexPath.section];
            }
            else
            {
                internalIndexPath = [NSIndexPath indexPathForRow:itemIndexPath.row + numberOfItems inSection:itemIndexPath.section];
            }
        }
        else
        {
            numberOfSections += [subdataSource numberOfSections];
            numberOfItems += [subdataSource count];
        }
    }];

    if (indexPath)
    {
        *indexPath = internalIndexPath;
    }

    if (subindexPath)
    {
        *subindexPath = internalSubindexPath;
    }

    return subdataSourceForItem;
}

#pragma mark - WKDataSource

- (NSUInteger)numberOfSections
{
    __block NSUInteger numberOfSections = 0;
    if (self.compoundType == KSNSectionsCompoundType)
    {
        [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
            numberOfSections += [subdataSource numberOfSections];
        }];
    }
    else
    {
        numberOfSections = 1;
    }
    return numberOfSections;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    KSNASSERT(sectionIndex < [self numberOfSections]);
    __block NSUInteger numberOfItems = 0;
    if (self.compoundType == KSNFlatCompoundType)
    {
        [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
            numberOfItems += [subdataSource numberOfItemsInSection:sectionIndex];
        }];
    }
    else
    {
        NSIndexPath *internalIndexPath;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
        id <KSNDataSource> dataSourceForSection = [self subdataSourceForIndexPath:indexPath subindexPath:&internalIndexPath];
        numberOfItems = [dataSourceForSection numberOfItemsInSection:internalIndexPath.section];
    }
    return numberOfItems;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section >= 0 && indexPath.section < [self numberOfSections]);
    KSNASSERT(indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section]);
    NSIndexPath *internalIndexPath;
    id <KSNDataSource> subdataSource = [self subdataSourceForIndexPath:indexPath subindexPath:&internalIndexPath];
    return [subdataSource itemAtIndexPath:internalIndexPath];
}

- (NSUInteger)count
{
    __block NSUInteger numberOfItems = 0;
    [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
        numberOfItems += [subdataSource count];
    }];
    return numberOfItems;
}

- (NSArray *)allObjects
{
    NSMutableArray *allObjects = [[NSMutableArray alloc] initWithCapacity:self.count];
    [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
        [allObjects addObjectsFromArray:[subdataSource allObjects]];
    }];
    return allObjects;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSIndexPath *indexPathOfItem;
    [self subdataSourceForItem:item indexPath:&indexPathOfItem subindexPath:nil];
    return indexPathOfItem;
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        NSIndexPath *internalIndexPath;
        id <KSNDataSource> subdataSource = [self subdataSourceForIndexPath:indexPath subindexPath:&internalIndexPath];
        [subdataSource removeItemsAtIndexPaths:@[internalIndexPath]];
    }
}

#pragma mark - WKDataSourceObserver

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceBeginNetworkUpdate:self];
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceEndNetworkUpdate:self];
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    [self.notifyProxy dataSourceRefreshed:self userInfo:userInfo];
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceBeginUpdates:self];
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(KSNDataSourceChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    KSNASSERTMSG(type != KSNDataSourceChangeTypeMove, @"for supporting TypeMove please extend this method");

    if (type == KSNDataSourceChangeTypeRemove)
    {
        if (self.compoundType == KSNSectionsCompoundType)
        {
            __block NSUInteger section = indexPath.section;
            [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
                if (subdataSource != dataSource)
                {
                    section += [subdataSource numberOfSections];
                }
                else
                {
                    *stop = YES;
                }
            }];
            NSIndexPath *externalIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:section];
            [self.notifyProxy dataSource:self didChangeObject:anObject atIndexPath:externalIndexPath forChangeType:type newIndexPath:nil];
        }
        else
        {
            KSNASSERTMSG(type != KSNDataSourceChangeTypeRemove, @"for supporting TypeRemove please extend this method");
        }
    }
    else
    {
        NSIndexPath *externalIndexPath;
        [self subdataSourceForItem:anObject indexPath:&externalIndexPath subindexPath:nil];
        [self.notifyProxy dataSource:self didChangeObject:anObject atIndexPath:externalIndexPath forChangeType:type newIndexPath:nil];
    }
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    KSNASSERTMSG(self.compoundType != KSNFlatCompoundType, @"You can't change sections for KSNFlatCompoundType");

    if (self.compoundType == KSNSectionsCompoundType)
    {
        __block NSUInteger section = sectionIndex;
        [self enumerateSubdataSources:^(id <KSNDataSource> subdataSource, BOOL *stop) {
            if (subdataSource != dataSource)
            {
                section += [subdataSource numberOfSections];
            }
            else
            {
                *stop = YES;
            }
        }];
        [self.notifyProxy dataSource:self didChange:change atSectionIndex:section];
    }
}

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    [self.notifyProxy dataSource:self updateFailedWithError:error];
}

- (void)dataSource:(id <KSNDataSource>)dataSource selectItemAtIndexPath:(NSIndexPath *)indexPath scrollTo:(UITableViewScrollPosition)scrollTo animated:(BOOL)animated
{
    NSIndexPath *externalIndexPath;
    [self subdataSourceForItem:[dataSource itemAtIndexPath:indexPath] indexPath:&externalIndexPath subindexPath:nil];
    [self.notifyProxy dataSource:self selectItemAtIndexPath:externalIndexPath scrollTo:scrollTo animated:animated];
}

- (void)dataSource:(id <KSNDataSource>)dataSource deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    NSIndexPath *externalIndexPath;
    [self subdataSourceForItem:[dataSource itemAtIndexPath:indexPath] indexPath:&externalIndexPath subindexPath:nil];
    [self.notifyProxy dataSource:self deselectItemAtIndexPath:externalIndexPath animated:animated];
}

- (void)pageDown
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    [lastDatSource pageDownWithUserInfo:nil];
}

- (NSUInteger)currentPage
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    return [lastDatSource currentPage];
}

- (NSUInteger)numberOfPages
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    return [lastDatSource numberOfPages];
}

- (BOOL)dataWasRefreshed
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    return [lastDatSource dataWasRefreshed];
}

- (BOOL)isLoading
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    return [lastDatSource isLoading];
}

- (void)refresh
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    [lastDatSource refreshWithUserInfo:nil];
}

- (void)pageUp
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    [lastDatSource pageUpWithUserInfo:nil];
}

- (BOOL)isPaginationSupported
{
    id <KSNPagingDataSource> lastDatSource = KSNSafeProtocolCast(@protocol(KSNPagingDataSource), [self.subdataSources lastObject]);
    return [lastDatSource isPaginationSupported];
}

@end
