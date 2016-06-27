//
//  KSNTwitterAPI.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KSNTwitterSocialAdapter;
@class RACSignal;
@class RACScheduler;
@class AFJSONResponseSerializer;

@protocol KSNTwitterResponseDeserializer <NSObject>

- (nullable id)parseJSON:(id)json error:(NSError * _Nullable *)pError;

@end

@interface KSNTwitterAPI : NSObject

- (instancetype)initWithSocialAdapter:(KSNTwitterSocialAdapter *)socialAdapter;

@end

@interface KSNTwitterAPI (UserTimeLine)

- (RACSignal *)userTimeLineWithDeserializer:(id <KSNTwitterResponseDeserializer>)deserializer
                               sinceTweetID:(nullable NSNumber *)sinceID
                                 maxTweetID:(nullable NSNumber *)maxTweetID
                                      count:(nullable NSNumber *)count;

@end

NS_ASSUME_NONNULL_END