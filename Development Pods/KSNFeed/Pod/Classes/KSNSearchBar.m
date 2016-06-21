//
//  KSNSearchBar.m

//
//  Created by Sergey Kovalenko on 12/3/15.
//  Copyright © 2015. All rights reserved.
//

#import "KSNSearchBar.h"

@interface KSNSearchBar () <UISearchBarDelegate>

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@end

@implementation KSNSearchBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    if (!self.searchBar)
    {
        self.searchBar = [[UISearchBar alloc] initWithFrame:self.bounds];
        self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.searchBar];
    }
    self.searchBar.delegate = self;
}

- (BOOL)canBecomeFirstResponder
{
    return [self.searchBar canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [self.searchBar becomeFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    return [self.searchBar canResignFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.searchBar resignFirstResponder];
}

- (BOOL)isFirstResponder
{
    return [self.searchBar isFirstResponder];
}

- (CGSize)intrinsicContentSize
{
    return [self.searchBar intrinsicContentSize];
}

- (void)setText:(NSString *)text
{
    self.searchBar.text = text;
}

- (NSString *)text
{
    return self.searchBar.text;
}

- (void)setScopeButtonTitles:(NSArray *)scopeButtonTitles {
	self.searchBar.scopeButtonTitles = scopeButtonTitles;
	self.searchBar.showsScopeBar = (scopeButtonTitles.count > 0);
	[self.searchBar sizeToFit];
}

- (NSArray *)scopeButtonTitles {
	return self.searchBar.scopeButtonTitles;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
		[self.delegate searchBarSearchButtonClicked:self];
	}
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(KSNSearchBarEvent)controlEvents
{
    [super addTarget:target action:action forControlEvents:(UIControlEvents) controlEvents];
}

- (BOOL)hasSearchCriteria
{
    return self.searchBar.text.length > 0;
}

- (void)clearSearchCriteria
{
    self.searchBar.text = nil;
}

@end
