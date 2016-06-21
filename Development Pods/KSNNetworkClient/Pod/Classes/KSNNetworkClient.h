//
//  KSNNetworkClient.h
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNNetworkRequest.h"

@class RACSignal;

extern NSString *const KSNResponseSerializationErrorDomain;
extern NSString *const KSNResponseSerializationResponseErrorKey;

typedef NS_ENUM(NSUInteger, KSNResponseSerializationErrorCode)
{
    KSNResponseSerializationErrorCannotDecodeContentData,
};

@protocol KSNNetworkOperation;

typedef void (^KSNNetworkResponseBlock)(id <KSNNetworkOperation> completedOperation, id responseData);
typedef void (^KSNNetworkErrorBlock)(id <KSNNetworkOperation> completedOperation, id responseData, NSError *error);

@protocol KSNNetworkOperation <NSObject>

- (void)cancel;

@end

@protocol KSNNetworkBackingFramework <NSObject>

- (void)registerHTTPHeaders:(NSDictionary *)headers;

- (NSMutableURLRequest *)URLRequestWithRequest:(KSNNetworkRequest *)request error:(NSError *__autoreleasing *)error;

- (id <KSNNetworkOperation>)operationForDispatchedRequest:(KSNNetworkRequest *)request successBlock:(KSNNetworkResponseBlock)successBlock failureBlock:(KSNNetworkErrorBlock)failureBlock;

@end

@protocol KSNNetworkModel <NSObject>

- (id)parseJSON:(id)json error:(NSError **)pError;

@optional
@property (nonatomic, readonly) NSString *objectID;

@end

@interface KSNNetworkClient : NSObject

- (id)initWithBackingFramework:(id <KSNNetworkBackingFramework>)backingFramework;

- (id <KSNNetworkOperation>)rawDataWithNetworkRequest:(KSNNetworkRequest *)request response:(KSNNetworkResponseBlock)response error:(KSNNetworkErrorBlock)errorBlock;

- (id <KSNNetworkOperation>)model:(id <KSNNetworkModel>)modelClass withNetworkRequest:(KSNNetworkRequest *)request response:(KSNNetworkResponseBlock)response error:(KSNNetworkErrorBlock)errorBlock;

@end

@interface KSNNetworkClient (RACSupport)

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request;
- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request reloadForEachSubscriber:(BOOL)reloadForEachSubscriber;

- (RACSignal *)rawDataWithNetworkRequest:(KSNNetworkRequest *)request;
- (RACSignal *)rawDataWithNetworkRequest:(KSNNetworkRequest *)request reloadForEachSubscriber:(BOOL)reloadForEachSubscriber;
@end
