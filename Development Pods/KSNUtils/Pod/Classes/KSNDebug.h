//
//  KSNDebug.h
//
//  Created by Sergey Kovalenko on 4/16/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KSN_REQUIRE_OVERRIDE NSAssert(NO, @"Override %2$@ in %1$@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd))

@interface KSNDebug : NSObject

+ (void)assert:(BOOL)condition message:(NSString *)message;
- (void)doAssert:(BOOL)condition message:(NSString *)message;

@end

static inline void KSNAssertHelper1(BOOL condition, NSString *message)
{
    [KSNDebug assert:condition message:message];
}

static inline void KSNAssertHelper2(BOOL condition, const char *message)
{
    NSString *newMessage = [NSString stringWithUTF8String:message];
    KSNAssertHelper1(condition, newMessage);
}

FOUNDATION_EXPORT void KSN_ASSERT(BOOL condition);
FOUNDATION_EXPORT void KSN_ASSERT_MSG(BOOL condition, NSString *message);

// Breaks the debugger if the condition is not met
FOUNDATION_EXPORT void KSN_VERIFY(BOOL condition, NSString *message);

#if !defined(KSNASSERT)
#define KSNASSERT(condition) KSN_ASSERT(!!(condition))
#define KSNASSERTMSG(condition, desc) KSN_ASSERT_MSG(!!(condition), (desc))
#define KSNVERIFY(condition, desc) KSN_VERIFY(!!(condition), (desc))
#endif
