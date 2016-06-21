//
//  KSNCollapsibleComponent.h
//
//  Created by Sergey Kovalenko on 11/1/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNComponent.h"

@protocol WKCollapsibleComponentTraits <KSNComponentTraits>

@property (nonatomic, assign, getter=isCollapsed) BOOL collapsed;

- (NSArray *)expandedComponents;

@end

@interface KSNCollapsibleComponent : KSNComponent <WKCollapsibleComponentTraits>
@end

@interface WKExcludeSelfComponent : KSNCollapsibleComponent
@end

@interface WKSingleSelectionCollapsibleComponent : KSNCollapsibleComponent
@end

@interface WKMultipleSelectionCollapsibleComponent : KSNCollapsibleComponent
@end

@interface WKSortOrderCollapsibleComponent : KSNCollapsibleComponent
@end