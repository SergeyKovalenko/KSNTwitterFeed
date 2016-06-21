//
//  AFMInfoBanner.m
//  AFMInfoBanner
//
//  Created by Romans Karpelcevs on 6/14/13.
//  Copyright (c) 2013 Ask.fm Europe, Ltd. All rights reserved.
//


#import "AFMInfoBanner.h"

#ifdef UIColorFromRGB
#undef UIColorFromRGB
#endif

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((((rgbValue) & 0xFF0000) >> 16))/255.f \
green:((((rgbValue) & 0xFF00) >> 8))/255.f \
blue:(((rgbValue) & 0xFF))/255.f alpha:1.0]

static const CGFloat kMargin = 10.f;
static const NSTimeInterval kAnimationDuration = 0.3;
static const int kRedBannerColor = 0xff0000;
static const int kGreenBannerColor = 0x008000;
static const int kDefaultTextColor = 0xffffff;
static const CGFloat kFontSize = 13.f;
static const CGFloat kDefaultHideInterval = 2.0;

@interface AFMInfoBanner ()
@property (nonatomic) UILabel *textLabel;
@end

@implementation AFMInfoBanner

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setStyle:(AFMInfoBannerStyle)style
{
    _style = style;
    [self applyStyle];
}

- (void)applyStyle
{
    if (self.style == AFMInfoBannerStyleError) {
        [self setBackgroundColor:self.errorBackgroundColor ?: UIColorFromRGB(kRedBannerColor)];
        [self.textLabel setTextColor:self.errorTextColor ?: UIColorFromRGB(kDefaultTextColor)];
    } else if (self.style == AFMInfoBannerStyleInfo) {
        [self setBackgroundColor:self.infoBackgroundColor ?: UIColorFromRGB(kGreenBannerColor)];
        [self.textLabel setTextColor:self.infoTextColor ?: UIColorFromRGB(kDefaultTextColor)];
    }
    [self.textLabel setFont:self.font ?: [UIFont boldSystemFontOfSize:kFontSize]];
    [self setNeedsLayout];
}

- (void)setText:(NSString *)text
{
    _text = text;
    [self.textLabel setText:text];
    [self setNeedsLayout];
}

- (void)setErrorBackgroundColor:(UIColor *)errorBackgroundColor
{
    _errorBackgroundColor = errorBackgroundColor;
    [self applyStyle];
}

- (void)setInfoBackgroundColor:(UIColor *)infoBackgroundColor
{
    _infoBackgroundColor = infoBackgroundColor;
    [self applyStyle];
}

- (void)setErrorTextColor:(UIColor *)errorTextColor
{
    _errorTextColor = errorTextColor;
    [self applyStyle];
}

- (void)setInfoTextColor:(UIColor *)infoTextColor
{
    _infoTextColor = infoTextColor;
    [self applyStyle];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self applyStyle];
}

- (void)setUp
{
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    [self setTextLabel:label];
    [self configureLabel];
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:label];
    self.topInset = 0.f;
    self.minimumHeight = 0.f;
}

- (void)setTopInset:(CGFloat)topInset
{
    _topInset = topInset;
    
    [self sizeToFit];
    
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.y = topInset;
    textLabelFrame.size.height = CGRectGetHeight(self.bounds) - topInset;
    self.textLabel.frame = textLabelFrame;
}

- (void)configureLabel
{
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    [self.textLabel setTextAlignment:NSTextAlignmentCenter];
    [self.textLabel setNumberOfLines:0];
    [self.textLabel setPreferredMaxLayoutWidth:CGRectGetWidth([[UIScreen mainScreen] bounds])];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size = [self.textLabel sizeThatFits:size];
    size.height += 2.0f * kMargin;
    size.height += self.topInset;
    size.height = fmaxf(size.height, self.minimumHeight);
    size.width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    return size;
}

- (void)show:(BOOL)animated inView:(UIView *)view;
{
    [self applyStyle];
    [self sizeToFit];
    
    [view addSubview:self];
    
    if (animated)
    {
        self.frame = CGRectMake(0, - CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             self.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
                         }];
    }
    else
    {
        self.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    }
}

- (void)hide:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.frame = CGRectMake(0, - CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
    else
    {
        [self removeFromSuperview];
    }
}

- (void)hideWithAnimatedNumber:(NSNumber *)animatedNumber
{
    return [self hide:[animatedNumber boolValue]];
}

@end