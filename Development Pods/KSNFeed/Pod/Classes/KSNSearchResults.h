//
//  KSNSearchResults.h

//
//  Created by Sergey Kovalenko on 12/10/14.
//  Copyright (c) 2014. All rights reserved.
//


@interface KSNSearchResults <__covariant ObjectType> : NSObject

@property (nonatomic, assign) NSUInteger availableItems;
@property (nonatomic, assign) NSUInteger totalItemsCount;

+ (instancetype)searchResultsFromItems:(NSArray *)items;

- (NSMutableArray <ObjectType> *)mutableCopyOfItems;
- (void)appendSearchResults:(KSNSearchResults <ObjectType> *)moreResults;
- (void)insertSearchResults:(KSNSearchResults <ObjectType> *)moreResults atIndex:(NSUInteger)index;

- (NSUInteger)count;
- (BOOL)containsObject:(id)items;
- (ObjectType)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexForItem:(ObjectType)item;
- (ObjectType)firstItem;
- (ObjectType)lastItem;
- (void)removeAllObjects;
- (void)removeObject:(ObjectType)items;
- (void)addObject:(ObjectType)items;
- (void)insertObject:(ObjectType)item atIndex:(NSUInteger)index;
- (id)updateObject:(ObjectType)item;

- (NSArray <ObjectType> *)selectItemsForItems:(NSArray <ObjectType> *)items;
- (NSArray <ObjectType> *)mapItemsForItems:(NSArray *)items;
- (ObjectType)mapItem:(id)item;

@end
