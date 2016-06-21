//
//  KSNCollapsibleDataSource.h
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNComponentDataSource.h"

@interface KSNCollapsibleDataSource : KSNComponentDataSource

- (void)collapseItemAtIndexPaths:(NSArray *)indexPaths;
- (void)collapseAll;
- (void)expandItemAtIndexPaths:(NSArray *)indexPaths;
- (void)expandAll;

@end
