//
//  KSNTwitterFeedDataProvider.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/25/16.
//
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libkern/OSAtomic.h>
#import "KSNTwitterFeedDataProvider.h"

@interface KSNCancelableBlockOperation : NSOperation <KSNCanceling>
{
    BOOL executing;
    BOOL finished;
}

- (instancetype)initWithBlock:(id <KSNCanceling>(^)(void(^completionBlock)(void)))cancelableBlock;

@end

@interface KSNCancelableBlockOperation ()

@property (nonatomic, copy) id <KSNCanceling> (^cancelableBlock)(void (^)(void));
@property (nonatomic, strong) id <KSNCanceling> canceling;
@end

@implementation KSNCancelableBlockOperation

- (instancetype)initWithBlock:(id <KSNCanceling>(^)(void(^completionBlock)(void)))cancelableBlock;
{
    self = [super init];
    if (self)
    {
        executing = NO;
        finished = NO;
        self.cancelableBlock = cancelableBlock;
    }
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return executing;
}

- (BOOL)isFinished
{
    return finished;
}

- (void)start
{
    // Always check for cancellation before launching the task.
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    @weakify(self);
    self.canceling = self.cancelableBlock(^{
        @strongify(self);
        [self completeOperation];
    });
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)cancel
{
    [super cancel];
    [self.canceling cancel];
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    executing = NO;
    finished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end

@interface KSNTwitterFeedDataProvider ()

@property (nonatomic, strong, readwrite) id <KSNTwitterFeedContext> context;
//@property (nonatomic, strong) RACScheduler *scheduler;
@property (nonatomic, strong) NSNumber *sinceID;
@property (nonatomic, strong) NSOperationQueue *pagesQueue;
@end

@implementation KSNTwitterFeedDataProvider
{
    volatile int32_t _operationCount;
}

- (instancetype)initWithTwitterFeedContext:(id <KSNTwitterFeedContext>)context
{
    self = [super init];
    if (self)
    {
        self.context = context;
        self.pagesQueue = [[NSOperationQueue alloc] init];
        self.pagesQueue.name = @"com.ksntwitterfeed.ksntwitterfeeddataprovider";
        self.pagesQueue.maxConcurrentOperationCount = 1;
        self.pageSize = @20;
    }

    return self;
}

- (BOOL)loading
{
    return _operationCount > 0;
}

- (id <KSNCanceling>)refreshWithCompletion:(KSNTweetsRequestHandler)completion
{
    @weakify(self);
    KSNCancelableBlockOperation *pageOperation = [[KSNCancelableBlockOperation alloc] initWithBlock:^id <KSNCanceling>(void (^completionBlock)(void)) {
        @strongify(self);
        [self startLoading];
        int64_t sinceID = self.context.sinceTweetId;

        void (^handler)(NSArray *, NSError *) = ^(NSArray *tweets, NSError *error) {
            @strongify(self);

            if (sinceID != 0 && error == nil && tweets.count == self.pageSize.unsignedIntegerValue)
            {
                self.sinceID = @(sinceID);
            }

            if (completion)
            {
                completion(tweets, error);
            }
            completionBlock();
            [self endLoading];
        };

        NSNumber *maxTweetID = self.context.maxTweetId > 0 ? @(self.context.maxTweetId - 1) : nil;
        NSNumber *sinceTweetID = sinceID > 0 ? @(sinceID) : nil;
        return [self.context performTweetsRequestSinceTweetID:sinceTweetID
                                                   maxTweetID:maxTweetID
                                                        count:self.pageSize
                                                      handler:handler];;
    }];
    [self.pagesQueue addOperation:pageOperation];
    return pageOperation;
}

- (id <KSNCanceling>)loadNextPageWithCompletion:(KSNTweetsRequestHandler)completion
{
    @weakify(self);
    KSNCancelableBlockOperation *pageOperation = [[KSNCancelableBlockOperation alloc] initWithBlock:^id <KSNCanceling>(void (^completionBlock)(void)) {
        @strongify(self);
        [self startLoading];
        void (^handler)(NSArray *, NSError *) = ^(NSArray *tweets, NSError *error) {
            @strongify(self);

            if (error == nil && tweets.count != self.pageSize.unsignedIntegerValue)
            {
                self.sinceID = nil;
            }

            if (completion)
            {
                completion(tweets, error);
            }
            completionBlock();
            [self endLoading];
        };

        NSNumber *TweetID = self.context.maxTweetId > 0 ? @(self.context.maxTweetId - 1) : nil;
        return [self.context performTweetsRequestSinceTweetID:self.sinceID maxTweetID:TweetID count:self.pageSize handler:handler];;
    }];
    [self.pagesQueue addOperation:pageOperation];
    return pageOperation;
}

- (void)startLoading
{
    [self willChangeValueForKey:@keypath(self, loading)];
    OSAtomicIncrement32Barrier(&_operationCount);
    [self didChangeValueForKey:@keypath(self, loading)];
}

- (void)endLoading
{
    [self willChangeValueForKey:@keypath(self, loading)];
    OSAtomicDecrement32Barrier(&_operationCount);
    [self didChangeValueForKey:@keypath(self, loading)];
}


@end
