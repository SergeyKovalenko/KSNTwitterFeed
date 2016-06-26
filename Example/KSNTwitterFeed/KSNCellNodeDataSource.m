//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import "KSNCellNodeDataSource.h"

@implementation KSNCellNodeDataSource

- (ASCellNodeBlock)cellNodeBlockAtIndexPath:(NSIndexPath *)indexPath;
{
    return ^ASCellNode * {
        return nil;
    };
}

- (ASCellNode *)cellNodeAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(self.configurationBlock);
    id item = [self itemAtIndexPath:indexPath];
    return self.configurationBlock(item);
}



@end