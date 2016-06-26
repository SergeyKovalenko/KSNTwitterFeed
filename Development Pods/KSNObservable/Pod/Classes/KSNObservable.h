//
// Created by Sergey Kovalenko on 10/31/14.
// Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KSNObservable <NSObject>

- (void)addListener:(id)listener;
- (void)removeListener:(id)listener;
- (void)removeAllListeners;

@end

// All listeners should implement observableProtocol
@interface KSNObservable : NSProxy <KSNObservable>

- (instancetype)initWithProtocol:(Protocol *)observableProtocol;
@property (nonatomic, assign) BOOL showDebugLogs;
@property (nonatomic, strong) dispatch_queue_t notificationQueue;
@end

@interface KSNDelegate : KSNObservable

- (instancetype)initWithProtocol:(Protocol *)observableProtocol delegate:(id)delegate;

@end