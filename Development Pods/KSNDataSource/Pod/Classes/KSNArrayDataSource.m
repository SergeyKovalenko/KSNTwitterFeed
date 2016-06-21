//
//  KSNArrayDataSource.m
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNArrayDataSource.h"
#import <KSNUtils/KSNDebug.h>

@interface KSNArrayDataSource ()

@property (nonatomic, strong) NSMutableArray *itemsSet;
@end

@implementation KSNArrayDataSource

- (instancetype)init
{
    return [self initWithItems:nil];
}

- (instancetype)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self)
    {
        _itemsSet = [NSMutableArray arrayWithArray:items];
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)array
{
    return [self.itemsSet copy];
}

- (NSArray *)allObjects
{
    return [self.itemsSet copy];
}

#pragma mark - WKDataSource

- (NSUInteger)numberOfSections
{
    return 1;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    KSNASSERT(sectionIndex < [self numberOfSections]);
    if (sectionIndex < [self numberOfSections])
    {
        return self.itemsSet.count;
    }
    else
    {
        return 0;
    }
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section < [self numberOfSections]);
    KSNASSERT(indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section]);
    if (indexPath.section < [self numberOfSections] && indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section])
    {
        return self.itemsSet[(NSUInteger) indexPath.row];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)count
{
    return [self.itemsSet count];
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSInteger index = [self.itemsSet indexOfObject:item];
    return (index == NSNotFound) ? nil : [NSIndexPath indexPathForRow:index inSection:0];
}

#pragma mark - Public

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    NSArray *objects = [self.itemsSet objectsAtIndexes:indexes];
    [self.itemsSet removeObjectsAtIndexes:indexes];
    __block NSUInteger objectIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                     didChangeObject:objects[objectIndex]
                         atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                       forChangeType:KSNDataSourceChangeTypeRemove
                        newIndexPath:nil];
        objectIndex++;
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
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
    [self removeItemsAtIndexes:indexes];
}

- (void)removeItemAtIndex:(NSInteger)index
{
    KSNASSERT(index >= 0 && index < self.itemsSet.count);
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (void)insertItems:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    [self.itemsSet insertObjects:objects atIndexes:indexes];
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

- (void)addItem:(id)item
{
    [self insertItems:@[item] atIndexes:[NSIndexSet indexSetWithIndex:self.count]];
}

- (void)setItems:(NSArray *)items
{
    self.itemsSet = [NSMutableArray arrayWithArray:items];
    [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
}

- (void)removeItems:(NSArray *)items
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (id item in items)
    {
        NSIndexPath *indexPath = [self indexPathOfItem:item];
        if (indexPath)
        {
            [indexPaths addObject:indexPath];
        }
    }

    [self removeItemsAtIndexPaths:indexPaths];
}

#pragma mark - KSNSortableDataSource

- (void)sortUsingSortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptor
{
    [self.itemsSet sortUsingDescriptors:sortDescriptor];
    [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
}

@end
