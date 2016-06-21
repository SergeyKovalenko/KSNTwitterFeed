//
//  KSNNetworkAPIEndPoint.h
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const KSNNetworkAPIEndPointDidChangeNotification;
FOUNDATION_EXTERN NSString *const KSNNetworkAPIEndPointKey;

@interface KSNNetworkAPIEndPoint : NSObject

// Base url
@property (nonatomic, strong, readonly) NSString *baseURL;
// Display value
@property (nonatomic, strong, readonly) NSString *name;
// Initializer
+ (instancetype)addApiEndPointWithName:(NSString *)name baseURL:(NSString *)baseURL;
// All available end points
+ (NSArray *)availableEndPoints;

+ (void)registerEndPoints:(NSArray *)endPoints;
// Currently active end point
+ (instancetype)activeEndPoint;
// Set active end point
+ (void)setActiveEndPoint:(KSNNetworkAPIEndPoint *)endPoint;

+ (instancetype)defaultEndPoint;

+ (void)setDefaultEndPoint:(KSNNetworkAPIEndPoint *)endPoint;

@end

