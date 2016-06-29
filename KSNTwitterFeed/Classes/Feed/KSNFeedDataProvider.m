//
//  KSNFeedDataProvider.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/27/16.
//
//

#import <KSNObservable/KSNObservable.h>
#import <libkern/OSAtomic.h>
#import "KSNFeedDataProvider.h"

static NSString *const KSNDaraProviderTaskOperationLockName = @"com.ksnfeeddataprovider.taskoperation.lock";

typedef NS_ENUM(NSInteger, KSNDataOperationState)
{
    KSNDataOperationPausedState = -1,
    KSNDataOperationReadyState = 1,
    KSNDataOperationExecutingState = 2,
    KSNDataOperationFinishedState = 3,
};

static inline NSString *KSNKeyPathFromOperationState(KSNDataOperationState state)
{
    switch (state)
    {
        case KSNDataOperationReadyState:
            return @"isReady";
        case KSNDataOperationExecutingState:
            return @"isExecuting";
        case KSNDataOperationFinishedState:
            return @"isFinished";
        case KSNDataOperationPausedState:
            return @"isPaused";
    }
    return @"state";
}

static inline BOOL KSNStateTransitionIsValid(KSNDataOperationState fromState, KSNDataOperationState toState, BOOL isCancelled)
{
    switch (fromState)
    {
        case KSNDataOperationReadyState:
            switch (toState)
            {
                case KSNDataOperationPausedState:
                case KSNDataOperationExecutingState:
                    return YES;
                case KSNDataOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case KSNDataOperationExecutingState:
            switch (toState)
            {
                case KSNDataOperationPausedState:
                case KSNDataOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case KSNDataOperationFinishedState:
            return NO;
        case KSNDataOperationPausedState:
            return toState == KSNDataOperationReadyState;
    }
    return NO;
}

static inline KSNDaraProviderTaskState NSDaraProviderTaskStateFromFromOperationState(KSNDataOperationState state, BOOL isCancelled)
{
    switch (state)
    {
        case KSNDataOperationReadyState:
        case KSNDataOperationPausedState:
            return KSNDaraProviderTaskStateSuspended;
        case KSNDataOperationExecutingState:
            return KSNDaraProviderTaskStateRunning;
        case KSNDataOperationFinishedState:
            return isCancelled ? KSNDaraProviderTaskStateCanceling : KSNDaraProviderTaskStateCompleted;
    }
}

@class KSNDaraProviderTaskOperation;

@interface KSNDaraProviderTask ()

@property (readwrite, copy) NSError *error;

@property (nonatomic, readwrite) KSNDaraProviderTaskState state;

@property (nonatomic, readwrite, copy) NSArray *items;

- (instancetype)initWithTaskIdentifier:(NSUInteger)taskIdentifier type:(KSNDaraProviderTaskType)type;

@property (nonatomic, weak) KSNDaraProviderTaskOperation *relativeOperation;

@end

@protocol KSNDaraProviderTaskOperationDelegate <NSObject>

@optional
- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation willStartTask:(KSNDaraProviderTask *)dataTask;
- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didPauseTask:(KSNDaraProviderTask *)dataTask;
- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didResumeTask:(KSNDaraProviderTask *)dataTask;
- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didEndTask:(KSNDaraProviderTask *)dataTask;
@end

@interface KSNDaraProviderTaskOperation : NSOperation

- (instancetype)initWitDataTask:(KSNDaraProviderTask *)dataTask contex:(id <KSNFeedDataProviderContext>)context;

@property (nonatomic, strong) KSNDaraProviderTask *dataTask;
@property (nonatomic, strong) id <KSNFeedDataProviderContext> context;
@property (nonatomic, strong) id <KSNCanceling> dataRequest;
@property (nonatomic, assign) KSNDataOperationState state;
@property (nonatomic, strong, readonly) NSRecursiveLock *lock;

@property (nonatomic, weak) id <KSNDaraProviderTaskOperationDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t notificationQueue;

@end

@implementation KSNDaraProviderTaskOperation

- (instancetype)initWitDataTask:(KSNDaraProviderTask *)dataTask contex:(id <KSNFeedDataProviderContext>)context
{
    NSParameterAssert(dataTask);
    NSParameterAssert(context);
    self = [super init];

    if (self)
    {

        self.context = context;
        _lock = [[NSRecursiveLock alloc] init];
        self.lock.name = KSNDaraProviderTaskOperationLockName;
        _state = KSNDataOperationReadyState;
        self.dataTask = dataTask;
        self.dataTask.relativeOperation = self;
        self.dataTask.state = NSDaraProviderTaskStateFromFromOperationState(self.state, NO);
    }
    return self;
}

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

#pragma mark - KSNDaraProviderTaskOperation

- (void)setItems:(NSArray *)items
{
    [self.lock lock];
    self.dataTask.items = items;
    [self.lock unlock];
}

- (void)setError:(NSError *)error
{
    [self.lock lock];
    self.dataTask.error = error;
    [self.lock unlock];
}

- (void)setState:(KSNDataOperationState)state
{
    if (!KSNStateTransitionIsValid(self.state, state, [self isCancelled]))
    {
        return;
    }

    [self.lock lock];
    NSString *oldStateKey = KSNKeyPathFromOperationState(self.state);
    NSString *newStateKey = KSNKeyPathFromOperationState(state);

    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    self.dataTask.state = NSDaraProviderTaskStateFromFromOperationState(self.state, NO);
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (void)pause
{
    if ([self isPaused] || [self isFinished] || [self isCancelled])
    {
        return;
    }

    [self.lock lock];
    if ([self isExecuting])
    {
        [self.dataRequest cancel];
    }

    self.state = KSNDataOperationPausedState;
    [self operationDidPause];

    [self.lock unlock];
}

- (BOOL)isPaused
{
    return self.state == KSNDataOperationPausedState;
}

- (void)resume
{
    if (![self isPaused])
    {
        return;
    }

    [self.lock lock];

    self.state = KSNDataOperationReadyState;

    [self continue];
    [self.lock unlock];
}

- (void)continue
{
    [self.lock lock];
    if ([self isCancelled])
    {
        [self finish];
    }
    else if ([self isReady])
    {
        if (self.dataTask.items || self.dataTask.error) // restore from pause
        {
            [self finish];
        }
        else
        {
            [self operationDidResume];
            self.state = KSNDataOperationExecutingState;
            [self operationDidStart];
        }
    }
    [self.lock unlock];
}

#pragma mark - NSOperation

- (BOOL)isReady
{
    return self.state == KSNDataOperationReadyState && [super isReady];
}

- (BOOL)isExecuting
{
    return self.state == KSNDataOperationExecutingState;
}

- (BOOL)isFinished
{
    return self.state == KSNDataOperationFinishedState;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)start
{
    [self.lock lock];
    if ([self isCancelled])
    {
        [self finish];
    }
    else if ([self isReady])
    {
        if (self.dataTask.items || self.dataTask.error) // restore from pause
        {
            [self finish];
        }
        else
        {
            [self operationWillStart];
            self.state = KSNDataOperationExecutingState;
            [self operationDidStart];
        }
    }
    [self.lock unlock];
}

- (void)operationDidStart
{
    __weak __typeof__(self) weakSelf = self;
    void (^completion)(NSArray *, NSError *) = ^(NSArray *items, NSError *error) {
        __typeof__(weakSelf) strongSelf = weakSelf;
        [strongSelf setItems:items];
        [strongSelf setError:error];
        if (![strongSelf isPaused])
        {
            [strongSelf finish];
        }
    };

    switch (self.dataTask.taskType)
    {
        case KSNDaraProviderRefreshTask:
        {
            self.dataRequest = [self.context refreshWithCompletion:completion];
        }
            break;
        case KSNDaraProviderNextPageTask:
        {
            self.dataRequest = [self.context loadNextPageWithCompletion:completion];
        }
            break;
    }
}

- (void)finish
{
    [self.lock lock];
    self.state = KSNDataOperationFinishedState;
    [self.lock unlock];

    [self operationDidEnd];
}

- (void)cancel
{
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled])
    {
        [super cancel];

        if ([self isExecuting])
        {
            [self.dataRequest cancel];
        }

        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        self.error = error;
        [self finish];
    }
    [self.lock unlock];
}

- (void)operationWillStart
{
    dispatch_queue_t queue = self.notificationQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        id <KSNDaraProviderTaskOperationDelegate> o = self.delegate;
        if ([o respondsToSelector:@selector(daraProviderTaskOperation:willStartTask:)])
        {
            [o daraProviderTaskOperation:self willStartTask:self.dataTask];
        }
    });
}

- (void)operationDidEnd
{
    dispatch_queue_t queue = self.notificationQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        id <KSNDaraProviderTaskOperationDelegate> o = self.delegate;
        if ([o respondsToSelector:@selector(daraProviderTaskOperation:didEndTask:)])
        {
            [o daraProviderTaskOperation:self didEndTask:self.dataTask];
        }
    });
}

- (void)operationDidPause
{
    dispatch_queue_t queue = self.notificationQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        id <KSNDaraProviderTaskOperationDelegate> o = self.delegate;
        if ([o respondsToSelector:@selector(daraProviderTaskOperation:didPauseTask:)])
        {
            [o daraProviderTaskOperation:self didPauseTask:self.dataTask];
        }
    });
}

- (void)operationDidResume
{
    dispatch_queue_t queue = self.notificationQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        id <KSNDaraProviderTaskOperationDelegate> o = self.delegate;
        if ([o respondsToSelector:@selector(daraProviderTaskOperation:didResumeTask:)])
        {
            [o daraProviderTaskOperation:self didResumeTask:self.dataTask];
        }
    });
}

@end

@implementation KSNDaraProviderTask

- (instancetype)initWithTaskIdentifier:(NSUInteger)taskIdentifier type:(KSNDaraProviderTaskType)type
{
    self = [super init];
    if (self)
    {
        _taskIdentifier = taskIdentifier;
        _taskType = type;
        _state = KSNDaraProviderTaskStateSuspended;
    }

    return self;
}

- (void)cancel
{
    [self.relativeOperation cancel];
}

- (void)suspend
{
    [self.relativeOperation pause];
}

- (void)resume
{
    [self.relativeOperation resume];
}

@end

@interface KSNFeedDataProvider () <KSNDaraProviderTaskOperationDelegate>

@property (nonatomic, strong) NSOperationQueue *dataTasksQueue;
@property (nonatomic, strong) id <KSNFeedDataProviderContext> dataProviderContext;
@property (nonatomic, strong) KSNObservable <KSNFeedDataProviderObserver> *notificationProxy;
@property (nonatomic, strong) NSMutableDictionary *callbacksByIdentifier;
@property (nonatomic, strong) NSLock *callbacksLock;
@end

@implementation KSNFeedDataProvider
{
    volatile int32_t _operationCount;
}

- (instancetype)initWithDataProviderContext:(id <KSNFeedDataProviderContext>)dataProviderContext
{
    self = [super init];
    if (self)
    {
        self.dataProviderContext = dataProviderContext;
        self.dataTasksQueue = [[NSOperationQueue alloc] init];
        self.dataTasksQueue.name = @"com.ksntwitterfeed.feeddataprovider";
        self.dataTasksQueue.maxConcurrentOperationCount = dataProviderContext.isAsynchronous ? NSOperationQueueDefaultMaxConcurrentOperationCount : 1;
        self.notificationProxy = (id <KSNFeedDataProviderObserver>) [[KSNObservable alloc] initWithProtocol:@protocol(KSNFeedDataProviderObserver)];
        self.callbacksLock = [[NSLock alloc] init];
        self.callbacksByIdentifier = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (dispatch_queue_t)notificationQueue
{
    return self.notificationProxy.notificationQueue;
}

- (void)setNotificationQueue:(dispatch_queue_t)notificationQueue
{
    self.notificationProxy.notificationQueue = notificationQueue;
}

- (void)setSuspended:(BOOL)suspended
{
    if (suspended)
    {
        self.dataTasksQueue.suspended = suspended;
        for (KSNDaraProviderTaskOperation *task in [self.dataTasksQueue.operations copy])
        {
            [task pause];
        }
    }
    else
    {
        for (KSNDaraProviderTaskOperation *task in [self.dataTasksQueue.operations copy])
        {
            [task resume];
        }
        self.dataTasksQueue.suspended = suspended;
    }
}

- (BOOL)isSuspended
{
    return self.dataTasksQueue.isSuspended;
}

- (void)addObserver:(id <KSNFeedDataProviderObserver>)observer
{
    [self.notificationProxy addListener:observer];
}

- (void)removeObserver:(id <KSNFeedDataProviderObserver>)observer
{
    [self.notificationProxy removeListener:observer];
}

- (void)removeAllObservers
{
    [self.notificationProxy removeAllListeners];
}

- (KSNDaraProviderTask *)refreshDataTaskWithCompletion:(void (^)(void))completion;
{
    NSUInteger identifier = (NSUInteger) OSAtomicIncrement32Barrier(&_operationCount);
    KSNDaraProviderTask *refreshTask = [[KSNDaraProviderTask alloc] initWithTaskIdentifier:identifier type:KSNDaraProviderRefreshTask];
    [self addOperationForTask:refreshTask withCompletion:completion];
    return refreshTask;
}

- (KSNDaraProviderTask *)nextPageTaskWithCompletion:(void (^)(void))completion;
{
    if ([self.dataProviderContext canLoadNextPage])
    {
        NSUInteger identifier = (NSUInteger) OSAtomicIncrement32Barrier(&_operationCount);
        KSNDaraProviderTask *refreshTask = [[KSNDaraProviderTask alloc] initWithTaskIdentifier:identifier type:KSNDaraProviderNextPageTask];
        [self addOperationForTask:refreshTask withCompletion:completion];
        return refreshTask;
    }
}

- (void)addOperationForTask:(KSNDaraProviderTask *)task withCompletion:(void (^)(void))completion;
{
    KSNDaraProviderTaskOperation *operation = [[KSNDaraProviderTaskOperation alloc] initWitDataTask:task contex:self.dataProviderContext];
    operation.delegate = self;
    operation.notificationQueue = self.notificationProxy.notificationQueue;
    [self addCallback:completion forTask:task];
    [self.dataTasksQueue addOperation:operation];
}

- (void)addCallback:(void (^)(void))callback forTask:(KSNDaraProviderTask *)dataTask
{
    if (callback)
    {
        [self.callbacksLock lock];
        self.callbacksByIdentifier[@(dataTask.taskIdentifier)] = callback;
        [self.callbacksLock unlock];
    }
}

- (nullable void (^)(void))removeCallbackForTask:(KSNDaraProviderTask *)dataTask
{
    void (^callback)(void) = nil;
    [self.callbacksLock lock];
    NSNumber *identifier = @(dataTask.taskIdentifier);
    callback = self.callbacksByIdentifier[identifier];
    [self.callbacksByIdentifier removeObjectForKey:identifier];
    [self.callbacksLock unlock];
    return callback;
}

#pragma mark - KSNDaraProviderTaskOperationDelegate

- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation willStartTask:(KSNDaraProviderTask *)dataTask
{
    [self.notificationProxy feedDataProvider:self willStartTask:dataTask];
}

- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didPauseTask:(KSNDaraProviderTask *)dataTask
{
    [self.notificationProxy feedDataProvider:self didSuspendTask:dataTask];
}

- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didResumeTask:(KSNDaraProviderTask *)dataTask
{
    [self.notificationProxy feedDataProvider:self didResumeTask:dataTask];
}

- (void)daraProviderTaskOperation:(KSNDaraProviderTaskOperation *)operation didEndTask:(KSNDaraProviderTask *)dataTask
{
    [self.notificationProxy feedDataProvider:self didCompleteTask:dataTask withError:dataTask.error];

    void (^callback)(void) = [self removeCallbackForTask:dataTask];
    if (callback)
    {
        dispatch_async(self.notificationQueue, callback);
    }
}

@end

