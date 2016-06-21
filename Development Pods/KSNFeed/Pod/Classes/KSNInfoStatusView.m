//
//  KSNInfoStatusView.m
//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNInfoStatusView.h"

@interface KSNInfoStatusView ()

@property (nonatomic, strong, readwrite) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *refreshButton;

@end

@implementation KSNInfoStatusView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame xibName:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
{
    return [self initWithFrame:CGRectZero xibName:nibNameOrNil];
}

- (instancetype)initWithFrame:(CGRect)frame xibName:(NSString *)xibNameOrNil
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self loadXibContentWithXibName:xibNameOrNil?:NSStringFromClass([self class])];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self loadXibContentWithXibName:NSStringFromClass([self class])];
    }
    return self;
}

- (void)loadXibContentWithXibName:(NSString *)xibName
{
    UIView *infoView = [[[UINib nibWithNibName:xibName bundle:nil] instantiateWithOwner:self options:nil] firstObject];
    infoView.frame = self.bounds;
    infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:infoView];
}

@end
