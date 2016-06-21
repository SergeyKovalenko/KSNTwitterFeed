//
//  AFMInfoBanner.h
//  AFMInfoBanner
//
//  Created by Romans Karpelcevs on 6/14/13.
//  Copyright (c) 2013 Ask.fm Europe, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AFMInfoBannerStyle) {
    AFMInfoBannerStyleError = 0,
    AFMInfoBannerStyleInfo,
};

@interface AFMInfoBanner : UIView

@property (nonatomic) AFMInfoBannerStyle style;
@property (nonatomic) NSString *text;

@property (nonatomic) UIFont *font UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *errorBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *infoBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *errorTextColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *infoTextColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat topInset;
@property (nonatomic) CGFloat minimumHeight;

- (void)show:(BOOL)animated inView:(UIView *)view;
- (void)hide:(BOOL)animated;
- (void)hideWithAnimatedNumber:(NSNumber *)animatedNumber;

@end
