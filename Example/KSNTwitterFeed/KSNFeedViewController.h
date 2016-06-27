//
// Created by Sergey Kovalenko on 5/24/16.
// Copyright (c) 2016 Windmill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <KSNDataSource/KSNDataSource.h>
#import <KSNTwitterFeed/KSNTwitterFeed.h>

@class KSNLoadingView;

NS_ASSUME_NONNULL_BEGIN

@protocol KSNCellNodeDataSource <KSNFeedDataSource>

- (ASCellNode *)cellNodeAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (ASCellNodeBlock)cellNodeBlockAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface KSNFeedViewController : ASViewController

@property (nonatomic, strong) __nullable id <KSNCellNodeDataSource> dataSource;
@end

NS_ASSUME_NONNULL_END