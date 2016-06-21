//
//  KSNLoadingIndicator.h
//
//  Created by Sergey Kovalenko on 1/12/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSNLoadingIndicator : UIView

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat progress;

- (void)fakeProgressWithDuration:(NSTimeInterval)timeInterval;
- (void)finish;

@end
