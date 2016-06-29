//
//  KSNNetworkReachabilityViewModel.h
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/29/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RACSignal;
@class AFNetworkReachabilityManager;

typedef NS_ENUM(NSInteger, KSNNetworkReachabilityStatus)
{
    KSNNetworkReachabilityStatusUnknown = -1,
    KSNNetworkReachabilityStatusNotReachable = 0,
    KSNNetworkReachabilityStatusReachable = 1,
};

@protocol KSNNetworkReachabilityViewModel

- (RACSignal *)reachabilityStatusSignal;
- (NSString *)stringFromNetworkReachabilityStatus:(KSNNetworkReachabilityStatus)status;

@end

@interface KSNNetworkReachabilityViewModel : NSObject <KSNNetworkReachabilityViewModel>

- (instancetype)initWithReachabilityManager:(nullable AFNetworkReachabilityManager *)reachabilityManager;

@property (nonatomic, strong, readonly) AFNetworkReachabilityManager *reachabilityManager;

@end

NS_ASSUME_NONNULL_END
