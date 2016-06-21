//
//  KSNNetworkClient.m
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNNetworkClient.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

NSString *const KSNResponseSerializationErrorDomain = @"com.KSNNetwork.serialization.response";
NSString *const KSNResponseSerializationResponseErrorKey = @"com.KSNNetwork.serialization.error.response";

@interface KSNNetworkClient ()

@property (nonatomic, strong) id <KSNNetworkBackingFramework> backingFramework;
@property (nonatomic, strong) dispatch_queue_t parsingQueue;
@property (nonatomic, strong) RACScheduler *parsingScheduler;

@end

@implementation KSNNetworkClient

- (id)initWithBackingFramework:(id <KSNNetworkBackingFramework>)backingFramework
{
    self = [super init];
    if (self)
    {
        _backingFramework = backingFramework;
        _parsingQueue = dispatch_queue_create("com.KSNNetwork.response.processing", DISPATCH_QUEUE_CONCURRENT);
        _parsingScheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.KSNNetwork.response.parsingScheduler"];
    }
    return self;
}

- (id <KSNNetworkOperation>)rawDataWithNetworkRequest:(KSNNetworkRequest *)request response:(KSNNetworkResponseBlock)response error:(KSNNetworkErrorBlock)errorBlock
{
    return [self.backingFramework operationForDispatchedRequest:request successBlock:response failureBlock:errorBlock];
}

- (id <KSNNetworkOperation>)model:(id <KSNNetworkModel>)modelClass withNetworkRequest:(KSNNetworkRequest *)request response:(KSNNetworkResponseBlock)response error:(KSNNetworkErrorBlock)errorBlock
{
    return [self rawDataWithNetworkRequest:request response:^(id <KSNNetworkOperation> completedOperation, id responseData) {
        dispatch_async(_parsingQueue, ^{
            NSError *error = nil;
            id responseObject = (id) [(id <KSNNetworkModel>) modelClass parseJSON:responseData error:&error];
            if (!responseObject)
            {
                errorBlock(completedOperation, responseData, error);
            }
            else
            {
                response(completedOperation, responseObject);
            }
        });
    }                                error:errorBlock];
}
@end

@implementation KSNNetworkClient (RACSupport)

- (RACSignal *)rawDataWithNetworkRequest:(KSNNetworkRequest *)request
{
    return [self rawDataWithNetworkRequest:request reloadForEachSubscriber:YES];
}

- (RACSignal *)rawDataWithNetworkRequest:(KSNNetworkRequest *)request reloadForEachSubscriber:(BOOL)reloadForEachSubscriber
{
    RACSignal *networkRequest = [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {

        KSNNetworkResponseBlock successBlock = ^(id <KSNNetworkOperation> completedOperation, id responseData) {
            [subscriber sendNext:responseData];
            [subscriber sendCompleted];
        };

        KSNNetworkErrorBlock failureBlock = ^(id <KSNNetworkOperation> completedOperation, id responseData, NSError *error) {
            if (responseData)
            {
                NSMutableDictionary *updatedInfo = [[error userInfo] mutableCopy];
                [updatedInfo setValue:responseData forKey:KSNResponseSerializationResponseErrorKey];
                [subscriber sendError:[NSError errorWithDomain:error.domain code:error.code userInfo:updatedInfo]];
            }
            else
            {
                [subscriber sendError:error];
            }
        };

        id <KSNNetworkOperation> operation = [self.backingFramework operationForDispatchedRequest:request
                                                                                     successBlock:successBlock
                                                                                     failureBlock:failureBlock];

        return [RACDisposable disposableWithBlock:^{
            [operation cancel];
        }];
    }];

    if (!reloadForEachSubscriber)
    {
        RACMulticastConnection *connection = [networkRequest multicast:[RACReplaySubject subject]];
        return [connection autoconnect];
    }
    else
    {
        return networkRequest;
    }
}

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request
{
    return [self model:model withNetworkRequest:request reloadForEachSubscriber:YES];
}

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request reloadForEachSubscriber:(BOOL)reloadForEachSubscriber
{
    RACSignal *data = [self rawDataWithNetworkRequest:request reloadForEachSubscriber:reloadForEachSubscriber];
    return [[data flattenMap:^RACStream *(id value) {
        return [self parseModel:model fromData:value];
    }] deliverOn:[RACScheduler mainThreadScheduler]];
}

#pragma mark - Private Methods

- (RACSignal *)parseModel:(id <KSNNetworkModel> )model fromData:(id)json
{
    return [RACSignal startEagerlyWithScheduler:self.parsingScheduler block:^(id <RACSubscriber> subscriber) {
        BOOL success = YES;
        NSError *error = nil;
        id <KSNNetworkModel> result = (id <KSNNetworkModel>) [model parseJSON:json error:&error];
        if (error != NULL)
        {
            result = nil;
            success = NO;
        }
        if (!success)
        {
            [subscriber sendError:error];
        }
        else
        {
            [subscriber sendNext:result];
            [subscriber sendCompleted];
        }
    }];
}

@end
