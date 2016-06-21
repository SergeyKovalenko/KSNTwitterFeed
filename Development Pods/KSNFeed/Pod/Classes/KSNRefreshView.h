//
//  KSNRefreshView.h

//
//  Created by Sergey Kovalenko on 12/29/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSNRefreshingView.h"
#import "KSNRefreshMediator.h"

@interface KSNRefreshView : UIView <KSNRefreshingView>

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position;

@property (nonatomic, readonly) KSNRefreshViewPosition position;

@property (nonatomic, copy) NSString *pullTitle;
@property (nonatomic, copy) NSString *releaseTitle;
@end
