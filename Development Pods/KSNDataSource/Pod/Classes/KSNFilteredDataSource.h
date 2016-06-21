//
//  KSNFilteredDataSource.h
//
//  Created by Sergey Kovalenko on 11/5/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNArrayDataSource.h"

@interface KSNFilteredDataSource : KSNArrayDataSource

- (void)filterWithPredicate:(NSPredicate *)predicate;

@end
