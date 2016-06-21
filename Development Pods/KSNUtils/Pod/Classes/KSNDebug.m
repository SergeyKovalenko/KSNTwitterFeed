//
//  KSNDebug.m
//
//  Created by Sergey Kovalenko on 4/16/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNDebug.h"
#import "KSNGlobalFunctions.h"

#ifdef DEBUG

#include <assert.h>
#include <sys/sysctl.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT BOOL AmIBeingDebugged(void)
// Returns true if the current process is being debugged (either 
// running under the debugger or has a debugger attached post facto).
{
    int junk;
    int mib[4];
    struct kinfo_proc info;
    size_t size;

    // Initialize the flags so that, if sysctl fails for some bizarre 
    // reason, we get a predictable result.

    info.kp_proc.p_flag = 0;

    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();

    // Call sysctl.

    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);

    // We're being debugged if the P_TRACED flag is set.

    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

#endif

@interface KSNDebug ()

- (void)showAlert:(NSString *)message;
- (void)breakIntoDebugger;
@end

@implementation KSNDebug

- (void)doAssert:(BOOL)condition message:(NSString *)message
{
#if DEBUG
    if (!condition)
    {
        if (AmIBeingDebugged())
        {
            [self showAlert:[NSString stringWithFormat:@"%@ - Debugger is breaking in!", message]];
            [self breakIntoDebugger];
        }
        else
        {
            [self showAlert:message];
        }
    }
#endif
}

- (void)breakIntoDebugger
{
    kill(getpid(), SIGINT);
}

- (void)showAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Assertion Failed"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    [alert show];
}

+ (void)assert:(BOOL)condition message:(NSString *)message
{
    static KSNDebug *instance;
    if (instance == nil)
    {
        instance = [[KSNDebug alloc] init];
    }
    [instance doAssert:condition message:message];
}

@end

void KSN_ASSERT(BOOL condition)
{
    do
    {
        if (!(condition))
        {
            LOGERROR(@"%s %d %s %s", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
            LOGERROR(@"Assert callstack: %@", (NSArray *) [NSThread callStackSymbols]);
#ifdef DEBUG
            KSNAssertHelper1((condition), @"");
#endif
        }
    } while (0);
}

void KSN_ASSERT_MSG(BOOL condition, NSString *message)
{
    do
    {
        if (!(condition))
        {
            LOGERROR(@"%s %d %s %s", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
            LOGERROR(@"Assert callstack: %@", (NSArray *) [NSThread callStackSymbols]);
#ifdef DEBUG
            KSNAssertHelper1((condition), message);
#endif
        }
    } while (0);
}

void KSN_VERIFY(BOOL condition, NSString *message)
{
#ifdef DEBUG
    if (AmIBeingDebugged() && !(condition))
    {
        kill(getpid(), SIGINT);
    }
#endif
}
