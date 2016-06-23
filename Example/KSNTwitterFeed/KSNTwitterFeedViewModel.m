//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNTwitterFeed/KSNSocialAdapter.h>
#import <KSNTwitterFeed/KSNTwitterSocialAdapter.h>
#import <KSNTwitterFeed/KSNTwitterAPI.h>
#import "KSNTwitterFeedViewModel.h"

@import Accounts;

@interface KSNTwitterFeedViewModel ()

@property (nonatomic, readwrite) RACCommand *logoutCommand;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, strong) KSNTwitterAPI *api;
@end

@implementation KSNTwitterFeedViewModel

- (instancetype)initWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter;
{
    self = [super init];
    if (self)
    {
        _logoutCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [twitterSocialAdapter endUserSession];
        }];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        RACSignal *startSessionSignal = [center rac_addObserverForName:KSNTwitterSocialAdapterDidStartUserSessionNotification
                                                                object:twitterSocialAdapter];
        RACSignal *endSessionSignal = [center rac_addObserverForName:KSNTwitterSocialAdapterDidEndUserSessionNotification
                                                              object:twitterSocialAdapter];
        RAC(self, username) = [[[RACSignal merge:@[startSessionSignal,
                                                   endSessionSignal]] map:^id(id value) {
            return [twitterSocialAdapter activeAccount].username;
        }] startWith:[twitterSocialAdapter activeAccount].username];

        self.api = [[KSNTwitterAPI alloc] initWithSocialAdapter:twitterSocialAdapter];
        [[self.api userTimelineWithDeserializer:nil] subscribeNext:^(id x) {
             NSLog(@"%@", x);
         }                                                   error:^(NSError *error) {
             NSLog(@"%@", error);
         }                                               completed:^{
             NSLog(@"complete");
         }];
    }

    return self;
}
@end