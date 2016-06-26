//
//  KSNTwitterFeedDataProvider.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/25/16.
//
//

#import <Foundation/Foundation.h>
#import "KSNFeedDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class RACSignal;
@protocol KSNTweet;
@class RACScheduler;

typedef void(^KSNTweetsRequestHandler)(NSArray <id <KSNTweet> > *tweets, NSError *error);


@protocol KSNTwitterFeedContext <NSObject>

- (id <KSNCanceling>)performTweetsRequestSinceTweetID:(nullable NSNumber *)sinceID
                                           maxTweetID:(nullable NSNumber *)maxTweetID
                                                count:(nullable NSNumber *)count
                                              handler:(nullable KSNTweetsRequestHandler)handler;

- (int64_t)maxTweetId; // the lowest Tweet received

- (int64_t)sinceTweetId; // the greatest Tweet of all the Tweets your application has already processed


@end

/// Implements pagination described here https://dev.twitter.com/rest/public/timelines

@interface KSNTwitterFeedDataProvider : NSObject <KSNFeedDataProvider>

- (instancetype)initWithTwitterFeedContext:(id <KSNTwitterFeedContext>)context;

@property (nonatomic, strong, readonly) id <KSNTwitterFeedContext> context;

@property (nonatomic, strong) NSNumber *pageSize; // 20 by defaults

@property (nonatomic, assign, readonly) BOOL loading;

- (id <KSNCanceling>)refreshWithCompletion:(nullable KSNTweetsRequestHandler)completion; // fetch latest tweets

- (id <KSNCanceling>)loadNextPageWithCompletion:(nullable KSNTweetsRequestHandler)completion;

@end

NS_ASSUME_NONNULL_END