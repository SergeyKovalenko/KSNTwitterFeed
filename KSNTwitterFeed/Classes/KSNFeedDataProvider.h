//
// Created by Sergey Kovalenko on 6/26/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^KSNRequestHandler)(NSArray *items, NSError *error);

@protocol KSNCanceling <NSObject>

- (void)cancel;

@end

@protocol KSNFeedDataProvider <NSObject>

@property (nonatomic, strong) NSNumber *pageSize; // 20 by defaults

@property (nonatomic, assign, readonly) BOOL loading;

- (id <KSNCanceling>)refreshWithCompletion:(nullable KSNRequestHandler)completion; // fetch latest tweets

- (id <KSNCanceling>)loadNextPageWithCompletion:(nullable KSNRequestHandler)completion;

@end
NS_ASSUME_NONNULL_END