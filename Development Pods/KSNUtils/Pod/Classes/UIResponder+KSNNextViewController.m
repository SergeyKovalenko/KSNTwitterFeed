//
//  UIResponder+KSNNextViewController.m
//
//  Created by Sergey Kovalenko on 11/2/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "UIResponder+KSNNextViewController.h"
#import "KSNGlobalFunctions.h"

@implementation UIResponder (KSNNextViewController)

- (UIViewController *)ksn_nextViewController
{
    id nextResponder = [self nextResponder];
    while (!(KSNSafeCast([UIViewController class], nextResponder) && [[(UIViewController *)nextResponder view] window]) && nextResponder != nil)
    {
        nextResponder = [nextResponder nextResponder];
    }
    return nextResponder;
}


- (UINavigationController *)ksn_nextNavigationViewController
{
    id nextResponder = [self nextResponder];
    while (!KSNSafeCast([UINavigationController class], nextResponder) && nextResponder != nil)
    {
        nextResponder = [nextResponder nextResponder];
    }
    return nextResponder;
}
@end