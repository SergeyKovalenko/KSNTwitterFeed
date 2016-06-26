//
// Created by Sergey Kovalenko on 6/26/16.
// Copyright (c) 2016 Sergey Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNFeedDataSource.h"

@class NSManagedObjectID;

@interface KSNManagedObjectStore : NSObject <KSNItemsStore>

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors;

@end