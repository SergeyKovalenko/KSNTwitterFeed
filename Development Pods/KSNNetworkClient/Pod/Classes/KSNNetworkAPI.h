//
//  KSNNetworkAPI.h
//
//  Created by Sergey Kovalenko on 1/26/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNNetwork.h"

@protocol KSNAPIToken;

FOUNDATION_EXTERN NSString *const KSNNetworkAPIErrorDomain;

typedef NS_ENUM(NSInteger, NTFAPIErrorCode)
{
    KSNUnknownNetworkAPIErrorCode = 0,
    KSNUnexpectedServerResponseNetworkAPIErrorCode
};

@interface KSNNetworkAPI : NSObject

+ (instancetype)api;

@property (nonatomic, strong) id <KSNAPIToken> token;

- (NSString *)buildURLStringWithPath:(NSString *)path;

- (NSString *)buildURLStringWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request;

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request JSONMapBlock:(id(^)(id))map;

- (RACSignal *)model:(id <KSNNetworkModel>)model withNetworkRequest:(KSNNetworkRequest *)request JSONMapBlock:(id(^)(id))map reloadForEachSubscriber:(BOOL)reload;

@end
