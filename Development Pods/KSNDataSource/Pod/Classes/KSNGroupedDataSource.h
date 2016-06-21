//
//  KSNGroupedDataSource.h
//
//  Created by Sergey Kovalenko on 1/21/15.
//  Copyright (c) 2015 iChannel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNDataSource.h"

@protocol KSNGroupedSection

@property (nonatomic, strong, readonly) id groupedValue;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSArray *items;
@end

@interface KSNGroupedDataSource : KSNDataSource

- (instancetype)initWithSectionKeyPath:(NSString *)sectionKeyPath
                       sectionMapBlock:(id <NSCopying>(^)(id item))sectionMapBLock
                       sortDescriptors:(NSArray *)sortDescriptors
                  sectionTitleMapBlock:(NSString *(^)(id item))titleMapBlock;

- (void)addItems:(NSArray *)items;
- (void)removeItems:(NSArray *)items;
- (void)removeAllItems;
- (NSArray *)sections;
- (id <KSNGroupedSection>)sectionAtIndex:(NSUInteger)index;

@end
