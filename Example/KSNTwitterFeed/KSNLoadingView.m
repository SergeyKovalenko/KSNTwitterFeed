//
//  KSNLoadingView.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/27/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <Masonry/View+MASAdditions.h>
#import "KSNLoadingView.h"

@interface KSNLoadingView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
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
