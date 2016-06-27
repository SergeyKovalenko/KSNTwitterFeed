//
// Created by Sergey Kovalenko on 6/22/16.
//

#import <Foundation/Foundation.h>
#import "KSNSocialAdapter.h"

FOUNDATION_EXPORT NSString *const KSNTwitterSocialAdapterName;
FOUNDATION_EXPORT NSString *const KSNTwitterSocialAdapterErrorDomain;

FOUNDATION_EXPORT NSString *const KSNTwitterSocialAdapterDidStartUserSessionNotification;
FOUNDATION_EXPORT NSString *const KSNTwitterSocialAdapterDidEndUserSessionNotification;
FOUNDATION_EXPORT NSString *const KSNTwitterSocialAdapterSessionNotificationKey;

typedef NS_ENUM(NSUInteger, KSNTwitterSocialAdapterErrorCode)
{
    KSNTwitterSocialAdapterUnknownError,
    KSNTwitterSocialAdapterActiveAccountHasBeenRemoved,
    KSNTwitterSocialAdapterACAccountAccessDenied,
    KSNTwitterSocialAdapterNoRootViewController,
    KSNTwitterSocialAdapterNoActiveAccountsAvailable
};

@class ACAccount;

@interface KSNTwitterSocialAdapter : KSNSocialAdapter

- (ACAccount *)activeAccount;

@end