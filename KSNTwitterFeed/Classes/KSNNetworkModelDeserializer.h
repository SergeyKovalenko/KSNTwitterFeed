//
//  KSNNetworkModelDeserializer.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//

#import <Foundation/Foundation.h>
#import <KSNNetworkClient/KSNNetworkClient.h>
#import "KSNTwitterAPI.h"

NS_ASSUME_NONNULL_BEGIN

@class FEMMapping;
@class FEMDeserializer;

@interface KSNNetworkModelDeserializer : NSObject <KSNTwitterResponseDeserializer>

- (instancetype)initWithModelMapping:(FEMMapping *)mapping;
- (instancetype)initWithModelMapping:(FEMMapping *)mapping JSONNormalizationBlock:(nullable id (^)(id, NSError **))normalizationBlock;
- (instancetype)initWithModelMapping:(FEMMapping *)mapping
                             context:(NSManagedObjectContext *)context
              JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock;

@property (nonatomic, strong, readonly) FEMDeserializer *deserializer;
@property (nonatomic, strong, readonly) FEMMapping *mapping;

@end

NS_ASSUME_NONNULL_END