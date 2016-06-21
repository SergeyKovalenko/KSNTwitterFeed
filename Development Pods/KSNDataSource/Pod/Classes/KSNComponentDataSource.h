//
//  KSNComponentDataSource.h
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNArrayDataSource.h"
#import "KSNComponent.h"

@interface KSNComponentDataSource : KSNDataSource

- (instancetype)initWithComponent:(KSNComponent *)component;
- (instancetype)initWithComponents:(NSArray *)components;

@property (nonatomic, strong) KSNComponent *component;
@property (nonatomic, strong) NSArray *components;

- (void)addItems:(NSArray *)items;
- (void)removeItems:(NSArray *)items;

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)removeItemAtIndex:(NSInteger)index;

@end
