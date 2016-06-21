//
//  KSNTableViewController.m

//
//  Created by Sergey Kovalenko on 11/2/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNTableViewController.h"
#import "KSNTableViewModelTraits.h"
#import "KSNRefreshMediator.h"
#import "KSNItemsTableViewDataSource.h"
#import "KSNRefreshView.h"
#import "KSNLogoRefreshView.h"
#import <KSNUtils/KSNGlobalFunctions.h>
#import <KSNDataSource/KSNDataSource.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNUtils/UIView+KSNAdditions.h>

static const CGFloat KSNNavigationBarHeight = 44.0f;
static const CGFloat KSNStatusBarHeight = 20.0f;

@interface KSNTableViewController () <KSNDataSourceObserver, UITableViewDelegate, UITableViewDataSource, KSNRefreshMediatorDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *disableOverlay;

@property (nonatomic, strong) KSNRefreshMediatorInfo *topRefreshMediatorInfo;
@property (nonatomic, strong) KSNRefreshMediatorInfo *bottomRefreshMediatorInfo;

@property (nonatomic, strong) UIView <KSNRefreshingView> *topRefreshView;
@property (nonatomic, strong) UIView <KSNRefreshingView> *bottomRefreshView;
@property (nonatomic, strong) KSNRefreshMediator *refreshMediator;

@property (nonatomic, strong) NSMutableSet *observationInfoSet;

@property (nonatomic, assign) UITableViewStyle style;
@property (nonatomic, assign) BOOL reloadDataOnViewWillAppear;
@property (nonatomic, assign, getter=isVisible) BOOL visible;

@property (nonatomic, assign) NSInteger beginEditingCount;
@property (nonatomic, assign) BOOL viewModelResponseToDidScrollSelector;
@property (nonatomic, strong) UIView *fakeStatusBarBackground;

@end

@implementation KSNTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.style = style;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.style = UITableViewStylePlain;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)commonInit
{
    self.observeKeyboard = YES;
    self.cellLayoutMargins = UIEdgeInsetsZero;
    self.showOverlay = YES;
    self.hidesBarsOnSwipe = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.reloadCellOnDataUpdates = YES;
    self.observationInfoSet = [[NSMutableSet alloc] init];
    [self createRefreshMediator];
}

- (void)dealloc
{
    [self.tableViewDataSource removeChangeObserver:self];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;

    [self.observationInfoSet enumerateObjectsUsingBlock:^(id observer, BOOL *stop) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];

    [self.observationInfoSet removeAllObjects];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createTableViewIfNeeded];
    [self createDisableOverlayViewIfNeeded];
    [self createRefreshControls];
    [self updatePageNumbers];

    if (self.pagingDataSource)
    {
        self.pagingDataSource.isLoading ? [self setupViewsWithLoading] : [self setupViewsLoaded];
    }
    [self adjustTableInsets];
    [self toggleKeyboardObservation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self deselectSelectedRowAnimated:YES];
    
    if ([self.viewModel respondsToSelector:@selector(tableViewDidAppear:)])
    {
        [self.viewModel tableViewDidAppear:self.tableView];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.visible = NO;

    [self setNavigationBarHidden:NO animated:animated];
    [self.topRefreshMediatorInfo setRefreshing:NO];
    [self.bottomRefreshMediatorInfo setRefreshing:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.visible = YES;

    [self updatePageNumbers];

    if (self.pagingDataSource)
    {
        self.pagingDataSource.isLoading ? [self setupViewsWithLoading] : [self setupViewsLoaded];
    }

    if (self.reloadDataOnViewWillAppear)
    {
        [self reloadData];
        self.reloadDataOnViewWillAppear = NO;
    }

    if (self.pagingDataSource && self.pagingDataSource.count == 0 && !self.pagingDataSource.isLoading)
    {
        [self.pagingDataSource refreshWithUserInfo:nil];
    }
    
    if ([self.viewModel respondsToSelector:@selector(tableViewWillAppear:)])
    {
        [self.viewModel tableViewWillAppear:self.tableView];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self scrollViewContentInsetsChanged];
}

- (void)scrollViewContentInsetsChanged
{
    if (!self.topRefreshMediatorInfo.isRefreshing && !self.bottomRefreshMediatorInfo.isRefreshing)
    {
        [self.refreshMediator scrollViewContentInsetsChanged];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];

    self.topRefreshMediatorInfo.refreshEnabled = editing ? NO : self.pagingDataSource.isRefreshAllowed;
    self.bottomRefreshMediatorInfo.refreshEnabled = editing ? NO : self.pagingDataSource.isPaginationSupported;
}

- (void)wk_scrollToTop
{
    UITableView *tableView = self.tableView;
    UIEdgeInsets tableInset = tableView.contentInset;
    [tableView setContentOffset:CGPointMake(-tableInset.left, -tableInset.top) animated:YES];
}

#pragma mark - Private Methods

- (id <KSNPagingDataSource>)pagingDataSource
{
    return KSNSafeProtocolCast(@protocol(KSNPagingDataSource), self.tableViewDataSource);
}

- (void)deselectSelectedRowAnimated:(BOOL)animated
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath != nil)
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (UIView <KSNRefreshingView> *)createBottomRefreshView
{
    KSNRefreshView *refreshView = [[KSNRefreshView alloc] initWithPosition:self.reverseOrder ? KSNRefreshViewPositionTop : KSNRefreshViewPositionBottom];
    refreshView.pullTitle = NSLocalizedString(@"refresh.pulldown.nextpage", @"KSNTableViewController: \"Pull up for next page\" title");
    refreshView.releaseTitle = NSLocalizedString(@"refresh.release.nextpage", @"KSNTableViewController: \"Release for next page\" title");
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [refreshView sizeToFit];
    CGRect refreshRect = refreshView.frame;
    refreshRect.size.width = CGRectGetWidth(self.view.bounds);
    refreshView.frame = refreshRect;
    return refreshView;
}

- (UIView <KSNRefreshingView> *)createTopRefreshView
{
    KSNLogoRefreshView *refreshView = [[KSNLogoRefreshView alloc] initWithPosition:self.reverseOrder ? KSNRefreshViewPositionBottom : KSNRefreshViewPositionTop];
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [refreshView sizeToFit];
    CGRect refreshRect = refreshView.frame;
    refreshRect.size.width = CGRectGetWidth(self.view.bounds);
    refreshView.frame = refreshRect;
    return refreshView;
}

- (void)createRefreshControls
{
    self.topRefreshView = self.reverseOrder ? [self createBottomRefreshView] : [self createTopRefreshView];
    self.bottomRefreshView = self.reverseOrder ? [self createTopRefreshView] : [self createBottomRefreshView];

    [self.view addSubview:self.topRefreshView];
    [self.view addSubview:self.bottomRefreshView];
    [self.view bringSubviewToFront:self.tableView];

    self.refreshMediator.scrollView = self.tableView;
    self.topRefreshMediatorInfo.refreshView = self.topRefreshView;
    self.bottomRefreshMediatorInfo.refreshView = self.bottomRefreshView;
    
}

- (void)createRefreshMediator
{
    self.topRefreshMediatorInfo = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionTop];
    self.bottomRefreshMediatorInfo = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionBottom];
    self.refreshMediator = [[KSNRefreshMediator alloc] initWithRefreshInfo:@[self.topRefreshMediatorInfo,
                                                                             self.bottomRefreshMediatorInfo]];

    self.refreshMediator.delegate = self;
}

- (void)createDisableOverlayViewIfNeeded
{
    if (!self.disableOverlay)
    {
        UIView *view = [[UIView alloc] initWithFrame:self.tableView.frame];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        view.alpha = 0.5f;
        self.disableOverlay = view;
    }
}

- (void)addDisableOverlay
{
    [self removeDisableOverlay];

    if ([self shouldShowOverlay])
    {
        CGRect disableRect = self.disableOverlay.frame;
        disableRect.size.height = self.tableView.contentSize.height;
        disableRect.size.width = CGRectGetWidth(self.tableView.frame);
        self.disableOverlay.frame = disableRect;
        self.disableOverlay.backgroundColor = [UIColor clearColor];
        [self.tableView addSubview:self.disableOverlay];
        self.tableView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//#pragma message("TODO: (Sergey) !!!")
//            self.disableOverlay.backgroundColor = [UIColor wk_disableOverlayColor];
        }                completion:NULL];
    }
}

- (void)removeDisableOverlay
{
    self.tableView.userInteractionEnabled = YES;
    if (self.disableOverlay.superview)
    {
        [self.disableOverlay removeFromSuperview];
    }
}

- (void)updatePageNumbers
{
    if (self.pagingDataSource)
    {
        BOOL nextPageAvailable = NO;
        BOOL canBeRefreshed = self.tableViewDataSource.count > 0 && self.pagingDataSource.isRefreshAllowed;
        
        if (self.pagingDataSource.isPaginationSupported)
        {
            NSUInteger currentPage = [self.pagingDataSource currentPage];
            NSUInteger numberOfPages = [self.pagingDataSource numberOfPages];
            nextPageAvailable = (currentPage + 1 < numberOfPages);
        }

        if (self.reverseOrder)
        {
            self.topRefreshMediatorInfo.refreshEnabled = nextPageAvailable;
            self.bottomRefreshMediatorInfo.refreshEnabled = canBeRefreshed;
        }
        else
        {
            self.topRefreshMediatorInfo.refreshEnabled = canBeRefreshed;
            self.bottomRefreshMediatorInfo.refreshEnabled = nextPageAvailable;
        }
    }
    else
    {
        self.topRefreshMediatorInfo.refreshEnabled = NO;
        self.bottomRefreshMediatorInfo.refreshEnabled = NO;
    }
}

- (void)setObserveKeyboard:(BOOL)observeKeyboard
{
    if (observeKeyboard != _observeKeyboard)
    {
        _observeKeyboard = observeKeyboard;
        [self toggleKeyboardObservation];
    }
}

- (void)toggleKeyboardObservation
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    if (self.isKeyboardObserved)
    {
        @weakify(self);

        __block UIEdgeInsets initialContentInsets = UIEdgeInsetsZero;
        __block UIEdgeInsets initialScrollIndicatorInsets = UIEdgeInsetsZero;
        __block BOOL wasShowed = NO;

        void (^willNotificationBlock)(BOOL, NSDictionary *) = ^(BOOL show, NSDictionary *keyboardInfo) {
            @strongify(self);
            if (self.isViewLoaded && self.view.window)
            {
                CGRect endFrame = [keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
                CGRect viewRect = [self.tableView.superview convertRect:endFrame fromView:self.view.window];
                CGFloat bottomInset = CGRectGetHeight(self.tableView.bounds) - viewRect.origin.y;

                UIEdgeInsets contentInsets = self.tableView.contentInset;
                UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;

                if (show)
                {
                    if (!wasShowed)
                    {
                        initialContentInsets = self.tableView.contentInset;
                        initialScrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
                        wasShowed = YES;
                    }

                    contentInsets.bottom = bottomInset;
                    scrollIndicatorInsets.bottom = bottomInset;
                }
                else
                {
                    if (wasShowed)
                    {
                        contentInsets = initialContentInsets;
                        scrollIndicatorInsets = initialScrollIndicatorInsets;
                    }
                    wasShowed = NO;
                }

                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationCurve:(UIViewAnimationCurve) [keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
                [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];

                self.tableView.contentInset = contentInsets;
                self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;

                [UIView commitAnimations];
            }
        };
        [self.observationInfoSet addObject:[center addObserverForName:UIKeyboardWillShowNotification
                                                               object:nil
                                                                queue:[NSOperationQueue mainQueue]
                                                           usingBlock:^(NSNotification *note) {
                                                               willNotificationBlock(YES, note.userInfo);
                                                           }]];

        [self.observationInfoSet addObject:[center addObserverForName:UIKeyboardWillHideNotification
                                                               object:nil
                                                                queue:[NSOperationQueue mainQueue]
                                                           usingBlock:^(NSNotification *note) {
                                                               willNotificationBlock(NO, note.userInfo);
                                                           }]];
    }
    else
    {
        for (id observationInfo in self.observationInfoSet)
        {
            [center removeObserver:observationInfo];
        }
    }
}

#pragma mark - Table View

- (void)createTableViewIfNeeded
{
    if (!self.tableView)
    {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:self.style];
        tableView.backgroundColor = [UIColor clearColor];
        // Setting the table footer eliminates separators past the last cell
        tableView.tableFooterView = [[UIView alloc] init];
        tableView.allowsMultipleSelectionDuringEditing = YES;

        if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
        {
            if (self.style == UITableViewStylePlain)
            {
                [tableView setSeparatorInset:UIEdgeInsetsZero];
            }
        }
        if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
        {
            [tableView setLayoutMargins:self.cellLayoutMargins];
        }
        if ([self.viewModel respondsToSelector:@selector(separatorStyle)])
        {
            tableView.separatorStyle = [self.viewModel separatorStyle];
        }
        self.tableView = tableView;
        [self.view addSubview:self.tableView];
    }

    self.tableView.frame = self.view.bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    if ([self.viewModel respondsToSelector:@selector(configureTableView:)])
    {
        [self.viewModel configureTableView:self.tableView];
    }
}

- (void)setTableView:(UITableView *)tableView
{
    if (_tableView != tableView)
    {
        _tableView = tableView;
        [self registerCells];
    }
}

- (void)registerCells
{
    if ([self.viewModel respondsToSelector:@selector(cellClasses)])
    {
        [self.viewModel.cellClasses enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class klass, BOOL *stop) {
            [self.tableView registerClass:klass forCellReuseIdentifier:key];
        }];
    }
    if ([self.viewModel respondsToSelector:@selector(cellNibs)])
    {
        [self.viewModel.cellNibs enumerateKeysAndObjectsUsingBlock:^(NSString *key, UINib *nib, BOOL *stop) {
            [self.tableView registerNib:nib forCellReuseIdentifier:key];
        }];
    }
}

- (NSDictionary *)tableViewModelMethodsMap
{
    static dispatch_once_t predicate;
    static NSDictionary *map;
    dispatch_once(&predicate, ^{
        map = @{NSStringFromSelector(@selector(tableView:cellForRowAtIndexPath:))             : NSStringFromSelector(@selector(cellReuseIdAtIndexPath:)),
                NSStringFromSelector(@selector(tableView:heightForRowAtIndexPath:))           : NSStringFromSelector(@selector(cellHeightAtIndexPath:forTableView:)),
                NSStringFromSelector(@selector(tableView:estimatedHeightForRowAtIndexPath:))  : NSStringFromSelector(@selector(estimatedCellHeightAtIndexPath:forTableView:)),
                NSStringFromSelector(@selector(tableView:titleForHeaderInSection:))           : NSStringFromSelector(@selector(titleForHeaderInSection:)),
                NSStringFromSelector(@selector(tableView:titleForFooterInSection:))           : NSStringFromSelector(@selector(titleForFooterInSection:)),
                NSStringFromSelector(@selector(tableView:heightForHeaderInSection:))          : NSStringFromSelector(@selector(heightForHeaderInSection:)),
                NSStringFromSelector(@selector(tableView:estimatedHeightForHeaderInSection:)) : NSStringFromSelector(@selector(estimatedHeightForHeaderInSection:)),
                NSStringFromSelector(@selector(tableView:heightForFooterInSection:))          : NSStringFromSelector(@selector(heightForFooterInSection:)),
                NSStringFromSelector(@selector(tableView:estimatedHeightForFooterInSection:)) : NSStringFromSelector(@selector(estimatedHeightForFooterInSection:)),
                NSStringFromSelector(@selector(tableView:viewForHeaderInSection:))            : NSStringFromSelector(@selector(viewForHeaderInSection:)),
                NSStringFromSelector(@selector(tableView:viewForFooterInSection:))            : NSStringFromSelector(@selector(viewForFooterInSection:)),
                NSStringFromSelector(@selector(tableView:viewForFooterInSection:))            : NSStringFromSelector(@selector(viewForFooterInSection:)),
                NSStringFromSelector(@selector(tableView:didSelectRowAtIndexPath:))           : NSStringFromSelector(@selector(tableView:didSelectCell:atIndexPath:selectedIndexes:)),
                NSStringFromSelector(@selector(tableView:didDeselectRowAtIndexPath:))         : NSStringFromSelector(@selector(tableView:didDeselectCell:atIndexPath:selectedIndexes:)),
                NSStringFromSelector(@selector(tableView:canEditRowAtIndexPath:))             : NSStringFromSelector(@selector(tableView:canEditRowAtIndexPath:)),
                NSStringFromSelector(@selector(tableView:indentationLevelForRowAtIndexPath:)) : NSStringFromSelector(@selector(tableView:indentationLevelForRowAtIndexPath:)),};
    });
    return map;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSString *viewModelSelector = self.tableViewModelMethodsMap[NSStringFromSelector(aSelector)];
    if (viewModelSelector)
    {
        return [self.viewModel respondsToSelector:NSSelectorFromString(viewModelSelector)];
    }
    else
    {
        return [super respondsToSelector:aSelector];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewDataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewDataSource numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseId = [self.viewModel cellReuseIdAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
    // Give view model an opportunity to customize the cell
    if ([self.viewModel respondsToSelector:@selector(customizeCell:forTableView:atIndexPath:)])
    {
        [self.viewModel customizeCell:cell forTableView:tableView atIndexPath:indexPath];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (editingStyle)
    {
        case UITableViewCellEditingStyleDelete:
        {
            if ([self.viewModel respondsToSelector:@selector(deleteRowAtIndexPath:)])
            {
                [self.viewModel deleteRowAtIndexPath:indexPath];
            }
        }
            break;

        default:
        {
            NSAssert(NO, @"Undefined behavior");
        }
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ([self.viewModel respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)])
    {
        [self.viewModel tableView:tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel cellHeightAtIndexPath:indexPath forTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // View model will handle selection
    [self.viewModel tableView:tableView
                didSelectCell:[tableView cellForRowAtIndexPath:indexPath]
                  atIndexPath:indexPath
              selectedIndexes:[tableView indexPathsForSelectedRows]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // View model will handle deselection
    [self.viewModel tableView:tableView
              didDeselectCell:[tableView cellForRowAtIndexPath:indexPath]
                  atIndexPath:indexPath
              selectedIndexes:[tableView indexPathsForSelectedRows]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.viewModel titleForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self.viewModel titleForFooterInSection:section];
}

- (UIView *)tableView:(UITableView *)tableViewIn viewForHeaderInSection:(NSInteger)section
{
    return [self.viewModel viewForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self.viewModel heightForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self.viewModel heightForFooterInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel estimatedCellHeightAtIndexPath:indexPath forTableView:tableView];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return [self.viewModel estimatedHeightForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
{
    return [self.viewModel estimatedHeightForFooterInSection:section];
}

- (UIView *)tableView:(UITableView *)tableViewIn viewForFooterInSection:(NSInteger)section
{
    return [self.viewModel viewForFooterInSection:section];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:self.cellLayoutMargins];
    }

    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
    {
        cell.preservesSuperviewLayoutMargins = YES;
        cell.contentView.preservesSuperviewLayoutMargins = YES;
    }

    if ([self.viewModel respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
    {
        [self.viewModel tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshMediator scrollViewDidScroll];
    [self showOrHideNavigationBarOnScrollViewMovement:scrollView targetContentOffset:scrollView.contentOffset];
    if (self.viewModelResponseToDidScrollSelector)
    {
        [self.viewModel tableViewDidScroll:self.tableView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshMediator scrollViewDidEndDragging];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self showOrHideNavigationBarOnScrollViewMovement:scrollView targetContentOffset:*targetContentOffset];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self setNavigationBarHidden:NO animated:YES];
    return YES;
}

#pragma mark - Public

- (void)setListInsets:(UIEdgeInsets)listInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_listInsets, listInsets))
    {
        _listInsets = listInsets;
        [self adjustTableInsets];
    }
}

- (void)setScrollIndicatorInsets:(UIEdgeInsets)listInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_scrollIndicatorInsets, listInsets))
    {
        _scrollIndicatorInsets = listInsets;
        [self adjustTableInsets];
    }
}

- (void)adjustTableInsets
{
    if ([self isViewLoaded])
    {
        // Check if we are at begin of table, if yes then we need update contentOffset so it fit new contentInset
        if (self.tableView.contentOffset.y == -self.tableView.contentInset.top)
        {
            self.tableView.contentOffset = CGPointMake(-self.listInsets.left, -self.listInsets.top);
        }
        self.tableView.contentInset = self.listInsets;
        self.tableView.scrollIndicatorInsets = self.scrollIndicatorInsets;

        [self.refreshMediator scrollViewContentInsetsChanged];
    }
}

- (void)setTableViewDataSource:(KSNItemsTableViewDataSource *)tableViewDataSource
{
    if (_tableViewDataSource != tableViewDataSource)
    {
        [_tableViewDataSource removeChangeObserver:self];
        [tableViewDataSource addChangeObserver:self];
        _tableViewDataSource = tableViewDataSource;

        [self updatePageNumbers];

        if ([self isViewLoaded])
        {
            [self reloadData];
        }
    }
}

- (void)setViewModel:(id <KSNTableViewModelTraits>)viewModel
{
    if (_viewModel != viewModel)
    {
        _viewModel = viewModel;
        self.viewModelResponseToDidScrollSelector = [viewModel respondsToSelector:@selector(tableViewDidScroll:)];
        if ([self isViewLoaded])
        {
            [self registerCells];
            [self reloadData];

            if (self.viewModelResponseToDidScrollSelector)
            {
                [self.viewModel tableViewDidScroll:self.tableView];
            }
        }
    }
}

- (void)reloadData
{
    [self.tableView reloadData];
    
    if([self.viewModel respondsToSelector:@selector(tableViewRefreshed:)])
    {
        [self.viewModel tableViewRefreshed:self.tableView];
    }
}

#pragma mark - View Controller Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        [self.refreshMediator scrollViewContentInsetsChanged];
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.refreshMediator scrollViewContentInsetsChanged];
}

#pragma mark - Private Helpers

- (void)deleteRowAtIndexPath:(NSIndexPath *)ip
{
    // Send the deleted cell to back of the view hierarchy. For some reason
    // UITableViewRowAnimationNone slides the neighbouring cell under the deleted
    // cell, which gives a weird animation.
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
    [cell.superview sendSubviewToBack:cell];
    [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)addRowAtIndexPath:(NSIndexPath *)ip
{
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
    [cell.superview sendSubviewToBack:cell];
}

#pragma mark - TRADataSource event handling

- (void)setupViewsWithError:(NSError *)error
{
    // Data source is loaded with error
    [self removeDisableOverlay];
}

- (void)setupViewsLoaded
{
    // Data source is loaded.
    [self updatePageNumbers];
//    [self removeDisableOverlay];
}

- (void)setupViewsWithLoading
{
    // Data source is  loading.
//    [self addDisableOverlay];
}

- (void)setupViewRefreshed
{
    CGFloat contentOffsetFromBottomBeforeReload = 0.0f;
    if (self.reverseOrder)
    {
        contentOffsetFromBottomBeforeReload = self.tableView.contentSize.height - self.tableView.contentOffset.y;
    }

    [self reloadData];

    [self setupViewsLoaded];

    if (self.pagingDataSource.dataWasRefreshed)
    {
        if (self.reverseOrder)
        {
            [self.tableView scrollRectToVisible:CGRectMake(0, self.tableView.contentSize.height - 1, 1, 1) animated:NO];
        }
        else
        {
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        }
    }
    else if (self.reverseOrder)
    {
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - contentOffsetFromBottomBeforeReload)];
    }
    [self.topRefreshMediatorInfo setRefreshing:NO];
    [self.bottomRefreshMediatorInfo setRefreshing:NO];
}

#pragma mark - TRADataSourceObserver

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    if (dataSource == self.tableViewDataSource)
    {
        if (self.isVisible)
        {
            [self reloadData];
            [self setupViewsWithError:error];

            if (!self.reverseOrder)
            {
                self.bottomRefreshMediatorInfo.remainOffset = CGPointZero;
            }
            [self.topRefreshMediatorInfo setRefreshing:NO];
            [self.bottomRefreshMediatorInfo setRefreshing:NO];
        }
        else
        {
            self.reloadDataOnViewWillAppear = YES;
        }
    }
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    if (dataSource == self.tableViewDataSource)
    {
        if (self.isVisible)
        {
            [self setupViewRefreshed];

            if (!self.reverseOrder)
            {
                self.bottomRefreshMediatorInfo.remainOffset = CGPointMake(0, 4.f * CGRectGetHeight([[UIScreen mainScreen] applicationFrame]));
            }
        }
        else
        {
            self.reloadDataOnViewWillAppear = YES;
        }
    }
}

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    if (dataSource == self.tableViewDataSource && self.isVisible)
    {
        [self setupViewsWithLoading];
    }
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    // NO-OP (views will be set up accordingly in the success / error handling)
}

- (void)dataSource:(id <KSNDataSource>)datasource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    if (self.isVisible)
    {
        if (datasource == self.tableViewDataSource)
        {
            switch (change)
            {
                case KSNDataSourceChangeTypeInsert:
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                    break;

                case KSNDataSourceChangeTypeRemove:
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                    break;

                case KSNDataSourceChangeTypeUpdate:
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                    break;

                case KSNDataSourceChangeTypeMove:
                    NSAssert(YES, @"Unsupported type KSNDataSourceChangeTypeMove");
                    break;
            }
        }
    }
    else
    {
        self.reloadDataOnViewWillAppear = YES;
    }
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(KSNDataSourceChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (self.isVisible)
    {
        if (dataSource == self.tableViewDataSource)
        {
            switch (type)
            {
                case KSNDataSourceChangeTypeInsert:
                    [self addRowAtIndexPath:indexPath];
                    break;

                case KSNDataSourceChangeTypeRemove:
                    [self deleteRowAtIndexPath:indexPath];
                    break;

                case KSNDataSourceChangeTypeUpdate:
                {

                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    if (!self.reloadCellOnDataUpdates && cell && [self.viewModel respondsToSelector:@selector(customizeCell:forTableView:atIndexPath:)])
                    {
                        [self.viewModel customizeCell:cell forTableView:self.tableView atIndexPath:indexPath];
                    }
                    else
                    {
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }
                    break;

                case KSNDataSourceChangeTypeMove:
                    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
                    break;
            }
        }
    }
    else
    {
        self.reloadDataOnViewWillAppear = YES;
    }
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)datasource
{
    if (datasource == self.tableViewDataSource && self.isVisible)
    {
        self.beginEditingCount++;
        [self.tableView beginUpdates];
    }
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)datasource
{
    if (datasource == self.tableViewDataSource && self.isVisible)
    {
        if (self.beginEditingCount > 0)
        {
            self.beginEditingCount--;
            [self.tableView endUpdates];
        }
        [self setupViewsLoaded];
    }
}

#pragma mark - TRARefreshMediatorDelegate

- (void)refreshMediator:(KSNRefreshMediator *)mediator didTriggerUpdateAtPossition:(KSNRefreshMediatorInfo *)position
{
    if (self.pagingDataSource && !self.pagingDataSource.isLoading)
    {
        if (position == self.topRefreshMediatorInfo)
        {
            self.reverseOrder ? [self.pagingDataSource pageDownWithUserInfo:nil] : [self.pagingDataSource refreshWithUserInfo:nil];
        }
        else if (position == self.bottomRefreshMediatorInfo)
        {
            self.reverseOrder ? [self.pagingDataSource refreshWithUserInfo:nil] : [self.pagingDataSource pageDownWithUserInfo:nil];
        }
    }
}

#pragma mark - Navigation bar hiding support

- (void)showOrHideNavigationBarOnScrollViewMovement:(UIScrollView *)scrollView targetContentOffset:(CGPoint)targetContentOffset
{
    if (!self.hidesBarsOnSwipe)
    {
        return;
    }

    // Speed at which you need to scroll down to hide the navigation bar after it is visible
    static const CGFloat kMinVelocityToHide = 100.0f; // pixels per second

    // Speed at which you need to scroll up to show the navigation bar after it is hidden
    static const CGFloat kMinVelocityToShow = 250.0f; // pixels per second

    // If we're within this offset we will never hide the navigation bar
    static const CGFloat kMinThresholdContentOffsetY = KSNNavigationBarHeight + KSNStatusBarHeight + 50.0f; // pixels

    CGPoint scrollVelocity = [[scrollView panGestureRecognizer] velocityInView:self.view];
    if (scrollVelocity.y > kMinVelocityToShow || targetContentOffset.y < kMinThresholdContentOffsetY)
    {
        [self setNavigationBarHidden:NO animated:YES];
    }
    else if (scrollVelocity.y < -kMinVelocityToHide)
    {
        [self setNavigationBarHidden:YES animated:YES];
    }
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.navigationController.navigationBarHidden != hidden)
    {
        [self.navigationController setNavigationBarHidden:hidden animated:animated];
        // When hiding add a fake background for the status bar
        if (hidden && self.fakeStatusBarBackground == nil)
        {
            self.fakeStatusBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, KSNStatusBarHeight)];
//#pragma message("TODO: (Sergey) !!!")
//            self.fakeStatusBarBackground.backgroundColor = [UIColor wk_tintColor];
            self.fakeStatusBarBackground.contentMode = UIViewContentModeScaleToFill;
            self.fakeStatusBarBackground.clipsToBounds = YES;
            self.fakeStatusBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            self.fakeStatusBarBackground.userInteractionEnabled = NO;
            [self.view addSubview:self.fakeStatusBarBackground];
        }

        self.fakeStatusBarBackground.frameTop = hidden ? -(KSNStatusBarHeight / 2.0f) : 0.f;
        [UIView animateWithDuration:animated ? UINavigationControllerHideShowBarDuration : 0.0f
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.fakeStatusBarBackground.frameTop = hidden ? 0 : -KSNStatusBarHeight;
                         }
                         completion:^(BOOL finished) {
                             if (finished)
                             {
                                 self.fakeStatusBarBackground.frameTop = self.navigationController.navigationBarHidden ? 0 : -KSNStatusBarHeight;
                             }
                         }];
    }
}
@end
