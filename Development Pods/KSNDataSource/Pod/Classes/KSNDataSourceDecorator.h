//
//  KSNDataSourceDecorator.h
//
//  Created by Sergey Kovalenko on 5/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNDataSource.h"

@interface KSNDataSourceDecorator : NSObject <KSNDataSource, KSNDataSourceObserver>

- (id)initWithDataSource:(id <KSNDataSource>)dataSource;

@property (nonatomic, strong, readonly) id <KSNDataSource> dataSource;

@end
