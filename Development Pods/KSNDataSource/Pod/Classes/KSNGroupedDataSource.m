//
//  KSNGroupedDataSource.m
//
//  Created by Sergey Kovalenko on 1/21/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNGroupedDataSource.h"
#import <KSNUtils/NSArray+KSNFunctionalAdditions.h>
#import <KSNUtils/KSNDebug.h>

@interface KSNGroupedSection : NSObject <NSCopying, KSNGroupedSection>

- (instancetype)initWithValue:(id)value name:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors;
- (NSUInteger)insertItem:(id)item;

@property (nonatomic, strong, readonly) id value;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSArray *sortDescriptors;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *objects;
@end

@interface KSNGroupedSection ()

@property (nonatomic, copy) NSComparator comparator;
@end

@implementation KSNGroupedSection

- (instancetype)initWithValue:(id)value name:(NSString *)name sortDescriptors:(NSArray *)sortDescriptors
{
    KSNASSERT(name);
    KSNASSERT([sortDescriptors count]);

    self = [super init];
    if (self)
    {
        _value = value;
        _name = [name copy];
        _objects = [NSMutableOrderedSet orderedSet];
        _sortDescriptors = [sortDescriptors copy];

        // create comparator from sort descriptors
        __weak typeof(self) weakSelf = self;
        _comparator = ^NSComparisonResult(id obj1, id obj2) {
            __strong KSNGroupedSection *strongSelf = weakSelf;
            NSComparisonResult result = NSOrderedSame;
            for (NSSortDescriptor *descriptor in strongSelf.sortDescriptors)
            {
                result = [descriptor compareObject:obj1 toObject:obj2];
                if (result != NSOrderedSame)
                {
                    break;
                }
            }

            return result;
        };
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    typeof(self) copy = [(KSNGroupedSection *) [[self class] alloc] initWithValue:self.value name:self.name sortDescriptors:self.sortDescriptors];
    [copy.objects unionOrderedSet:self.objects];
    return copy;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]])
    {
        return NO;
    }
    KSNGroupedSection *otherSection = other;
    return [self.name isEqualToString:otherSection.name];
}

- (NSUInteger)hash
{
    return [self.name hash];
}

- (NSString *)description
{
    return [self.objects description];
}

- (NSString *)debugDescription
{
    return [super debugDescription];
}

- (NSUInteger)insertItem:(id)item
{
    // search insert index when objects > 0
    if ([self.objects containsObject:item])
    {
        return NSNotFound;
    }

    NSUInteger insertIndex = 0;
    if ([self.objects count] > 0)
    {
        insertIndex = [self.objects indexOfObject:item
                                    inSortedRange:NSMakeRange(0, self.objects.count)
                                          options:NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual
                                  usingComparator:self.comparator];
        [self.objects insertObject:item atIndex:insertIndex];
    }
    else
    {
        [self.objects addObject:item];
    }
    return insertIndex;
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
{
    [self.objects removeObjectsAtIndexes:indexes];
}

- (id)groupedValue
{
    return self.value;
}

- (NSArray *)items
{
    return [self.objects array];
}
@end

@interface KSNGroupedDataSource ()

@property (nonatomic, copy) NSString *sectionKeyPath;
@property (nonatomic, copy) NSString *(^sectionTitleMapBlock)(id item);
@property (nonatomic, copy) id <NSCopying>  (^sectionMapBlock)(id item);

@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, strong) NSMutableDictionary *sectionsMap;
@property (nonatomic, strong) NSMutableOrderedSet *sectionsOrder;

@end

@implementation KSNGroupedDataSource

#pragma mark - KSNGroupedDataSource

- (instancetype)initWithSectionKeyPath:(NSString *)sectionKeyPath
                       sectionMapBlock:(id <NSCopying>(^)(id item))sectionMapBLock
                       sortDescriptors:(NSArray *)sortDescriptors
                  sectionTitleMapBlock:(NSString *(^)(id item))titleMapBlock
{
    KSNASSERT(sectionKeyPath.length);
    NSSortDescriptor *firstDescriptor = [sortDescriptors firstObject];
    KSNASSERT(!firstDescriptor || [firstDescriptor.key isEqualToString:sectionKeyPath]);
    self = [super init];
    if (self)
    {
        self.sectionKeyPath = sectionKeyPath;
        self.sortDescriptors = [sortDescriptors count] ? sortDescriptors : @[[NSSortDescriptor sortDescriptorWithKey:sectionKeyPath ascending:YES]];
        self.sectionsMap = [NSMutableDictionary dictionary];
        self.sectionsOrder = [NSMutableOrderedSet orderedSet];
        self.sectionTitleMapBlock = titleMapBlock;
        self.sectionMapBlock = sectionMapBLock;
    }
    return self;
}

- (id <NSCopying>)sectionKeyForItem:(id)item
{
    id sectionKey = [item valueForKeyPath:self.sectionKeyPath];
    if (self.sectionMapBlock)
    {
        sectionKey = self.sectionMapBlock(sectionKey);
    }
    if ([sectionKey conformsToProtocol:@protocol(NSCopying)])
    {
        return sectionKey;
    }
    else
    {
        return [NSValue valueWithNonretainedObject:sectionKey];
    }
}

- (void)removeItems:(NSArray *)items
{
    NSArray *indexPaths = [items ksn_map:^id(id item) {
        return [self indexPathOfItem:item];
    }];
    [self removeItemsAtIndexPaths:indexPaths];
}

- (void)removeAllItems
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.sectionsOrder.count];
    for (KSNGroupedSection *section in self.sectionsOrder)
    {
        [array addObjectsFromArray:section.items];
    }
    [self removeItems:array];
}

- (void)addItems:(NSArray *)items
{
    KSNASSERT(items);

    if ([items count])
    {
        [self.notifyProxy dataSourceBeginUpdates:self];
        NSArray *sortedItems = [items sortedArrayUsingDescriptors:self.sortDescriptors];
        for (id item in sortedItems)
        {
            KSNGroupedSection *sectionForObject = self.sectionsMap[[self sectionKeyForItem:item]];
            if (sectionForObject)
            {
                NSUInteger insertedIndex = [sectionForObject insertItem:item];
                if (insertedIndex == NSNotFound)
                {
                    continue;
                }
                [self.notifyProxy dataSource:self
                             didChangeObject:item
                                 atIndexPath:[NSIndexPath indexPathForRow:insertedIndex inSection:[self.sectionsOrder indexOfObject:sectionForObject]]
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:nil];
            }
            else
            {
                sectionForObject = [[KSNGroupedSection alloc] initWithValue:item
                                                                       name:self.sectionTitleMapBlock(item)
                                                            sortDescriptors:self.sortDescriptors];
                self.sectionsMap[[self sectionKeyForItem:item]] = sectionForObject;
                NSUInteger sectionIndex = [self insertSection:sectionForObject];
                [self.notifyProxy dataSource:self didChange:KSNDataSourceChangeTypeInsert atSectionIndex:sectionIndex];
                NSUInteger insertedIndex = [sectionForObject insertItem:item];
                [self.notifyProxy dataSource:self
                             didChangeObject:item
                                 atIndexPath:[NSIndexPath indexPathForRow:insertedIndex inSection:[self.sectionsOrder indexOfObject:sectionForObject]]
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:nil];
            }
        }
        [self.notifyProxy dataSourceEndUpdates:self];
    }
}

- (NSArray *)sections
{
    return [self.sectionsOrder array];
}

- (id <KSNGroupedSection>)sectionAtIndex:(NSUInteger)index
{
    return [self.sectionsOrder objectAtIndex:index];
}

- (NSUInteger)insertSection:(KSNGroupedSection *)section
{
    NSUInteger index = [self.sectionsOrder indexOfObject:section
                                           inSortedRange:NSMakeRange(0, self.sectionsOrder.count)
                                                 options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                                         usingComparator:^NSComparisonResult(KSNGroupedSection *obj1, KSNGroupedSection *obj2) {
                                             return [self.sortDescriptors.firstObject compareObject:obj1.value toObject:obj2.value];
                                         }];
    [self.sectionsOrder insertObject:section atIndex:index];
    return index;
}

#pragma mark - WKDataSource

- (NSUInteger)numberOfSections
{
    return [self.sectionsOrder count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return [[self sectionAtIndex:sectionIndex].items count];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id <KSNGroupedSection> section = [self sectionAtIndex:(NSUInteger) indexPath.section];
    return section.items[(NSUInteger) indexPath.row];
}

- (NSUInteger)count
{
    __block NSUInteger count = 0;
    [self.sectionsOrder enumerateObjectsUsingBlock:^(KSNGroupedSection *section, NSUInteger idx, BOOL *stop) {
        count += [section.objects count];
    }];
    return count;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    id <NSCopying> key = [self sectionKeyForItem:item];
    KSNGroupedSection *section = self.sectionsMap[key];
    return [NSIndexPath indexPathForRow:[section.objects indexOfObject:item] inSection:[self.sectionsOrder indexOfObject:section]];
}

- (BOOL)validateIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section >= 0 && indexPath.section < [self numberOfSections] && indexPath.row >= 0 && indexPath.row < [self numberOfItemsInSection:indexPath.section];
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
            NSMutableIndexSet *set = sectionedIndexSets[(NSUInteger) indexPath.section];
            [set addIndex:(NSUInteger) indexPath.row];
        }
    }

    [self.notifyProxy dataSourceBeginUpdates:self];
    for (NSUInteger section = 0; section < sectionedIndexSets.count; section++)
    {
        NSIndexSet *indexSet = sectionedIndexSets[section];
        if (indexSet.count > 0)
        {
            NSArray *objects = [[(KSNGroupedSection *) [self sectionAtIndex:section] items] objectsAtIndexes:indexSet];
            [(KSNGroupedSection *) [self sectionAtIndex:section] removeObjectsAtIndexes:indexSet];
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
    for (NSUInteger section = 0; section < [self numberOfSections]; section++)
    {
        if ([self numberOfItemsInSection:section] == 0)
        {
            [emptySections addIndex:section];
        }
    }
    [self.sectionsOrder enumerateObjectsAtIndexes:emptySections options:0 usingBlock:^(KSNGroupedSection *section, NSUInteger idx, BOOL *stop) {
        [self.sectionsMap removeObjectForKey:[self sectionKeyForItem:section.value]];
    }];
    [self.sectionsOrder removeObjectsAtIndexes:emptySections];
    [emptySections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.notifyProxy dataSource:self didChange:KSNDataSourceChangeTypeRemove atSectionIndex:idx];
    }];

    [self.notifyProxy dataSourceEndUpdates:self];
}

- (NSString *)titleForHeaderInSection:(NSUInteger)sectionIndex
{
    return [self sectionAtIndex:sectionIndex].name;
}

@end
