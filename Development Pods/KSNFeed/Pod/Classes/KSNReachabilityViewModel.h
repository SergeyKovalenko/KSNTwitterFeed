//
//  KSNReachabilityViewModel.h
//
//  Created by Sergey Kovalenko on 12/15/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KSNDataSource;

@protocol KSNReachabilityViewModel <NSObject>

@property (nonatomic, assign, readonly) BOOL instructionsViewHidden;

@property (nonatomic, strong, readonly) NSString *instructionsTitle;

@property (nonatomic, strong, readonly) NSString *instructionsSubtitle;

@property (nonatomic, strong, readonly) UIColor *instructionsViewTintColor;

@property (nonatomic, strong, readonly) UIColor *instructionsViewBackgroundColor;

@property (nonatomic, assign, getter=isRefreshEnabled) BOOL refreshEnabled;

@property (nonatomic, assign, readonly, getter=isLoading) BOOL loading;

@property (nonatomic, assign) NSTimeInterval fakeLoadingDuration;

@property (nonatomic, strong, readonly) NSError *reachabilityError;

@optional

- (void)refresh:(id)sender;

@property (nonatomic, assign, readonly, getter=isContentDimmed) BOOL dimContent;

- (NSString *)infoStatusViewNibName;

@end

@interface KSNReachabilityViewModel : NSObject <KSNReachabilityViewModel>

- (instancetype)initWithDataSource:(id <KSNDataSource>)dataSource;

@property (nonatomic, strong) id <KSNDataSource> dataSource;

- (void)setInstructionsNoItemsTitle:(NSString *)title;
- (void)setInstructionsNoItemsSubtitle:(NSString *)subtitle;

- (void)setInstructionsViewTintColor:(UIColor *)color;
- (void)setInstructionsViewBackgroundColor:(UIColor *)color;

- (void)setAlwaysInstructionsViewHidden:(BOOL)alwaysHidden;

- (void)setAlwaysInstructionsRefreshEnabled:(BOOL)refreshEnabled;

- (void)setInfoStatusViewNibName:(NSString *)nibName;

@end