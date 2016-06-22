//
//  NSObject+KSNModal.h
//
//  Created by Sergey Kovalenko on 2/3/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KSNVoidBlock)(void);

@interface NSObject (KSNModal)

/*!
 * @method: ksn_showModalViewController:animated:
 * @abstract: Present the given view controller modally with animation
 */
- (void)ksn_showModalViewController:(UIViewController *)vc;

- (void)ksn_showViewController:(UIViewController *)vc asPopoverWithConfigurationBlock:(void(^)(UIPopoverPresentationController *))popoverConfigurationBlock;

/*!
 * @method: ksn_showModalViewController:animated:
 * @abstract: Present the given view controller modally (optionally animated)
 */
- (void)ksn_showModalViewController:(UIViewController *)vc animated:(BOOL)animated;

/*!
 * @method: ksn_showModalViewController:animated:
 * @abstract: Present the given view controller modally (optionally animated)
 */
- (void)ksn_showModalViewController:(UIViewController *)vc animated:(BOOL)animated completion:(KSNVoidBlock)completion;

/*!
 * @method: ksn_dismissModalViewControllerAnimated:
 * @abstract: Dismisses the topmost modally presented view with animation
 */
- (void)ksn_dismissModalViewController;

/*!
 * @method: ksn_dismissModalViewControllerAnimated:
 * @abstract: Dismisses the topmost modally presented view (optionally animated)
 */
- (void)ksn_dismissModalViewControllerAnimated:(BOOL)animated;

/*!
 * @method: ksn_dismissModalViewControllerAnimated:
 * @abstract: Dismisses the topmost modally presented view (optionally animated)
 */
- (void)ksn_dismissModalViewControllerAnimated:(BOOL)animated completion:(KSNVoidBlock)completion;

/*!
 * @method: ksn_dismissModalViewControllerViewController:animated:completion:
 * @abstract: Dismisses modall presented view controller (optionally animated) with competion block
 */
- (void)ksn_dismissModalViewControllerViewController:(UIViewController *)vc animated:(BOOL)animated completion:(KSNVoidBlock)completion;

/*!
 * @method: ksn_dismissAllAnimated:
 * @abstract: Dismisses all modally presented views (optionally animated)
 */
- (void)ksn_dismissAllAnimated:(BOOL)animated;

- (void)ksn_dismissAllAnimated:(BOOL)animated completion:(void (^)(void))completion;

/*!
 * @method: topViewController
 * @abstract: Returns the top-most presented view controller
 */
- (UIViewController *)ksn_topViewController;
@end
