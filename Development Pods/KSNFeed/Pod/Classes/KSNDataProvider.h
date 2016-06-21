//
//  KSNDataProvider.h
//
//  Created by Sergey Kovalenko on 10/30/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNEditModelContext.h"
#import <KSNObservable/KSNObservable.h>

@class KSNSearchResults;

FOUNDATION_EXTERN NSString *const KSNDataProviderAddedItemKey;
FOUNDATION_EXTERN NSString *const KSNDataProviderRemovedItemKey;
FOUNDATION_EXTERN NSString *const KSNDataProviderUpdatedItemKey;
FOUNDATION_EXTERN NSString *const KSNDataProviderRefreshKey;

@protocol KSNItemsDataProviderTraits;
@class RACSignal;

@protocol KSNObservableChangeListener <NSObject>

@optional

- (void)providerWillChangeContent:(id <KSNItemsDataProviderTraits>)provider userInfo:(NSMutableDictionary *)userInfo;

- (void)providerDidChangeContent:(id <KSNItemsDataProviderTraits>)provider userInfo:(NSMutableDictionary *)userInfo;

- (void)provider:(id <KSNItemsDataProviderTraits>)provider failedToUpdateWithError:(NSError *)error userInfo:(NSMutableDictionary *)userInfo;

@end

@protocol KSNItemsDataProviderTraits <KSNObservable>

- (KSNSearchResults *)searchResults;

- (NSUInteger)count;

- (id)objectAtIndex:(NSUInteger)index;

- (NSUInteger)indexForItem:(id)listing;

- (id)itemFollowingItem:(id)listing;

- (id)itemPrecedingItem:(id)listing;

- (NSUInteger)currentPage;

- (NSUInteger)numberOfPages;

@property (nonatomic, assign, readonly, getter = isLoading) BOOL loading;

@property (nonatomic, assign, readonly) BOOL isPaginationSupported;

- (RACSignal *)startNewSearchForItemsWithUserInfo:(NSMutableDictionary *)userInfo;

- (RACSignal *)startNewSearchForItemsOnNextPageWithUserInfo:(NSMutableDictionary *)userInfo;

- (RACSignal *)startNewSearchForItemsOnPreviousPageWithUserInfo:(NSMutableDictionary *)userInfo;

- (RACSignal *)startNewSearchForItemsPageNumber:(NSUInteger)pageNumber userInfo:(NSMutableDictionary *)userInfo;

- (void)addItems:(NSArray *)items;

- (void)removeItems:(NSArray *)items;

- (void)updateItems:(NSArray *)items;

@end

@protocol KSNDataProviderRequestFactory

@required
- (RACSignal *)createRequestWithOffset:(NSInteger)offset limit:(NSInteger)limit;
@end

@interface KSNDataProviderRequestFactory : NSObject <KSNDataProviderRequestFactory>

- (instancetype)initWithFactoryBlock:(RACSignal *(^)(NSInteger offset, NSInteger limit))factoryBlock;
@end

FOUNDATION_EXTERN NSUInteger KSNDataProviderMaxPageLength;

@interface KSNDataProvider : NSObject <KSNItemsDataProviderTraits, KSNEditModelContextObserver>

- (instancetype)initWithSearchResults:(KSNSearchResults *)searchResults requestFactory:(id <KSNDataProviderRequestFactory>)requestFactory;
- (instancetype)initWithRequestFactory:(id <KSNDataProviderRequestFactory>)requestFactory;

- (void)clearData;
@property (nonatomic, strong, readonly) KSNSearchResults *searchResults;
@property (nonatomic, strong, readonly) id <KSNDataProviderRequestFactory> requestFactory;

@property (nonatomic, assign, readonly) NSUInteger currentPage;
@property (nonatomic, assign, readonly) NSUInteger numberOfPages;

@property (nonatomic, strong) KSNEditModelContext *editingContext;
@property (nonatomic, assign) NSUInteger defaultPageLength;

- (BOOL)shouldApplyChanges:(NSArray *)models
               fromContext:(id <KSNEditModelContext>)editContext
              withEditType:(KSNEditContextEditType)editType
                  userInfo:(NSDictionary *)userInfo;

- (void)notifyWillChangeContent:(NSMutableDictionary *)userInfo;
- (void)notifyDidChangeContent:(NSMutableDictionary *)userInfo;
- (void)notifyChangeContent:(NSMutableDictionary *)userInfo failedWithError:(NSError *)error;

@end
