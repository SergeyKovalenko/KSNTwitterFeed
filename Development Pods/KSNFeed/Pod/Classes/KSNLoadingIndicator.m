//
//  KSNLoadingIndicator.m
//
//  Created by Sergey Kovalenko on 1/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNLoadingIndicator.h"
#import "KSNGlobalFunctions.h"

@interface KSNLoadingIndicatorLayer : CALayer

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat progress;
@end

@implementation KSNLoadingIndicatorLayer

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self)
    {
        self.needsDisplayOnBoundsChange = YES;
        KSNLoadingIndicatorLayer *loadingLayer = KSNSafeCast([KSNLoadingIndicatorLayer class], layer);
        self.progress = loadingLayer.progress;
        self.color = loadingLayer.color;
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    return [key isEqualToString:@"progress"] || [key isEqualToString:@"color"] || [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
    CGContextSaveGState(ctx);

    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextClearRect(ctx, self.bounds);

    CGRect progressRect = self.bounds;
    progressRect.size.width = self.progress * progressRect.size.width / 100;
    CGContextSetFillColorWithColor(ctx, self.color.CGColor);
    CGContextFillRect(ctx, progressRect);
    CGContextRestoreGState(ctx);
}

@end

@interface KSNLoadingIndicator ()

@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval interval;
@property (nonatomic, assign, getter = isAnimating) BOOL animating;

@end

@implementation KSNLoadingIndicator

@dynamic progress;
@dynamic color;

+ (Class)layerClass
{
    return [KSNLoadingIndicatorLayer class];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size.height = 3.0f;
    return size;
}

#pragma mark - Public methods

- (void)setProgress:(CGFloat)progress
{
    if (progress < 0)
    {
        progress = 0;
    }
    if (progress >= 100)
    {
        [self finish];
    }
    else
    {
        self.customLayer.progress = progress;
    }
}

- (CGFloat)progress
{
    return self.customLayer.progress;
}

- (void)setColor:(UIColor *)color
{
    self.customLayer.color = color;
}

- (UIColor *)color
{
    return self.customLayer.color;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    if (self.superview && !self.color)
    {
        self.color = self.tintColor;
    }
}

- (void)fakeProgressWithDuration:(NSTimeInterval)timeInterval
{
    if (self.isAnimating)
    {
        return;
    }
    self.animating = YES;

    [self.layer removeAllAnimations];

    self.progress = 0;

    self.alpha = 1.0f;

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"progress"];
    animation.keyTimes = @[@(0),
                           @(0.25),
                           @(1.0)];
    animation.values = @[@(0),
                         @(85),
                         @(95)];
    animation.removedOnCompletion = NO;
    animation.duration = timeInterval * 4;
    animation.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:animation forKey:@"fake-progress"];

    self.startTime = [self.customLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.interval = timeInterval;
}

- (void)finish
{
    self.animating = NO;

    CAKeyframeAnimation *oldAnimation = (CAKeyframeAnimation *) [self.layer animationForKey:@"fake-progress"];
    CFTimeInterval endTime = [self.customLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    CFTimeInterval duration = endTime - self.startTime;
    CFTimeInterval fastProgress = MIN(duration, self.interval) * [oldAnimation.values[1] doubleValue] / self.interval;
    CFTimeInterval slowProgress = MAX(duration - self.interval, 0.f) * (100 - [oldAnimation.values[1] doubleValue]) / self.interval * 3;

    [self.layer removeAllAnimations];

    self.customLayer.progress = 100;
    CABasicAnimation *finish = [CABasicAnimation animationWithKeyPath:@"progress"];
    finish.fromValue = @(fastProgress + slowProgress);
    finish.toValue = @(100);
    finish.duration = 0.1f;
    finish.removedOnCompletion = NO;
    [self.customLayer addAnimation:finish forKey:@"finish-progress"];

    [UIView animateWithDuration:0.4 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 0;
    }                completion:NULL];
}

#pragma mark - Private methods

- (KSNLoadingIndicatorLayer *)customLayer
{
    return ((KSNLoadingIndicatorLayer *) self.layer);
}

@end
