//
//  KSNSectionsDataSource.h
//
//  Created by Sergey Kovalenko on 2/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNArrayDataSource.h"

@interface KSNSectionsDataSource : KSNArrayDataSource

- (instancetype)initWithSectionItems:(NSArray *)items numberOfItemsInSection:(NSUInteger)count;

@property (nonatomic, assign, readonly) NSUInteger numberOfItemsInSection;
@property (nonatomic, readonly) NSArray *allItems;

@end
