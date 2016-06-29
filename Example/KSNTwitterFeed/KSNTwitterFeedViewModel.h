//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNNetworkReachabilityViewModel.h"

@class RACCommand;
@class KSNTwitterSocialAdapter;
@protocol KSNCellNodeDataSource;

@interface KSNTwitterFeedViewModel : NSObject <KSNNetworkReachabilityViewModel>

- (instancetype)initWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter;

@property (nonatomic, readonly) RACCommand *logoutCommand;
@property (nonatomic, readonly) NSString *username;

- (id <KSNCellNodeDataSource>)feedDataSource;

@end