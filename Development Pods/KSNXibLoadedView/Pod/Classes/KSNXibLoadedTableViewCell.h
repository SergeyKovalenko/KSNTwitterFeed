//
//  KSNXibLoadedTableViewCell.h
//  Pods
//
//  Created by Sergey Kovalenko on 2/24/16.
//
//

#import <UIKit/UIKit.h>

@interface KSNXibLoadedTableViewCell : UITableViewCell

- (instancetype)initWithNibName:(NSString *)nibNameOrNil;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundle reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, copy, readonly) NSString *nibName;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) UIView *containerView; // root view from the nib by

- (void)xibContentLoaded;
@end
