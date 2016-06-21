//
//  KSNFeedViewController.h
//
//  Created by Sergey Kovalenko on 4/29/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KSNFeedViewModel;
@protocol KSNSearchableFeedViewModel;
@class KSNSearchViewController;
@class KSNSearchController;
@protocol KSNSearchBar;
@protocol KSNSearchControllerDelegate;
@class KSNCollectionViewController;
@class KSNTableViewController;

@interface KSNFeedViewController : UIViewController

@property (nonatomic, weak) id <KSNSearchControllerDelegate> delegate;

- (instancetype)initWithFeedViewModel:(id <KSNFeedViewModel>)feedViewModel searchFeedViewModel:(id <KSNSearchableFeedViewModel>)searchFeedViewModel;
- (instancetype)initWithFeedViewModel:(id <KSNFeedViewModel>)feedViewModel
                  searchFeedViewModel:(id <KSNSearchableFeedViewModel>)searchFeedViewModel
                            searchBar:(UIView <KSNSearchBar> *)searchBar;
@property (nonatomic, strong, readonly) id <KSNFeedViewModel> feedViewModel;
@property (nonatomic, strong, readonly) id <KSNSearchableFeedViewModel> searchFeedViewModel;

@property (nonatomic, strong, readonly) KSNCollectionViewController *collectionViewController;
@property (nonatomic, strong, readonly) KSNTableViewController *tableViewController;

- (void)reload;

@end
