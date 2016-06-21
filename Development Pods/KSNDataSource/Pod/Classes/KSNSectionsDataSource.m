//
//  KSNSectionsDataSource.m
//
//  Created by Sergey Kovalenko on 2/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNSectionsDataSource.h"
#import <KSNUtils/KSNDebug.h>

@interface KSNArrayDataSource ()

@property (nonatomic, strong) NSMutableArray *itemsSet;

@end


@interface KSNSectionsDataSource ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfItemsInSection;

@end

@implementation KSNSectionsDataSource

- (instancetype)initWithItems:(NSArray *)items
{
    return [self initWithSectionItems:items numberOfItemsInSection:3];
}

- (instancetype)initWithSectionItems:(NSArray *)items numberOfItemsInSection:(NSUInteger)count
{
    self = [super initWithItems:items];
    if (self)
    {
        self.numberOfItemsInSection = count;
    }
    return self;
}

- (NSArray *)allItems
{
    return [self.itemsSet copy];
}

- (NSUInteger)numberOfSections
{
    return self.count;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    KSNASSERT(sectionIndex < [self numberOfSections]);
    if (sectionIndex < [self numberOfSections])
    {
        return self.numberOfItemsInSection;
    }
    else
    {
        return 0;
    }
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSIndexPath *indexPath = [super indexPathOfItem:item];
    return [NSIndexPath indexPathForRow:0 inSection:indexPath.row];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section >= 0 &&
                      indexPath.section < [self numberOfSections]);
    
    if (indexPath.section >= 0 && indexPath.section < [self numberOfSections])
    {
        return [self.itemsSet objectAtIndex:indexPath.section];
    }
    else
    {
        return nil;
    }
}

#pragma mark - Public

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    NSArray *objects = [super.itemsSet objectsAtIndexes:indexes];
    [super.itemsSet removeObjectsAtIndexes:indexes];
    __block NSUInteger objectIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        for (NSInteger i = self.numberOfItemsInSection - 1; i >= 0; --i)
        {
            [self.notifyProxy dataSource:self
                         didChangeObject:objects[objectIndex]
                             atIndexPath:[NSIndexPath indexPathForRow:i inSection:idx]
                           forChangeType:KSNDataSourceChangeTypeRemove
                            newIndexPath:nil];
        }
        objectIndex++;
        [self.notifyProxy dataSource:self
                           didChange:KSNDataSourceChangeTypeRemove
                      atSectionIndex:idx];
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSIndexPath *ip in indexPaths)
    {
        if (ip.section < [self numberOfSections])
        {
            [indexes addIndex:ip.section];
        }
    }
    [self removeItemsAtIndexes:indexes];
}

- (void)insertItems:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];
    [self.itemsSet insertObjects:objects atIndexes:indexes];
    __block NSUInteger objectIndex = 0;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self
                           didChange:KSNDataSourceChangeTypeInsert
                      atSectionIndex:idx];
        for (NSInteger i = 0 ; i < self.numberOfItemsInSection; ++i)
        {
            [self.notifyProxy dataSource:self
                         didChangeObject:objects[objectIndex]
                             atIndexPath:[NSIndexPath indexPathForRow:i inSection:idx]
                           forChangeType:KSNDataSourceChangeTypeInsert
                            newIndexPath:nil];
        }
        objectIndex++;
    }];
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)setItems:(NSArray *)items
{
    self.itemsSet = [NSMutableArray arrayWithArray:items];
    [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
}

@end
