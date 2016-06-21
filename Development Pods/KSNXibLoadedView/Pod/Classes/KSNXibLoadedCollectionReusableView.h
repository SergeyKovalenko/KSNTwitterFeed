//
//  KSNXibLoadedCollectionReusableView.h
//  Pods
//
//  Created by Sergey Kovalenko on 3/3/16.
//
//

#import <UIKit/UIKit.h>

@interface KSNXibLoadedCollectionReusableView : UICollectionReusableView

@property (nonatomic, copy, readonly) NSString *nibName;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly)  UIView *contentView;

- (void)xibContentLoaded;

@end
