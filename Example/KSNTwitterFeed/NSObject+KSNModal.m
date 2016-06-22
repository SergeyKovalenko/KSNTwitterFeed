//
//  NSObject+KSNModal.m
//
//  Created by Sergey Kovalenko on 2/3/16.
//  Copyright © 2016. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSMutableArray+NTFQueueAdditions.h"
#import "NSObject+KSNModal.h"

@interface UIViewController (KSNSwizzledMethods)

- (void)ksn_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^ __nullable)(void))completion;
- (void)ksn_dismissViewControllerAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion;

@end

@implementation UIViewController (KSNSwizzledMethods)

#pragma mark - UIViewController's original implementation of display & dismiss methods

- (void)ksn_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^ __nullable)(void))completion
{
    BOOL keyWindowTransition = [[self view] window] == [[[UIApplication sharedApplication] delegate] window];

    if (!keyWindowTransition)
    {
        [self ksn_presentViewController:viewControllerToPresent animated:flag completion:completion];
    }
    else
    {
        [self ksn_showModalViewController:viewControllerToPresent animated:flag completion:completion];
    }
}

- (void)ksn_dismissViewControllerAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion
{
    UIWindow *applicationWindow = [[[UIApplication sharedApplication] delegate] window];
    BOOL keyWindowTransition = [[self view] window] == applicationWindow || self.presentedViewController.view.window == applicationWindow;

    if (!keyWindowTransition)
    {
        [self ksn_dismissViewControllerAnimated:flag completion:completion];
    }
    else
    {
        [self ksn_dismissModalViewControllerViewController:self animated:flag completion:completion];
    }
}

@end

@implementation NSObject (KSNModal)

static BOOL kIsAnimatingModalViewController;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
// Let's use single way to present modal controllers
        BOOL success = [UIViewController jr_swizzleMethod:@selector(presentViewController:animated:completion:)
                                               withMethod:@selector(ksn_presentViewController:animated:completion:)
                                                    error:&error];
        if (!success)
        {
            NSLog(@"UIViewController presentViewController:animated:completion: swizzle error %@", error);
            return;
        }

        success = [UIViewController jr_swizzleMethod:@selector(dismissViewControllerAnimated:completion:)
                                          withMethod:@selector(ksn_dismissViewControllerAnimated:completion:)
                                               error:&error];
        if (!success)
        {
            NSLog(@"UIViewController dismissViewControllerAnimated:completion:swizzle error %@", error);
            NSLog(@"Restore presentViewController:animated:completion: swizzle");
            if (![UIViewController jr_swizzleMethod:@selector(ksn_presentViewController:animated:completion:)
                                         withMethod:@selector(presentViewController:animated:completion:)
                                              error:&error])
            {
                NSLog(@"Restore UIViewController presentViewController:animated:completion: swizzle error %@", error);
            };
        }
    });
}

- (NSMutableArray *)modalActionQueue
{
    static dispatch_once_t onceToken;
    static NSMutableArray *kModalActionQueue;

    dispatch_once(&onceToken, ^{
        kModalActionQueue = [NSMutableArray array];
    });

    return kModalActionQueue;
}

+ (BOOL)isAnimatingModal
{
    NSAssert([NSThread isMainThread], @"This method is not thread safe.");
    return kIsAnimatingModalViewController;
}

+ (void)setIsAnimatingModal:(BOOL)isAnimating
{
    NSAssert([NSThread isMainThread], @"This method is not thread safe.");
    kIsAnimatingModalViewController = isAnimating;
}

- (void)ksn_showModalViewController:(UIViewController *)vc
{
    [self ksn_showModalViewController:vc animated:YES];
}

- (void)ksn_showViewController:(UIViewController *)vc asPopoverWithConfigurationBlock:(void (^)(UIPopoverPresentationController *))popoverConfigurationBlock
{
    // Present the view controller using the popover style.
    vc.modalPresentationStyle = UIModalPresentationPopover;

    [self ksn_showModalViewController:vc];

    // Get the popover presentation controller and configure it.
    if (popoverConfigurationBlock)
    {
        popoverConfigurationBlock([vc popoverPresentationController]);
    }
}

- (void)ksn_showModalViewController:(UIViewController *)vc animated:(BOOL)animated
{
    [self ksn_showModalViewController:vc animated:animated completion:NULL];
}

- (void)ksn_showModalViewController:(UIViewController *)vc animated:(BOOL)animated completion:(KSNVoidBlock)completion
{
    NSParameterAssert(vc);
    UIViewController *topViewController = [self ksn_topViewController];

    if (![[self class] isAnimatingModal] && !topViewController.isBeingPresented && !topViewController.isBeingDismissed)
    {
        [[self class] setIsAnimatingModal:YES];
        LOG(@"%@ is presenting controller %@", self, vc);

        NSAssert(topViewController != vc, @"Presenting same VC modally?");
        // http://stackoverflow.com/questions/24854802/presenting-a-view-controller-modally-from-an-action-sheets-delegate-in-ios8
//        dispatch_async(dispatch_get_main_queue(), ^ {
        __block BOOL comleted = NO;
        @weakify(self);
        @weakify(vc);
        void(^completionInternal)() = ^{
            @strongify(self);
            @strongify(vc);
            if (!comleted)
            {
                [[self class] setIsAnimatingModal:NO];
                LOG(@"%@ presented controller %@", self, vc);

                if (completion)
                {
                    completion();
                }
                [self ksn_asyncDispatchDequeueActionQueue];
            }
            comleted = YES;
        };

        [topViewController ksn_presentViewController:vc animated:animated completion:completionInternal];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            @strongify(vc);

            if (!comleted)
            {
                LOG(@"%@ presenting delayed callback for %@", self, vc);
                completionInternal();
            }
        });
//        });
    }
//    else  
    else
    {
        LOG(@"***ERROR*** Enqueing modal view controller presentation for %@ from stack %@", vc, [NSThread callStackSymbols]);
        [self ksn_enqueueActionShowModalViewController:vc animated:animated completion:completion];
    }
}

- (void)ksn_dismissModalViewController
{
    [self ksn_dismissModalViewControllerAnimated:YES];
}

- (void)ksn_dismissModalViewControllerAnimated:(BOOL)animated
{
    [self ksn_dismissModalViewControllerAnimated:animated completion:NULL];
}

- (void)ksn_dismissModalViewControllerAnimated:(BOOL)animated completion:(KSNVoidBlock)completion
{
    UIViewController *topViewController = [self ksn_topViewController];
    [self ksn_dismissModalViewControllerViewController:topViewController animated:animated completion:completion];
}

- (void)ksn_dismissModalViewControllerViewController:(UIViewController *)vc animated:(BOOL)animated completion:(KSNVoidBlock)completion;
{
    if ((vc.presentingViewController != nil || vc.presentedViewController != nil) && ![vc isBeingDismissed])
    {
        if (![[self class] isAnimatingModal])
        {
            [[self class] setIsAnimatingModal:YES];
            LOG(@"%@ is hidding controller %@", self, vc);

            // Calling dismiss on the topmost view controller will automatically forward
            // the request to its presenting view controller
            __block BOOL comleted = NO;
            @weakify(self);
            @weakify(vc);
            void(^completionInternal)() = ^{
                @strongify(self);
                @strongify(vc);
                if (!comleted)
                {
                    [[self class] setIsAnimatingModal:NO];
                    LOG(@"%@ hidden controller %@", self, vc);
                    if (completion)
                    {
                        completion();
                    }
                    [self ksn_asyncDispatchDequeueActionQueue];
                }
                comleted = YES;
            };

            [vc ksn_dismissViewControllerAnimated:animated completion:completionInternal];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!comleted)
                {
                    LOG(@"%@ hidding delayed callback for %@", self, vc);
                    completionInternal();
                }
            });
        }
        else
        {
            LOG(@"***ERROR*** Enqueing modal view controller %@ dismissal (presentingViewController == %@, isBeingDismissed %@) from stack %@", vc, vc.presentingViewController, @([vc isBeingDismissed]), [NSThread callStackSymbols]);
            [self ksn_enqueueActionDismissModalViewControllerAnimated:animated completion:completion];
        }
    }
    else
    {
        LOG(@"Won't hide %@ (presentingViewController == %@, \
            presentedViewController == %@, \
            isBeingDismissed %@, \
            transitionCoordinator %@)", vc, vc.presentingViewController, vc.presentedViewController, @([vc isBeingDismissed]), vc.transitionCoordinator);

        @weakify(self);
        void(^completionInternal)(void) = ^{
            @strongify(self);
            if (completion)
            {
                completion();
            }
            [self ksn_asyncDispatchDequeueActionQueue];
        };

        if (vc.transitionCoordinator)
        {
            BOOL queued = [vc.transitionCoordinator animateAlongsideTransition:nil
                                                                    completion:^(id <UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                                                                        completionInternal();
                                                                    }];
            if (!queued)
            {
                completionInternal();
            }
        }
    }
}

- (void)ksn_dismissAllAnimated:(BOOL)animated
{
    [self ksn_dismissAllAnimated:animated completion:NULL];
}

- (void)ksn_dismissAllAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIViewController *rootController = self.ntf_rootViewController;
    BOOL hasPresentedController = rootController.presentedViewController != nil;
    [rootController ksn_dismissViewControllerAnimated:animated completion:completion];
    if (!hasPresentedController && completion)
    {
        completion();
    }
}

#pragma mark - Private methods

/*!
 * @method: topViewController
 * @abstract: Returns the top-most presented view controller
 */
- (UIViewController *)ksn_topViewController
{
    UIViewController *topController = self.ntf_rootViewController;
    while (topController.presentedViewController && (KSN_SYSTEM_VERSION_LESS_THAN(@"8.0") || ![topController.presentedViewController.presentationController isKindOfClass:[UIPopoverPresentationController class]]))
    {
        topController = topController.presentedViewController;
    }
    NSAssert(topController != nil, @"Top view controller cannot be nil");
    return topController;
}

/*!
 * @method: ksn_rootViewController
 * @abstract: Helper to get the key window's root view controller
 * @return: The root view controller of the key window
 */
- (UIViewController *)ntf_rootViewController
{
    UIViewController *vc = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    NSAssert(vc != nil, @"Root view controller cannot be nil");
    return vc;
}

#pragma mark - Queuing

- (void)ksn_enqueueActionShowModalViewController:(UIViewController *)vc animated:(BOOL)animated completion:(KSNVoidBlock)completion
{
    NSAssert([NSThread isMainThread], @"This method is not thread safe.");
    @weakify(self);
    KSNVoidBlock action = ^{
        @strongify(self);
        [self ksn_showModalViewController:vc animated:animated completion:completion];
    };
    [self.modalActionQueue addObject:action];
}

- (void)ksn_enqueueActionDismissModalViewControllerAnimated:(BOOL)animated completion:(KSNVoidBlock)completion
{
    NSAssert([NSThread isMainThread], @"This method is not thread safe.");
    @weakify(self);
    KSNVoidBlock action = ^{
        @strongify(self);
        LOG(@"Enqueue action for %@", self);
        [self ksn_dismissModalViewControllerAnimated:animated completion:completion];
    };
    [self.modalActionQueue ntf_enqueue:action];
}

- (void)ksn_asyncDispatchDequeueActionQueue
{
    NSAssert([NSThread isMainThread], @"This method is not thread safe.");
    // Asynchronously dispatch since we get called from the completion block of another
    // presentation/dismissal. The completion block may have enqueue another modal action.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[self class] isAnimatingModal])
        {
            KSNVoidBlock block = [self.modalActionQueue ntf_dequeue];
            if (block)
            {
                // We're safe to execute the action now. We dispatch it async again because
                // We want to be done with using the kModalActionQueue. The block may actually
                // get enqueue again...
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                });
            }
        }
    });
}
@end
