//
//  KSNRefreshMediatorInfo.m
//
//  Created by Sergey Kovalenko on 10/21/15.
//  Copyright © 2015. All rights reserved.
//

#import "KSNRefreshMediatorInfo.h"
#import <KSNUtils/UIView+KSNAdditions.h>

@interface KSNRefreshMediatorInfo ()

@property (nonatomic, readwrite) KSNRefreshViewPosition position;
@property (nonatomic, assign, readwrite) CGFloat refreshOffset;
@property (nonatomic, assign) CGRect initialScrollFrame;
@end

@implementation KSNRefreshMediatorInfo

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position
{
    self = [super init];
    if (self)
    {
        self.position = position;
        self.remainOffset = CGPointZero;
        self.baseInsets = UIEdgeInsetsMake(-1, -1, -1, -1);
        self.initialScrollFrame = CGRectZero;
        _refreshOffset = CGFLOAT_MAX;
        _refreshEnabled = YES;
    }
    return self;
}

#pragma mark - Public properties

- (CGFloat)refreshOffset
{
    if (self.refreshView && !(_refreshOffset > 0 && _refreshOffset < CGFLOAT_MAX))
    {
        if ([self.refreshView respondsToSelector:@selector(refreshOffset)])
        {
            _refreshOffset = self.refreshView.refreshOffset;
        }
        else
        {
            if (self.position == KSNRefreshViewPositionTop || self.position == KSNRefreshViewPositionBottom)
            {
                _refreshOffset = CGRectGetHeight(self.refreshView.frame);
            }
            else if (self.position == KSNRefreshViewPositionLeft || self.position == KSNRefreshViewPositionRight)
            {
                _refreshOffset = CGRectGetWidth(self.refreshView.frame);
            }
        }
    }
    return _refreshOffset;
}

- (void)setRefreshEnabled:(BOOL)refreshEnabled
{
    if (_refreshEnabled != refreshEnabled)
    {
        if (!refreshEnabled)
        {
            self.refreshView.hidden = YES;
        }

        if (self.isRefreshing && !refreshEnabled)
        {
            self.refreshing = NO;
        }

        _refreshEnabled = refreshEnabled;
    }

    if (self.isRefreshing && !refreshEnabled)
    {
        self.refreshing = NO;
    }
}

- (void)setRefreshing:(BOOL)refreshing
{
    [self setRefreshing:refreshing animated:NO];
}

- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated
{
    if (self.refreshEnabled && _refreshing != refreshing)
    {
        _refreshing = refreshing;
        self.refreshView.hidden = !refreshing;
        [self setInsetsAnimated:animated];
    }
}

static const NSTimeInterval TRARefreshMediatorAnimationDuration = 0.2;

- (void)setInsetsAnimated:(BOOL)animated
{
    if (self.refreshView)
    {
        CGFloat newInset = [self adjustedScrollInset];
        BOOL needUpdateInsets = fabs(newInset - [self scrollInset]) > 0.1;

        if (self.isRefreshing && needUpdateInsets)
        {
            [self.refreshView setRefreshing:YES];

            if (animated)
            {
                [UIView animateWithDuration:TRARefreshMediatorAnimationDuration animations:^{
                    [self adjustScrollInsetsWithInset:newInset];
                }];
            }
            else
            {
                [self adjustScrollInsetsWithInset:newInset];
            }
        }
        else if (!self.isRefreshing && needUpdateInsets)
        {
            if (animated)
            {
                [UIView animateWithDuration:TRARefreshMediatorAnimationDuration animations:^{
                    [self adjustScrollInsetsWithInset:newInset];
                }                completion:^(BOOL finished) {
                    [self.refreshView setRefreshing:NO];
                }];
            }
            else
            {
                [self adjustScrollInsetsWithInset:newInset];
                [self.refreshView setRefreshing:NO];
            }
        }
    }
}

- (void)setOffsetReached:(BOOL)offsetReached
{
    if (_offsetReached != offsetReached)
    {
        _offsetReached = offsetReached;
        if (self.isRefreshEnabled)
        {
            [self.refreshView setRefreshOffsetReached:offsetReached];
        }
    }
}

- (void)setAmountPass:(CGFloat)amountPass
{
    if (fabs(_amountPass - fabs(amountPass)) > 0.1)
    {
        _amountPass = amountPass > 0.f ? amountPass : 0.0f;

        self.offsetReached = amountPass >= self.refreshOffset;

        if (self.refreshEnabled && !self.isRefreshing)
        {
            if (amountPass > 1 && self.refreshView.isHidden)
            {
                self.refreshView.hidden = NO;
            }
            else if (amountPass < 1 && !self.refreshView.isHidden)
            {
                self.refreshView.hidden = YES;
            }
        }

        if ([self.refreshView respondsToSelector:@selector(setAmountPass:)])
        {
            [self.refreshView setAmountPass:amountPass];
        }
    }
}

- (void)setRefreshView:(UIView <KSNRefreshingView> *)refreshView
{
    if (_refreshView != refreshView)
    {
        _refreshView = refreshView;
        _refreshView.hidden = !self.isRefreshEnabled;
    }
}

#pragma mark - Private methods

- (void)resetOffsetReached
{
    _offsetReached = NO;
}

- (CGFloat)adjustedScrollInset
{
    UIEdgeInsets insets = self.baseInsets;
    CGFloat inset = 0.f;
    switch (self.position)
    {
        case KSNRefreshViewPositionTop:
            inset = insets.top + (self.isRefreshing ? self.refreshOffset : 0.f);
            break;
        case KSNRefreshViewPositionLeft:
            inset = insets.left + (self.isRefreshing ? self.refreshOffset : 0.f);
            break;
        case KSNRefreshViewPositionBottom:
            inset = insets.bottom + (self.isRefreshing ? self.refreshOffset : 0.f);
            break;
        case KSNRefreshViewPositionRight:
            inset = insets.right + (self.isRefreshing ? self.refreshOffset : 0.f);
            break;
    }
    return inset;
}

- (CGFloat)scrollInset
{
    UIEdgeInsets insets = self.scrollView.contentInset;
    CGFloat inset = 0.f;
    switch (self.position)
    {
        case KSNRefreshViewPositionTop:
            inset = insets.top;
            break;
        case KSNRefreshViewPositionLeft:
            inset = insets.left;
            break;
        case KSNRefreshViewPositionBottom:
            inset = insets.bottom;
            break;
        case KSNRefreshViewPositionRight:
            inset = insets.right;
            break;
    }
    return inset;
}

- (void)adjustScrollInsetsWithInset:(CGFloat)inset
{
    UIEdgeInsets insets = self.scrollView.contentInset;
    switch (self.position)
    {
        case KSNRefreshViewPositionTop:
            insets.top = inset;
            break;
        case KSNRefreshViewPositionLeft:
            insets.left = inset;
            break;
        case KSNRefreshViewPositionBottom:
            insets.bottom = inset;
            break;
        case KSNRefreshViewPositionRight:
            insets.right = inset;
            break;
    }
    self.scrollView.contentInset = insets;
}

- (CGFloat)calculateAmountPast
{
    CGFloat amountPast = 0.0f;
    if (self.isRefreshEnabled)
    {
        CGSize contentSize = self.scrollView.contentSize;

        if (contentSize.height > 0 || contentSize.width > 0)
        {
            CGPoint contentOffset = self.scrollView.contentOffset;
            UIEdgeInsets contentInset = self.scrollView.contentInset;
            CGSize frameSize = self.scrollView.frame.size;

            switch (self.position)
            {
                case KSNRefreshViewPositionTop:
                {
                    CGFloat visibleTopOffset = contentOffset.y + contentInset.top;
                    amountPast = -1 * visibleTopOffset;
                }
                    break;
                case KSNRefreshViewPositionLeft:
                {
                    CGFloat visibleLeftOffset = contentOffset.x + contentInset.left;
                    amountPast = -1 * visibleLeftOffset;
                }
                    break;
                case KSNRefreshViewPositionBottom:
                {
                    CGFloat visibleFrameHeight = frameSize.height - contentInset.top - contentInset.bottom;
                    CGFloat visibleTopOffset = contentOffset.y + contentInset.top;
                    CGFloat visibleBottomOffset = visibleTopOffset + MIN(visibleFrameHeight, contentSize.height);
                    amountPast = visibleBottomOffset - contentSize.height;
                }
                    break;
                case KSNRefreshViewPositionRight:
                {
                    CGFloat visibleFrameWidth = frameSize.width - contentInset.left - contentInset.right;
                    CGFloat visibleLeftOffset = contentOffset.x + contentInset.left;
                    CGFloat visibleRightOffset = visibleLeftOffset + MIN(visibleFrameWidth, contentSize.width);
                    amountPast = visibleRightOffset - contentSize.width;
                }
                    break;
            }
        }
    }

    return amountPast;
}

- (void)checkOffsetsReached
{
    self.amountPass = [self calculateAmountPast];
    [self triggerNotificationForRemainOffset];
}

- (BOOL)shouldTriggerNotificationForRemainOffset
{
    BOOL needToNotify = NO;
    if (self.refreshEnabled && (!CGPointEqualToPoint(self.remainOffset, CGPointZero)) && !self.isRefreshing && (self.position == KSNRefreshViewPositionBottom || self.position == KSNRefreshViewPositionRight))
    {
        CGPoint contentOffset = self.scrollView.contentOffset;
        CGSize contentSize = self.scrollView.contentSize;
        CGRect frame = self.scrollView.frame;
        switch (self.position)
        {

            case KSNRefreshViewPositionBottom:
            {
                CGFloat availableContentSpace = contentSize.height - CGRectGetHeight(frame) - contentOffset.y;
                needToNotify = availableContentSpace <= self.remainOffset.y;
            }
                break;
            case KSNRefreshViewPositionRight:
            {
                CGFloat availableContentSpace = contentSize.width - CGRectGetWidth(frame) - contentOffset.x;
                needToNotify = availableContentSpace <= self.remainOffset.x;
            }
                break;

            default:
                needToNotify = NO;
                break;
        }
    }
    return needToNotify;
}

- (void)triggerNotificationForRemainOffset
{
    if ([self shouldTriggerNotificationForRemainOffset])
    {
        [self setRefreshing:YES animated:NO];
        [self notifyRefreshing];
    }
}

- (void)notifyRefreshing
{
    if (self.refreshedBlock)
    {
        self.refreshedBlock(self);
    }
}

#pragma mark - Public methods

- (void)scrollViewDidScroll
{
    [self checkOffsetsReached];
}

- (void)scrollViewDidEndDragging
{
    [self checkOffsetsReached];

    if (!self.isRefreshing)
    {
        if (self.isRefreshEnabled && self.offsetReached)
        {
            [self setRefreshing:YES animated:YES];
            [self notifyRefreshing];
        }
    }
    [self resetOffsetReached];
}

- (void)scrollViewContentInsetsChanged
{
    // Position the refresh views at the content insets so they appear at the "top", "bottom", "left" and "right" of the scroll view
    if (!UIEdgeInsetsEqualToEdgeInsets(self.baseInsets, self.scrollView.contentInset) || !CGRectEqualToRect(self.scrollView.frame, self.initialScrollFrame))
    {
        CGPoint origin = self.refreshView.frame.origin;
        CGRect scrollFrame = self.scrollView.frame;
        switch (self.position)
        {
            case KSNRefreshViewPositionTop:
            {
                origin.y = self.scrollView.contentInset.top;
            }
                break;
            case KSNRefreshViewPositionLeft:
            {
                origin.x = self.scrollView.contentInset.left;
            }
                break;
            case KSNRefreshViewPositionBottom:
            {
                origin.y = (CGRectGetMaxY(scrollFrame) - self.scrollView.contentInset.bottom) - self.refreshView.frameHeight;
            }
                break;
            case KSNRefreshViewPositionRight:
            {
                origin.x = (CGRectGetMaxX(scrollFrame) - self.scrollView.contentInset.right) - self.refreshView.frameWidth;
            }
                break;
        }

        CGRect refreshViewRect = self.refreshView.frame;
        refreshViewRect.origin = origin;
        self.refreshView.frame = refreshViewRect;

        self.baseInsets = self.scrollView.contentInset;
        self.initialScrollFrame = scrollFrame;
    }
}

@end

