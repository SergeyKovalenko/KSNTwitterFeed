//
//  KSNSectionedDataSource.m
//
//  Created by Sergey Kovalenko on 1/21/15.
//  Copyright (c) 2015. All rights reserved.
//


#import "KSNSectionedDataSource.h"
#import <KSNUtils/KSNDebug.h>

@interface KSNSectionedDataSource ()

@property (nonatomic, strong) NSMutableArray *sections;

@end

@implementation KSNSectionedDataSource

#pragma mark - WKSectionedDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _sections = [NSMutableArray array];
    }
    
    return self;
}

- (void)addSection:(NSArray *)section
{
    KSNASSERT(section);
    [self.notifyProxy dataSourceBeginUpdates:self];
    [self.sections addObject:[NSMutableArray arrayWithArray:section]];
    [self.notifyProxy dataSource:self
                       didChange:KSNDataSourceChangeTypeInsert
                  atSectionIndex:self.numberOfSections - 1];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)addItems:(NSArray *)items inSection:(NSUInteger)sectionIndex
{
    KSNASSERT(sectionIndex <= [self numberOfSections]);
    // Add new section
    if (sectionIndex == [self numberOfSections])
    {
        [self addSection:items];
    }
    else
    {
        [self.notifyProxy dataSourceBeginUpdates:self];
        NSMutableArray *section = [self sectionAtIndex:sectionIndex];
        NSIndexSet *insertIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([section count], [items count])];
        [section addObjectsFromArray:items];
        __block NSUInteger itemIndex = 0;
        [insertIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.notifyProxy dataSource:self
                         didChangeObject:items[itemIndex]
                             atIndexPath:[NSIndexPath indexPathForRow:idx
                                                            inSection:sectionIndex]
                           forChangeType:KSNDataSourceChangeTypeInsert
                            newIndexPath:nil];
            itemIndex++;
        }];
        [self.notifyProxy dataSourceEndUpdates:self];
    }
}

- (void)setSections:(NSArray *)sections
{
    [self.sections removeAllObjects];
    for (NSArray *section in sections)
    {
        [self.sections addObject:[NSMutableArray arrayWithArray:section]];
    }
    
    [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
}

#pragma mark - Private Methods

- (NSMutableArray *)sectionAtIndex:(NSUInteger)sectionIndex
{
    BOOL indexAvailable = sectionIndex < [self numberOfSections];
    KSNASSERT(indexAvailable);
    if (indexAvailable)
    {
        return self.sections[sectionIndex];
    }
    else
    {
        return nil;
    }
}

- (BOOL)validateIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section >= 0 && indexPath.section < [self numberOfSections] && indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section];
}

#pragma mark - WKDataSource

- (NSUInteger)numberOfSections
{
    return [self.sections count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return [[self sectionAtIndex:sectionIndex] count];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section >= 0 && indexPath.section < [self numberOfSections]);
    KSNASSERT(indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section]);
    
    if (indexPath.section >= 0 && indexPath.section < [self numberOfSections] && indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section])
    {
        return [[self sectionAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)count
{
    NSUInteger count = 0;
    for (NSUInteger section = 0; section < [self numberOfSections]; section++)
    {
        count += [self numberOfItemsInSection:section];
    }
    return count;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSIndexPath *indexPath = nil;
    for (NSUInteger section = 0; section < [self numberOfSections]; section++)
    {
        NSInteger index = [[self sectionAtIndex:section] indexOfObject:item];
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:section];
            break;
        }
    }
    return indexPath;
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section >= 0 && indexPath.section < [self numberOfSections]);
    KSNASSERT(indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section]);
    [self.notifyProxy dataSourceBeginUpdates:self];
    
    id object = [[self sectionAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [[self sectionAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
    [self.notifyProxy dataSource:self
                 didChangeObject:object
                     atIndexPath:indexPath
                   forChangeType:KSNDataSourceChangeTypeRemove
                    newIndexPath:nil];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *sectionedIndexSets = [NSMutableArray arrayWithCapacity:[self numberOfSections]];
    for (NSUInteger i = 0; i < [self numberOfSections]; i++)
    {
        sectionedIndexSets[i] = [NSMutableIndexSet indexSet];
    }
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        if ([self validateIndexPath:indexPath])
        {
            NSMutableIndexSet *set = sectionedIndexSets[indexPath.section];
            [set addIndex:indexPath.row];
        }
    }
    
    [self.notifyProxy dataSourceBeginUpdates:self];
    for (NSUInteger section = 0; section < sectionedIndexSets.count; section++)
    {
        NSIndexSet *indexSet = sectionedIndexSets[section];
        if (indexSet.count > 0)
        {
            NSArray *objects = [[self sectionAtIndex:section] objectsAtIndexes:indexSet];
            [[self sectionAtIndex:section] removeObjectsAtIndexes:indexSet];
            __block NSUInteger objectIndex = 0;
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.notifyProxy dataSource:self
                             didChangeObject:objects[objectIndex]
                                 atIndexPath:[NSIndexPath indexPathForRow:idx inSection:section]
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:nil];
                objectIndex++;
            }];
        }
    }
    
    NSMutableIndexSet *emptySections = [NSMutableIndexSet indexSet];
    for (int section = 0; section < [self numberOfSections]; section++)
    {
        if ([self numberOfItemsInSection:section] == 0)
        {
            [emptySections addIndex:section];
        }
    }
    [self.sections removeObjectsAtIndexes:emptySections];
    [emptySections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                           didChange:KSNDataSourceChangeTypeRemove
                      atSectionIndex:idx];
    }];
    
    [self.notifyProxy dataSourceEndUpdates:self];
}

@end
