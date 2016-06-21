//
//  KSNSearchController.h

//
//  Created by Sergey Kovalenko on 1/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KSNSearchController;

@protocol KSNSearchControllerDelegate <NSObject>

@optional
// These methods are called when automatic presentation or dismissal occurs. They will not be called if you present or dismiss the search controller yourself.
- (void)searchControllerStartSearch:(KSNSearchController *)searchBar;
- (void)searchControllerEndSearch:(KSNSearchController *)searchBar;

- (void)willPresentSearchController:(KSNSearchController *)searchController;
- (void)didPresentSearchController:(KSNSearchController *)searchController;

- (void)willDismissSearchController:(KSNSearchController *)searchController;
- (void)didDismissSearchController:(KSNSearchController *)searchController;

- (UIViewController *)searchControllerWillShowSearchResultsControllerFor:(KSNSearchController *)searchController;

// Called after the search controller's search bar has agreed to begin editing or when 'active' is set to YES. If you choose not to present the controller yourself or do not implement this method, a default presentation is performed on your behalf.
- (void)presentSearchController:(KSNSearchController *)searchController;
@end

@protocol TRASearchControllerUpdating <NSObject>

@required
// Called when the search bar's text or scope has changed or when the search bar becomes first responder.
- (void)updateSearchResultsForSearchController:(KSNSearchController *)searchController;
@end

typedef NS_ENUM(NSUInteger, KSNSearchBarEvent)
{
    TRASearchBarEventValueChanged = UIControlEventValueChanged,
    TRASearchBarEventSearchDidBegin = UIControlEventEditingDidBegin,
    TRASearchBarEventSearchDidEnd = UIControlEventEditingDidEnd,
};

@class KSNSearchBar;

@protocol TRASearchBarDelegate <UIBarPositioningDelegate>

@optional

- (void)searchBarTextDidBeginEditing:(UIView *)searchBar;                     // called when text starts editing
- (void)searchBarTextDidEndEditing:(UIView *)searchBar;                       // called when text ends editing
- (void)searchBar:(UIView *)searchBar textDidChange:(NSString *)searchText;   // called when text changes (including clear)

- (void)searchBar:(UIView *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope NS_AVAILABLE_IOS(3_0);

- (void)searchBarSearchButtonClicked:(UIView *)searchBar;

@end

@protocol KSNSearchBar <NSObject>

@property (nonatomic, weak) id <TRASearchBarDelegate> delegate;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(KSNSearchBarEvent)controlEvents;
- (BOOL)hasSearchCriteria;
- (void)clearSearchCriteria;

@end

@interface KSNSearchController : UIViewController <UIViewControllerTransitioningDelegate>

// Pass nil if you wish to display search results (please check it first :)) in the same view that you are searching or delegate will provide search results controller
// dynamically.
- (instancetype)initWithSearchResultsController:(UIViewController *)searchResultsController searchBar:(UIView <KSNSearchBar> *)searchBar;

// The object responsible for updating the content of the searchResultsController.
@property (nonatomic, weak) id <TRASearchControllerUpdating> searchResultsUpdater;

// Setting this property to YES is a convenience method that performs a default presentation of the search controller appropriate for how the controller is configured. Implement -presentSearchController: if the default presentation is not adequate.
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, assign) BOOL clearSearchOnDeactivate;         // default is YES

@property (nonatomic, weak) id <KSNSearchControllerDelegate> delegate;
@property (nonatomic, assign) BOOL dimsBackgroundDuringPresentation;         // default is YES

@property (nonatomic, retain, readonly) UIViewController *searchResultsController;

// You are free to become the search bar's delegate to monitor for text changes and button presses.
@property (nonatomic, retain, readonly) UIView <KSNSearchBar> *searchBar;

@end

@interface UIViewController (TRASearchControllerItem)

@property (nonatomic, readonly, strong) KSNSearchController *ksn_searchController; // If this view controller has been pushed onto a navigation controller, return it.

@end