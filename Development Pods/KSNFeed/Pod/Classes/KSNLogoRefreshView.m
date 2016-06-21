//
//  KSNLogoRefreshView.m

//
//  Created by Sergey Kovalenko on 2/25/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNLogoRefreshView.h"
#import <KSNUtils/UIView+KSNAdditions.h>

static CGFloat TRALogoRefreshViewHeight = 50.0f;

@interface KSNLogoRefreshView ()

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (nonatomic, assign) BOOL refreshOffsetReached;
@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
@property (nonatomic, assign) CGFloat amountPass;
@property (nonatomic, readwrite) KSNRefreshViewPosition position;

@end

@implementation KSNLogoRefreshView

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.position = position;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithPosition:KSNRefreshViewPositionTop];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.position = KSNRefreshViewPositionTop;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (NSBundle *)bundle
{
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"KSNFeedXib" ofType:@"bundle"]];
}

#pragma mark - TRARefreshingView

- (CGFloat)refreshOffset
{
    return TRALogoRefreshViewHeight;
}

- (void)setAmountPass:(CGFloat)amountPass
{
    if (!self.refreshing && amountPass > 0)
    {
        [self adjustPositionForAmount:amountPass];

        if (amountPass)
        {
            if (![self.logoImageView.layer animationForKey:@"PulseAnimationSlow"])
            {
                CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
                anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                anim.duration = 0.6;
                anim.repeatCount = HUGE_VALF;
                anim.autoreverses = YES;
                anim.removedOnCompletion = YES;
                anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
                [self.logoImageView.layer addAnimation:anim forKey:@"PulseAnimationSlow"];
            }
        }
    }
    else
    {
        [self.logoImageView.layer removeAnimationForKey:@"PulseAnimationSlow"];
    }
}

- (void)adjustPositionForAmount:(CGFloat)amount
{
    switch (self.position)
    {
        case KSNRefreshViewPositionTop:
        {
            CGFloat top = self.frameTop;
            self.frameHeight = amount;
            self.frameTop = top;
        };
            break;
        case KSNRefreshViewPositionBottom:
        {
            CGFloat bottom = self.frameBottom;
            self.frameHeight = amount;
            self.frameBottom = bottom;
        };
            break;
        case KSNRefreshViewPositionLeft:
        {
            CGFloat left = self.frameLeft;
            self.frameWidth = amount;
            self.frameLeft = left;
        };
            break;
        case KSNRefreshViewPositionRight:
        {
            CGFloat right = self.frameRight;
            self.frameWidth = amount;
            self.frameRight = right;
        };
            break;
    }
}

- (void)setRefreshOffsetReached:(BOOL)refreshOffsetReached
{
    if (_refreshOffsetReached != refreshOffsetReached)
    {
        _refreshOffsetReached = refreshOffsetReached;

        if (!self.refreshing)
        {
            if (refreshOffsetReached)
            {
                CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                rotate.toValue = @(2.0f * M_PI); // The angle we are rotating to
                rotate.duration = 0.5;

                [self.logoImageView.layer addAnimation:rotate forKey:@"RotationAnimation"];
            }
            else
            {
                [self.logoImageView.layer removeAnimationForKey:@"RotationAnimation"];
            }
        }
    }
}

- (void)setRefreshing:(BOOL)refreshing
{
    if (_refreshing != refreshing)
    {
        _refreshing = refreshing;
        if (refreshing)
        {
            [self adjustPositionForAmount:self.refreshOffset];

            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            anim.duration = 0.4;
            anim.beginTime = CACurrentMediaTime() + 0.2f;
            anim.repeatCount = HUGE_VALF;
            anim.autoreverses = YES;
            anim.removedOnCompletion = YES;
            anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
            [self.logoImageView.layer addAnimation:anim forKey:@"PulseAnimation"];
        }
        else
        {
            [self.logoImageView.layer removeAnimationForKey:@"PulseAnimation"];
        }
    }
}

@end
