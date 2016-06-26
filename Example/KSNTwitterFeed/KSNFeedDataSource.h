//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KSNDataSource/KSNDataSource.h>

NS_ASSUME_NONNULL_BEGIN
@protocol KSNItemsStore <NSObject>

- (void)registerItems:(NSArray *)items withChangeBlock:(void (^)(id item, NSIndexPath *insertedIndexPath))changeBlock;
- (NSArray *)registeredItemsForIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (NSArray <NSIndexPath *> *)indexPathsForRegisteredItems:(NSArray *)items;

- (NSArray *)allItems;
- (NSUInteger)itemsCountForDimension:(NSUInteger)depth;

// TODO: remove, update operations
@end

@protocol KSNFeedDataProvider;

@protocol KSNFeedDataSource <KSNDataSource>

- (BOOL)isLoading;
- (void)lock;
- (void)unlock;
- (void)loadNextPageWithCompletion:(nullable void (^)(void))completion;
- (void)refreshWithCompletion:(nullable void (^)(void))completion;
@end

@interface KSNFeedDataSource <__covariant ObjectType> : KSNDataSource <KSNFeedDataSource>

- (instancetype)initWithDataProvider:(id <KSNFeedDataProvider>)dataProvider itemsStore:(id <KSNItemsStore>)storeClass;

- (ObjectType)itemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END