//
//  WKReorderedDataSource.h
//
//  Created by Sergey Kovalenko on 11/2/15.
//  Copyright © 2015. All rights reserved.
//

#import "KSNDataSource.h"

@protocol KSNReorderedDataSource <KSNDataSource>

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

- (void)insertItems:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;

@end

