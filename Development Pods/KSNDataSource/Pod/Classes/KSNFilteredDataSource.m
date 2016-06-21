//
//  KSNFilteredDataSource.m
//
//  Created by Sergey Kovalenko on 11/5/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNFilteredDataSource.h"

@interface KSNArrayDataSource ()

@property (nonatomic, strong) NSMutableArray *itemsSet;
@end

@interface KSNFilteredDataSource ()

@property (nonatomic, strong) NSArray *backingItems;
@property (nonatomic, strong) NSPredicate *searchPredicate;
@end

@implementation KSNFilteredDataSource

- (instancetype)initWithItems:(NSArray *)items
{
    self = [super initWithItems:items];
    if (self)
    {
        self.backingItems = items;
    }
    return self;
}

- (void)restoreItems
{
    NSMutableArray *backingItems = [NSMutableArray arrayWithArray:self.backingItems];
    if (![backingItems isEqualToArray:self.itemsSet])
    {
        self.itemsSet = backingItems;
    }
}

- (void)filterWithPredicate:(NSPredicate *)predicate
{
    if (![self.searchPredicate isEqual:predicate])
    {
        if (predicate)
        {
            self.itemsSet = [NSMutableArray arrayWithArray:[self.backingItems filteredArrayUsingPredicate:predicate]];
        }
        else
        {
            [self restoreItems];
        }
        [self.notifyProxy dataSourceRefreshed:self userInfo:nil];
    }
}

@end