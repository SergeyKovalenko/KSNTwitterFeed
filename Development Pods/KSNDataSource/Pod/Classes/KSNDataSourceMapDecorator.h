//
//  KSNDataSourceMapDecorator.h
//
//  Created by Sergey Kovalenko on 5/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNDataSourceDecorator.h"

typedef id (^WKMappingBlock)(id);

@interface KSNDataSourceMapDecorator : KSNDataSourceDecorator

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource mapBlock:(WKMappingBlock)mapBlock;

@property (nonatomic, strong, readonly) id <KSNDataSource> itemsDataSource;

@end

@interface WKDataSourceAsyncMapDecorator : KSNDataSourceDecorator

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource mapBlock:(WKMappingBlock)mapBlock;

@property (nonatomic, strong, readonly) id <KSNDataSource> itemsDataSource;

@end
