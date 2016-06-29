//
//  KSNLoadingView.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/27/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <Masonry/View+MASAdditions.h>
#import "KSNLoadingView.h"
#import "KSNRefreshView.h"
#import "KSNLoadingIndicator.h"

@interface KSNLoadingView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong, readwrite) KSNRefreshView *refreshView;
@end

@implementation KSNLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }

    return self;
}

- (void)commonInit
{
    KSNRefreshView *refreshView = [[KSNRefreshView alloc] initWithPosition:KSNRefreshViewPositionTop];
    refreshView.pullTitle = NSLocalizedString(@"Pull down for refresh", nil);
    refreshView.releaseTitle = NSLocalizedString(@"Release for refresh", nil);
    [self addSubview:refreshView];
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [refreshView sizeToFit];
    CGRect refreshRect = refreshView.frame;
    refreshRect.size.width = CGRectGetWidth(self.bounds);
    refreshView.frame = refreshRect;
    self.refreshView = refreshView;

    UIView *contentView = [[UIView alloc] init];
    [self addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self);
        make.trailing.equalTo(self);
        make.bottom.equalTo(self);
        make.height.mas_equalTo(55.f);
    }];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [contentView addSubview:self.activityIndicator];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(contentView);
    }];
}

@end
