//
//  KSNGlobalFunctions.h
//  Pods
//
//  Created by Sergey Kovalenko on 2/5/16.
//
//
#import <Foundation/Foundation.h>

#ifndef KSNGlobalFunctions_h
#define KSNGlobalFunctions_h

FOUNDATION_STATIC_INLINE id KSNSafeProtocolCast(Protocol *protocol, id obj)
{
    return [[obj class] conformsToProtocol:protocol] ? obj : nil;
}

FOUNDATION_STATIC_INLINE id KSNSafeCast(Class klass, id obj)
{
    return [obj isKindOfClass:klass] ? obj : nil;
}

FOUNDATION_STATIC_INLINE BOOL KSNObjectEqualToObject(id o1, id o2)
{
    return (o1 == o2) || [o1 isEqual:o2];
}

#define KSN_SYSTEM_VERSION_EQUAL_TO(v)                  ([KSN_SystemVersion() compare:v options:NSNumericSearch] == NSOrderedSame)
#define KSN_SYSTEM_VERSION_GREATER_THAN(v)              ([KSN_SystemVersion() compare:v options:NSNumericSearch] == NSOrderedDescending)
#define KSN_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([KSN_SystemVersion() compare:v options:NSNumericSearch] != NSOrderedAscending)
#define KSN_SYSTEM_VERSION_LESS_THAN(v)                 ([KSN_SystemVersion() compare:v options:NSNumericSearch] == NSOrderedAscending)
#define KSN_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([KSN_SystemVersion() compare:v options:NSNumericSearch] != NSOrderedDescending)


// Memoize expensive API
FOUNDATION_STATIC_INLINE NSString * KSN_SystemVersion(void)
{
    static NSString *KSNSystemVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KSNSystemVersion = [[UIDevice currentDevice] systemVersion];
    });
    return KSNSystemVersion;
}

#define isIPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define isIPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#ifndef LOGERROR
#ifdef DEBUG
#define LOGERROR(__FORMAT__, ...) NSLog((@"ERROR %s line %d $ " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define LOGERROR(__FORMAT__, ...)
#endif
#endif /* KSNGlobalFunctions_h */

#ifndef LOG
#ifdef DEBUG
#define LOG(__FORMAT__, ...) NSLog((@"%s line %d $ " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define LOG(__FORMAT__, ...)
#endif
#endif /* KSNGlobalFunctions_h */

#endif /* KSNGlobalFunctions_h */
