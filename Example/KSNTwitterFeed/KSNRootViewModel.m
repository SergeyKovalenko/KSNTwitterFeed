//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <KSNTwitterFeed/KSNTwitterSocialAdapter.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNRootViewModel.h"
#import "KSNTwitterLoginViewModel.h"
#import "KSNTwitterFeedViewModel.h"

@interface KSNRootViewModel ()

@property (nonatomic, readwrite) KSNTwitterSocialAdapter *twitterSocialAdapter;
@property (nonatomic, strong) RACReplaySubject *transitionSubject;
@property (nonatomic, strong) NSMutableArray *observers;
@end

@implementation KSNRootViewModel

- (instancetype)initWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter
{
    self = [super init];
    if (self)
    {
        _twitterSocialAdapter = twitterSocialAdapter;
        _transitionSubject = [RACReplaySubject replaySubjectWithCapacity:1];
        [_transitionSubject sendNext:[twitterSocialAdapter userSession] ? @(KSNRootViewModelToFeedTransition) : @(KSNRootViewModelToLoginTransition)];
        self.observers = [NSMutableArray arrayWithCapacity:2];
        [self startSessionObservation];
    }

    return self;
}

- (void)dealloc
{
    [self endSessionObservation];
}

- (RACSignal *)transitionSignal
{
    return self.transitionSubject;
}

- (KSNTwitterFeedViewModel *)twitterFeedViewModel;
{
    return [[KSNTwitterFeedViewModel alloc] initWithTwitterSocialAdapter:self.twitterSocialAdapter];

}

- (KSNTwitterLoginViewModel *)twitterLoginViewModel
{
    return [[KSNTwitterLoginViewModel alloc] initWithSocialAdapter:self.twitterSocialAdapter];

}

#pragma mark - Private Methods

- (void)startSessionObservation
{
    [self endSessionObservation];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    @weakify(self);
    [self.observers addObject:[center addObserverForName:KSNTwitterSocialAdapterDidStartUserSessionNotification
                                                  object:self.twitterSocialAdapter
                                                   queue:[NSOperationQueue mainQueue]
                                              usingBlock:^(NSNotification *__nonnull note) {
                                                  @strongify(self);
                                                  [self.transitionSubject sendNext:@(KSNRootViewModelToFeedTransition)];
                                              }]];

    [self.observers addObject:[center addObserverForName:KSNTwitterSocialAdapterDidEndUserSessionNotification
                                                  object:self.twitterSocialAdapter
                                                   queue:[NSOperationQueue mainQueue]
                                              usingBlock:^(NSNotification *__nonnull note) {
                                                  @strongify(self);
                                                  [self.transitionSubject sendNext:@(KSNRootViewModelToLoginTransition)];
                                              }]];
}

- (void)endSessionObservation
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    for (id observer in self.observers)
    {
        [center removeObserver:observer];
    }
}

@end