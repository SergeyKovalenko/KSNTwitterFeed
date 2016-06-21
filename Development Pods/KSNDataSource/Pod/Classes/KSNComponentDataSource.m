//
//  KSNComponentDataSource.m
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNComponentDataSource.h"
#import "KSNCollapsibleComponent.h"
#import <KSNUtils/KSNDebug.h>

@interface KSNComponent ()

@property (nonatomic, strong) NSMutableOrderedSet *components;

@end

@implementation KSNComponentDataSource

- (instancetype)initWithComponent:(KSNComponent *)component
{
    self = [super init];
    if (self)
    {
        _component = component;
    }
    return self;
}

- (instancetype)initWithComponents:(NSArray *)components
{
    WKExcludeSelfComponent *selfExcludedComponent = [[WKExcludeSelfComponent alloc] initWithValue:nil];
    for (KSNComponent *component in components)
    {
        [selfExcludedComponent addComponent:component];
    }
    return [self initWithComponent:selfExcludedComponent];
}

- (void)setComponent:(KSNComponent *)component
{
    _component = component;
    [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
}

- (void)setComponents:(NSArray *)components
{
    _components = components;
    WKExcludeSelfComponent *selfExcludedComponent = [[WKExcludeSelfComponent alloc] initWithValue:nil];
    for (KSNComponent *component in components)
    {
        [selfExcludedComponent addComponent:component];
    }
    self.component = selfExcludedComponent;
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [self.notifyProxy dataSourceBeginUpdates:self];

    NSArray *objects = [self.component.flattenComponents objectsAtIndexes:indexes];
    for (KSNComponent *component in objects)
    {
        [self.component removeComponent:component];
    }

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

#pragma mark - WKDataSource

- (NSUInteger)numberOfSections
{
    return 1;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    KSNASSERT(sectionIndex < [self numberOfSections]);
    if (sectionIndex <= [self numberOfSections])
    {
        return self.component.flattenComponents.count;
    }
    else
    {
        return 0;
    }
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSNASSERT(indexPath.section == 0);
    KSNASSERT(indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section]);
    if (indexPath.section == 0 && indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section])
    {
        return self.component.flattenComponents[indexPath.row];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)count
{
    return [self.component.flattenComponents count];
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    NSInteger index = [self.component.flattenComponents indexOfObject:item];
    return (index == NSNotFound) ? nil : [NSIndexPath indexPathForRow:index inSection:0];
}

#pragma mark - Public

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
    KSNASSERT(index >= 0 && index < self.component.flattenComponents.count);
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (void)addItems:(NSArray *)items
{
    [self.notifyProxy dataSourceBeginUpdates:self];

    for (KSNComponent *component in items)
    {
        [self.component addComponent:component];
    }

    for (KSNComponent *component in items)
    {
        [self.notifyProxy dataSource:self
                     didChangeObject:component
                         atIndexPath:[self indexPathOfItem:component]
                       forChangeType:KSNDataSourceChangeTypeInsert
                        newIndexPath:nil];
    }
    [self.notifyProxy dataSourceEndUpdates:self];
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

@end
