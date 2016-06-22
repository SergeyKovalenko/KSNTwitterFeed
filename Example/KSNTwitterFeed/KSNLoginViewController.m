//
//  KSNLoginViewController.m
//  KSNTwitterFeed
//
//  Created by Sergey Kovalenko on 06/21/2016.
//  Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNLoginViewController.h"
#import "KSNTwitterLoginViewModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <KSNErrorHandler/KSNErrorHandler.h>

@interface KSNLoginViewController ()

@property (nonatomic, strong) IBOutlet UIButton *connectButton;
@property (nonatomic, readwrite) KSNTwitterLoginViewModel *viewModel;
@end

@implementation KSNLoginViewController

- (instancetype)initWithViewModel:(KSNTwitterLoginViewModel *)viewModel
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _viewModel = viewModel;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.connectButton.rac_command = self.viewModel.loginCommand;
    [self.viewModel.loginCommand.errors subscribeNext:^(id x) {
        [APP_DELEGATE.errorHandler handleError:x];
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
