//
//  KSNXibLoadedTableViewHeaderFooterView.m
//  Pods
//
//  Created by Sergey Kovalenko on 3/7/16.
//
//

#import "KSNXibLoadedTableViewHeaderFooterView.h"
#import <Masonry/Masonry.h>

@interface KSNXibLoadedTableViewHeaderFooterView ()

@property (nonatomic, copy, readwrite) NSString *nibName IBInspectable;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong, readwrite) IBOutlet UIView *containerView;

@end

@implementation KSNXibLoadedTableViewHeaderFooterView

- (instancetype)initWithReuseIdentifier:(nullable NSString *)reuseIdentifier
{
    return [self initWithNibName:nil bundle:nil reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundle reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
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
    return [self initWithNibName:nibNameOrNil bundle:nil reuseIdentifier:NSStringFromClass(self.class)];
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
    if (!_containerView)
    {
        [self loadXibContent];
    }
    return _containerView;
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
    [_containerView removeFromSuperview];
    
    [[self nib] instantiateWithOwner:self options:nil];
    
    if (!_containerView)
    {
        NSAssert(@"IBOutlet 'containerView' of %@ didn't set", self);
    }
    
    [self.contentView addSubview:_containerView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [self xibContentLoaded];
}

- (void)xibContentLoaded
{
    
}

@end
