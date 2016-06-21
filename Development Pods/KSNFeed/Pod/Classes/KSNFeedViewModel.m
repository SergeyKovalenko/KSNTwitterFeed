//
//  KSNFeedViewModel.m
//
//  Created by Sergey Kovalenko on 12/15/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNFeedViewModel.h"
#import "KSNReachabilityViewModel.h"
#import "KSNDebug.h"

@interface KSNFeedViewModel ()

@property (nonatomic, strong, readwrite) id <KSNDataSource> dataSource;
@property (nonatomic, strong, readwrite) KSNReachabilityViewModel *reachability;

@end

@implementation KSNFeedViewModel

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource
{
    self = [super init];
    if (self)
    {
        _dataSource = dataSource;
        _reachability = [[KSNReachabilityViewModel alloc] initWithDataSource:dataSource];
    }
    return self;
}

- (id <KSNReachabilityViewModel>)reachabilityViewModel
{
    return self.reachability;
}

@end

@implementation KSNSearchableFeedViewModel

- (void)startSearchWithTerm:(NSString *)string userInfo:(NSDictionary *)info
{
    KSN_REQUIRE_OVERRIDE;
}

- (void)endSearch
{
    KSN_REQUIRE_OVERRIDE;
}

@end