//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACCommand;
@class KSNTwitterSocialAdapter;

@interface KSNTwitterFeedViewModel : NSObject

- (instancetype)initWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter;

@property (nonatomic, readonly) RACCommand *logoutCommand;
@property (nonatomic, readonly) NSString *username;

@end