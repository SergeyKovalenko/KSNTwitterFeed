//
// Created by Sergey Kovalenko on 6/26/16.
//

#import "KSNTwitterManagedObjectFeedContext.h"
#import "KSNTwitterAPI.h"
#import "KSNNetworkModelDeserializer.h"
#import "KSNTweet.h"
#import "NSManagedObject+MagicalRequests.h"
#import "NSManagedObject+MagicalFinders.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNUtils/KSNGlobalFunctions.h>

@interface RACDisposable (KSNCanceling) <KSNCanceling>
@end

@implementation RACDisposable (KSNCanceling)

- (void)cancel
{
    [self dispose];
}
@end

@interface KSNTwitterManagedObjectFeedContext ()

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) KSNTwitterAPI *api;
@property (nonatomic, strong) KSNNetworkModelDeserializer *deserializer;
@property (nonatomic, strong) NSFetchRequest *feedRequest;
@property (nonatomic, assign) int64_t maxTweetId;
@property (nonatomic, assign) int64_t sinceTweetId;
@property (nonatomic, assign) int64_t sinceTweetIdForNextPage;
@property (nonatomic, assign) BOOL reachEnd;

@end

@implementation KSNTwitterManagedObjectFeedContext

- (instancetype)init
{
    return [self initWithAPI:nil managedObjectContect:nil];
}

- (instancetype)initWithAPI:(KSNTwitterAPI *)api managedObjectContect:(NSManagedObjectContext *)context
{
    NSParameterAssert(api);
    NSParameterAssert(context);
    self = [super init];
    if (self)
    {
        self.context = context;
        self.feedRequest = [KSNTweet MR_requestAllSortedBy:@keypath(KSNTweet.new, tweetID) ascending:NO inContext:context];
        self.api = api;
        self.deserializer = [[KSNNetworkModelDeserializer alloc] initWithModelMapping:[KSNTweet tweetMapping]
                                                                              context:context
                                                               JSONNormalizationBlock:nil];
        [context performBlockAndWait:^{
            KSNTweet *newestTweet = [KSNTweet MR_findFirstOrderedByAttribute:@keypath(KSNTweet.new, tweetID) ascending:NO inContext:context];
            self.sinceTweetId = newestTweet.tweetID;
        }];
        self.pageSize = 20;
    }

    return self;
}

#pragma mark - KSNFeedDataProviderContext

- (BOOL)isAsynchronous
{
    return NO;
}

- (id <KSNCanceling>)refreshWithCompletion:(KSNRequestHandler)completion
{
    @weakify(self);
    NSNumber *maxTweetID = self.maxTweetId > 0 ? @(self.maxTweetId - 1) : nil;
    NSNumber *sinceTweetID = self.sinceTweetId > 0 ? @(self.sinceTweetId) : nil;
    RACSignal *request = [self.api userTimeLineWithDeserializer:self.deserializer
                                                   sinceTweetID:sinceTweetID
                                                     maxTweetID:maxTweetID
                                                          count:@(self.pageSize)];
    return [request subscribeNext:^(id x) {
        @strongify(self);
        [self.context performBlockAndWait:^{
            @strongify(self)
            NSArray *tweets = KSNSafeCast([NSArray class], x);
            if (tweets.count)
            {
                if (tweets.count == self.pageSize)
                {
                    self.sinceTweetIdForNextPage = self.sinceTweetId;
                }
                KSNTweet *oldestTweet = KSNSafeCast([KSNTweet class], tweets.lastObject);
                self.maxTweetId = oldestTweet.tweetID;
                KSNTweet *newestTweet = KSNSafeCast([KSNTweet class], tweets.firstObject);
                self.sinceTweetId = MAX(newestTweet.tweetID, self.sinceTweetId);
            }

            if (completion)
            {
                completion(tweets, nil);
            }
        }];
    }                       error:^(NSError *error) {
        if (completion)
        {
            completion(nil, error);
        }
    }];
}

- (BOOL)canLoadNextPage
{
    return self.reachEnd == NO || self.sinceTweetIdForNextPage > 0;
}

- (id <KSNCanceling>)loadNextPageWithCompletion:(KSNRequestHandler)completion
{
    @weakify(self);
    NSNumber *maxTweetID = self.maxTweetId > 0 ? @(self.maxTweetId - 1) : nil;
    NSNumber *sinceTweetID = self.sinceTweetIdForNextPage > 0 ? @(self.sinceTweetIdForNextPage) : nil;
    RACSignal *request = [self.api userTimeLineWithDeserializer:self.deserializer
                                                   sinceTweetID:sinceTweetID
                                                     maxTweetID:maxTweetID
                                                          count:@(self.pageSize)];
    return [request subscribeNext:^(id x) {
        @strongify(self);
        [self.context performBlockAndWait:^{
            @strongify(self)
            NSArray *tweets = KSNSafeCast([NSArray class], x);

            if (tweets.count != self.pageSize)
            {
                self.sinceTweetIdForNextPage = 0;
            }

            if (tweets.count)
            {
                KSNTweet *oldestTweet = KSNSafeCast([KSNTweet class], tweets.lastObject);
                self.maxTweetId = oldestTweet.tweetID;
                KSNTweet *newestTweet = KSNSafeCast([KSNTweet class], tweets.firstObject);
                self.sinceTweetId = MAX(newestTweet.tweetID, self.sinceTweetId);
            }
            else
            {
                self.reachEnd = YES;
            }

            if (completion)
            {
                completion(tweets, nil);
            }
        }];
    }                       error:^(NSError *error) {
        if (completion)
        {
            completion(nil, error);
        }
    }];
}

@end