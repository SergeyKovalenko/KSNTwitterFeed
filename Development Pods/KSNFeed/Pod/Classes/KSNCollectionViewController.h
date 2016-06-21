//
//  KSNCollectionViewController.h
//
//  Created by Sergey Kovalenko on 2/6/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KSNDataSource;
@protocol KSNCollectionViewModelTraits;

@interface KSNCollectionViewController : UIViewController

/**
*  DESIGNATED_INITIALIZER.
*/
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)collectionViewLayout NS_DESIGNATED_INITIALIZER;

/**
*  The data source.
*/
@property (nonatomic, strong) id <KSNDataSource> dataSource;

/**
*  List view model.
*/
@property (nonatomic, strong) id <KSNCollectionViewModelTraits> viewModel;

/**
*  Collection view.
*/
@property (nonatomic, readonly) UICollectionView *collectionView;

/**
*  Collection view layout.
*/
@property (nonatomic, strong, readonly) UICollectionViewLayout *collectionViewLayout;

/**
*  Boolean value indicates that table collection should adjust insets. YES by defaults
*/
@property (nonatomic, assign, getter=isKeyboardObserved) IBInspectable BOOL observeKeyboard;

/**
*  Content insets for the collection view
*/
@property (nonatomic, assign) UIEdgeInsets listInsets;

/**
*  Content insets for the table view's scroll indicator
*/
@property (nonatomic, assign) UIEdgeInsets scrollIndicatorInsets;

/**
 *  Insets of content from external edges
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 *  Show logo as top refresh indicator
 */
@property (nonatomic, assign) BOOL showLogo;

/**
 *  Show disable overlay. Default is YES.
 */
@property (nonatomic, assign, getter = shouldShowOverlay) BOOL showOverlay;

@property (nonatomic, assign) BOOL reloadHeadersOnDataUpdates; // YES by

@end
