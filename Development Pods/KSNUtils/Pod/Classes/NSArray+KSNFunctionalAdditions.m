//
//  NSArray+KSNFunctionalAdditions.m
//
//  Created by Sergey Kovalenko on 10/6/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "NSArray+KSNFunctionalAdditions.h"

@implementation NSArray (KSNFunctionalAdditions)

- (NSArray *)ksn_filter:(BOOL(^)(id item))filterBlock
{
    return [self ksn_map:^id(id item) {
        return filterBlock(item) ? item : nil;
    }];
}

- (NSArray *)ksn_map:(id(^)(id item))mapBlock
{
    return [self ksn_mapWithIndex:^id(id item, NSUInteger idx) {
        return mapBlock(item);
    }];
}

- (NSArray *)ksn_mapWithIndex:(id(^)(id item, NSUInteger idx))mapBlock
{
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        id mappedItem = mapBlock(item, idx);
        if (mappedItem != nil)
        {
            [out addObject:mappedItem];
        }
    }];
    return out;
}

- (NSArray *)ksn_withoutNulls
{
    NSNull *null = [NSNull null];
    return [self ksn_filter:^BOOL(id item) {
        return ![null isEqual:item];
    }];
}

- (NSArray *)ksn_flatten
{
    NSMutableArray *ans = [NSMutableArray array];
    for (NSArray *elem in self)
    {
        [ans addObjectsFromArray:elem];
    }
    return ans;
}

- (NSArray *)ksn_totalFlatten
{
    NSMutableArray *ans = [NSMutableArray array];
    for (id elem in self)
    {
        if ([elem isKindOfClass:[NSArray class]])
        {
            [ans addObjectsFromArray:[elem ksn_totalFlatten]];
        }
        else
        {
            [ans addObject:elem];
        }
    }
    return ans;
}

- (NSArray *)ksn_flatMap:(NSArray *(^)(id item))mapBlock
{
    return [[self ksn_map:mapBlock] ksn_flatten];
}

+ (NSArray *)ksn_arrayWithCapacity:(NSUInteger)count factoryBlock:(id(^)(NSUInteger idx))factoryBlock;
{
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; ++i)
    {
        [out addObject:factoryBlock(i)];
    }
    return out;
}

- (void)ksn_each:(void (^)(id obj))block
{
    NSParameterAssert(block != nil);
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj);
    }];
}

- (void)ksn_apply:(void (^)(id obj))block
{
    NSParameterAssert(block != nil);
    
    [self enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj);
    }];
}

- (id)ksn_match:(BOOL (^)(id obj))block
{
    NSParameterAssert(block != nil);
    
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }];
    
    if (index == NSNotFound)
        return nil;
    
    return self[index];
}

- (NSArray *)ksn_select:(BOOL (^)(id obj))block
{
    NSParameterAssert(block != nil);
    return [self objectsAtIndexes:[self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return block(obj);
    }]];
}

- (NSArray *)ksn_reject:(BOOL (^)(id obj))block
{
    NSParameterAssert(block != nil);
    return [self ksn_select:^BOOL(id obj) {
        return !block(obj);
    }];
}

- (BOOL)ksn_any:(BOOL (^)(id obj))block
{
    return [self ksn_match:block] != nil;
}

- (BOOL)ksn_none:(BOOL (^)(id obj))block
{
    return [self ksn_match:block] == nil;
}

- (BOOL)ksn_all:(BOOL (^)(id obj))block
{
    NSParameterAssert(block != nil);
    
    __block BOOL result = YES;
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (!block(obj)) {
            result = NO;
            *stop = YES;
        }
    }];
    
    return result;
}

@end
