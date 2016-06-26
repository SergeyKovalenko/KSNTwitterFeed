//
// Created by Sergey Kovalenko on 6/26/16.
//

#import <Foundation/Foundation.h>
#import "KSNTwitterFeedDataProvider.h"

@class KSNTwitterAPI;
@class KSNNetworkModelDeserializer;

@interface KSNTwitterManagedObjectFeedContext : NSObject <KSNTwitterFeedContext>

- (instancetype)initWithAPI:(KSNTwitterAPI *)api managedObjectContect:(NSManagedObjectContext *)context;
@end