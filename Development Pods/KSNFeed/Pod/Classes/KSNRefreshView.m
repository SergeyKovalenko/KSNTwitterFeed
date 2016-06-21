//
//  KSNRefreshView.m
//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNRefreshView.h"
#import <KSNUtils/UIView+KSNAdditions.h>
#import <KSNUtils/KSNGlobalFunctions.h>
#import <Masonry/Masonry.h>

static const CGFloat TRARefreshViewHeight = 44.0f;
static const CGFloat TRARefreshViewWidth = 60.0f;

@interface KSNRefreshView ()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutletCollection(UIActivityIndicatorView) NSArray *activityIndicators;

@property (nonatomic, assign) BOOL refreshOffsetReached;
@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
@property (nonatomic, readwrite) KSNRefreshViewPosition position;
@end

@implementation KSNRefreshView

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.position = position;
        [self loadXibContent];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithPosition:KSNRefreshViewPositionTop];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.position = KSNRefreshViewPositionTop;
        [self loadXibContent];
    }
    return self;
}

- (CGFloat)refreshOffset
{
    if (KSNRefreshViewPositionVertical(self.position))
    {
        return TRARefreshViewWidth;
    }
    else
    {
        return TRARefreshViewHeight;
    }
}

- (void)setAmountPass:(CGFloat)amountPass
{
    if (!self.refreshing && amountPass > 0)
    {
        [self adjustPositionForAmount:amountPass];
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

- (CGSize)sizeThatFits:(CGSize)size
{
     if (KSNRefreshViewPositionHorizontal(self.position))
     {
         size.height = TRARefreshViewHeight;
     }
    else
    {
         size.width = TRARefreshViewWidth;
    }
    return size;
}

- (UINib *)nib
{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"KSNFeedXib" ofType:@"bundle"]];
    
    if (KSNRefreshViewPositionHorizontal(self.position))
    {
        return [UINib nibWithNibName:[NSStringFromClass([self class]) stringByAppendingString:@"Horizontical"] bundle:bundle];
    }
    else if (KSNRefreshViewPositionVertical(self.position))
    {
        return [UINib nibWithNibName:[NSStringFromClass([self class]) stringByAppendingString:@"TRARefreshViewVertical"] bundle:bundle];
    }
    else
    {
        LOGERROR(@"Wrong KSNRefreshViewPosition %lu", (unsigned long) self.position);
        return nil;
    }
}

- (void)loadXibContent
{
    UIView *infoView = [[[self nib] instantiateWithOwner:self options:nil] firstObject];
    self.clipsToBounds = YES;
    [self addSubview:infoView];
    [infoView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.equalTo(self).insets(UIEdgeInsetsZero);
    }];
}

- (void)setPullTitle:(NSString *)pullTitle
{
    _pullTitle = [pullTitle copy];
    [self updateTitle];
}

- (void)setReleaseTitle:(NSString *)releaseTitle
{
    _releaseTitle = [releaseTitle copy];
    [self updateTitle];
}

- (void)updateTitle
{
    if (self.refreshOffsetReached)
    {
        self.titleLabel.text = self.releaseTitle;
    }
    else
    {
        self.titleLabel.text = self.pullTitle;
    }
}

- (void)setRefreshOffsetReached:(BOOL)refreshOffsetReached
{
    if (_refreshOffsetReached != refreshOffsetReached)
    {
        _refreshOffsetReached = refreshOffsetReached;

        if (!self.isRefreshing)
        {
            [self.activityIndicators enumerateObjectsUsingBlock:^(UIActivityIndicatorView *activityIndicator, NSUInteger idx, BOOL *stop) {
                if (refreshOffsetReached)
                {
                    [activityIndicator startAnimating];
                }
                else
                {
                    [activityIndicator stopAnimating];
                }
            }];

            [self updateTitle];
        }
    }
}

- (void)setRefreshing:(BOOL)refreshing
{
    if (_refreshing != refreshing)
    {

        [self.activityIndicators enumerateObjectsUsingBlock:^(UIActivityIndicatorView *activityIndicator, NSUInteger idx, BOOL *stop) {
            if (refreshing)
            {
                [activityIndicator startAnimating];
            }
            else
            {
                [activityIndicator stopAnimating];
            }
        }];
        _refreshing = refreshing;

        if (refreshing)
        {
            [self adjustPositionForAmount:self.refreshOffset];
        }
    }
}


@end
