//
//  KSNSearchResults.m

//
//  Created by Sergey Kovalenko on 12/10/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNSearchResults.h"

@interface KSNSearchResults ()

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong, readwrite) NSSet *relatedAreaIds;
@property (nonatomic, strong, readwrite) NSString *criteriaDescription;

@end

@implementation KSNSearchResults

+ (instancetype)searchResultsFromItems:(NSArray *)items
{
    KSNSearchResults *searchResults = [[KSNSearchResults alloc] initWithItems:items];
    searchResults.availableItems = items.count;
    return searchResults;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.items = [NSMutableArray array];
    }
    return self;
}

- (id)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self)
    {
        self.items = [NSMutableArray arrayWithArray:items];
    }
    
    return self;
}

- (NSUInteger)count;
{
    return self.items.count;
}

- (BOOL)containsObject:(id)items
{
    return [self.items containsObject:items];
}

- (id)objectAtIndex:(NSUInteger)index;
{
    id items = nil;
    if (index < [self.items count])
    {
        items = [self.items objectAtIndex:index];
    }
    return items;
}

- (NSUInteger)indexForItem:(id)items
{
    return [self.items indexOfObject:items];
}

- (id)firstItem
{
    return [self.items firstObject];
}

- (id)lastItem
{
    return [self.items lastObject];
}

- (void)removeAllObjects
{
    [self.items removeAllObjects];
}

- (void)removeObject:(id)item
{
    NSUInteger index = [self indexForItem:item];
    if (index != NSNotFound)
    {
        [self.items removeObjectAtIndex:index];
        self.availableItems--;
    }
}

- (void)addObject:(id)item
{
    if (item)
    {
//        if (![self containsObject:item])
//        {
            [self.items addObject:item];
            self.availableItems++;
//        }
    }
}

- (void)insertObject:(id)item atIndex:(NSUInteger)index
{
    if (item)
    {
//        if (![self containsObject:item])
//        {
            [self.items insertObject:item atIndex:index];
            self.availableItems++;
//        }
    }
}

- (id)updateObject:(id)item
{
    NSUInteger index = [self indexForItem:item];
    if (index != NSNotFound)
    {
        [self.items replaceObjectAtIndex:index withObject:item];
        return item;
    }
    else
    {
        return nil;
    }
}

- (NSMutableArray *)mutableCopyOfItems
{
    return [self.items mutableCopy];
}

- (void)appendSearchResults:(KSNSearchResults *)moreResults
{
    NSArray* newItems = [moreResults mutableCopyOfItems];
    for (id item in newItems)
    {
        [self addObject:item];
    }
}

- (void)insertSearchResults:(KSNSearchResults *)moreResults atIndex:(NSUInteger)index
{
    NSArray* newItems = [moreResults mutableCopyOfItems];
    [self.items insertObjects:newItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, newItems.count)]];
}

- (NSArray *)selectItemsForItems:(NSArray *)items
{
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    for (id item in items)
    {
        NSUInteger index = [self indexForItem:item];
        if (index != NSNotFound)
        {
            [indexSet addIndex:index];
        }
    }
    return [self.items objectsAtIndexes:indexSet];
}

- (NSArray *)mapItemsForItems:(NSArray *)items
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:items.count];
    for (id item in items)
    {
        NSUInteger index = [self indexForItem:item];
        if (index != NSNotFound)
        {
            [array addObject:[self.items objectAtIndex:index]];
        }
        else
        {
            [array addObject:[self mapItem:item]];
        }
    }
    return array;
}

- (id)mapItem:(id)item
{
    return item;
}

@end
