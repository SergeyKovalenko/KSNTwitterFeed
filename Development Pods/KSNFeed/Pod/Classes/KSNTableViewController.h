//
//  KSNTableViewController.h
//
//  Created by Sergey Kovalenko on 11/2/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KSNTableViewModelTraits, KSNDataSource;
@class KSNRefreshMediator;
@class KSNRefreshMediatorInfo;

@interface KSNTableViewController : UIViewController

- (instancetype)initWithStyle:(UITableViewStyle)style;
/**
 *  The data source.
 */
@property (nonatomic, strong) id <KSNDataSource> tableViewDataSource;

/**
 *  List view model.
 */
@property (nonatomic, strong) id <KSNTableViewModelTraits> viewModel;

/**
 *  list table view.
 */
@property (nonatomic, readonly) UITableView *tableView;

/**
 *  Boolean value indicates that table view should adjust insets. YES by defaults
 */
@property (nonatomic, assign, getter=isKeyboardObserved) IBInspectable BOOL observeKeyboard;

/**
 *  Content insets for the table view
 */
@property (nonatomic, assign) UIEdgeInsets listInsets;

/**
 *  Content insets for the table view's scroll indicator
 */
@property (nonatomic, assign) UIEdgeInsets scrollIndicatorInsets;

@property (nonatomic) UIEdgeInsets cellLayoutMargins;

@property (nonatomic, assign) BOOL reverseOrder;

@property (nonatomic, readwrite, assign) BOOL hidesBarsOnSwipe;

/**
 *  Show disable overlay. Default is YES.
 */
@property (nonatomic, assign, getter = shouldShowOverlay) BOOL showOverlay;

@property (nonatomic, assign) BOOL reloadCellOnDataUpdates; // YES by 

@end
