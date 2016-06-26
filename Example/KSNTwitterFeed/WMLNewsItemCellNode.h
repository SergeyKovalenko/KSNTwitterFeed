//
// Created by Sergey Kovalenko on 5/24/16.
// Copyright (c) 2016 Windmill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASCellNode.h>

@class MRKNewsItem;

@interface WMLNewsItemCellNode : ASCellNode

- (instancetype)initWithNewsItems:(MRKNewsItem *)newsItem;

@end