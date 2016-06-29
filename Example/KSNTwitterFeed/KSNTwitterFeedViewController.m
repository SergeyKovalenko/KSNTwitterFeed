//
// Created by Sergey Kovalenko on 6/22/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNTwitterFeedViewController.h"
#import "KSNTwitterFeedViewModel.h"
#import "KSNFeedViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNUtils/UIViewController+KSNChildViewController.h>

@interface KSNTwitterFeedViewController ()

@property (nonatomic, readwrite) KSNTwitterFeedViewModel *viewModel;
@property (nonatomic, strong) UIViewController *childViewController;
@end

@implementation KSNTwitterFeedViewController

- (instancetype)initWithViewModel:(KSNTwitterFeedViewModel *)viewModel
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _viewModel = viewModel;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", @"")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:nil
                                                                                 action:nil];
        self.navigationItem.rightBarButtonItem.rac_command = self.viewModel.logoutCommand;
        RAC(self, title) = RACObserve(viewModel, username);
        KSNFeedViewController *feedViewController = [[KSNFeedViewController alloc] init];
        feedViewController.dataSource = [viewModel feedDataSource];
        self.childViewController = feedViewController;
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithViewModel:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSAssert(NO, @"initWithCoder unsupported");
    return nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self ksn_addChildViewControllerAndSubview:self.childViewController viewAdjustmentBlock:^(UIView *view) {
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.frame = self.view.bounds;
    }];
}

@end