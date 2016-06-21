//
//  KSNCollapsibleDataSource.m
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNCollapsibleDataSource.h"
#import "KSNCollapsibleComponent.h"
#import <KSNUtils/KSNGlobalFunctions.h>
#import <KSNUtils/KSNDebug.h>

@implementation KSNCollapsibleDataSource

- (NSMutableIndexSet *)indexFromPaths:(NSArray *)indexPaths
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSIndexPath *ip in indexPaths)
    {
        KSNASSERT(ip.section == 0);
        if (ip.section == 0 && ip.row < [self numberOfItemsInSection:0])
        {
            [indexes addIndex:ip.row];
        }
    }
    return indexes;
}

- (void)collapseItemAtIndexPaths:(NSArray *)indexPaths
{
    [self collapseItemsAtIndexes:[self indexFromPaths:indexPaths]];
}

- (void)expandItemAtIndexPaths:(NSArray *)indexPaths
{
    [self expandItemsAtIndexes:[self indexFromPaths:indexPaths]];
}

- (void)collapseAll
{
    [self collapseItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.count)]];
}

- (void)collapseItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];

    NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:indexes];

    NSMutableOrderedSet *itemsToHide = [[NSMutableOrderedSet alloc] init];
    NSArray *flattenItems = self.component.flattenComponents;
    NSArray *collapsedItems = [self.component.flattenComponents objectsAtIndexes:indexes];

    [collapsedItems enumerateObjectsUsingBlock:^(KSNCollapsibleComponent *component, NSUInteger idx, BOOL *stop) {
        if ([component respondsToSelector:@selector(setCollapsed:)])
        {
            [itemsToHide addObjectsFromArray:component.flattenComponents];
            component.collapsed = YES;
            [itemsToHide removeObject:component];
        }
        else
        {
            [mutableIndexSet removeIndex:idx];
        }
    }];

    __block NSUInteger collapsedItemIndex = 0;
    [mutableIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:collapsedItems[collapsedItemIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeUpdate
                        newIndexPath:nil];
        collapsedItemIndex++;
    }];

    indexes = [flattenItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        BOOL pass = [itemsToHide containsObject:obj];
        if (pass)
        {
            [itemsToHide removeObject:obj];
            *stop = itemsToHide.count == 0;
        }
        return pass;
    }];
    NSArray *items = [flattenItems objectsAtIndexes:indexes];
    __block NSUInteger itemIndex = 0;
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:items[itemIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeRemove
                        newIndexPath:nil];
        itemIndex++;
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)expandAll
{
    [self expandItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.count)]];
}

- (void)expandItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:indexes];
    NSMutableOrderedSet *objectsToShow = [[NSMutableOrderedSet alloc] init];
    NSArray *collapsedItems = [self.component.flattenComponents objectsAtIndexes:indexes];

    [collapsedItems enumerateObjectsUsingBlock:^(KSNCollapsibleComponent *component, NSUInteger idx, BOOL *stop) {
        if ([component respondsToSelector:@selector(setCollapsed:)])
        {
            component.collapsed = NO;
            [objectsToShow addObjectsFromArray:component.flattenComponents];
            [objectsToShow removeObject:component];
        }
        else
        {
            [mutableIndexSet removeIndex:idx];
        }
    }];

    __block NSUInteger collapsedItemIndex = 0;
    [mutableIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:collapsedItems[collapsedItemIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeUpdate
                        newIndexPath:nil];
        collapsedItemIndex++;
    }];

    indexes = [self.component.flattenComponents indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        BOOL pass = [objectsToShow containsObject:obj];
        if (pass)
        {
            [objectsToShow removeObject:obj];
            *stop = objectsToShow.count == 0;
        }
        return pass;
    }];
    NSArray *items = [self.component.flattenComponents objectsAtIndexes:indexes];
    __block NSUInteger itemIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:items[itemIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeInsert
                        newIndexPath:nil];
        itemIndex++;
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <WKCollapsibleComponentTraits> selectedComponent = KSNSafeProtocolCast(@protocol(WKCollapsibleComponentTraits), [self itemAtIndexPath:indexPath]);

    if (selectedComponent)
    {
        if (selectedComponent.isCollapsed)
        {
            [self expandItemAtIndexPaths:@[indexPath]];
        }
        else
        {
            [self collapseItemAtIndexPaths:@[indexPath]];
        }
    }

    [super selectItemAtIndexPath:indexPath];
}

@end
