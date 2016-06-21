//
//  KSNFeedViewModel.m
//
//  Created by Sergey Kovalenko on 12/15/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNSearchableTraits.h"

@protocol KSNTableViewModelTraits, KSNCollectionViewModelTraits, KSNDataSource, KSNReachabilityViewModel;

@class KSNReachabilityViewModel;

@protocol KSNFeedViewModel <NSObject>

@property (nonatomic, strong, readonly) id <KSNDataSource> dataSource;
@property (nonatomic, strong, readonly) id <KSNReachabilityViewModel> reachabilityViewModel;

@optional
@property (nonatomic, strong, readonly) id <KSNTableViewModelTraits> tableViewModel;
@property (nonatomic, strong, readonly) id <KSNCollectionViewModelTraits> collectionViewModel;
@property (nonatomic, strong, readonly) id <KSNDataSource> tableViewDataSource;

@end

@interface KSNFeedViewModel : NSObject <KSNFeedViewModel>

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource;

@property (nonatomic, assign, getter=isActive) BOOL active;

@property (nonatomic, strong, readonly) KSNReachabilityViewModel *reachability;

@end

@protocol KSNSearchableFeedViewModel <KSNFeedViewModel, KSNSearchableTraits>

@end

@interface KSNSearchableFeedViewModel : KSNFeedViewModel <KSNSearchableFeedViewModel>

@end