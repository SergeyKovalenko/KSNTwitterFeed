//
//  KSNNetworkAPIEndPoint.m
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.

#import "KSNNetworkAPIEndPoint.h"

NSString *const KSNNetworkAPIEndPointDidChangeNotification = @"KSNNetworkAPIEndPointDidChangeNotification";
NSString *const KSNNetworkAPIEndPointKey = @"KSNNetworkAPIEndPointKey";

static NSString *const KSNDefaultEndPointKey = @"KSNDefaultEndPointKey";

@interface KSNNetworkAPIEndPoint ()

@property (nonatomic, strong, readwrite) NSString *baseURL;
@property (nonatomic, strong, readwrite) NSString *name;

@end

@implementation KSNNetworkAPIEndPoint

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *_Nonnull note) {
                                                      NSString *archivedBaseUrl = [[NSUserDefaults standardUserDefaults] stringForKey:KSNNetworkAPIEndPointKey];
                                                      KSNNetworkAPIEndPoint *activeEndPoint = [self endPointsMap][KSNNetworkAPIEndPointKey];

                                                      if (archivedBaseUrl != activeEndPoint.baseURL && ![archivedBaseUrl isEqualToString:[activeEndPoint baseURL]])
                                                      {
                                                          KSNNetworkAPIEndPoint *newActiveEndPoint;
                                                          for (KSNNetworkAPIEndPoint *endPoint in [self availableEndPoints])
                                                          {
                                                              if ([endPoint.baseURL isEqualToString:archivedBaseUrl])
                                                              {
                                                                  newActiveEndPoint = endPoint;
                                                                  break;
                                                              }
                                                          }
                                                          if (!newActiveEndPoint)
                                                          {
                                                              newActiveEndPoint = [[KSNNetworkAPIEndPoint alloc] init];
                                                              newActiveEndPoint.name = KSNNetworkAPIEndPointKey;
                                                              newActiveEndPoint.baseURL = archivedBaseUrl;
                                                          }
                                                          [self setActiveEndPoint:newActiveEndPoint];
                                                      }
                                                  }];
}

+ (instancetype)addApiEndPointWithName:(NSString *)name baseURL:(NSString *)baseURL
{
    KSNNetworkAPIEndPoint *endPoint = [[KSNNetworkAPIEndPoint alloc] init];
    endPoint.name = name;
    endPoint.baseURL = baseURL;
    [self registerEndPoints:@[endPoint]];
    return endPoint;
}

+ (NSMutableDictionary *)endPointsMap
{
    static NSMutableDictionary *endPointsMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        endPointsMap = [[NSMutableDictionary alloc] init];
    });
    return endPointsMap;
}

+ (void)registerEndPoints:(NSArray *)endPoints
{
    for (KSNNetworkAPIEndPoint *endPoint in endPoints)
    {
        [self endPointsMap][endPoint.name] = endPoint;
    }
}

+ (instancetype)defaultEndPoint
{
    KSNNetworkAPIEndPoint *endPoint = [self endPointsMap][KSNDefaultEndPointKey];
    if (!endPoint)
    {
        NSString *baseURL = [[NSUserDefaults standardUserDefaults] objectForKey:KSNDefaultEndPointKey];
        if (baseURL)
        {
            endPoint = [[KSNNetworkAPIEndPoint alloc] init];
            endPoint.name = KSNDefaultEndPointKey;
            endPoint.baseURL = baseURL;
        }
    }
    return endPoint;
}

+ (void)setDefaultEndPoint:(KSNNetworkAPIEndPoint *)endPoint
{
    [self endPointsMap][KSNDefaultEndPointKey] = endPoint;
    [[NSUserDefaults standardUserDefaults] setObject:endPoint.baseURL forKey:KSNDefaultEndPointKey];
}

+ (NSArray *)availableEndPoints
{
    return [[self endPointsMap] allValues];
}

+ (instancetype)activeEndPoint
{
    KSNNetworkAPIEndPoint *activeEndPoint = [self endPointsMap][KSNNetworkAPIEndPointKey];

    if (!activeEndPoint)
    {
        NSString *archivedBaseUrl = [[NSUserDefaults standardUserDefaults] stringForKey:KSNNetworkAPIEndPointKey];
        if (archivedBaseUrl.length > 0)
        {
            for (KSNNetworkAPIEndPoint *endPoint in [self availableEndPoints])
            {
                if ([endPoint.baseURL isEqualToString:archivedBaseUrl])
                {
                    activeEndPoint = endPoint;
                    break;
                }
            }
        }
        else
        {
            activeEndPoint = [self defaultEndPoint];
        }
    }

    return activeEndPoint;
}

+ (void)setActiveEndPoint:(KSNNetworkAPIEndPoint *)endPoint
{
    KSNNetworkAPIEndPoint *activeEndPoint = [self endPointsMap][KSNNetworkAPIEndPointKey];

    if (![activeEndPoint isEqual:endPoint])
    {
        [self endPointsMap][KSNNetworkAPIEndPointKey] = endPoint;

        NSString *archivedBaseUrl = [[NSUserDefaults standardUserDefaults] stringForKey:KSNNetworkAPIEndPointKey];
        if (![endPoint.baseURL isEqualToString:archivedBaseUrl])
        {
            [[NSUserDefaults standardUserDefaults] setObject:endPoint.baseURL forKey:KSNNetworkAPIEndPointKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:KSNNetworkAPIEndPointDidChangeNotification
                                                            object:nil
                                                          userInfo:@{KSNNetworkAPIEndPointKey : endPoint}];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, key: %@, baseURL: %@>",
                                      NSStringFromClass([self class]),
                                      (__bridge void *) self,
                                      self.name,
                                      self.baseURL];
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]])
    {
        return NO;
    }
    KSNNetworkAPIEndPoint *otherEndPoint = other;

    return [self.baseURL isEqualToString:otherEndPoint.baseURL];
}

- (NSUInteger)hash
{
    return [self.baseURL hash];
}

@end
