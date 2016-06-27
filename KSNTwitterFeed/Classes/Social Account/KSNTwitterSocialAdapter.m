//
// Created by Sergey Kovalenko on 6/22/16.
//

#import "KSNTwitterSocialAdapter.h"
#import "KSNGlobalFunctions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@import Accounts;

NSString *const KSNTwitterSocialAdapterName = @"KSNTwitterSocialAdapter";
NSString *const KSNTwitterSocialAdapterErrorDomain = @"KSNTwitterSocialAdapterErrorDomain";

NSString *const KSNTwitterSocialAdapterDidStartUserSessionNotification = @"KSNTwitterSocialAdapterDidStartUserSessionNotification";
NSString *const KSNTwitterSocialAdapterDidEndUserSessionNotification = @"KSNTwitterSocialAdapterDidEndUserSessionNotification";
NSString *const KSNTwitterSocialAdapterSessionNotificationKey = @"KSNTwitterSocialAdapterSessionNotificationKey";

FOUNDATION_STATIC_INLINE NSError *KSNErrorWithCode(KSNTwitterSocialAdapterErrorCode errorCode, NSError *underlyingError)
{
    NSError *(^createErrorBlock)(NSString *, NSInteger, NSError *) = ^(NSString *localizedDescription, NSInteger code, NSError *underlyingError) {
        NSMutableDictionary *mutableUserInfo = [@{NSLocalizedDescriptionKey : localizedDescription} mutableCopy];
        if (underlyingError)
        {
            mutableUserInfo[NSUnderlyingErrorKey] = underlyingError;
        }

        return [NSError errorWithDomain:KSNTwitterSocialAdapterErrorDomain code:code userInfo:mutableUserInfo];
    };
    switch (errorCode)
    {
        case KSNTwitterSocialAdapterUnknownError:
        {
            return createErrorBlock(NSLocalizedString(@"Unknown error occurred", @""), errorCode, underlyingError);
        };
        case KSNTwitterSocialAdapterActiveAccountHasBeenRemoved:
        {
            return createErrorBlock(NSLocalizedString(@"Active twitter account has been removed from iOS settings", @""), errorCode, underlyingError);
        };
        case KSNTwitterSocialAdapterNoRootViewController:
        {
            return createErrorBlock(NSLocalizedString(@"There is no rootViewController for [UIApplication sharedApplication].delegate.window or window is not visible yet", @""), errorCode, underlyingError);
        };
        case KSNTwitterSocialAdapterACAccountAccessDenied:
        {
            return createErrorBlock(NSLocalizedString(@"Access denied for Account Store with type ACAccountTypeIdentifierTwitter, please grant access in Setting->Twitter ", @""), errorCode, underlyingError);
        };
        case KSNTwitterSocialAdapterNoActiveAccountsAvailable:
        {
            return createErrorBlock(NSLocalizedString(@"No accounts found with type ACAccountTypeIdentifierTwitter, please add in Setting->Twitter ", @""), errorCode, underlyingError);
        };
            
    }
}

@interface ACAccountStore (RACSupport)

- (RACSignal *)ksn_requestAccessToAccountWithType:(ACAccountType *)accountType identifier:(NSString *)identifier;
- (RACSignal *)ksn_requestAccessToAccountWithType:(ACAccountType *)accountType;

@end

@implementation ACAccountStore (RACSupport)

- (RACSignal *)ksn_requestAccessToAccountWithType:(ACAccountType *)accountType identifier:(NSString *)identifier
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        @strongify(self);
        RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
            // nothing to cancel :(
        }];

        void (^nextBlock)(void) = ^{
            id next = identifier ? [self accountWithIdentifier:identifier] : [self accountsWithAccountType:accountType];
            [subscriber sendNext:next];
            [subscriber sendCompleted];
        };
        if (accountType.accessGranted)
        {
            nextBlock();
        }
        else
        {
            @weakify(self);
            [self requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
                @strongify(self);
                if (!disposable.isDisposed)
                {
                    if (error)
                    {
                        [subscriber sendError:error];
                    }
                    else
                    {
                        if (granted)
                        {
                            nextBlock();
                        }
                        else
                        {
                            [subscriber sendNext:nil];
                            [subscriber sendCompleted];
                        }
                    }
                }
            }];
        }
        return disposable;
    }];
}

- (RACSignal *)ksn_requestAccessToAccountWithType:(ACAccountType *)accountType
{
    return [self ksn_requestAccessToAccountWithType:accountType identifier:nil];
}

@end

@interface KSNTwitterSocialAdapter ()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSString *accountIdentifier;
@end

@implementation KSNTwitterSocialAdapter

- (instancetype)init
{
    return [self initWithSocialAdapterName:KSNTwitterSocialAdapterName];
}

- (instancetype)initWithSocialAdapterName:(NSString *)socialAdapterName
{
    self = [super initWithSocialAdapterName:socialAdapterName];
    if (self)
    {
        _accountStore = [[ACAccountStore alloc] init];
        [self restoreFromDefaults];
    }

    return self;
}


#pragma mark - Private Methods

- (void)restoreFromDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.accountIdentifier = [userDefaults stringForKey:@keypath(self, accountIdentifier)];
}

- (void)saveDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (self.accountIdentifier)
    {
        [userDefaults setObject:self.accountIdentifier forKey:@keypath(self, accountIdentifier)];
    }
    else
    {
        [userDefaults removeObjectForKey:@keypath(self, accountIdentifier)];
    }
    [userDefaults synchronize];
}

- (void)didStartUserSession:(ACAccount *)session
{
    self.accountIdentifier = session.identifier;
    [self saveDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:KSNTwitterSocialAdapterDidStartUserSessionNotification
                                                        object:self
                                                      userInfo:@{KSNTwitterSocialAdapterSessionNotificationKey : session}];
}

- (void)didEndtUserSession
{
    ACAccount *session = [self userSession];
    self.accountIdentifier = nil;
    [self saveDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:KSNTwitterSocialAdapterDidEndUserSessionNotification
                                                        object:self
                                                      userInfo:@{KSNTwitterSocialAdapterSessionNotificationKey : session}];
}

- (RACSignal *)pickAccountFromArray:(NSArray <ACAccount *> *)array
{
    if (array.count)
    {
        return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
            UIViewController *presentingViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
            if (presentingViewController && presentingViewController.view.window)
            {
                UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select twitter account to login", @"")
                                                                                     message:nil
                                                                              preferredStyle:UIAlertControllerStyleActionSheet];
                for (ACAccount *account in array)
                {
                    [actionSheet addAction:[UIAlertAction actionWithTitle:account.username
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [subscriber sendNext:account];
                                                                      [subscriber sendCompleted];
                                                                  }]];
                }
                [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action) {
                                                                  [subscriber sendCompleted];
                                                              }]];
                [compoundDisposable addDisposable:[RACDisposable disposableWithBlock:^{
                    if (actionSheet.presentingViewController)
                    {
                        [actionSheet dismissViewControllerAnimated:NO completion:nil];
                    }
                }]];
                [presentingViewController presentViewController:actionSheet animated:YES completion:nil];
            }
            else
            {
                [subscriber sendError:KSNErrorWithCode(KSNTwitterSocialAdapterNoRootViewController, nil)];
            }

            return compoundDisposable;
        }];
    }
    else
    {
        return [RACSignal return:nil];
    }
}

#pragma mark - KSNSocialAdapter Overridden Methods

- (RACSignal *)startUserSession
{
    @weakify(self);
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    RACSignal *requestAccessSignal = [[self.accountStore ksn_requestAccessToAccountWithType:accountType
                                                                                 identifier:self.accountIdentifier] deliverOnMainThread];
    RACSignal *startUserSessionSignal = [[[requestAccessSignal catch:^RACSignal *(NSError *error) {
        @strongify(self);
        return [RACSignal error:KSNErrorWithCode(KSNTwitterSocialAdapterUnknownError, error)];
    }] flattenMap:^RACStream *(id value) {
        @strongify(self);
        ACAccountType *grantedAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        if (!grantedAccountType.accessGranted)
        {
            return [RACSignal error:KSNErrorWithCode(KSNTwitterSocialAdapterACAccountAccessDenied, nil)];
        }
        else
        {
            if (self.accountIdentifier && value == nil)
            {
                return [[self endUserSession] flattenMap:^RACStream *(__unused id value) {
                    return [RACSignal error:KSNErrorWithCode(KSNTwitterSocialAdapterActiveAccountHasBeenRemoved, nil)];
                }];
            }
            else
            {
                ACAccount *account = KSNSafeCast([ACAccount class], value);
                if (account)
                {
                    return [RACSignal return:KSNSafeCast([ACAccount class], value)];
                }
                
                NSArray *accounts = KSNSafeCast([NSArray class], value);
                if (accounts.count)
                {
                    return [self pickAccountFromArray:value];
                }
                else
                {
                    return [RACSignal error:KSNErrorWithCode(KSNTwitterSocialAdapterNoActiveAccountsAvailable, nil)];
                }
            }
        }
    }] doNext:^(ACAccount *x) {
        @strongify(self);
        [self didStartUserSession:x];
    }];

    return [startUserSessionSignal replay];
}

- (RACSignal *)endUserSession
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        @strongify(self);
        [self didEndtUserSession];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
        }];
    }];
}

- (id)userSession
{
    return [self activeAccount];
}

- (ACAccount *)activeAccount
{
    return [self.accountStore accountWithIdentifier:self.accountIdentifier];
}

//- (RACSignal *)postMessage:(NSString *)message linkURL:(NSURL *)linkURL mediaURL:(NSURL *)mediaURL
//{
//    return [super postMessage:message linkURL:linkURL mediaURL:mediaURL];
//}

@end