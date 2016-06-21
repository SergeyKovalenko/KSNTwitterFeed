//
//  KSNReachabilityViewModel.m

//
//  Created by Dmytro Zavgorodniy on 1/30/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNReachabilityViewModel.h"
#import <KSNUtils/KSNGlobalFunctions.h>
#import <KSNDataSource/KSNDataSource.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNErrorHandler/KSNErrorHandler.h>

@interface KSNReachabilityViewModel () <KSNDataSourceObserver>

@property (nonatomic, readwrite, getter=isLoading) BOOL loading;

// refactor
@property (nonatomic, strong) NSError *error;

@property (nonatomic, assign, readwrite) BOOL instructionsViewHidden;

@property (nonatomic, strong, readwrite) NSString *instructionsTitle;

@property (nonatomic, strong, readwrite) NSString *instructionsSubtitle;

@property (nonatomic, strong, readwrite) NSError *reachabilityError;

@property (nonatomic, strong) RACTuple *p_noItemsTexts;
@property (nonatomic, strong) RACTuple *p_loadingTexts;
@property (nonatomic, strong) RACTuple *p_errorTexts;

@property (nonatomic, assign) BOOL p_alwaysInstructionsViewHidden;

@property (nonatomic, assign) BOOL p_alwaysInstructionsRefreshEnabled;

@property (nonatomic, copy) NSString *p_infoStatusViewNibName;

@end

@implementation KSNReachabilityViewModel

@synthesize instructionsViewHidden = _instructionsViewHidden;
@synthesize instructionsTitle = _instructionsTitle;
@synthesize instructionsSubtitle = _instructionsSubtitle;
@synthesize refreshEnabled = _refreshEnabled;
@synthesize fakeLoadingDuration = _fakeLoadingDuration;
@synthesize instructionsViewTintColor = _instructionsViewTintColor;
@synthesize instructionsViewBackgroundColor = _instructionsViewBackgroundColor;
@synthesize reachabilityError = _reachabilityError;

#pragma mark - Initialization

- (instancetype)init
{
    return [self initWithDataSource:nil];
}

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource
{
    self = [super init];
    if (self)
    {
        _instructionsViewTintColor = [UIColor blackColor];
//#pragma message("TODO: (Sergey) !!!")

        _instructionsViewBackgroundColor = [UIColor grayColor];//[UIColor wk_colorWithR:230 G:230 B:230];
        
        _instructionsViewHidden = YES;
        _refreshEnabled = YES;

        _fakeLoadingDuration = 2.0f;

        _p_noItemsTexts = [RACTuple tupleWithObjectsFromArray:
                           @[
                             NSLocalizedString(@"info.noresults.title", @"KSNFeedViewModel: \"No Matching Products\" no results title"),
                             NSLocalizedString(@"info.noresults.subtitle", @"KSNFeedViewModel: \"Try change your filter to find more matching products.\" no results subtitle")
                             ]];

        _p_loadingTexts = [RACTuple tupleWithObjectsFromArray:
                           @[
                             NSLocalizedString(@"info.loading.title", @"KSNFeedViewModel: \"Loading...\" loading title"),
                             NSLocalizedString(@"info.loading.subtitle", @"KSNFeedViewModel: \"Look Out Behind You.\" loading subtitle")
                             ]];
        
        _p_errorTexts = [RACTuple tupleWithObjectsFromArray:
                         @[
                           NSLocalizedString(@"info.error.title", @"KSNFeedViewModel: \"No Internet Connection\" error title"),
                           NSLocalizedString(@"info.error.subtitle", @"KSNFeedViewModel: \"Wifi or data connection required.\" error subtitle")
                           ]];
        self.dataSource = dataSource;

    }
    return self;
}

- (void)dealloc
{
    self.dataSource = nil;
}

#pragma mark - Properties

- (void)setDataSource:(id<KSNDataSource>)dataSource
{
    if (_dataSource != dataSource)
    {
        [_dataSource removeChangeObserver:self];
        
        _dataSource = dataSource;
        
        [self p_handleSourceLoading:self.pagingDataSource.isLoading error:nil];
        
        [_dataSource addChangeObserver:self];
    }
}

- (id <KSNPagingDataSource>)pagingDataSource
{
    return KSNSafeProtocolCast(@protocol(KSNPagingDataSource), self.dataSource);
}

- (NSString *)infoStatusViewNibName
{
    return self.p_infoStatusViewNibName;
}

#pragma mark - Public

- (void)setInstructionsNoItemsTitle:(NSString *)title
{
    NSParameterAssert(title);
    self.p_noItemsTexts = [RACTuple tupleWithObjectsFromArray:@[title, [self.p_noItemsTexts second]]];
    
    // refactor
    [self p_handleSourceLoading:self.loading error:self.error];
}

- (void)setInstructionsNoItemsSubtitle:(NSString *)subtitle
{
    NSParameterAssert(subtitle);
    self.p_noItemsTexts = [RACTuple tupleWithObjectsFromArray:@[[self.p_noItemsTexts first], subtitle]];
    
    // refactor
    [self p_handleSourceLoading:self.loading error:self.error];
}

- (void)setInstructionsViewTintColor:(UIColor *)color
{
    _instructionsViewTintColor = color;
}

- (void)setInstructionsViewBackgroundColor:(UIColor *)color
{
    _instructionsViewBackgroundColor = color;
}

- (void)setAlwaysInstructionsViewHidden:(BOOL)alwaysHidden
{
    self.p_alwaysInstructionsViewHidden = alwaysHidden;
    if (alwaysHidden)
    {
        self.instructionsViewHidden = YES;
    }
}

- (void)refresh:(id)sender
{
    if (self.refreshEnabled)
    {
        [self.pagingDataSource refreshWithUserInfo:nil];
    }
}

#pragma mark - TRADataSourceObserver

- (void)dataSourceBeginNetworkUpdate:(id<KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource)
    {
        [self p_handleSourceLoading:self.pagingDataSource.loading error:nil];
    }
}

- (void)dataSourceEndNetworkUpdate:(id<KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource)
    {
        [self p_handleSourceLoading:self.pagingDataSource.loading error:nil];
    }
}

- (void)dataSource:(id<KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    if (dataSource == self.dataSource)
    {
        [self p_handleSourceLoading:self.pagingDataSource.loading error:error];
    }
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource
{
    if (dataSource == self.dataSource)
    {
        [self p_handleSourceLoading:self.pagingDataSource.loading error:nil];
    }
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    if (dataSource == self.dataSource)
    {
        [self p_handleSourceLoading:self.pagingDataSource.loading error:nil];
    }
}

#pragma mark - Private

- (void)p_setInstructionsForNoResults
{
    self.instructionsTitle = [self.p_noItemsTexts first];
    self.instructionsSubtitle = [self.p_noItemsTexts second];
}

- (void)p_setInstructionsWithError:(NSError *)error
{
    if (KSNIsNetworkError(error))
    {
        self.instructionsTitle = [self.p_errorTexts first];
        self.instructionsSubtitle = [self.p_errorTexts second];
    }
    else
    {
        NSString *title = NSLocalizedString(@"application.error.default.alert.title", @"TRAAppDelegate: \"An error occurred, please try again later\" alert title");

        NSString *localizedDescription = [error localizedDescription];
        if ([localizedDescription length] == 0)
        {
            localizedDescription = @"";
        }
#ifdef DEBUG
        NSString *messageFormat = NSLocalizedString(@"application.error.default.alert.message", @"TRAAppDelegate: \"%@\nDomain=%@, Code=%d\", localized description, error domain, error code");
        NSString *message = [NSString stringWithFormat:messageFormat, localizedDescription, error.domain, error.code];
#else
        NSString *message = localizedDescription;
#endif
        self.instructionsTitle = title;
        self.instructionsSubtitle = message;
    }
    
}

- (void)p_setInstructionsForLoading
{
    self.instructionsTitle = [self.p_loadingTexts first];
    self.instructionsSubtitle = [self.p_loadingTexts second];
}

- (void)p_handleSourceLoading:(BOOL)loading error:(NSError *)error
{
    self.loading = loading;
    self.error = error;
    
    if (loading)
    {
        [self p_setInstructionsForLoading];
        self.refreshEnabled = NO;
    }
    else if (!error && [self.dataSource count] == 0)
    {
        [self p_setInstructionsForNoResults];
        self.refreshEnabled = self.p_alwaysInstructionsRefreshEnabled && [self.dataSource respondsToSelector:@selector(refresh)];
    }
    else if (error && [self.dataSource count] == 0)
    {
        [self p_setInstructionsWithError:error];
        self.refreshEnabled = self.p_alwaysInstructionsRefreshEnabled && [self.dataSource respondsToSelector:@selector(refresh)];
    }
    else
    {
        self.reachabilityError = error;
    }
    
    self.instructionsViewHidden = self.p_alwaysInstructionsViewHidden ?: [self.dataSource count] > 0;
}

- (void)setAlwaysInstructionsRefreshEnabled:(BOOL)refreshEnabled {
	self.p_alwaysInstructionsRefreshEnabled = refreshEnabled;
}

- (void)setInfoStatusViewNibName:(NSString *)nibName
{
    self.p_infoStatusViewNibName = nibName;
}

@end
