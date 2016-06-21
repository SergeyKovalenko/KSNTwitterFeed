//
//  KSNItemsTableViewDataSource.h
//
//  Created by Sergey Kovalenko on 12/9/14.
//  Copyright (c) 2014. All rights reserved.
//


#import <KSNDataSource/KSNDataSource.h>

@protocol KSNItemsDataProviderTraits;

@interface KSNItemsTableViewDataSource : KSNDataSource <KSNPagingDataSource>

- (id)initWithDataProvider:(id <KSNItemsDataProviderTraits>)dataProvider;

@property (nonatomic, strong, readonly) id <KSNItemsDataProviderTraits> dataProvider;

@end
