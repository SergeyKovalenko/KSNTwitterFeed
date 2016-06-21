//
//  KSNCollectionViewController.m
//
//  Created by Sergey Kovalenko on 2/6/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNCollectionViewController.h"
#import "KSNRefreshMediator.h"
#import "KSNRefreshView.h"
#import "KSNCollectionViewModelTraits.h"
#import "KSNLogoRefreshView.h"
#import "KSNDataSource.h"
#import "KSNGlobalFunctions.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "UIView+KSNAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface TRAVerticalLayout : UICollectionViewFlowLayout
@end

@implementation TRAVerticalLayout

- (id)init
{
    self = [super init];
    if (self)
    {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.minimumLineSpacing = 0;
        self.minimumInteritemSpacing = 0;
        self.sectionInset = UIEdgeInsetsZero;
    }
    return self;
}
@end

@interface KSNCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KSNDataSourceObserver, KSNRefreshMediatorDelegate>

@property (nonatomic, strong, readwrite) UICollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong) IBOutlet UIView *disableOverlay;

@property (nonatomic, strong) UIView <KSNRefreshingView> *topRefreshView;
@property (nonatomic, strong) UIView <KSNRefreshingView> *leftRefreshView;
@property (nonatomic, strong) UIView <KSNRefreshingView> *bottomRefreshView;
@property (nonatomic, strong) UIView <KSNRefreshingView> *rightRefreshView;

@property (nonatomic, strong) KSNRefreshMediator *refreshMediator;
@property (nonatomic, strong) KSNRefreshMediatorInfo *topRefresher;
@property (nonatomic, strong) KSNRefreshMediatorInfo *leftRefresher;
@property (nonatomic, strong) KSNRefreshMediatorInfo *bottomRefresher;
@property (nonatomic, strong) KSNRefreshMediatorInfo *rightRefresher;

@property (nonatomic, strong) NSMutableArray *updateBlocks;

@property (nonatomic, strong) NSMutableSet *observationInfoSet;

@property (nonatomic, readwrite) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL reloadDataOnViewWillAppear;
@property (nonatomic, assign, getter=isVisible) BOOL visible;

- (id)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@implementation KSNCollectionViewController

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.collectionViewLayout = [[TRAVerticalLayout alloc] init];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithCollectionViewLayout:[[TRAVerticalLayout alloc] init]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)collectionViewLayout
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.collectionViewLayout = collectionViewLayout;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.contentInset = UIEdgeInsetsZero;
    self.observeKeyboard = YES;
    self.showOverlay = YES;
    self.reloadHeadersOnDataUpdates = YES;
    self.observationInfoSet = [[NSMutableSet alloc] init];
}

- (void)dealloc
{
    [self.dataSource removeChangeObserver:self];
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;

    [self.observationInfoSet enumerateObjectsUsingBlock:^(id observer, BOOL *stop) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];

    [self.observationInfoSet removeAllObjects];
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor clearColor];

    [self createCollectionViewIfNeeded];
    [self createDisableOverlayViewIfNeeded];
    [self createRefreshMediator];
    [self createRefreshControls];
    [self updatePageNumbers];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor clearColor];

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
    // When selectionDataSource is nil we should deselect all selected rows (old implementation)

    [self deselectSelectedRowsAnimated:animated];
    [self updatePageNumbers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.visible = YES;

    if (self.reloadDataOnViewWillAppear)
    {
        [self.collectionView reloadData];
        self.reloadDataOnViewWillAppear = NO;
    }
//    [self updateSelectedRowsAnimated:animated];

    if (self.pagingDataSource)
    {
        BOOL refreshData = self.pagingDataSource.count == 0 && !self.pagingDataSource.isLoading;
        if (refreshData)
        {
            [self.pagingDataSource refreshWithUserInfo:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.visible = NO;
    [self.topRefresher setRefreshing:NO animated:NO];
    [self.leftRefresher setRefreshing:NO animated:NO];
    [self.bottomRefresher setRefreshing:NO animated:NO];
    [self.rightRefresher setRefreshing:NO animated:NO];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self scrollViewContentInsetsChanged];

    if (KSN_SYSTEM_VERSION_LESS_THAN(@"8.0"))
    {
        [self.collectionView reloadData];
//        [self updateSelectedRowsAnimated:NO];
    }
}

- (void)scrollViewContentInsetsChanged
{
    if (!self.topRefresher.isRefreshing && !self.bottomRefresher.isRefreshing && !self.leftRefresher.isRefreshing && !self.rightRefresher.isRefreshing)
    {
        [self.refreshMediator scrollViewContentInsetsChanged];
    }
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    [self updateConstraints];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.collectionView reloadData];
//    [self updateSelectedRowsAnimated:animated];
    self.topRefresher.refreshEnabled = !editing;
}

- (void)wk_scrollToTop
{
    UICollectionView *collectionView = self.collectionView;
    UIEdgeInsets collectionInset = collectionView.contentInset;
    [collectionView setContentOffset:CGPointMake(-collectionInset.left, -collectionInset.top) animated:YES];
}

- (id <KSNPagingDataSource>)pagingDataSource
{
    return KSNSafeProtocolCast(@protocol(KSNPagingDataSource), self.dataSource);
}

#pragma mark - Private Methods

- (void)createCollectionViewIfNeeded
{
    if (!self.collectionView)
    {
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewLayout];
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        if ([self isVerticalDirection])
        {
            self.collectionView.alwaysBounceVertical = YES;
        }
        else
        {
            self.collectionView.alwaysBounceHorizontal = YES;
        }
        [self.view addSubview:self.collectionView];
        [self updateConstraints];
    }
    else
    {
        self.collectionViewLayout = KSNSafeCast([UICollectionViewFlowLayout class], self.collectionView.collectionViewLayout);
    }

    if ([self.viewModel respondsToSelector:@selector(configureCollectionView:)])
    {
        [self.viewModel configureCollectionView:self.collectionView];
    }

    [self registerCells];
}

- (void)updateConstraints
{
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.collectionView.superview).with.insets(self.contentInset);
    }];
}

- (void)registerCells
{
    if ([self.viewModel respondsToSelector:@selector(cellClasses)])
    {
        [self.viewModel.cellClasses enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class klass, BOOL *stop) {
            [self.collectionView registerClass:klass forCellWithReuseIdentifier:key];
        }];
    }
    if ([self.viewModel respondsToSelector:@selector(cellNibs)])
    {
        [self.viewModel.cellNibs enumerateKeysAndObjectsUsingBlock:^(NSString *key, UINib *nib, BOOL *stop) {
            [self.collectionView registerNib:nib forCellWithReuseIdentifier:key];
        }];
    }

    if ([self.viewModel respondsToSelector:@selector(supplementaryViewClasses)])
    {
        [self.viewModel.supplementaryViewClasses enumerateKeysAndObjectsUsingBlock:^(NSString *reuseIdentifier, NSDictionary *kinds, BOOL *stop) {
            [kinds enumerateKeysAndObjectsUsingBlock:^(NSString *kind, Class klass, BOOL *stop) {
                [self.collectionView registerClass:klass forSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier];
            }];
        }];
    }

    if ([self.viewModel respondsToSelector:@selector(supplementaryViewNibs)])
    {
        [self.viewModel.supplementaryViewNibs enumerateKeysAndObjectsUsingBlock:^(NSString *reuseIdentifier, NSDictionary *kinds, BOOL *stop) {
            [kinds enumerateKeysAndObjectsUsingBlock:^(NSString *kind, UINib *nib, BOOL *stop) {
                [self.collectionView registerNib:nib forSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier];
            }];
        }];
    }
}

#pragma mark - Selection

- (void)deselectSelectedRowsAnimated:(BOOL)animated
{
    [[self.collectionView indexPathsForSelectedItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }];
}

//- (void)updateSelectedRowsAnimated:(BOOL)animated
//{
//    if (self.selectionDataSource)
//    {
//        // deselect without animation
//        [self deselectSelectedRowsAnimated:NO];
//
//        if ([self.selectionDataSource respondsToSelector:@selector(selectedObjects)])
//        {
//            NSArray *selectedObjects = [self.selectionDataSource selectedObjects];
//            [selectedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                [self p_selectObject:obj animated:animated scrollPosition:UICollectionViewScrollPositionNone];
//            }];
//        }
//    }
//}

- (void)p_selectObject:(id)object animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition
{
    NSIndexPath *indexPath = [self.dataSource indexPathOfItem:object];
    if (indexPath && ![[self.collectionView indexPathsForSelectedItems] containsObject:indexPath])
    {
        [self.collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    }
}

- (void)p_deselectObject:(id)object animated:(BOOL)animated
{
    NSIndexPath *indexPath = [self.dataSource indexPathOfItem:object];
    if (indexPath && [[self.collectionView indexPathsForSelectedItems] containsObject:indexPath])
    {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }
}

#pragma mark -

- (UIView <KSNRefreshingView> *)createRefreshViewWithPosition:(KSNRefreshViewPosition)position
{
    KSNRefreshView *refreshView = [[KSNRefreshView alloc] initWithPosition:position];

    if (KSNRefreshViewPositionHorizontal(position))
    {
        if (self.showLogo && position == KSNRefreshViewPositionTop)
        {
            KSNLogoRefreshView *logoRefreshView = [[KSNLogoRefreshView alloc] initWithPosition:KSNRefreshViewPositionTop];
            logoRefreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [logoRefreshView sizeToFit];
            CGRect refreshRect = logoRefreshView.frame;
            refreshRect.size.width = CGRectGetWidth(self.view.bounds);
            logoRefreshView.frame = refreshRect;
            return logoRefreshView;
        }
        else
        {
            refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            CGRect refreshRect = refreshView.frame;
            refreshRect.size.width = CGRectGetWidth(self.view.bounds);
            refreshView.frame = refreshRect;
        }
    }
    else if (KSNRefreshViewPositionVertical(position))
    {

        refreshView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        CGRect refreshRect = refreshView.frame;
        refreshRect.size.height = CGRectGetHeight(self.view.bounds);
        refreshView.frame = refreshRect;
    }

    switch (position)
    {
        case KSNRefreshViewPositionTop:
            refreshView.pullTitle = NSLocalizedString(@"refresh.pulldown", @"KSNCollectionViewController: \"Pull down for refresh\" title");
            refreshView.releaseTitle = NSLocalizedString(@"refresh.release", @"KSNCollectionViewController: \"Release for refresh\" title");
            break;
        case KSNRefreshViewPositionBottom:
            refreshView.pullTitle = NSLocalizedString(@"refresh.pulldown.nextpage", @"KSNCollectionViewController: \"Pull up for next page\" title");
            refreshView.releaseTitle = NSLocalizedString(@"refresh.release.nextpage", @"KSNCollectionViewController: \"Release for next page\" title");
            break;
        case KSNRefreshViewPositionLeft:
            refreshView.pullTitle = NSLocalizedString(@"refresh.pullright", @"KSNCollectionViewController: \"Pull right for refresh\" title");
            refreshView.releaseTitle = NSLocalizedString(@"refresh.release", @"KSNCollectionViewController: \"Release for refresh\" title");
            break;
        case KSNRefreshViewPositionRight:
            refreshView.pullTitle = NSLocalizedString(@"refresh.pullleft.nextpage", @"KSNCollectionViewController: \"Pull left for next page\" title");
            refreshView.releaseTitle = NSLocalizedString(@"refresh.release.nextpage", @"KSNCollectionViewController: \"Release for next page\" title");
            break;

        default:
            break;
    }

    [refreshView sizeToFit];

    return refreshView;
}

- (void)createRefreshControls
{
    if ([self isVerticalDirection])
    {
        self.topRefreshView = [self createRefreshViewWithPosition:KSNRefreshViewPositionTop];
        self.bottomRefreshView = [self createRefreshViewWithPosition:(KSNRefreshViewPositionBottom)];
        [self.view addSubview:self.topRefreshView];
        [self.view addSubview:self.bottomRefreshView];
        self.topRefresher.refreshView = self.topRefreshView;
        self.bottomRefresher.refreshView = self.bottomRefreshView;
    }
    else
    {
        self.leftRefreshView = [self createRefreshViewWithPosition:(KSNRefreshViewPositionLeft)];
        self.rightRefreshView = [self createRefreshViewWithPosition:(KSNRefreshViewPositionRight)];
        [self.view addSubview:self.leftRefreshView];
        [self.view addSubview:self.rightRefreshView];
        self.leftRefresher.refreshView = self.leftRefreshView;
        self.rightRefresher.refreshView = self.rightRefreshView;
    }

    [self.view bringSubviewToFront:self.collectionView];
    self.refreshMediator.scrollView = self.collectionView;
}

- (void)createRefreshMediator
{
    NSMutableArray *refreshers = [NSMutableArray array];
    if ([self isVerticalDirection])
    {
        self.topRefresher = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionTop];
        [refreshers addObject:self.topRefresher];
        self.bottomRefresher = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionBottom];
        [refreshers addObject:self.bottomRefresher];
    }
    else
    {
        self.leftRefresher = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionLeft];
        [refreshers addObject:self.leftRefresher];
        self.rightRefresher = [[KSNRefreshMediatorInfo alloc] initWithPosition:KSNRefreshViewPositionRight];
        [refreshers addObject:self.rightRefresher];
    }
    self.refreshMediator = [[KSNRefreshMediator alloc] initWithRefreshInfo:refreshers];
    CGFloat delta = 0.5f * CGRectGetHeight([[UIScreen mainScreen] applicationFrame]);
    self.bottomRefresher.remainOffset = CGPointMake(0, delta);
    self.rightRefresher.remainOffset = CGPointMake(delta, 0);
    self.refreshMediator.delegate = self;
}

- (void)createDisableOverlayViewIfNeeded
{
    if (!self.disableOverlay)
    {
        UIView *view = [[UIView alloc] initWithFrame:self.collectionView.frame];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
        disableRect.size.height = self.collectionView.contentSize.height;
        disableRect.size.width = self.collectionView.contentSize.width;
        self.disableOverlay.frame = disableRect;
        self.disableOverlay.backgroundColor = [UIColor clearColor];
        [self.collectionView addSubview:self.disableOverlay];
        self.collectionView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//#pragma message("TODO: (Sergey) !!!")

//            self.disableOverlay.backgroundColor = [UIColor wk_disableOverlayColor];
        }                completion:NULL];
    }
}

- (void)removeDisableOverlay
{
    self.collectionView.userInteractionEnabled = YES;
    if (self.disableOverlay.superview)
    {
        [self.disableOverlay removeFromSuperview];
    }
}

- (BOOL)isVerticalDirection
{
    UICollectionViewFlowLayout *flowLayout = KSNSafeCast([UICollectionViewFlowLayout class], self.collectionView.collectionViewLayout);
    if (flowLayout)
    {
        return flowLayout.scrollDirection == UICollectionViewScrollDirectionVertical;
    }
    else
    {
        return YES;
    }
}

- (void)updatePageNumbers
{
    if (self.pagingDataSource)
    {
        KSNRefreshMediatorInfo *nextPageRefresher = [self isVerticalDirection] ? self.bottomRefresher : self.rightRefresher;
        KSNRefreshMediatorInfo *refreshPageRefresher = [self isVerticalDirection] ? self.topRefresher : self.leftRefresher;

        NSUInteger currentPage = [self.pagingDataSource currentPage];
        NSUInteger numberOfPages = [self.pagingDataSource numberOfPages];

        nextPageRefresher.refreshEnabled = (currentPage + 1 < numberOfPages);
        refreshPageRefresher.refreshEnabled = YES;
    }
    else
    {
        self.bottomRefresher.refreshEnabled = NO;
        self.bottomRefresher.refreshEnabled = YES;
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
                CGRect viewRect = [self.collectionView.superview convertRect:endFrame fromView:self.view.window];
                CGFloat bottomInset = CGRectGetHeight(self.collectionView.bounds) - viewRect.origin.y;

                UIEdgeInsets contentInsets = self.collectionView.contentInset;
                UIEdgeInsets scrollIndicatorInsets = self.collectionView.scrollIndicatorInsets;

                if (show)
                {
                    if (!wasShowed)
                    {
                        initialContentInsets = self.collectionView.contentInset;
                        initialScrollIndicatorInsets = self.collectionView.scrollIndicatorInsets;
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

                self.collectionView.contentInset = contentInsets;
                self.collectionView.scrollIndicatorInsets = scrollIndicatorInsets;

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
        [self.observationInfoSet enumerateObjectsUsingBlock:^(id observer, BOOL *stop) {
            [center removeObserver:observer];
        }];

        [self.observationInfoSet removeAllObjects];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.dataSource numberOfSections] ?: 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseId = [self.viewModel cellReuseIdAtIndexPath:indexPath];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseId forIndexPath:indexPath];

    if ([self.viewModel respondsToSelector:@selector(customizeCell:forCollectionView:atIndexPath:)])
    {
        [self.viewModel customizeCell:cell forCollectionView:collectionView atIndexPath:indexPath];
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseId = [self.viewModel supplementaryViewReuseIdOfKind:kind atIndexPath:indexPath];
    UICollectionReusableView *collectionReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                          withReuseIdentifier:cellReuseId
                                                                                                 forIndexPath:indexPath];
    if ([self.viewModel respondsToSelector:@selector(customizeSupplementaryVie:forCollectionView:OfKind:forIndexPath:)])
    {
        [self.viewModel customizeSupplementaryVie:collectionReusableView forCollectionView:collectionView OfKind:kind forIndexPath:indexPath];
    }

    return collectionReusableView;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.viewModel respondsToSelector:@selector(didSelectCell:atIndexPath:selectedIndexes:)])
    {
        [self.viewModel didSelectCell:[collectionView cellForItemAtIndexPath:indexPath]
                          atIndexPath:indexPath
                      selectedIndexes:[collectionView indexPathsForSelectedItems]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.viewModel respondsToSelector:@selector(didDeselectCell:atIndexPath:selectedIndexes:)])
    {
        [self.viewModel didDeselectCell:[collectionView cellForItemAtIndexPath:indexPath]
                            atIndexPath:indexPath
                        selectedIndexes:[collectionView indexPathsForSelectedItems]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.viewModel respondsToSelector:@selector(cellSizeAtIndexPath:forCollectionView:)])
    {
        return [self.viewModel cellSizeAtIndexPath:indexPath forCollectionView:collectionView];
    }
    else
    {
        UICollectionViewFlowLayout *flowLayout = KSNSafeCast([UICollectionViewFlowLayout class], collectionViewLayout);
        return flowLayout.itemSize;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([self.viewModel respondsToSelector:@selector(sizeForHeaderInSection:forCollectionView:)])
    {
        return [self.viewModel sizeForHeaderInSection:section forCollectionView:collectionView];
    }
    else
    {
        UICollectionViewFlowLayout *flowLayout = KSNSafeCast([UICollectionViewFlowLayout class], collectionViewLayout);
        return flowLayout.headerReferenceSize;
    }
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath isHeld:(BOOL)held
{
    if ([self.viewModel respondsToSelector:@selector(moveItemAtIndexPath:toIndexPath:isHeld:)])
    {
        [self.viewModel moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath isHeld:held];
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshMediator scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshMediator scrollViewDidEndDragging];
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
        if ([self isVerticalDirection])
        {
            if (self.collectionView.contentOffset.y == -self.collectionView.contentInset.top)
            {
                self.collectionView.contentOffset = CGPointMake(-self.listInsets.left, -self.listInsets.top);
            }
        }
        else
        {
            if (self.collectionView.contentOffset.x == -self.collectionView.contentInset.left)
            {
                self.collectionView.contentOffset = CGPointMake(-self.listInsets.left, -self.listInsets.top);
            }
        }

        self.collectionView.contentInset = self.listInsets;
        self.collectionView.scrollIndicatorInsets = self.scrollIndicatorInsets;

        [self.refreshMediator scrollViewContentInsetsChanged];
    }
}

- (void)setDataSource:(id <KSNDataSource>)dataSource
{
    if (_dataSource != dataSource)
    {
        [_dataSource removeChangeObserver:self];
        _dataSource = dataSource;
        [_dataSource addChangeObserver:self];

        [self updatePageNumbers];

        if ([self isViewLoaded])
        {
            [self.collectionView reloadData];
        }

        [self.topRefresher setRefreshing:NO animated:NO];
        [self.leftRefresher setRefreshing:NO animated:NO];
        [self.bottomRefresher setRefreshing:NO animated:NO];
        [self.rightRefresher setRefreshing:NO animated:NO];
    }
}

- (void)setViewModel:(id <KSNCollectionViewModelTraits>)viewModel
{
    if (_viewModel != viewModel)
    {
        _viewModel = viewModel;
        if ([self isViewLoaded])
        {
            [self registerCells];
            [self.collectionView reloadData];
        }
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

#pragma mark - Private Helpers

- (void)deleteRowAtIndexPath:(NSIndexPath *)ip
{
    // Send the deleted cell to back of the view hierarchy. For some reason
    // UITableViewRowAnimationNone slides the neighbouring cell under the deleted
    // cell, which gives a weird animation.
//    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:ip];
//    [cell.superview sendSubviewToBack:cell];
    [self.collectionView deleteItemsAtIndexPaths:@[ip]];
}

- (void)addRowAtIndexPath:(NSIndexPath *)ip
{
    [self.collectionView insertItemsAtIndexPaths:@[ip]];
//    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:ip];
//    [cell.superview sendSubviewToBack:cell];
}

#pragma mark - TRADataSourceObserver

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    if (dataSource == self.dataSource && self.isVisible)
    {
        [self.collectionView reloadData];
        [self setupViewsWithError:error];

        self.bottomRefresher.remainOffset = CGPointZero;
        self.rightRefresher.remainOffset = CGPointZero;

        [self.topRefresher setRefreshing:NO animated:NO];
        [self.leftRefresher setRefreshing:NO animated:NO];
        [self.bottomRefresher setRefreshing:NO animated:NO];
        [self.rightRefresher setRefreshing:NO animated:NO];
    }
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    if (self.isVisible)
    {
        [self.collectionView reloadData];
        [self.collectionView layoutIfNeeded]; // contentSize will be changed only after layout
        [self setupViewsLoaded];

        if (self.pagingDataSource.dataWasRefreshed)
        {
            [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            if ([self isVerticalDirection])
            {
                [self.topRefresher setRefreshing:NO animated:YES];
            }
            else
            {
                [self.leftRefresher setRefreshing:NO animated:YES];
            }
        }
        else
        {
            [self.topRefresher setRefreshing:NO animated:NO];
            [self.leftRefresher setRefreshing:NO animated:NO];
        }

        [self.bottomRefresher setRefreshing:NO animated:NO];
        [self.rightRefresher setRefreshing:NO animated:NO];
    }
    else
    {
        self.reloadDataOnViewWillAppear = YES;
    }
}

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource && self.isVisible)
    {
        [self setupViewsWithLoading];
    }
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    // NO-OP (views will be set up accordingly in the success / error handling)
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    if (self.isVisible)
    {
        if (dataSource == self.dataSource)
        {
            @weakify(self);
            void (^updateBlock)(void) = ^(void) {
                @strongify(self);
                switch (change)
                {
                    case KSNDataSourceChangeTypeInsert:
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                        break;

                    case KSNDataSourceChangeTypeRemove:
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                        break;

                    case KSNDataSourceChangeTypeUpdate:
                    {
                        if (!self.reloadHeadersOnDataUpdates)
                        {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

                            __block UICollectionReusableView *collectionReusableView = nil;

                            if (KSN_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
                            {
                                collectionReusableView = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader
                                                                                                  atIndexPath:indexPath];
                            }
                            else
                            {
                                UICollectionViewLayoutAttributes *supplementaryAttributes = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
                                                                                                                                                   atIndexPath:indexPath];

                                [self.collectionView ksn_enumerateSubviews:^(UIView *view, NSUInteger depth, BOOL *recurse) {
                                    if ([view isKindOfClass:[UICollectionReusableView class]] && ![view isKindOfClass:[UICollectionViewCell class]])
                                    {
                                        if (CGRectContainsPoint(view.frame, supplementaryAttributes.center))
                                        {
                                            collectionReusableView = (id) view;
                                        }
                                        *recurse = NO;
                                    }
                                }];
                            }

                            if ([self.viewModel respondsToSelector:@selector(customizeSupplementaryVie:forCollectionView:OfKind:forIndexPath:)])
                            {
                                [self.viewModel customizeSupplementaryVie:collectionReusableView
                                                        forCollectionView:self.collectionView
                                                                   OfKind:UICollectionElementKindSectionHeader
                                                             forIndexPath:indexPath];
                            }
                        }
                        else
                        {
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                        }
                    }
                        break;

                    case KSNDataSourceChangeTypeMove:
                        NSAssert(YES, @"Unsupported type: KSNDataSourceChangeTypeMove");
                        break;
                }
            };

            [self.updateBlocks addObject:updateBlock];
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
        if (dataSource == self.dataSource)
        {
            @weakify(self);
            void (^updateBlock)(void) = ^(void) {
                @strongify(self);
                switch (type)
                {
                    case KSNDataSourceChangeTypeInsert:
                        [self addRowAtIndexPath:indexPath];
                        break;

                    case KSNDataSourceChangeTypeRemove:
                        [self deleteRowAtIndexPath:indexPath];
                        break;

                    case KSNDataSourceChangeTypeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                        break;

                    case KSNDataSourceChangeTypeMove:
                        [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
                        break;
                }
            };

            [self.updateBlocks addObject:updateBlock];
        }
    }
    else
    {
        self.reloadDataOnViewWillAppear = YES;
    }
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource && self.isVisible)
    {
        self.updateBlocks = [NSMutableArray array];
    }
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource && self.isVisible)
    {
        NSArray *updates = [self.updateBlocks copy];
        [self.collectionView performBatchUpdates:^{
            [updates enumerateObjectsUsingBlock:^(KSNVoidBlock block, NSUInteger idx, BOOL *stop) {
                block();
            }];
        }                             completion:^(BOOL finished) {
            //            self.collectionViewBatchUpdatesBlocks = nil;
        }];

        [self setupViewsLoaded];
    }
}

#pragma mark - TRARefreshMediatorDelegate

- (void)refreshMediator:(KSNRefreshMediator *)mediator didTriggerUpdateAtPossition:(KSNRefreshMediatorInfo *)position
{
    if (self.pagingDataSource && !self.pagingDataSource.isLoading)
    {
        if (position == self.topRefresher || position == self.leftRefresher)
        {
            [self.pagingDataSource refreshWithUserInfo:nil];
        }
        else if (position == self.bottomRefresher || position == self.rightRefresher)
        {
            [self.pagingDataSource pageDownWithUserInfo:nil];
        }
    }
}

@end
