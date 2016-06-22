//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACCommand;
@class KSNSocialAdapter;

@interface KSNTwitterLoginViewModel : NSObject

@property (nonatomic, readonly) RACCommand *loginCommand;

- (instancetype)initWithSocialAdapter:(KSNSocialAdapter *)adapter;

@end