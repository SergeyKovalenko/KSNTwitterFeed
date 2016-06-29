//
// Created by Sergey Kovalenko on 6/26/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KSNFeedDataProvider;
@class KSNObservable;

typedef void(^KSNRequestHandler)(NSArray *items, NSError *error);

@protocol KSNCanceling <NSObject>

- (void)cancel;

@end

typedef NS_ENUM(NSInteger, KSNDaraProviderTaskState)
{
    KSNDaraProviderTaskStateRunning = 0,
    KSNDaraProviderTaskStateSuspended = 1,
    KSNDaraProviderTaskStateCanceling = 2,
    KSNDaraProviderTaskStateCompleted = 3,
};

typedef NS_ENUM(NSInteger, KSNDaraProviderTaskType)
{
    KSNDaraProviderRefreshTask = 0,
    KSNDaraProviderNextPageTask = 1,
};

@interface KSNDaraProviderTask : NSObject

@property (nonatomic, assign, readonly) NSUInteger taskIdentifier;

@property (nonatomic, assign, readonly) KSNDaraProviderTaskType taskType;

@property (nullable, nonatomic, readonly, copy) NSArray *items;         /* may be nil if no response has been received */

/*
 * The taskDescription property is available for the developer to
 * provide a descriptive label for the task.
 */
@property (nullable, nonatomic, copy) NSString *taskDescription;

/* -cancel returns immediately, but marks a task as being canceled.
 * -cancel may be sent to a task that has been suspended.
 */
- (void)cancel;

/*
 * The current state of the task within the data provider.
 */
@property (nonatomic, readonly) KSNDaraProviderTaskState state;

/*
 * The error, if any, delivered via -feedDataProvider:didCompleteTask:withError:
 * This property will be nil in the event that no error occured.
 */
@property (nullable, readonly, copy) NSError *error;

/*
 * Suspending a task will prevent the DataProvider from continuing to
 * load data for related page.
 */
- (void)suspend;
- (void)resume;

@end

@protocol KSNFeedDataProviderContext <NSObject>

//A Boolean value indicating whether refreshWithCompletion: and loadNextPageWithCompletion: methods sequences could be called asynchronously.
@property (readonly, getter=isAsynchronous) BOOL asynchronous;

//  Must be thread-safe (can be called on the main thread or a background)
- (id <KSNCanceling>)refreshWithCompletion:(nullable KSNRequestHandler)completion;

- (BOOL)canLoadNextPage;

- (id <KSNCanceling>)loadNextPageWithCompletion:(nullable KSNRequestHandler)completion;

@end

@protocol KSNFeedDataProviderObserver <NSObject>

@required

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider willStartTask:(KSNDaraProviderTask *)task;

- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didSuspendTask:(KSNDaraProviderTask *)task;
- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didResumeTask:(KSNDaraProviderTask *)task;

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)feedDataProvider:(KSNFeedDataProvider *)dataProvider didCompleteTask:(KSNDaraProviderTask *)task withError:(nullable NSError *)error;

@end

@interface KSNFeedDataProvider : NSObject

- (instancetype)initWithDataProviderContext:(id <KSNFeedDataProviderContext>)dataProviderContext;

@property (nonatomic, strong) dispatch_queue_t notificationQueue;

@property (getter=isSuspended) BOOL suspended;

- (void)addObserver:(id <KSNFeedDataProviderObserver>)observer;
- (void)removeObserver:(id <KSNFeedDataProviderObserver>)observer;
- (void)removeAllObservers;

- (KSNDaraProviderTask *)refreshDataTaskWithCompletion:(void(^)(void))completion;
- (KSNDaraProviderTask *)nextPageTaskWithCompletion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END