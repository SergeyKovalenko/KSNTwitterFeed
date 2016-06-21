//
//  UIView+KSNAdditions.m
//
//  Created by Sergey Kovalenko on 2/27/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "UIView+KSNAdditions.h"
#import "KSNGlobalFunctions.h"

@interface NSString (KSNAdditions)
@end

@implementation NSString (KSNAdditions)

- (NSString *)ksn_repeat:(NSUInteger)count
{
    NSMutableString *ans = [NSMutableString stringWithCapacity:self.length * count];
    while (count)
    {
        [ans appendString:self];
        count--;
    }
    return ans;
}
@end

@interface KSNTouchyView : UIView

@property (nonatomic, copy) void(^touchEnded)(UITouch *touches, UIEvent *event);
@end

@implementation UIView (KSNAdditions)

@dynamic frameLeft;
@dynamic frameTop;
@dynamic frameRight;
@dynamic frameBottom;
@dynamic frameWidth;
@dynamic frameHeight;
@dynamic frameCenter;

- (CGFloat)frameLeft
{
    return self.frame.origin.x;
}

- (void)setFrameLeft:(CGFloat)frameLeft
{
    CGRect frame = self.frame;
    frame.origin.x = frameLeft;
    self.frame = frame;
}

- (CGFloat)frameTop
{
    return self.frame.origin.y;
}

- (void)setFrameTop:(CGFloat)frameTop
{
    CGRect frame = self.frame;
    frame.origin.y = frameTop;
    self.frame = frame;
}

- (CGFloat)frameRight
{
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setFrameRight:(CGFloat)frameRight
{
    CGRect frame = self.frame;
    frame.origin.x = frameRight - frame.size.width;
    self.frame = frame;
}

- (CGFloat)frameBottom
{
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setFrameBottom:(CGFloat)frameBottom
{
    CGRect frame = self.frame;
    frame.origin.y = frameBottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)frameHeight
{
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)frameHeight
{
    CGRect frame = self.frame;
    frame.size.height = frameHeight;
    self.frame = frame;
}

- (CGFloat)frameWidth
{
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)frameWidth
{
    CGRect frame = self.frame;
    frame.size.width = frameWidth;
    self.frame = frame;
}

- (CGPoint)frameCenter
{
    return self.center;
}

- (void)setFrameCenter:(CGPoint)frameCenter
{
    self.center = frameCenter;
    self.frameLeft = floor(self.frameLeft);
    self.frameTop = floor(self.frameTop);
}

- (CGFloat)frameCenterX
{
    return self.frameCenter.x;
}

- (void)setFrameCenterX:(CGFloat)frameCenterX
{
    self.frameCenter = CGPointMake(frameCenterX, self.frameCenterY);
}

- (CGFloat)frameCenterY
{
    return self.frameCenter.y;
}

- (void)setFrameCenterY:(CGFloat)frameCenterY
{
    self.frameCenter = CGPointMake(self.frameCenterX, frameCenterY);
}

- (CGFloat)boundsTop
{
    return self.bounds.origin.y;
}

- (CGFloat)boundsBottom
{
    return self.bounds.origin.y + self.bounds.size.height;
}

- (CGFloat)boundsLeft
{
    return self.bounds.origin.x;
}

- (CGFloat)boundsRight
{
    return self.bounds.origin.x + self.bounds.size.width;
}

- (CGPoint)boundsCenter
{
    return CGPointMake(self.bounds.origin.x + floor(self.bounds.size.width / 2), self.bounds.origin.y + floor(self.bounds.size.height / 2));
}

- (void)ksn_shakeWithMagnitude:(CGFloat)magnitude duration:(CFTimeInterval)duration repeatCount:(float)repeatCount
{
    UIView *shakeView = self;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:duration];
    [animation setRepeatCount:repeatCount];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:CGPointMake([shakeView center].x - magnitude, [shakeView center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:CGPointMake([shakeView center].x + magnitude, [shakeView center].y)]];
    [[shakeView layer] addAnimation:animation forKey:@"position"];
}

- (UIImage *)ksn_screenshot
{
    UIGraphicsBeginImageContext(self.frame.size);
    [[self layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshot;
}

- (UIView *)ksn_snapshotViewAfterScreenUpdates:(BOOL)afterUpdates
{
    if (KSN_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        return [self snapshotViewAfterScreenUpdates:afterUpdates];
    }
    else
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[self ksn_screenshot]];
        return imageView;
    }
}

#pragma mark - Debugging

- (void)ksn_enumerateSubviews:(void (^)(UIView *view, NSUInteger depth, BOOL *recurse))block
{
    if (block)
    {
        [self ntf_enumerateSubviews:block depth:0];
    }
}

- (void)ntf_enumerateSubviews:(void (^)(UIView *view, NSUInteger depth, BOOL *recurse))block depth:(NSUInteger)depth
{
    BOOL recurse = YES;
    block(self, depth, &recurse);
    if (recurse)
    {
        for (UIView *v in self.subviews)
        {
            [v ntf_enumerateSubviews:block depth:(depth + 1)];
        }
    }
}

- (NSString *)ksn_describeSubviews
{
    NSMutableString *ans = [NSMutableString string];
    [self ksn_enumerateSubviews:^(UIView *view, NSUInteger depth, BOOL *recurse) {
        CGRect frame = view.frame;
        [ans appendString:[@"  " ksn_repeat:depth]];
        [ans appendFormat:@"<%@: %p; frame = (%g %g; %g %g)>\n",
                          NSStringFromClass([view class]),
                          (__bridge void *) view,
                          frame.origin.x,
                          frame.origin.y,
                          frame.size.width,
                          frame.size.height];
    }];
    return ans;
}

- (NSString *)ksn_describeViewTree
{
    UIView *root = self;
    while (root.superview)
    {
        root = root.superview;
    }
    return [root ksn_describeSubviews];
}

+ (void)ksn_beginViewsAtTouch
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self beginViewsAtTouchMT];
    });
}

+ (void)ksn_enumerateTargetsAndActions:(UIControl *)control block:(void (^)(id target, NSString *action, UIControlEvents event))block
{
    if (!block)
    {
        return;
    }

    NSArray *events = @[@(UIControlEventTouchUpInside),
                        @(UIControlEventValueChanged)];
    for (id target in [control allTargets])
    {
        for (NSNumber *evt in events)
        {
            UIControlEvents event = evt.unsignedIntegerValue;
            for (NSString *action in [control actionsForTarget:target forControlEvent:event])
            {
                block(target, action, event);
            }
        }
    }
}

+ (void)beginViewsAtTouchMT
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];

    KSNTouchyView *view = [[KSNTouchyView alloc] initWithFrame:keyWindow.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor colorWithHue:0 saturation:1.0 brightness:0.5 alpha:0.2];

    __weak typeof(view) weakView = view;
    view.touchEnded = ^(UITouch *touch, UIEvent *event) {
        __strong typeof(weakView) view = weakView;
        [view removeFromSuperview];

        for (UIView *root in [keyWindow.subviews reverseObjectEnumerator])
        {
            if (![root isKindOfClass:[KSNTouchyView class]])
            {
                UIView *leaf = [root hitTest:[touch locationInView:root] withEvent:nil];
                if (leaf)
                {
                    NSLog(@"LEAF: %@", leaf);
                    if ([leaf isKindOfClass:[UIControl class]])
                    {
                        NSMutableArray *actions = [NSMutableArray array];
                        [self ksn_enumerateTargetsAndActions:(id) leaf block:^(id target, NSString *action, UIControlEvents evt) {
                            [actions addObject:[NSString stringWithFormat:@"-[%@ %@]: %@", [target class], action, target]];
                        }];
                        NSLog(@"Actions: %@", actions);
                    }
                }
            }
        }
    };

    [keyWindow addSubview:view];
}

+ (void)ksn_animateWithDuration:(NSTimeInterval)duration
                          delay:(NSTimeInterval)delay
         usingSpringWithDamping:(CGFloat)dampingRatio
          initialSpringVelocity:(CGFloat)velocity
                        options:(UIViewAnimationOptions)options
                     animations:(void (^)(void))animations
                     completion:(void (^)(BOOL finished))completion
{
    if (KSN_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        [UIView animateWithDuration:duration
                              delay:delay
             usingSpringWithDamping:dampingRatio
              initialSpringVelocity:velocity
                            options:options
                         animations:animations
                         completion:completion];
    }
    else
    {
        [UIView animateWithDuration:duration delay:delay options:options animations:animations completion:completion];
    }
}

- (void)ksn_addShakeAnimatinon
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"position.x";
    animation.values = @[@0,
                         @20,
                         @-20,
                         @10,
                         @0];
    animation.keyTimes = @[@0,
                           @(1 / 6.0),
                           @(3 / 6.0),
                           @(5 / 6.0),
                           @1];
    animation.duration = 0.3;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.additive = YES;

    [self.layer addAnimation:animation forKey:@"shake"];
}

+ (void)ksn_performBlock:(KSNVoidBlock)block
   withAnimationDuration:(NSTimeInterval)duration
                animated:(BOOL)animated
              completion:(void (^)(BOOL))completion
{
    if (block)
    {
        if (animated)
        {
            [UIView animateWithDuration:duration animations:block completion:completion];
        }
        else
        {
            block();
            if (completion)
            {
                completion(YES);
            }
        }
    }
}

@end

@implementation KSNTouchyView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchEnded)
    {
        for (UITouch *t in touches)
        {
            self.touchEnded(t, event);
        }
    }
}

@end
