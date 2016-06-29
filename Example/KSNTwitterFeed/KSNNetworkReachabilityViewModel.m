//
//  KSNNetworkReachabilityViewModel.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/29/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNNetworkReachabilityViewModel.h"

static inline KSNNetworkReachabilityStatus KSNNetworkReachabilityStatusFromAFStatus(AFNetworkReachabilityStatus status)
{
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable:
            return KSNNetworkReachabilityStatusNotReachable;

        case AFNetworkReachabilityStatusUnknown:
            return KSNNetworkReachabilityStatusUnknown;

        case AFNetworkReachabilityStatusReachableViaWiFi:
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return KSNNetworkReachabilityStatusReachable;
        default:
            return KSNNetworkReachabilityStatusUnknown;
    }
}

NSString *KSNStringFromNetworkReachabilityStatus(KSNNetworkReachabilityStatus status)
{
    switch (status)
    {
        case KSNNetworkReachabilityStatusNotReachable:
            return NSLocalizedString(@"Not Reachable", nil);
        case KSNNetworkReachabilityStatusReachable:
            return NSLocalizedString(@"Reachable", nil);
        case KSNNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedString(@"Unknown", nil);
    }
}

@interface KSNNetworkReachabilityViewModel ()

@property (nonatomic, strong, readwrite) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) RACSignal *reachabilityStatusSignal;

@end

@implementation KSNNetworkReachabilityViewModel

- (instancetype)init
{
    return [self initWithReachabilityManager:nil];
}

- (instancetype)initWithReachabilityManager:(AFNetworkReachabilityManager *)reachabilityManager
{
    self = [super init];
    if (self)
    {
        _reachabilityManager = reachabilityManager ?: [AFNetworkReachabilityManager sharedManager];
        [_reachabilityManager startMonitoring];
        self.reachabilityStatusSignal = [[RACObserve(self.reachabilityManager, networkReachabilityStatus) distinctUntilChanged] map:^id(NSNumber *statusNumber) {
            AFNetworkReachabilityStatus status = (AFNetworkReachabilityStatus) statusNumber.integerValue;
            return @(KSNNetworkReachabilityStatusFromAFStatus(status));
        }];
    }

    return self;
}

- (NSString *)stringFromNetworkReachabilityStatus:(KSNNetworkReachabilityStatus)status
{
    return KSNStringFromNetworkReachabilityStatus(status);
}

@end
