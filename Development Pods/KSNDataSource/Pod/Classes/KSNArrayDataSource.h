//
//  KSNArrayDataSource.h
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNDataSource.h"

@interface KSNArrayDataSource : KSNDataSource <KSNSortableDataSource>

- (instancetype)initWithItems:(NSArray *)items;

@property (nonatomic, readonly) NSArray *array;

- (void)insertItems:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
- (void)addItem:(id)item;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)removeItemAtIndex:(NSInteger)index;
- (void)removeItems:(NSArray *)items;

- (void)setItems:(NSArray *)items;

@end
