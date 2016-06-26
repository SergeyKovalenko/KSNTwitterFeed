//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNTwitterFeed/KSNSocialAdapter.h>
#import <KSNTwitterFeed/KSNTwitterSocialAdapter.h>
#import <KSNTwitterFeed/KSNTwitterAPI.h>
#import "KSNTwitterFeedViewModel.h"
#import "KSNCellNodeDataSource.h"
#import "KSNManagedObjectStore.h"

@import Accounts;
#import <KSNTwitterFeed/KSNTwitterFeedDataProvider.h>
#import <KSNTwitterFeed/KSNTwitterManagedObjectFeedContext.h>
#import <MagicalRecord/NSManagedObjectContext+MagicalRecord.h>
#import <KSNTwitterFeed/KSNTweet.h>

@interface KSNTwitterFeedViewModel ()

@property (nonatomic, readwrite) RACCommand *logoutCommand;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, strong) KSNTwitterAPI *api;
@property (nonatomic, strong) id <KSNCellNodeDataSource> feedDataSource;
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

        KSNTwitterAPI *api = [[KSNTwitterAPI alloc] initWithSocialAdapter:twitterSocialAdapter];
        NSManagedObjectContext *dataImportContext = [NSManagedObjectContext MR_context];
        KSNTwitterManagedObjectFeedContext *feedContext = [[KSNTwitterManagedObjectFeedContext alloc] initWithAPI:api
                                                                                             managedObjectContect:dataImportContext];

        KSNTwitterFeedDataProvider *dataProvider = [[KSNTwitterFeedDataProvider alloc] initWithTwitterFeedContext:feedContext];

        NSManagedObjectContext *uiContext = [NSManagedObjectContext MR_newMainQueueContext];
        [uiContext setParentContext:dataImportContext];

        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@keypath(KSNTweet.new, tweetID) ascending:NO]];
        KSNManagedObjectStore *store = [[KSNManagedObjectStore alloc] initWithManagedObjectContext:uiContext sortDescriptors:sortDescriptors];
        KSNCellNodeDataSource *feedDataSource = [[KSNCellNodeDataSource alloc] initWithDataProvider:dataProvider itemsStore:store];
        feedDataSource.configurationBlock = ^ASCellNode *(KSNTweet *model) {
            ASTextCellNode *textCellNode = [[ASTextCellNode alloc] init];
            textCellNode.text = [@(model.tweetID).stringValue stringByAppendingString:model.text];
            return textCellNode;
        };
        self.feedDataSource = feedDataSource;
    }

    return self;
}


@end