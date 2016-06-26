//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNManagedObjectStore.h"
@import CoreData;

@interface KSNManagedObjectStore ()

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSArray<NSSortDescriptor *> *sortDescriptors;
@property (nonatomic, strong) NSMutableArray *store;
@end

@implementation KSNManagedObjectStore

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors;
{
    NSParameterAssert(context);
    NSParameterAssert(sortDescriptors.count);
    self = [super init];
    if (self)
    {
        self.context = context;
        self.sortDescriptors = sortDescriptors;
        self.store = [NSMutableArray array];
    }

    return self;
}

- (void)registerItems:(NSArray *)items withChangeBlock:(void (^)(id item, NSIndexPath *insertedIndexPath))changeBlock
{
    NSArray <NSManagedObjectID *> *ids = [items valueForKeyPath:@"objectID"];
    [self.context performBlockAndWait:^{
        [ids enumerateObjectsUsingBlock:^(NSManagedObjectID *objID, NSUInteger idx, BOOL *stop) {
            NSManagedObject *item = [self.context objectWithID:objID];
            NSUInteger index = [self indexForItem:item options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex];
            if (self.store.count == index || (self.store.count > index && ![item isEqual:self.store[index]]))
            {
                [self.store insertObject:item atIndex:index];
                if (changeBlock)
                {
                    const NSUInteger indexes[] = {0,
                                                  index};
                    changeBlock(item, [NSIndexPath indexPathWithIndexes:indexes length:2]);
                }
            }
        }];
    }];
}

- (NSArray *)registeredItemsForIndexPaths:(NSArray <NSIndexPath *> *)indexPaths
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:indexPaths.count];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        NSParameterAssert(indexPath.length == 2);
        [items addObject:self.store[[indexPath indexAtPosition:1]]];
    }];

    return items;
}

- (NSArray <NSIndexPath *> *)indexPathsForRegisteredItems:(NSArray *)items
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        NSParameterAssert(KSNSafeCast([NSManagedObject class], item));
        NSUInteger index = [self indexForItem:item options:NSBinarySearchingFirstEqual];
        const NSUInteger indexes[] = {0,
                                      index};
        [indexPaths addObject:[NSIndexPath indexPathWithIndexes:indexes length:2]];
    }];

    return indexPaths;
}

- (NSUInteger)indexForItem:(id)item options:(NSBinarySearchingOptions)opts
{
    NSUInteger index = [self.store indexOfObject:item
                                   inSortedRange:NSMakeRange(0, self.store.count)
                                         options:opts
                                 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                     __block NSComparisonResult result = NSOrderedSame;
                                     [self.sortDescriptors enumerateObjectsUsingBlock:^(NSSortDescriptor *sortDescriptor, NSUInteger idx, BOOL *stop) {
                                         result = [sortDescriptor compareObject:obj1 toObject:obj2];
                                         *stop = result != NSOrderedSame;
                                     }];
                                     return result;
                                 }];
    return index;
}

- (NSArray *)allItems
{
    return [self.store copy];
}

- (NSUInteger)itemsCountForDimension:(NSUInteger)depth
{
    switch (depth)
    {
        case 0:
            return 1;
        case 1:
            return self.store.count;
        default:
            return 0;
    }
}


@end