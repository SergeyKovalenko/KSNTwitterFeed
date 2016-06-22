//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSNTwitterSocialAdapter;
@class KSNTwitterLoginViewModel;
@class KSNTwitterFeedViewModel;
typedef NS_ENUM(NSUInteger, KSNRootViewModelTransition)
{
    KSNRootViewModelToLoginTransition,
    KSNRootViewModelToFeedTransition,
};

@interface KSNRootViewModel : NSObject

@property (nonatomic, readonly) KSNTwitterSocialAdapter *twitterSocialAdapter;
@property (nonatomic, readonly) KSNTwitterLoginViewModel *twitterLoginViewModel;
@property (nonatomic, readonly) KSNTwitterFeedViewModel *twitterFeedViewModel;

- (instancetype)initWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter;

- (RACSignal *)transitionSignal;

@end