//
// Created by Sergey Kovalenko on 6/26/16.
//

#import <Foundation/Foundation.h>
#import "KSNFeedDataProvider.h"

@class KSNTwitterAPI;
@class NSManagedObjectContext;
@class NSFetchRequest;

@interface KSNTwitterManagedObjectFeedContext : NSObject <KSNFeedDataProviderContext>

- (instancetype)initWithAPI:(KSNTwitterAPI *)api managedObjectContect:(NSManagedObjectContext *)context;

@property (nonatomic, assign) NSInteger pageSize;

- (NSFetchRequest *)feedRequest;

@end