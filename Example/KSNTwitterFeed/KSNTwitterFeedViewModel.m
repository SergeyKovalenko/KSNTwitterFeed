//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNTwitterFeed/KSNTwitterFeed.h>
#import <MagicalRecord/MagicalRecord.h>

#import "KSNTwitterFeedViewModel.h"
#import "KSNCellNodeDataSource.h"

@import Accounts;

@interface KSNTwitterFeedViewModel ()

@property (nonatomic, readwrite) RACCommand *logoutCommand;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, strong) KSNTwitterAPI *api;
@property (nonatomic, strong) id <KSNCellNodeDataSource> feedDataSource;
@property (nonatomic, strong) KSNNetworkReachabilityViewModel *reachabilityViewModel;
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

        NSString *(^usernameBlock)(ACAccount *) = ^(ACAccount *account) {
            return account ? [@"@" stringByAppendingString:account.username] : @"";
        };

        RAC(self, username) = [[[RACSignal merge:@[startSessionSignal,
                                                   endSessionSignal]] map:^id(NSNotification *notification) {
            KSNTwitterSocialAdapter *adapter = KSNSafeCast([KSNTwitterSocialAdapter class], notification.object);
            return usernameBlock(adapter.activeAccount);
        }] startWith:usernameBlock(twitterSocialAdapter.activeAccount)];

        KSNTwitterAPI *api = [[KSNTwitterAPI alloc] initWithSocialAdapter:twitterSocialAdapter];
        NSManagedObjectContext *dataImportContext = [NSManagedObjectContext MR_context];
        KSNTwitterManagedObjectFeedContext *feedContext = [[KSNTwitterManagedObjectFeedContext alloc] initWithAPI:api
                                                                                             managedObjectContect:dataImportContext];

        KSNFeedDataProvider *dataProvider = [[KSNFeedDataProvider alloc] initWithDataProviderContext:feedContext];
        NSManagedObjectContext *uiContext = [NSManagedObjectContext MR_newMainQueueContext];
        [uiContext setParentContext:dataImportContext];

        KSNManagedObjectStore *store = [[KSNManagedObjectStore alloc] initWithManagedObjectContext:uiContext fetchRequest:feedContext.feedRequest];
        KSNCellNodeDataSource *feedDataSource = [[KSNCellNodeDataSource alloc] initWithDataProvider:dataProvider itemsStore:store];
        feedDataSource.configurationBlock = ^ASCellNode *(KSNTweet *model) {
            ASTextCellNode *textCellNode = [[ASTextCellNode alloc] init];
            textCellNode.text = [@(model.tweetID).stringValue stringByAppendingString:model.text];
            return textCellNode;
        };
        self.feedDataSource = feedDataSource;

        @weakify(self);
        self.reachabilityViewModel = [[KSNNetworkReachabilityViewModel alloc] init];
        [[[[self.reachabilityViewModel reachabilityStatusSignal] filter:^BOOL(NSNumber *status) {
            return status.integerValue == KSNNetworkReachabilityStatusReachable;
        }] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
            @strongify(self);
            [self.feedDataSource refreshWithCompletion:nil];
        }];
    }

    return self;
}

- (RACSignal *)reachabilityStatusSignal
{
    return [self.reachabilityViewModel reachabilityStatusSignal];
}

- (NSString *)stringFromNetworkReachabilityStatus:(KSNNetworkReachabilityStatus)status
{
    return [self.reachabilityViewModel stringFromNetworkReachabilityStatus:status];
}

@end