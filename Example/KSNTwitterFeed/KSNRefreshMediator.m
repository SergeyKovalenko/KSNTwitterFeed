//
//  KSNRefreshMediator.m

//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNRefreshMediator.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface KSNRefreshMediator ()

@property (nonatomic, strong) NSArray *refreshInfo;
@end

@implementation KSNRefreshMediator

#pragma mark - Properties

- (instancetype)init
{
    return [self initWithRefreshInfo:nil];
}

- (instancetype)initWithRefreshInfo:(NSArray *)refreshInfo
{
    self = [super init];
    if (self)
    {
        self.refreshInfo = refreshInfo;
        
        for (KSNRefreshMediatorInfo *info in self.refreshInfo)
        {
            @weakify(self);
            info.refreshedBlock = ^(KSNRefreshMediatorInfo *refreshedInfo) {
                @strongify(self);
                if (self.delegate)
                {
                    [self.delegate refreshMediator:self didTriggerUpdateAtPossition:refreshedInfo];
                }
            };
        }
    }
    return self;
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    for (KSNRefreshMediatorInfo *info in self.refreshInfo)
    {
        info.scrollView = scrollView;
    }
}

- (void)scrollViewContentInsetsChanged
{
    for (KSNRefreshMediatorInfo *info in self.refreshInfo)
    {
        [info scrollViewContentInsetsChanged];
    }
}

- (void)scrollViewDidScroll
{
    for (KSNRefreshMediatorInfo *info in self.refreshInfo)
    {
        [info scrollViewDidScroll];
    }
}

- (void)scrollViewDidEndDragging
{
    for (KSNRefreshMediatorInfo *info in self.refreshInfo)
    {
        [info scrollViewDidEndDragging];
    }
}

@end

