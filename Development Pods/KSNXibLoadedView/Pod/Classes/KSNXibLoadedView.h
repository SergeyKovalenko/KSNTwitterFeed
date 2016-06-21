//
//  KSNXibLoadedView.h
//
//  Created by Sergey Kovalenko on 2/19/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSNXibLoadedView : UIView

- (instancetype)initWithNibName:(NSString *)nibNameOrNil;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundle;

@property (nonatomic, copy, readonly) NSString *nibName;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) UIView *contentView; // root view from the nib by 

- (void)xibContentLoaded;

@end
