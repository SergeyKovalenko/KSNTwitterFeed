//
//  KSNRefreshMediator.h
//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNRefreshMediatorInfo.h"

@class KSNRefreshMediator;

@protocol KSNRefreshMediatorDelegate <NSObject>

- (void)refreshMediator:(KSNRefreshMediator *)mediator didTriggerUpdateAtPossition:(KSNRefreshMediatorInfo *)position;

@end

@interface KSNRefreshMediator : NSObject

- (instancetype)initWithRefreshInfo:(NSArray *)refreshInfo;

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, weak) id <KSNRefreshMediatorDelegate> delegate;

- (void)scrollViewContentInsetsChanged;

- (void)scrollViewDidScroll;

- (void)scrollViewDidEndDragging;

@end
