//
//  KSNLogoRefreshView.h

//
//  Created by Sergey Kovalenko on 2/25/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNRefreshingView.h"
#import "KSNRefreshMediator.h"
#import <KSNXibLoadedView/KSNXibLoadedView.h>

@interface KSNLogoRefreshView : KSNXibLoadedView <KSNRefreshingView>

- (instancetype)initWithPosition:(KSNRefreshViewPosition)position;
@property (nonatomic, readonly) KSNRefreshViewPosition position;

@end
