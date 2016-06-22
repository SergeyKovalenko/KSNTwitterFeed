//
// Created by Sergey Kovalenko on 6/2/16.
// Copyright (c) 2016 Smart Solutions GmbH. All rights reserved.
//

#import "UIAlertController+WMLShortcut.h"

@implementation UIAlertController (WMLShortcut)

+ (instancetype)ksn_showWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"common.ok", @"") style:UIAlertActionStyleCancel handler:nil]];

    [self ksn_showModalViewController:alertController];
    return alertController;
}

@end