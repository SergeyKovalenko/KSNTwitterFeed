//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNFeedDataSource.h"
#import "KSNFeedViewController.h"

typedef ASCellNode *(^KSNCellNodeConfigurationBlock)(id model);

@interface KSNCellNodeDataSource : KSNFeedDataSource <KSNCellNodeDataSource>

@property (nonatomic, copy) KSNCellNodeConfigurationBlock configurationBlock;
@end