//
//  NSArray+KSNFunctionalAdditions.h
//
//  Created by Sergey Kovalenko on 10/6/14.
//  Copyright (c) 2014. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSArray (KSNFunctionalAdditions)

- (NSArray *)ksn_filter:(BOOL(^)(id item))filterBlock;

- (NSArray *)ksn_map:(id(^)(id item))mapBlock;

- (NSArray *)ksn_mapWithIndex:(id(^)(id item, NSUInteger idx))mapBlock;

- (NSArray *)ksn_withoutNulls;

- (NSArray *)ksn_flatten;

- (NSArray *)ksn_totalFlatten;

- (NSArray *)ksn_flatMap:(NSArray *(^)(id item))mapBlock;

- (void)ksn_each:(void (^)(id obj))block;

- (void)ksn_apply:(void (^)(id obj))block;

- (id)ksn_match:(BOOL (^)(id obj))block;

- (NSArray *)ksn_select:(BOOL (^)(id obj))block;

- (NSArray *)ksn_reject:(BOOL (^)(id obj))block;

- (BOOL)ksn_any:(BOOL (^)(id obj))block;

- (BOOL)ksn_none:(BOOL (^)(id obj))block;

- (BOOL)ksn_all:(BOOL (^)(id obj))block;

+ (NSArray *)ksn_arrayWithCapacity:(NSUInteger)count factoryBlock:(id(^)(NSUInteger idx))mapBlock;

@end
