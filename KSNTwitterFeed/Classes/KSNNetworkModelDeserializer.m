//
//  KSNNetworkModelDeserializer.m
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//

#import <FastEasyMapping/FEMDeserializer.h>
#import "KSNNetworkModelDeserializer.h"
#import "FEMManagedObjectStore.h"
#import <KSNUtils/KSNGlobalFunctions.h>

@interface KSNNetworkModelDeserializer ()

@property (nonatomic, strong, readwrite) FEMDeserializer *deserializer;
@property (nonatomic, strong, readwrite) FEMMapping *mapping;
@property (nonatomic, copy) id (^normalizationBlock)(id, NSError **);
@end

@implementation KSNNetworkModelDeserializer

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
{
    return [self initWithModelMapping:mapping JSONNormalizationBlock:nil];
}

- (instancetype)initWithModelMapping:(FEMMapping *)mapping JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    return [self initWithModelMapping:mapping context:nil JSONNormalizationBlock:normalizationBlock];
}

- (instancetype)initWithModelMapping:(FEMMapping *)mapping
                             context:(NSManagedObjectContext *)context
              JSONNormalizationBlock:(id (^)(id, NSError **))normalizationBlock
{
    self = [super init];
    if (self)
    {
        FEMObjectStore *store = context ? [[FEMManagedObjectStore alloc] initWithContext:context] : [[FEMObjectStore alloc] init];
        self.deserializer = [[FEMDeserializer alloc] initWithStore:store];
        self.mapping = mapping;
        self.normalizationBlock = normalizationBlock;
    }
}

- (id)parseJSON:(id)json error:(NSError **)pError
{
    id representation = nil;
    if (self.normalizationBlock)
    {
        representation = self.normalizationBlock(json, pError);
    }
    else
    {
        representation = json;
    }

    return representation ? [self objectFromRepresentation:representation] : nil;
}

- (id)objectFromRepresentation:(id)representation
{
    if (KSNSafeCast([NSArray class], representation))
    {
        return [self.deserializer collectionFromRepresentation:representation mapping:self.mapping];
    }
    else if (KSNSafeCast([NSDictionary class], representation))
    {
        return [self.deserializer objectFromRepresentation:representation mapping:self.mapping];
    }
    else
    {
        NSAssert(NO, @"Unsupported representation class %@ - %@", NSStringFromClass([representation class]), representation);
        return nil;
    }
}

@end