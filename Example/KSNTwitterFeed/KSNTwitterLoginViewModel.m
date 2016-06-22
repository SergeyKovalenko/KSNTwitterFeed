//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNTwitterFeed/KSNSocialAdapter.h>
#import "KSNTwitterLoginViewModel.h"

@interface KSNTwitterLoginViewModel ()

@property (nonatomic, readwrite) RACCommand *loginCommand;
@end

@implementation KSNTwitterLoginViewModel

- (instancetype)initWithSocialAdapter:(KSNSocialAdapter *)adapter
{
    self = [super init];
    if (self)
    {
        _loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [adapter startUserSession];
        }];
    }

    return self;
}
@end