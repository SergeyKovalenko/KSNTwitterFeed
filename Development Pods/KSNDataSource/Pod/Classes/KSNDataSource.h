//
//  KSNDataSource.h
//
//  Created by Sergey Kovalenko on 10/30/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KSNDataSourceChangeType)
{
    KSNDataSourceChangeTypeInsert,
    KSNDataSourceChangeTypeRemove,
    KSNDataSourceChangeTypeMove,
    KSNDataSourceChangeTypeUpdate,
};

@protocol KSNDataSource;

@protocol KSNDataSourceObserver <NSObject>

@optional
// Data source began a long running network update
- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource;
// Data source ended a long running network update
- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource;
// Data source was completely refreshed (must be reloaded)
- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo;
// Called at the beginning of updates
- (void)dataSourceBeginUpdates:(id <KSNDataSource>)dataSource;
// Called at the end of updates
- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource;
// Called when the items change
- (void)dataSource:(id <KSNDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(KSNDataSourceChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath;
// Called when the sections changes
- (void)dataSource:(id <KSNDataSource>)dataSource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex;
// Called when the data source fails
- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error;
// Called to select item at index path
- (void)   dataSource:(id <KSNDataSource>)dataSource
selectItemAtIndexPath:(NSIndexPath *)indexPath
             scrollTo:(UITableViewScrollPosition)scrollTo
             animated:(BOOL)animated;
// Called to select item at index path
- (void)dataSource:(id <KSNDataSource>)dataSource deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
@end

@protocol KSNDataSource <NSObject>

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex;
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)count;
- (NSIndexPath *)indexPathOfItem:(id)item;
- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths;

// Add/Remove observers
- (void)addChangeObserver:(id <KSNDataSourceObserver>)observer;
- (void)removeChangeObserver:(id <KSNDataSourceObserver>)observer;
- (void)removeAllChangeObservers;
// Public
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSArray *)allObjects;

@end

// Pagination Support
@protocol KSNPagingDataSource <KSNDataSource>

@property (nonatomic, readonly) NSUInteger currentPage;
@property (nonatomic, readonly) NSUInteger numberOfPages;

@property (nonatomic, readonly) BOOL dataWasRefreshed;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;
@property (nonatomic, assign, readonly) BOOL isPaginationSupported;

@property (nonatomic, assign, getter=isRefreshAllowed) BOOL allowRefresh; // Yes by defaults

- (void)refreshWithUserInfo:(NSDictionary *)userInfo;
- (void)pageUpWithUserInfo:(NSDictionary *)userInfo;
- (void)pageDownWithUserInfo:(NSDictionary *)userInfo;
@end

@protocol KSNSortableDataSource <KSNDataSource>

- (void)sortUsingSortDescriptors:(NSArray <NSSortDescriptor *>*)sortDescriptor;

@end

@interface KSNDataSource <__covariant ObjectType> : NSObject <KSNDataSource>

- (ObjectType)itemAtIndexPath:(NSIndexPath *)indexPath;

// Indicates when the data source is updating from network IO (long running)
@property (nonatomic, assign) BOOL updatingFromNetwork;

// Use to notify observers
@property (nonatomic, readonly) id <KSNDataSourceObserver> notifyProxy;

@end
