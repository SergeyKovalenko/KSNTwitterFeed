//
//  KSNReachabilityPlaceholderView.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 6/29/16.
//  Copyright © 2016 Sergey Kovalenko. All rights reserved.
//

#import <Masonry/View+MASAdditions.h>
#import "KSNReachabilityPlaceholderView.h"

@interface KSNReachabilityPlaceholderView ()

@property (nonatomic, readwrite) UIImageView *imageView;
@property (nonatomic, readwrite) UILabel *titleLabel;
@end

@implementation KSNReachabilityPlaceholderView

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
        make.center.equalTo(self);
    }];

    self.imageView = [[UIImageView alloc] init];
    [contentView addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView);
        make.leading.greaterThanOrEqualTo(contentView);
        make.trailing.lessThanOrEqualTo(contentView);
        make.centerX.equalTo(contentView);
    }];

    self.titleLabel = [[UILabel alloc] init];
    [contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView).offset(25.f);
        make.leading.greaterThanOrEqualTo(contentView);
        make.trailing.lessThanOrEqualTo(contentView);
        make.bottom.equalTo(contentView);
        make.centerX.equalTo(contentView);
    }];

}

@end
