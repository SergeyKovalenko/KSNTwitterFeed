//
//  KSNAppDelegate.h
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

@import UIKit;
@class KSNErrorHandler;
@class KSNTwitterAPI;

@interface KSNAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) KSNErrorHandler *errorHandler;
@end
