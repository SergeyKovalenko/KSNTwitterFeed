//
//  KSNSearchableTraits.h
//
//  Created by Sergey Kovalenko on 11/5/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol KSNSearchableTraits <NSObject>

- (void)startSearchWithTerm:(NSString *)string userInfo:(NSDictionary *)info;
- (void)endSearch;

@end
