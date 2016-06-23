//
//  KSNAppDelegate.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <KSNTwitterFeed/KSNTwitterSocialAdapter.h>
#import <KSNErrorHandler/KSNErrorHandler.h>
#import <MagicalRecord/MagicalRecord.h>
#import "UIAlertController+WMLShortcut.h"
#import "KSNRootViewController.h"
#import "KSNRootViewModel.h"

@interface KSNAppDelegate ()

@property (nonatomic, strong) KSNTwitterSocialAdapter *twitterSocialAdapter;
@property (nonatomic, strong, readwrite) KSNErrorHandler *errorHandler;
@end

@implementation KSNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self installDefaultErrorHandlers];
    [self setupPersistentStore];

    self.twitterSocialAdapter = [[KSNTwitterSocialAdapter alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [self createRootControllerWithTwitterSocialAdapter:self.twitterSocialAdapter];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)setupPersistentStore
{
    NSURL *storeURL = [NSPersistentStore MR_defaultLocalStoreUrl];
    [MagicalRecord setupCoreDataStackWithStoreAtURL:storeURL];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // No need to unsubscribe
    [center addObserverForName:KSNTwitterSocialAdapterDidEndUserSessionNotification
                        object:self.twitterSocialAdapter
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *__nonnull note) {
                        // Remove all user data
                        NSURL *dbURL = storeURL;
                        [MagicalRecord cleanUp];
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSError *cleanUpError;
                        // Let's remove whole folder since multiple files can be created
                        NSURL *url = [dbURL URLByDeletingLastPathComponent];
                        if (![fileManager removeItemAtURL:url error:&cleanUpError])
                        {
                            LOG_ERROR(@"Clean up DB Error: %@", cleanUpError);
                        }
                        // Setup Core Data Stack just to be ready for the next user session
                        [MagicalRecord setupCoreDataStackWithStoreAtURL:storeURL];
                    }];
}

- (UIViewController *)createRootControllerWithTwitterSocialAdapter:(KSNTwitterSocialAdapter *)twitterSocialAdapter
{
    KSNRootViewModel *viewModel = [[KSNRootViewModel alloc] initWithTwitterSocialAdapter:twitterSocialAdapter];
    KSNRootViewController *rootViewController = [[KSNRootViewController alloc] initWithViewModel:viewModel];
    return rootViewController;
}

- (void)installDefaultErrorHandlers
{
    self.errorHandler = [[KSNErrorHandler alloc] init];

    // Network error handler
    self.errorHandler.networkErrorHandler = ^(NSError *error) {
        NSString *title = NSLocalizedString(@"common.applicationNetworkErrorHandler.title", nil);
        NSString *message = NSLocalizedString(@"common.applicationNetworkErrorHandler.message", nil);
        [UIAlertController ksn_showWithTitle:title message:message];
        return YES;
    };

    self.errorHandler.defaultErrorHandler = ^(NSError *error) {
        // Send errors to Crashlytics


        NSString *title = NSLocalizedString(@"common.applicationDefaultErrorHandler.title", nil);

        NSString *localizedDescription = [error localizedDescription];
        if ([localizedDescription length] == 0)
        {
            localizedDescription = @"";
        }
#ifdef DEBUG
        NSString *messageFormat = NSLocalizedString(@"%@\n[%@, %d]", nil);
        NSString *message = [NSString stringWithFormat:messageFormat, localizedDescription, error.domain, error.code];
#else
        NSString * message = localizedDescription;
#endif
        [UIAlertController ksn_showWithTitle:title message:message];
        LOG_ERROR(@"Default Error Handler: %@", error);
        return YES;
    };
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [MagicalRecord cleanUp];
}

@end
