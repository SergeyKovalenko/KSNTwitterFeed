//
//  KSNSectionedDataSource.h
//
//  Created by Sergey Kovalenko on 1/21/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNDataSource.h"

@interface KSNSectionedDataSource : KSNDataSource

- (void)addSection:(NSArray *)section;
- (void)addItems:(NSArray *)items inSection:(NSUInteger)section;
- (void)setSections:(NSArray *)sections;

@end
