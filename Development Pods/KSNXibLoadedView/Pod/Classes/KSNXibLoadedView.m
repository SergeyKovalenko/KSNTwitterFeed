//
//  KSNXibLoadedView.m
//
//  Created by Sergey Kovalenko on 2/19/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNXibLoadedView.h"
#import <Masonry/Masonry.h>

@interface KSNXibLoadedView ()

@property (nonatomic, copy, readwrite) NSString *nibName IBInspectable;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong, readwrite) IBOutlet UIView *contentView;

@end

@implementation KSNXibLoadedView

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundle
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.nibName = nibNameOrNil;
        self.bundle = bundle;
        [self loadXibContent];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithNibName:nil bundle:nil];
    if (self)
    {
        self.frame = frame;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self loadXibContent];
    }
    return self;
}

- (NSString *)nibName
{
    if (!_nibName)
    {
        _nibName = NSStringFromClass([self class]);
    }
    return _nibName;
}

- (NSBundle *)bundle
{
    if (!_bundle)
    {
        _bundle = [NSBundle bundleForClass:self.class];
    }
    return _bundle;
}

- (UIView *)contentView
{
    if (!_contentView)
    {
        [self loadXibContent];
    }
    return _contentView;
}

- (UINib *)nib
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *staticNibs;
    dispatch_once(&onceToken, ^{
        staticNibs = [NSMutableDictionary dictionary];
    });
    
    UINib *nib = staticNibs[self.nibName];
    
    if (!nib)
    {
        nib = [UINib nibWithNibName:self.nibName bundle:self.bundle];
        staticNibs[self.nibName] = nib;
    }
    return nib;
}

- (void)loadXibContent
{
    [_contentView removeFromSuperview];
    
    [[self nib] instantiateWithOwner:self options:nil];
    
    if (!_contentView)
    {
        NSAssert(@"IBOutlet 'containerView' of %@ didn't set", self);
    }
    
    [self addSubview:_contentView];
    
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self xibContentLoaded];
}

- (void)xibContentLoaded
{

}

@end
