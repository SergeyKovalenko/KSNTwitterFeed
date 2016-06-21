//
//  KSNSearchBar.h
//
//  Created by Sergey Kovalenko on 12/3/15.
//  Copyright © 2015. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSNSearchController.h"

@interface KSNSearchBar : UIControl <KSNSearchBar>

@property (nonatomic, weak) id <TRASearchBarDelegate> delegate;
@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSArray *scopeButtonTitles;

@property (nonatomic, strong, readonly) UISearchBar *searchBar;

@end
