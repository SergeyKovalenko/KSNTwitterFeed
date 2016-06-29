//
//  KSNRefreshingView.h
//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

@protocol KSNRefreshingView <NSObject>
- (void)setRefreshOffsetReached:(BOOL)reached;
- (void)setRefreshing:(BOOL)refreshing;

@optional
@property (nonatomic, readonly) CGFloat refreshOffset;
- (void)setAmountPass:(CGFloat)amountPass;

@end