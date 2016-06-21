//
//  KSNDataProvider.m
//
//  Created by Sergey Kovalenko on 10/30/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNDataProvider.h"
#import "KSNSearchResults.h"
#import "NSArray+KSNFunctionalAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface KSNDataProviderRequestFactory ()

@property (nonatomic, copy) RACSignal *(^factoryBlock)(NSInteger, NSInteger);
@end

@implementation KSNDataProviderRequestFactory

- (instancetype)initWithFactoryBlock:(RACSignal *(^)(NSInteger offset, NSInteger limit))factoryBlock
{
    self = [super init];
    if (self)
    {
        NSParameterAssert(factoryBlock);
        self.factoryBlock = factoryBlock;
    }
    return self;
}

- (RACSignal *)createRequestWithOffset:(NSInteger)offset limit:(NSInteger)limit
{
    return self.factoryBlock(offset, limit);
}

@end

NSString *const KSNDataProviderAddedItemKey = @"KSNDataProviderAddedItemKey";
NSString *const KSNDataProviderRemovedItemKey = @"KSNDataProviderRemovedItemKey";
NSString *const KSNDataProviderUpdatedItemKey = @"KSNDataProviderUpdatedItemKey";
NSString *const KSNDataProviderRefreshKey = @"KSNDataProviderRefreshKey";

NSUInteger KSNDataProviderMaxPageLength = NSUIntegerMax;

@interface KSNDataProvider ()

@property (nonatomic, assign) NSInteger notifyCount;

@property (nonatomic, assign, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, strong) KSNObservable *observeProxy;
@property (nonatomic, strong, readwrite) KSNSearchResults *searchResults;
@property (nonatomic, strong, readwrite) id <KSNDataProviderRequestFactory> requestFactory;
@property (nonatomic, assign, readwrite) NSUInteger currentPage;
@property (nonatomic, assign, readwrite) NSUInteger numberOfPages;
@property (nonatomic, strong) NSMutableDictionary *userInfo;
@property (nonatomic, strong) RACDisposable *runningSearch;
@end

@implementation KSNDataProvider

- (instancetype)initWithSearchResults:(KSNSearchResults *)searchResults requestFactory:(id <KSNDataProviderRequestFactory>)requestFactory
{
    self = [super init];
    if (self)
    {
        self.observeProxy = [[KSNObservable alloc] initWithProtocol:@protocol(KSNObservableChangeListener)];
        self.defaultPageLength = 20;
        self.numberOfPages = 1;
        self.searchResults = searchResults;
        self.requestFactory = requestFactory;
    }
    return self;
}

- (instancetype)initWithRequestFactory:(id <KSNDataProviderRequestFactory>)requestFactory
{
    return [self initWithSearchResults:[[KSNSearchResults alloc] init] requestFactory:requestFactory];
}

- (instancetype)init
{
    return [self initWithSearchResults:[[KSNSearchResults alloc] init] requestFactory:nil];;
}

- (BOOL)isPaginationSupported
{
    return self.defaultPageLength != KSNDataProviderMaxPageLength;
}

- (void)dealloc
{
    [self.editingContext removeEditContextObserver:self];
}

- (void)addListener:(id)listener
{
    [self.observeProxy addListener:listener];
}

- (void)removeListener:(id)listener
{
    [self.observeProxy removeListener:listener];
}

- (void)removeAllListeners
{
    [self.observeProxy removeAllListeners];
}

- (id <KSNObservableChangeListener>)observableChangeListener
{
    return (id) self.observeProxy;
}

+ (NSError *)badPageError
{
    NSError *error = [NSError errorWithDomain:NSStringFromClass(self)
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Attempted to start a search on an invalid page", nil)}];
    return error;
}

- (void)clearData
{
    self.numberOfPages = 1;
    [self.searchResults removeAllObjects];
}

- (RACSignal *)startNewSearchForItemsWithUserInfo:(NSMutableDictionary *)userInfo;
{
    [self clearData];
    return [self startNewSearchForItemsPageNumber:0 userInfo:userInfo];
}

- (RACSignal *)startNewSearchForItemsOnNextPageWithUserInfo:(NSMutableDictionary *)userInfo;
{
    if (self.currentPage + 1 < self.numberOfPages)
    {
        return [self startNewSearchForItemsPageNumber:self.currentPage + 1 userInfo:userInfo];
    }
    else
    {
        NSError *error = [[self class] badPageError];
        [self notifyWillChangeContent:userInfo];
        [self notifyChangeContent:userInfo failedWithError:error];
        return [RACSignal empty];
    }
}

- (RACSignal *)startNewSearchForItemsOnPreviousPageWithUserInfo:(NSMutableDictionary *)userInfo;
{
    if (self.currentPage > 0)
    {
        return [self startNewSearchForItemsPageNumber:self.currentPage - 1 userInfo:userInfo];
    }
    else
    {
        NSError *error = [[self class] badPageError];
        [self notifyWillChangeContent:userInfo];
        [self notifyChangeContent:userInfo failedWithError:error];
        return [RACSignal empty];
    }
}

- (RACSignal *)startNewSearchForItemsPageNumber:(NSUInteger)pageNumber userInfo:(NSMutableDictionary *)userInfo
{
    self.currentPage = pageNumber;
    self.userInfo = userInfo.mutableCopy;
    [self notifyWillChangeContent:self.userInfo];
    @weakify(self);
    return [self performSearchWithPageNumber:pageNumber success:^(KSNSearchResults *x) {
        @strongify(self);
        [self.searchResults appendSearchResults:x];
        // Increment available pages in case we reseaved results.count == limit
        if (x.count == self.defaultPageLength)
        {
            self.numberOfPages++;
        }
        else
        {
            self.numberOfPages = pageNumber;
        }

        if (self.currentPage > 0)
        {
            self.userInfo[KSNDataProviderAddedItemKey] = [x mutableCopyOfItems];
        }
        [self notifyDidChangeContent:self.userInfo];
    }                                  error:^(NSError *error) {
        @strongify(self);
        self.currentPage--;
        [self notifyChangeContent:self.userInfo failedWithError:error];
    }];
}

#pragma mark - Private

- (RACSignal *)performSearchWithPageNumber:(NSUInteger)pageNumber
                                   success:(void (^)(KSNSearchResults *x))successBlock
                                     error:(void (^)(NSError *error))errorBlock
{
    if (self.runningSearch && !self.runningSearch.isDisposed)
    {
        if (self.isLoading)
        {
            [self notifyDidChangeContent:self.userInfo];
        }
        [self.runningSearch dispose];
    }

    RACSignal *dataLookup;
    if ([self.requestFactory createRequestWithOffset:(pageNumber * self.defaultPageLength) limit:self.defaultPageLength])
    {
        dataLookup = [self.requestFactory createRequestWithOffset:(pageNumber * self.defaultPageLength) limit:self.defaultPageLength];
    }
    else
    {
        dataLookup = [RACSignal return:[[KSNSearchResults alloc] init]];
    }

    self.runningSearch = [dataLookup subscribeNext:successBlock error:errorBlock];

    return dataLookup;
}

- (NSUInteger)count;
{
    return [self.searchResults count];
}

- (id)objectAtIndex:(NSUInteger)index;
{
    return [self.searchResults objectAtIndex:index];
}

- (NSUInteger)indexForItem:(id)listing
{
    return [self.searchResults indexForItem:listing];
}

- (id)itemFollowingItem:(id)listing
{
    NSUInteger index = [self.searchResults indexForItem:listing];
    if (index != NSNotFound && index < [self.searchResults availableItems] - 1)
    {
        return [self.searchResults objectAtIndex:index + 1];
    }
    return nil;
}

- (id)itemPrecedingItem:(id)listing
{
    NSUInteger index = [self.searchResults indexForItem:listing];
    if (index > 0 && index != NSNotFound)
    {
        return [self.searchResults objectAtIndex:index - 1];
    }
    return nil;
}

#pragma mark - Properties

- (BOOL)isLoading
{
    return self.notifyCount > 0;
}

#pragma mark - Track loading

- (void)notifyWillChangeContent:(NSMutableDictionary *)userInfo
{
    self.notifyCount++;
    self.loading = YES;
    [self.observableChangeListener providerWillChangeContent:self userInfo:userInfo];
}

- (void)notifyDidChangeContent:(NSMutableDictionary *)userInfo
{
    if (self.notifyCount > 0)
    {
        self.notifyCount--;
    }
    self.loading = NO;
    [self.observableChangeListener providerDidChangeContent:self userInfo:userInfo];
}

- (void)notifyChangeContent:(NSMutableDictionary *)userInfo failedWithError:(NSError *)error
{
    if (self.notifyCount > 0)
    {
        self.notifyCount--;
    }
    self.loading = NO;
    [self.observableChangeListener provider:self failedToUpdateWithError:error userInfo:userInfo];
}

- (void)addItems:(NSArray *)items
{
    if (items.count == 0)
    {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderAddedItemKey];

    [self notifyWillChangeContent:userInfo];

    [self p_addItems:items];

    [self notifyDidChangeContent:userInfo];
}

- (void)p_addItems:(NSArray *)items
{
    for (id item in items)
    {
        [self.searchResults addObject:item];
    }
}

- (void)removeItems:(NSArray *)items
{
    items = [items ksn_select:^BOOL(id item) {
        return [self.searchResults containsObject:item];
    }];

    if (items.count == 0)
    {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderRemovedItemKey];

    [self notifyWillChangeContent:userInfo];
    [self p_removeItems:items];
    [self notifyDidChangeContent:userInfo];
}

- (void)p_removeItems:(NSArray *)items
{
    for (id item in items)
    {
        [self.searchResults removeObject:item];
    }
}

- (void)updateItems:(NSArray *)items
{
    items = [items ksn_select:^BOOL(id item) {
        return [self.searchResults containsObject:item];
    }];

    if (items.count == 0)
    {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderUpdatedItemKey];

    [self notifyWillChangeContent:userInfo];
    [self p_updateItems:items];
    [self notifyDidChangeContent:userInfo];
}

- (NSArray *)p_updateItems:(NSArray *)items
{
    NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
    for (id item in items)
    {
        id updatedItem = [[self searchResults] updateObject:item];
        if (updatedItem)
        {
            [updatedItems addObject:updatedItem];
        }
    }
    return [updatedItems copy];
}

#pragma mark - Editing Context

- (void)setEditingContext:(KSNEditModelContext *)editingContext
{
    if (_editingContext != editingContext)
    {
        [_editingContext removeEditContextObserver:self];
        _editingContext = editingContext;
        [_editingContext addEditContextObserver:self];
    }
}

- (BOOL)shouldApplyChanges:(NSArray *)models
               fromContext:(id <KSNEditModelContext>)editContext
              withEditType:(KSNEditContextEditType)editType
                  userInfo:(NSDictionary *)userInfo
{
    return YES;
}

- (void)editContext:(id <KSNEditModelContext>)editContext
   willChangeModels:(NSArray *)models
       withEditType:(KSNEditContextEditType)editType
           userInfo:(NSDictionary *)userInfo
{
    if (editContext == self.editingContext && [self shouldApplyChanges:models fromContext:editContext withEditType:editType userInfo:userInfo])
    {
        switch (editType)
        {
            case KSNEditContextEditTypeInsert:
            {
                if (models.count)
                {
                    NSArray *items = [self.searchResults mapItemsForItems:models];
                    [self notifyWillChangeContent:[NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderAddedItemKey]];
                }
            }
                break;
            case KSNEditContextEditTypeRemove:
            {
                NSArray *items = [self.searchResults selectItemsForItems:models];
                if (items.count)
                {
                    [self notifyWillChangeContent:[NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderRemovedItemKey]];
                }
            }
                break;
            case KSNEditContextEditTypeUpdate:
            {
                NSArray *items = [self.searchResults selectItemsForItems:models];
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderUpdatedItemKey];
                if (items.count)
                {
                    [self notifyWillChangeContent:userInfo];
                }
            }
                break;
        }
    }
}

- (void)editContext:(id <KSNEditModelContext>)editContext
    didChangeModels:(NSArray *)models
       withEditType:(KSNEditContextEditType)editType
           userInfo:(NSDictionary *)userInfo
{
    if (editContext == self.editingContext && [self shouldApplyChanges:models fromContext:editContext withEditType:editType userInfo:userInfo])
    {
        switch (editType)
        {
            case KSNEditContextEditTypeInsert:
            {
                if (models.count != 0)
                {
                    [self p_addItems:[self.searchResults mapItemsForItems:models]];
                    [self notifyDidChangeContent:[NSMutableDictionary dictionaryWithObject:models forKey:KSNDataProviderAddedItemKey]];
                }
            }
                break;
            case KSNEditContextEditTypeRemove:
            {
                NSArray *items = [self.searchResults selectItemsForItems:models];
                if (items.count != 0)
                {
                    [self p_removeItems:items];
                    [self notifyDidChangeContent:[NSMutableDictionary dictionaryWithObject:items forKey:KSNDataProviderRemovedItemKey]];
                }
            }
                break;
            case KSNEditContextEditTypeUpdate:
            {
                NSArray *updatedItems = [self p_updateItems:models];
                if (updatedItems.count != 0)
                {
                    [self notifyDidChangeContent:[NSMutableDictionary dictionaryWithObject:updatedItems forKey:KSNDataProviderUpdatedItemKey]];
                }
            }
                break;
        }
    }
}

- (void)editContext:(id <KSNEditModelContext>)editContext failedWithError:(NSError *)error userInfo:(NSDictionary *)userInfo
{
    [self notifyChangeContent:[userInfo mutableCopy] failedWithError:error];
}

@end
