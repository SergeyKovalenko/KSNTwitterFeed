//
//  KSNCompoundDataSource.h
//
//  Created by Sergey Kovalenko on 6/18/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNDataSource.h"

typedef NS_ENUM(NSUInteger, KSNCompoundPredicateType)
{
    KSNFlatCompoundType = 0, // For subdataSources with 1 section only. Result compound data source also will have 1 section.
    KSNSectionsCompoundType // For two subdataSources with 1 section a result compound data source  will have 2 section.
};

@interface KSNCompoundDataSource : KSNDataSource

- (instancetype)initWithType:(KSNCompoundPredicateType)type subdataSources:(NSArray *)subdataSources;

@property (nonatomic, readonly) KSNCompoundPredicateType compoundType;
@property (nonatomic, readonly, copy) NSArray *subdataSources;

+ (instancetype)sectionDataSourceWithSubdataSources:(NSArray *)subdataSources;
+ (instancetype)flatDataSourceWithSubdataSources:(NSArray *)subdataSources;

@end