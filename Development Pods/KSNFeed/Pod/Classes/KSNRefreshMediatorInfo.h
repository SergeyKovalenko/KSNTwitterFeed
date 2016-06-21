//
//  KSNRefreshMediatorInfo.h
//
//  Created by Sergey Kovalenko on 10/21/15.
//  Copyright © 2015. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNRefreshingView.h"

typedef NS_ENUM(NSUInteger, KSNRefreshViewPosition)
{
    KSNRefreshViewPositionTop,
    KSNRefreshViewPositionLeft,
    KSNRefreshViewPositionBottom,
    KSNRefreshViewPositionRight
};

FOUNDATION_STATIC_INLINE BOOL KSNRefreshViewPositionHorizontal(KSNRefreshViewPosition position)
{
    return position == KSNRefreshViewPositionTop || position == KSNRefreshViewPositionBottom;
}

FOUNDATION_STATIC_INLINE BOOL KSNRefreshViewPositionVertical(KSNRefreshViewPosition position)
{
    return position == KSNRefreshViewPositionLeft || position == KSNRefreshViewPositionRight;
}

@interface KSNRefreshMediatorInfo : NSObject

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position;

@property (nonatomic, readonly) KSNRefreshViewPosition position;

@property (nonatomic, copy) void (^refreshedBlock)(KSNRefreshMediatorInfo *info);

@property (nonatomic, weak) UIView <KSNRefreshingView> *refreshView;
@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, assign, readonly) CGFloat refreshOffset;
@property (nonatomic, assign) UIEdgeInsets baseInsets;
@property (nonatomic, assign) CGFloat amountPass;
@property (nonatomic, assign) CGPoint remainOffset; // refreshing will be triggered when the scroll's content offset reach this point. CGPoitZero by default.

@property (nonatomic, assign, getter = isRefreshEnabled) BOOL refreshEnabled;

@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated;

@property (nonatomic, assign, getter = isOffsetReached) BOOL offsetReached;

- (void)scrollViewDidScroll;
- (void)scrollViewDidEndDragging;
- (void)scrollViewContentInsetsChanged;

@end
