//
//  KSNInfoStatusView.h
//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSNInfoStatusView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) UIButton *refreshButton;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil;

@end
